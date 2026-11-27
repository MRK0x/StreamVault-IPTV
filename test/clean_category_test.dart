import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mrk0slive/data/models/category_group.dart';

/// Locks in live-category name cleanup: "English | Arabic" → Arabic only.
void main() {
  final arabic = RegExp(r'[؀-ۿ]');
  final latin = RegExp(r'[A-Za-z]');

  group('cleanLiveCategoryName — specific cases', () {
    test('drops the English and keeps the Arabic', () {
      expect(cleanLiveCategoryName('General | قنوات عربية'), 'قنوات عربية');
      expect(cleanLiveCategoryName('Cartoon | كرتون'), 'كرتون');
      expect(cleanLiveCategoryName('Saudi Arabia | السعودية'), 'السعودية');
    });

    test('keeps pure Arabic as-is', () {
      expect(cleanLiveCategoryName('السعودية'), 'السعودية');
    });

    test('pure English is translated if known, otherwise kept', () {
      expect(cleanLiveCategoryName('General'), 'عام');
      expect(cleanLiveCategoryName('Documentary'), 'وثائقي');
      expect(cleanLiveCategoryName('SomeBrand'), 'SomeBrand'); // unknown
    });

    test('a fully foreign "country | genre" category is translated entirely', () {
      expect(cleanLiveCategoryName('INDIA | Sports |'), 'الهند • رياضة');
      expect(cleanLiveCategoryName('Pakistan | News'), 'باكستان • أخبار');
    });

    test('picks the most-Arabic part (ignores markers like |AR|)', () {
      expect(cleanLiveCategoryName('ENGLISH | بي ان | AR'), 'بي ان');
    });

    test('trims whitespace, and empty stays empty', () {
      expect(cleanLiveCategoryName('  X | العربية  '), 'العربية');
      expect(cleanLiveCategoryName(''), '');
    });
  });

  test('🎯 all real categories (107) become Arabic with no English', () {
    final file = File('test/fixtures/livecats.json');
    final data = jsonDecode(file.readAsStringSync());
    final cats = data is List ? data : (data['data'] as List? ?? const []);
    expect(cats, isNotEmpty);

    var checked = 0;
    for (final c in cats) {
      final raw = '${(c as Map)['category_name'] ?? ''}'.trim();
      if (raw.isEmpty) continue;
      final clean = cleanLiveCategoryName(raw);
      checked++;
      // The result is Arabic…
      expect(arabic.hasMatch(clean), isTrue,
          reason: 'not Arabic: $raw → $clean');
      // …with no Latin letters at all.
      expect(latin.hasMatch(clean), isFalse,
          reason: 'English left over: $raw → $clean');
    }
    expect(checked, greaterThan(100));
  });
}
