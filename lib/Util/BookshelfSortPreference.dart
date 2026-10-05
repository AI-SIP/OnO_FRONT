import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Model/Common/ListSort.dart';

/// 책장에서 고른 정렬을 기기에 기억해 둔다. 처음에는 최근 등록순이다.
class BookshelfSortPreference {
  static const String _key = 'bookshelf_sort';

  static Future<ListSort> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return ListSort.fromName(prefs.getString(_key));
    } catch (e) {
      debugPrint('[BookshelfSortPreference] 읽기 실패: $e');
      return ListSort.newest;
    }
  }

  static Future<void> save(ListSort sort) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, sort.name);
    } catch (e) {
      debugPrint('[BookshelfSortPreference] 저장 실패: $e');
    }
  }
}
