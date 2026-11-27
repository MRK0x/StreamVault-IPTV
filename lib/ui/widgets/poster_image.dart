import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/theme.dart';

/// Poster/backdrop image with rounded corners and a tasteful gradient
/// background while loading or when offline. (The UI stays good-looking even
/// without internet.)
class PosterImage extends StatelessWidget {
  const PosterImage({
    super.key,
    required this.url,
    required this.seed,
    this.borderRadius = AppRadii.md,
    this.fit = BoxFit.cover,
    this.backgroundColor,
    this.padding = EdgeInsets.zero,
  });

  final String url;
  final String seed; // derives a stable fallback colour
  final double borderRadius;
  final BoxFit fit;

  /// Background shown behind the image when fit=contain (for channel logos —
  /// avoids cropping/letterboxing).
  final Color? backgroundColor;
  final EdgeInsets padding;

  static const _fallbacks = [
    [Color(0xFF463399), Color(0xFF221A47)],
    [Color(0xFF6C4BC9), Color(0xFF2B2256)],
    [Color(0xFF9E8FFF), Color(0xFF463399)],
    [Color(0xFF3A2E73), Color(0xFF181234)],
  ];

  List<Color> get _gradient => _fallbacks[seed.hashCode.abs() % _fallbacks.length];

  @override
  Widget build(BuildContext context) {
    // 13% of the provider's channels have no `stream_icon` at all — don't hit the
    // network with an empty URL and then show the fallback; show it right away.
    if (url.trim().isEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: _placeholder(icon: true),
      );
    }

    Widget image = CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      fadeInDuration: const Duration(milliseconds: 250),
      placeholder: (_, _) => _placeholder(),
      errorWidget: (_, _, _) => _placeholder(icon: true),
      // A logo inside a ~92-124px card needs no more resolution; decoding at a
      // smaller size saves memory and processing time across thousands of channels.
      memCacheWidth: 360,
      maxWidthDiskCache: 360,
    );
    if (padding != EdgeInsets.zero) {
      image = Padding(padding: padding, child: image);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: backgroundColor != null
          ? Container(
              color: backgroundColor,
              alignment: Alignment.center,
              child: image,
            )
          : image,
    );
  }

  Widget _placeholder({bool icon = false}) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: icon
          ? const Center(
              child: Icon(Icons.movie_creation_outlined,
                  color: Colors.white24, size: 32),
            )
          : null,
    );
  }
}
