# StreamVault-IPTV: Flutter client (iOS / Android)

An IPTV client built with Flutter. It talks to an Xtream-style API gateway
and runs on iOS and Android from a single codebase.

## Features

- **Authentication**: HMAC-SHA256 request signing + `device_id` + JWT (Bearer) with automatic refresh, a device limit (HTTP 409) and remote device sign-out
- **Account**: registration, subscription activation by coupon code, active device management
- **Live catalog**: live channels, movies and series, grouped by category with "show more"
- **Player (media_kit / libmpv)**: live `.ts` and VOD `.mp4` with video, audio tracks and subtitles, plus resume playback
- **Series**: seasons and episodes, played by `episode_id`
- **Local cache**: load once, then open instantly; manual refresh with "Sync all"
- **Search**: per-section search
- **Voice rooms + watch party** (LiveKit): a floating room button available everywhere, avatars, mic control
- **Localization**: Arabic (RTL) and English, with a dark brand theme

## Running

```bash
flutter pub get
flutter run   # demo mode: sample data, no server needed
```

For a real build, secrets and endpoints are passed **at build time only** and
are never stored in the repository:

```bash
flutter run \
  --dart-define=HMAC_SECRET=<hmac-secret> \
  --dart-define=MANAGED_PROVIDER_URL=https://api.example.com \
  --dart-define=VOICE_SERVICE_URL=https://voice.example.com \
  --dart-define=APP_USER_AGENT="<user-agent>"
```

`AppConfig.useMockData` becomes `false` automatically when `HMAC_SECRET` is set.

The GitHub Actions workflow in `.github/workflows/ios-build.yml` builds an
unsigned **demo-mode** iOS IPA on demand. It uses no secrets: build a real
app locally with the `--dart-define` values above.

## Project structure

```text
lib/
 ├─ core/      config (dart-define) + theme (colors / typography)
 ├─ network/   dio + HMAC + auth (Bearer / refresh) + session + api_paths
 ├─ auth/      auth_api + auth_controller (login / 409 / device sign-out)
 ├─ data/      models + repositories + xtream_mapper + catalog_cache (disk)
 ├─ player/    playback (URLs + headers) + resume_store
 ├─ voice/     voice rooms + watch party (LiveKit)
 ├─ state/     providers (Riverpod)
 ├─ l10n/      Arabic / English strings
 └─ ui/        auth · shell · home · browse · detail · player · search · settings · voice
```

## Rules the client follows

- **Playback headers:** `User-Agent` + `Authorization: Bearer` + `X-Ts` + `X-Sig`, and nothing else.
  No `Icy-MetaData` (it breaks mp4 demuxing), and no made-up headers.
- **`.mp4` is always used** for movies and episodes (`container_extension` is ignored).
- **A series is not playable by itself**: the episode owns the stream (`episode_id`).
- **Empty responses are never cached**: an `[]` reply is a temporary provider failure, so it is retried, not stored.

## Tests

```bash
flutter test
```

## Disclaimer

This project was made **for testing and experimentation only**. It contains
**many bugs** and is not production-ready. Use it at your own risk.
