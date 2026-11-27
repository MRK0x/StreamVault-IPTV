import 'media_item.dart';

/// Titled content row (Netflix-style row).
class ContentRow {
  const ContentRow({
    required this.title,
    required this.items,
    this.isContinueWatching = false,
  });

  final String title;
  final List<MediaItem> items;
  final bool isContinueWatching;
}
