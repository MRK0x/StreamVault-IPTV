import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../core/config.dart';
import '../../core/theme.dart';
import '../../data/models/media_item.dart';
import '../../l10n/app_text.dart';
import '../../player/playback.dart';
import '../../player/resume_store.dart';
import '../../state/providers.dart';
import '../../voice/watch_now_info.dart';
import '../../voice/watch_party_manager.dart';

/// Full-screen player (media_kit / libmpv) — plays `.ts` for live and `.mp4`
/// for VOD from the same server URLs, passing the headers (User-Agent + Bearer
/// + HMAC computed at open time).
///
/// In demo mode (no secrets) it plays a public sample to prove the player
/// works; with HMAC_SECRET it plays the real gateway URL, which resolves (302)
/// to the CDN.
class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({super.key, required this.item});

  final MediaItem item;

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  // Public sample for demo only (libmpv handles .ts the same way).
  static const _demoSample =
      'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4';

  final Player _player = Player();

  late final VideoController _controller = VideoController(_player);
  final List<StreamSubscription> _subs = [];

  bool get _demo => AppConfig.useMockData;
  bool get _isLive => _item.isLive;

  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _playing = true;
  bool _buffering = true;
  String? _error;

  /// The error is caused by auth/signing (401/403), not the channel — a
  /// different message.
  bool _authError = false;
  bool _seekedToResume = false;
  bool _started = false; // playback actually started (audio/video came out)
  int _openRetries = 0;

  bool _controlsVisible = true;
  Timer? _hideTimer;

  /// Playback start watchdog — detects a frozen stream (see
  /// [_armStartWatchdog]).
  Timer? _startWatchdog;

  /// The CDN node we are playing from now — recorded as failed if it doesn't
  /// work, so the next resolve avoids it (~60% of the provider's nodes are
  /// dead and the gateway assigns them randomly).
  String? _cdnHost;

  @override
  void initState() {
    super.initState();
    // We don't force landscape: it stays portrait unless the user rotates the
    // phone, so it never "flips" on its own, and dispose restores portrait.
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _bind();
    _openMedia();
    _scheduleHide();
    _attachWatchParty();
  }

  // ── Watch party ──────────────────────────────────────────────────────

  /// The item currently shown (changes when following a host who switches
  /// content).
  late MediaItem _item = widget.item;

  /// Reference to the watch-party manager — kept for use in dispose without
  /// `ref.read` (so no exception can block player cleanup and orientation
  /// restore after it).
  WatchPartyManager? _wp;

  /// Broadcast what we're watching if we're in a room, and receive updates
  /// from whoever we follow.
  void _attachWatchParty() {
    final wp = ref.read(watchPartyProvider);
    _wp = wp;
    final inRoom = ref.read(voiceRoomProvider).inRoom;

    wp.onFollowUpdate = _applyFollowUpdate;
    wp.onFollowStopped = () {
      // The host left (stop) → we leave with them.
      if (mounted) Navigator.of(context).maybePop();
    };

    if (inRoom && !wp.isFollowing) wp.startBroadcast(_snapshot);
  }

  /// Snapshot of my current state — broadcast every 3s and on every change.
  WatchNowInfo _snapshot() => WatchNowInfo(
        kind: _item.kind,
        streamId: _item.kind == MediaKind.series ? null : _item.id,
        episodeId: _item.kind == MediaKind.series ? _item.id : null,
        title: _item.title,
        image: _item.backdropUrl ?? _item.posterUrl,
        positionMs: _position.inMilliseconds,
        durationMs: _duration > Duration.zero ? _duration.inMilliseconds : null,
        playing: _playing,
        isLive: _item.isLive,
        sentAtMs: DateTime.now().millisecondsSinceEpoch,
      );

  /// The host broadcast a state: switched content? paused? seeked?
  Future<void> _applyFollowUpdate(WatchNowInfo info) async {
    if (!mounted) return;

    // (1) Content switch — resolve it by the provider ID on our device.
    final sameContent = info.contentKey == _keyOf(_item);
    if (!sameContent) {
      final resolved = await ref.read(contentResolverProvider).resolve(info);
      if (!mounted || resolved == null) return;
      setState(() {
        _item = resolved;
        _started = false;
        _openRetries = 0;
        _seekedToResume = true; // don't resume our old position — follow host
      });
      await _openMedia();
      if (!info.isLive) await _player.seek(info.seekTarget());
      if (!info.playing) await _player.pause();
      return;
    }

    // (2) Same content: follow pause/play and position (VOD only — live has
    //     no timeline, so no precise sync).
    if (info.playing != _playing) {
      info.playing ? await _player.play() : await _player.pause();
    }
    if (!info.isLive) {
      final target = info.seekTarget();
      final diff = (target - _position).inMilliseconds.abs();
      if (diff > 2500) await _player.seek(target); // ignore small drifts
    }
  }

  String _keyOf(MediaItem m) => switch (m.kind) {
        MediaKind.series => 'series:${m.id}',
        MediaKind.live => 'live:${m.id}',
        MediaKind.movie => 'movie:${m.id}',
      };

  void _bind() {
    _subs.addAll([
      _player.stream.position.listen((p) {
        if (mounted) setState(() => _position = p);
      }),
      _player.stream.duration.listen((d) {
        if (mounted) setState(() => _duration = d);
        _maybeResume();
      }),
      _player.stream.playing.listen((p) {
        if (!mounted) return;
        setState(() {
          _playing = p;
          if (p) {
            _started = true;
            _error = null; // playback succeeded → hide any earlier error
            _startWatchdog?.cancel(); // actually started — watchdog not needed
          }
        });
        ref.read(watchPartyProvider).pushNow(); // notify followers right away
      }),
      _player.stream.buffering.listen((b) {
        if (mounted) setState(() => _buffering = b);
      }),
      _player.stream.error.listen((e) {
        debugPrint('PLAYER ERROR: $e');
        if (!mounted || _started) return;
        // Only a real open failure is fatal; libmpv warnings (seek/…) are
        // ignored.
        final msg = e.toLowerCase();
        final openFailure =
            msg.contains('failed to open') || msg.contains('cannot open');
        if (!openFailure) return;
        _onOpenFailed(e);
      }),
    ]);
  }

  /// Retry backoff when playback fails.
  ///
  /// ⚠️ **Measured on the real server:** the gateway pins a channel's CDN node
  /// for **~10 seconds per IP** then rotates it, and **~60% of nodes are
  /// dead**. So retries within the cache window get the same dead node; the
  /// total here (~12s) **outlasts the cache**, guaranteeing a fresh node on
  /// the last attempt. We also block every failed node so we never return.
  ///
  /// Explicit note: a channel the provider routes **only to dead nodes** (we
  /// measured that they exist) can't be fixed by any retry — the fix is on
  /// the provider's side, not the client's.
  static const _retryDelays = [
    Duration(milliseconds: 500), // another node right away if cache expired
    Duration(milliseconds: 1500),
    Duration(seconds: 3),
    Duration(seconds: 7), // total ~12s > 10s cache ⇒ guaranteed new node
  ];

  /// Playback failed to start — from an explicit mpv error or the start
  /// watchdog.
  ///
  /// ~60% of the provider's CDN nodes are dead and the gateway assigns them
  /// randomly, so a failure is usually **a bad node, not a bad channel**.
  /// Hence: record the node as failed, then resolve again — the gateway
  /// hands us another node (proven: the same channel gets different hosts).
  /// We only report failure after all retries are exhausted.
  void _onOpenFailed(String reason) {
    if (!mounted || _started) return;

    // The node that just failed: block it so the next resolve avoids it.
    // This includes nodes that accept TCP but never stream — which the
    // proactive probe can't detect.
    if (_cdnHost case final h?) {
      Playback.markDead(h);
      _cdnHost = null;
    }

    if (_openRetries < _retryDelays.length) {
      final wait = _retryDelays[_openRetries];
      _openRetries++;
      debugPrint('PLAYER retry #$_openRetries after ${wait.inMilliseconds}ms '
          '($reason)');
      // Retry silently (no text) — only the loading indicator stays.
      Future.delayed(wait, () {
        if (mounted && !_started) _openMedia(); // re-resolves ⇒ new node
      });
    } else {
      setState(() => _error = reason);
    }
  }

  /// Playback start watchdog — the last safety net.
  ///
  /// Some dead streams **open and then freeze**, so mpv stays silent until
  /// `network-timeout` (60s) and then emits an error that doesn't match
  /// "failed to open" (e.g. `ffurl_read -110`), leaving the user stuck on an
  /// endless spinner with no error and no retry.
  /// We rely on **playback not starting**, not on mpv's error text (which
  /// changes).
  ///
  /// Doesn't affect healthy streams: it only fires while
  /// `_started == false`, and the timeout is generous.
  void _armStartWatchdog() {
    _startWatchdog?.cancel();
    // 12s is plenty for any healthy node and exposes dead ones quickly, so
    // we try another instead of leaving the user on a spinner.
    _startWatchdog = Timer(const Duration(seconds: 12), () {
      if (!mounted || _started) return;
      _onOpenFailed('stalled: playback did not start within 12s');
    });
  }

  bool _configured = false;

  /// libmpv properties for robust live streaming (`.ts`): longer timeout +
  /// automatic FFmpeg reconnect.
  Future<void> _configureNative() async {
    if (_configured) return;
    _configured = true;
    final p = _player.platform;
    if (p is NativePlayer) {
      try {
        await p.setProperty('network-timeout', '60');
        // reconnect: FFmpeg reconnects when a read drops instead of failing;
        // rw_timeout in microseconds (30s) prevents an early ETIMEDOUT on
        // open.
        await p.setProperty(
          'stream-lavf-o',
          'reconnect=1,reconnect_streamed=1,reconnect_on_network_error=1,'
              'reconnect_delay_max=5,rw_timeout=30000000',
        );
      } catch (e) {
        debugPrint('mpv config: $e');
      }
    }
  }

  Future<void> _openMedia() async {
    await _configureNative();

    // Demo mode: public sample, no gateway and no redirect.
    if (_demo) {
      _armStartWatchdog();
      await _player.open(
        Media(_demoSample, httpHeaders: {'User-Agent': AppConfig.userAgent}),
        play: true,
      );
      return;
    }

    final gateway = Playback.streamUri(_item);
    final PlaybackTarget target;
    try {
      // Resolve the 302 ourselves: the gateway redirects to a CDN on plain
      // http, and if libmpv followed it, it would carry the Bearer and
      // signature to the CDN — the open fails and the JWT leaks over http.
      // (Android strips them in StripAuthOnPlainHttpInterceptor.)
      target = await Playback.resolve(
        ref.read(dioProvider),
        gateway,
        accessToken: ref.read(sessionStoreProvider).access,
      );
    } on PlaybackResolveException catch (e) {
      debugPrint('PLAYER resolve failed: $e');
      // 401/403 = session/signature, not the channel → clear error without
      // opening the player.
      if (mounted) {
        setState(() {
          _authError = e.isAuth;
          _error = 'gateway ${e.statusCode}';
        });
      }
      return;
    } catch (e) {
      debugPrint('PLAYER resolve error: $e');
      _onOpenFailed('resolve: $e'); // network → retry as usual
      return;
    }

    // Keep the node so we can block it if playback fails (see
    // [_onOpenFailed]).
    _cdnHost = target.isGateway ? null : Uri.tryParse(target.url)?.host;
    debugPrint('PLAYER open: ${Playback.sanitizeForLog(target.url)}  '
        'headers=${target.headers.keys.toList()}');
    _armStartWatchdog(); // cancelled as soon as playback actually starts
    await _player.open(
      Media(target.url, httpHeaders: target.headers),
      play: true,
    );
  }

  void _maybeResume() {
    if (_seekedToResume || _isLive || _duration <= Duration.zero) return;
    _seekedToResume = true;
    final saved = ResumeStore.instance.get(_item.id);
    if (saved != null && saved < _duration) {
      _player.seek(saved);
    }
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(milliseconds: 3800), () {
      if (mounted) setState(() => _controlsVisible = false);
    });
  }

  void _toggleControls() {
    setState(() => _controlsVisible = !_controlsVisible);
    if (_controlsVisible) _scheduleHide();
  }

  void _seekBy(Duration delta) {
    final target = _position + delta;
    _player.seek(target < Duration.zero ? Duration.zero : target);
    ref.read(watchPartyProvider).pushNow(); // followers jump with me
    _scheduleHide();
  }

  @override
  void dispose() {
    // -- Critical cleanup first, not relying on ref (so no exception can
    //    block it): --
    // 1) Stop the stream, then dispose the player (prevents audio/channel
    //    from continuing after going back).
    _hideTimer?.cancel();
    _startWatchdog?.cancel();
    for (final s in _subs) {
      s.cancel();
    }
    _player.stop();
    _player.dispose();
    // 2) Restore portrait and the system bars (going back is always portrait
    //    and clean).
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    // -- Everything below is secondary (save position + notify followers): --
    if (!_isLive && _duration > Duration.zero) {
      ResumeStore.instance.save(_item.id, _position, _duration);
    }
    // I left the watch session → notify followers with {"stop":1}.
    final wp = _wp;
    if (wp != null) {
      wp.onFollowUpdate = null;
      wp.onFollowStopped = null;
      wp.stopBroadcast(notifyStop: true);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: Video(
                controller: _controller,
                controls: NoVideoControls,
                fit: BoxFit.contain,
              ),
            ),
            // Clean loading indicator only. Retries on dead nodes happen
            // silently in the background — we don't show "retrying", it's a
            // technical detail that worries the user for no reason.
            if (_buffering && _error == null)
              const Center(
                child: CircularProgressIndicator(color: AppColors.brand),
              ),
            if (_error != null) _errorOverlay(),
            AnimatedOpacity(
              opacity: _controlsVisible && _error == null ? 1 : 0,
              duration: const Duration(milliseconds: 220),
              child: IgnorePointer(
                ignoring: !_controlsVisible,
                child: _controls(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _controls() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.55),
            Colors.transparent,
            Colors.black.withValues(alpha: 0.65),
          ],
          stops: const [0, 0.4, 1],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _topBar(),
            const Spacer(),
            _centerControls(),
            const Spacer(),
            _bottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          _circleBtn(Icons.close_rounded, () => Navigator.of(context).pop()),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                if (_isLive)
                  Row(
                    children: [
                      const Icon(Icons.circle, size: 8, color: AppColors.live),
                      const SizedBox(width: 4),
                      Text(_item.nowPlaying ?? AppText.of(context).playerLive,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12)),
                    ],
                  ),
              ],
            ),
          ),
          // (PiP button removed: iOS doesn't support system PiP with
          //  media_kit/libmpv — it needs an AVPlayerLayer that isn't
          //  available, so we don't pretend to offer a missing feature.)
          _circleBtn(Icons.closed_caption_rounded, () {}),
        ],
      ),
    );
  }

  Widget _centerControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (!_isLive)
          _circleBtn(Icons.replay_10_rounded,
              () => _seekBy(const Duration(seconds: -10))),
        const SizedBox(width: AppSpacing.xl),
        _circleBtn(
          _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
          () {
            _player.playOrPause();
            _scheduleHide();
          },
          big: true,
        ),
        const SizedBox(width: AppSpacing.xl),
        if (!_isLive)
          _circleBtn(Icons.forward_10_rounded,
              () => _seekBy(const Duration(seconds: 10))),
      ],
    );
  }

  Widget _bottomBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
      child: Column(
        children: [
          if (_demo)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadii.pill),
              ),
              child: Text(
                AppText.of(context).playerDemoMode,
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ),
          if (_isLive)
            Align(
              alignment: Alignment.centerRight,
              child: Text(AppText.of(context).playerLiveStream,
                  style: const TextStyle(
                      color: AppColors.live, fontWeight: FontWeight.w700)),
            )
          else
            Row(
              children: [
                Text(_fmt(_position),
                    style: const TextStyle(color: Colors.white70, fontSize: 12)),
                Expanded(
                  child: SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 3,
                      activeTrackColor: AppColors.brand,
                      inactiveTrackColor: Colors.white24,
                      thumbColor: AppColors.brandStrong,
                      overlayShape:
                          const RoundSliderOverlayShape(overlayRadius: 14),
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 6),
                    ),
                    child: Slider(
                      value: _sliderValue,
                      onChanged: _duration > Duration.zero
                          ? (v) {
                              final t = _duration * v;
                              setState(() => _position = t);
                            }
                          : null,
                      onChangeEnd: (v) {
                        _player.seek(_duration * v);
                        ref.read(watchPartyProvider).pushNow();
                        _scheduleHide();
                      },
                    ),
                  ),
                ),
                Text(_fmt(_duration),
                    style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
        ],
      ),
    );
  }

  double get _sliderValue {
    if (_duration <= Duration.zero) return 0;
    final v = _position.inMilliseconds / _duration.inMilliseconds;
    return v.clamp(0.0, 1.0);
  }

  Widget _errorOverlay() {
    return Container(
      color: Colors.black,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.live, size: 44),
          const SizedBox(height: AppSpacing.md),
          Text(
              _authError
                  ? AppText.of(context).playerErrorAuthTitle
                  : AppText.of(context).playerErrorTitle,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
            _authError
                ? AppText.of(context).playerErrorAuthBody
                : _demo
                    ? AppText.of(context).playerErrorDemoBody
                    : AppText.of(context).playerErrorRealBody,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _error = null;
                    _authError = false;
                    _openRetries = 0;
                  });
                  _openMedia();
                },
                child: Text(AppText.of(context).commonRetry,
                    style: const TextStyle(color: AppColors.brand)),
              ),
              const SizedBox(width: AppSpacing.md),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(AppText.of(context).playerBack,
                    style: const TextStyle(color: Colors.white54)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap, {bool big = false}) {
    return Material(
      color: Colors.white.withValues(alpha: 0.16),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(big ? 14 : 9),
          child: Icon(icon, color: Colors.white, size: big ? 36 : 22),
        ),
      ),
    );
  }

  static String _fmt(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final h = d.inHours;
    final m = two(d.inMinutes.remainder(60));
    final s = two(d.inSeconds.remainder(60));
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }
}
