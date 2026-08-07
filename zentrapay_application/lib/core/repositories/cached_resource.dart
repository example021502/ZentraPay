import 'package:flutter/foundation.dart';

/// Base for every "load once, then apply deltas" repository in the app.
///
/// Screens call [ensureLoaded] in `initState`: the first caller triggers the
/// GET and every subsequent caller (e.g. revisiting a pushed screen, or a
/// sibling widget listening via `context.watch`) gets the already-cached
/// value instantly, no network round trip. When an operation on the screen
/// performs a POST/PUT that changes this resource, call [applyDelta] (or
/// [setData] if the endpoint just returns the new state wholesale) to merge
/// the response into the cache instead of re-fetching everything.
abstract class CachedResource<T> extends ChangeNotifier {
  T? _data;
  bool _loading = false;
  Object? _error;

  T? get data => _data;
  bool get isLoaded => _data != null;
  bool get isLoading => _loading;
  Object? get error => _error;

  /// The actual network call. Implemented by each concrete repository.
  Future<T> fetch();

  /// Loads the resource the first time it's needed; subsequent calls are a
  /// no-op unless [forceRefresh] is set (pull-to-refresh, explicit retry).
  Future<T?> ensureLoaded({bool forceRefresh = false}) async {
    if (_data != null && !forceRefresh) return _data;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _data = await fetch();
      return _data;
    } catch (e) {
      _error = e;
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Applies a POST/PUT response onto the cached value without refetching.
  void applyDelta(T Function(T current) updater) {
    final current = _data;
    if (current == null) return;
    _data = updater(current);
    notifyListeners();
  }

  /// Replaces the cached value outright (e.g. a POST that returns the full
  /// new resource rather than something to merge).
  void setData(T value) {
    _data = value;
    notifyListeners();
  }

  void clear() {
    _data = null;
    _error = null;
    notifyListeners();
  }
}

/// Same contract as [CachedResource] but for a list resource, with a couple
/// of convenience mutators list-shaped screens (savings, cards, challenges,
/// investments...) all need.
abstract class CachedListResource<T> extends CachedResource<List<T>> {
  void addItem(T item) => applyDelta((current) => [...current, item]);

  void replaceItem(bool Function(T item) matches, T replacement) {
    applyDelta(
      (current) => [
        for (final item in current) matches(item) ? replacement : item,
      ],
    );
  }

  void removeItem(bool Function(T item) matches) {
    applyDelta(
      (current) => current.where((item) => !matches(item)).toList(),
    );
  }
}
