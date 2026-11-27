import 'models/content_row.dart';
import 'models/episode.dart';
import 'models/media_item.dart';

/// Sample display data — posters from picsum (loaded over the internet; a
/// gradient background shows when unavailable).
class MockCatalog {
  MockCatalog._();

  static String _poster(String seed) =>
      'https://picsum.photos/seed/$seed/300/450';
  static String _backdrop(String seed) =>
      'https://picsum.photos/seed/$seed/1200/700';

  static const mockCategories = <String, String>{
    'lv_sport': 'قنوات رياضية',
    'lv_movies': 'قنوات أفلام',
    'lv_news': 'قنوات إخبارية',
    'lv_kids': 'قنوات أطفال',
    'mv_action': 'أفلام أكشن',
    'mv_comedy': 'أفلام كوميديا',
    'mv_drama': 'أفلام دراما',
    'sr_drama': 'مسلسلات درامية',
    'sr_thriller': 'مسلسلات تشويق',
  };

  static const _liveCats = ['lv_sport', 'lv_movies', 'lv_news', 'lv_kids'];
  static const _movieCats = ['mv_action', 'mv_comedy', 'mv_drama'];
  static const _seriesCats = ['sr_drama', 'sr_thriller'];

  static const _movieTitles = [
    'الرحلة الأخيرة',
    'ظلال المدينة',
    'ما وراء الأفق',
    'الطريق إلى الشمال',
    'ليلة القمر',
    'حارس الصمت',
    'العاصفة القادمة',
    'سرّ الوادي',
    'نبض المدينة',
    'الغريب',
  ];

  static const _seriesTitles = [
    'أيام الحكاية',
    'بيت العائلة',
    'مدار الزمن',
    'الحيّ القديم',
    'وجوه',
    'خيوط',
    'الموسم الأخير',
    'ذاكرة المكان',
  ];

  static const _channelNames = [
    'MRK Sports 1',
    'MRK Movies',
    'الإخبارية',
    'MRK Kids',
    'وثائقيات',
    'MRK Drama',
    'الرياضية HD',
    'MRK Music',
  ];

  static const _nowPlaying = [
    'المباراة الكبرى — الشوط الثاني',
    'فيلم المساء',
    'نشرة الأخبار',
    'برنامج الأطفال',
    'رحلة في الطبيعة',
    'المسلسل اليومي',
    'الدوري — مباشر',
    'قائمة الأغاني',
  ];

  static final List<MediaItem> movies = List.generate(_movieTitles.length, (i) {
    return MediaItem(
      id: 'mv_${1000 + i}',
      kind: MediaKind.movie,
      title: _movieTitles[i],
      posterUrl: _poster('movie$i'),
      backdropUrl: _backdrop('movie$i'),
      categoryId: _movieCats[i % _movieCats.length],
      categoryName: mockCategories[_movieCats[i % _movieCats.length]],
      rating: 6.5 + (i % 4) * 0.8,
      year: '${2019 + (i % 6)}',
      description:
          'فيلم يأخذك في رحلة مشوّقة عبر أحداث متشابكة ونهاية غير متوقّعة. تجربة مشاهدة غامرة بجودة عالية.',
    );
  });

  static final List<MediaItem> series = List.generate(_seriesTitles.length, (i) {
    return MediaItem(
      id: 'sr_${2000 + i}',
      kind: MediaKind.series,
      title: _seriesTitles[i],
      posterUrl: _poster('series$i'),
      backdropUrl: _backdrop('series$i'),
      categoryId: _seriesCats[i % _seriesCats.length],
      categoryName: mockCategories[_seriesCats[i % _seriesCats.length]],
      rating: 7.0 + (i % 3) * 0.7,
      year: '${2020 + (i % 5)}',
      description:
          'مسلسل درامي من عدّة مواسم يتابع مصائر شخصيات متنوّعة في حبكة متصاعدة.',
    );
  });

  static final List<MediaItem> liveChannels =
      List.generate(_channelNames.length, (i) {
    return MediaItem(
      id: 'lv_${3000 + i}',
      kind: MediaKind.live,
      title: _channelNames[i],
      posterUrl: _poster('channel$i'),
      backdropUrl: _backdrop('channel$i'),
      categoryId: _liveCats[i % _liveCats.length],
      categoryName: mockCategories[_liveCats[i % _liveCats.length]],
      nowPlaying: _nowPlaying[i],
    );
  });

  static final List<MediaItem> continueWatching = [
    movies[0].copyProgress(0.35),
    series[1].copyProgress(0.72),
    movies[3].copyProgress(0.15),
    series[4].copyProgress(0.9),
    movies[6].copyProgress(0.5),
  ];

  static final MediaItem featured = MediaItem(
    id: 'mv_featured',
    kind: MediaKind.movie,
    title: 'ما وراء الأفق',
    posterUrl: _poster('featured'),
    backdropUrl: _backdrop('featured'),
    categoryName: 'الأكثر مشاهدة',
    rating: 8.4,
    year: '2025',
    description:
        'حين تتقاطع مصائر ثلاثة غرباء في مدينة لا تنام، تبدأ رحلة البحث عن الحقيقة. الفيلم الأكثر مشاهدة هذا الأسبوع.',
  );

  /// Sample episodes (2 seasons × 5 episodes) for any series.
  static List<Episode> episodesFor(String seriesId) => [
        for (int s = 1; s <= 2; s++)
          for (int e = 1; e <= 5; e++)
            Episode(
              id: '${seriesId}_s${s}e$e',
              title: 'الحلقة $e',
              season: s,
              number: e,
              plot: 'ملخّص الحلقة $e من الموسم $s.',
              cover: _poster('$seriesId-s$s-e$e'),
              durationSecs: 45 * 60,
            ),
      ];

  static final List<ContentRow> homeRows = [
    ContentRow(
      title: 'تابع المشاهدة',
      items: continueWatching,
      isContinueWatching: true,
    ),
    ContentRow(title: 'قنوات مباشرة', items: liveChannels),
    ContentRow(title: 'أفلام رائجة', items: movies),
    ContentRow(title: 'مسلسلات مختارة', items: series),
    ContentRow(
      title: 'أضيف حديثاً',
      items: [...movies.reversed.take(6), ...series.take(4)],
    ),
  ];
}

extension on MediaItem {
  MediaItem copyProgress(double p) => MediaItem(
        id: id,
        kind: kind,
        title: title,
        posterUrl: posterUrl,
        backdropUrl: backdropUrl,
        categoryId: categoryId,
        categoryName: categoryName,
        rating: rating,
        year: year,
        description: description,
        nowPlaying: nowPlaying,
        progress: p,
      );
}
