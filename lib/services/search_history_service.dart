import 'package:shared_preferences/shared_preferences.dart';
import 'logger_service.dart';

class SearchHistoryService {
  static const _storageKey = 'mleko_search_history';
  static const _maxItems = 10;

  Future<List<String>> getHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_storageKey);
      return list ?? [];
    } catch (e) {
      LoggerService.warning('Failed to load search history',
          extra: {'error': e.toString()});
      return [];
    }
  }

  Future<void> addToHistory(String query) async {
    if (query.trim().isEmpty) return;
    final history = await getHistory();
    history.remove(query.trim());
    history.insert(0, query.trim());
    if (history.length > _maxItems) {
      history.removeRange(_maxItems, history.length);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_storageKey, history);
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
