import 'package:shared_preferences/shared_preferences.dart';
import '../core/logger_service.dart';

class SearchHistoryService {
  static final SearchHistoryService _instance = SearchHistoryService._();
  factory SearchHistoryService() => _instance;
  SearchHistoryService._();

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
    history
      ..remove(query.trim())
      ..insert(0, query.trim());
    if (history.length > _maxItems) {
      history.removeRange(_maxItems, history.length);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_storageKey, history);
  }

  Future<void> removeFromHistory(String query) async {
    final history = await getHistory();
    if (history.remove(query.trim())) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_storageKey, history);
    }
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  /// Vraća listu istorije koja počinje ili sadrži zadati query.
  Future<List<String>> getSuggestions(String query) async {
    if (query.trim().isEmpty) return getHistory();
    final history = await getHistory();
    final normalized = query.trim().toLowerCase();
    return history
        .where((h) => h.toLowerCase().contains(normalized))
        .toList();
  }
}
