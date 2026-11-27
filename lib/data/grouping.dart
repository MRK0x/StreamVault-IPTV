import 'models/category_group.dart';
import 'models/media_item.dart';

/// Groups items by category, preserving the category order of [orderedCats]
/// (id → name).
List<CategoryGroup> buildGroups(
  List<MediaItem> items,
  Map<String, String> orderedCats,
) {
  final byCat = <String, List<MediaItem>>{};
  for (final it in items) {
    (byCat[it.categoryId ?? ''] ??= <MediaItem>[]).add(it);
  }
  final groups = <CategoryGroup>[];
  orderedCats.forEach((id, name) {
    final list = byCat.remove(id);
    if (list != null && list.isNotEmpty) {
      groups.add(CategoryGroup(id: id, name: name, items: list));
    }
  });
  // Categories with no known name — collected under an "Other" group; the name
  // is localized in the UI via the sentinel id [kOtherCategoryId] (we don't
  // build Arabic text here).
  final leftovers = <MediaItem>[];
  byCat.forEach((_, list) => leftovers.addAll(list));
  if (leftovers.isNotEmpty) {
    groups.add(
        CategoryGroup(id: kOtherCategoryId, name: '', items: leftovers));
  }
  return groups;
}
