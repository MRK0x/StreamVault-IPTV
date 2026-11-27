import 'media_item.dart';

/// Sentinel id for the "Other" group (unnamed categories) — the UI shows a
/// localized name.
const String kOtherCategoryId = '__other__';

/// Arabic translations for purely English live-category names — when a word
/// is missing we keep it as is instead of hiding it.
const Map<String, String> _categoryEnAr = {
  'general': 'عام',
  'documentary': 'وثائقي',
  'cartoon': 'كرتون',
  'movies': 'أفلام',
  'series': 'مسلسلات',
  'sports': 'رياضة',
  'sport': 'رياضة',
  'news': 'أخبار',
  'music': 'موسيقى',
  'kids': 'أطفال',
  'entertainment': 'ترفيه',
  'religious': 'ديني',
  'premium': 'مميّز',
  // Countries and languages (purely English foreign categories).
  'india': 'الهند',
  'pakistan': 'باكستان',
  'tamil': 'تاميل',
  'telugu': 'تيلوغو',
  'kannada': 'كنّادا',
  'malayalam': 'مالايالام',
  'punjabi': 'بنجابي',
};

bool _hasArabic(String s) => RegExp(r'[؀-ۿ]').hasMatch(s);
int _arabicCount(String s) => RegExp(r'[؀-ۿ]').allMatches(s).length;

/// Cleans a live category name in the form "English | Arabic": keeps only the
/// Arabic part, and if the name is purely English, translates it (or keeps it
/// if unknown).
///
/// Live-only — its category names are clean (`En | Ar`); movie categories use
/// a different mixed format that isn't handled here.
String cleanLiveCategoryName(String raw) {
  final t = raw.trim();
  if (t.isEmpty) return t;

  if (t.contains('|')) {
    final parts =
        t.split('|').map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
    final arabic = parts.where(_hasArabic).toList();
    if (arabic.isNotEmpty) {
      // The most-Arabic part (ignores markers like |AR| if present).
      arabic.sort((a, b) => _arabicCount(b).compareTo(_arabicCount(a)));
      return arabic.first;
    }
    // All parts are English (foreign category) → translate each and join.
    if (parts.isEmpty) return t;
    return parts.map(_translate).join(' • ');
  }

  // No separator: Arabic stays, English gets translated.
  return _hasArabic(t) ? t : _translate(t);
}

String _translate(String en) =>
    _categoryEnAr[en.toLowerCase().trim()] ?? en;

/// A content group by category — shown with a "Show more" action.
class CategoryGroup {
  const CategoryGroup({
    required this.id,
    required this.name,
    required this.items,
  });

  final String id;
  final String name;
  final List<MediaItem> items;
}
