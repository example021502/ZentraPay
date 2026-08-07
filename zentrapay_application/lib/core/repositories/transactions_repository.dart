import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:zentrapay_application/core/utils/interceptor.dart';
import 'package:zentrapay_application/core/models/transaction.dart';

/// Transaction history is paginated, so it doesn't fit the plain
/// single-value [CachedResource] shape: the "load once" behavior here means
/// page 0 is fetched once and cached; scrolling further pages appends
/// rather than refetching everything, and a new transaction posted
/// elsewhere (a transfer, a bill payment...) is prepended locally instead
/// of re-querying page 0.
class TransactionsRepository extends ChangeNotifier {
  TransactionsRepository._();
  static final TransactionsRepository instance = TransactionsRepository._();

  final Dio _dio = ApiClient().dio;

  final List<AppTransaction> _items = [];
  int _page = 0;
  int _totalPages = 1;
  bool _loading = false;
  bool _loadedOnce = false;

  List<AppTransaction> get items => List.unmodifiable(_items);
  bool get isLoading => _loading;
  bool get hasMore => _page + 1 < _totalPages;

  Future<void> ensureLoaded({bool forceRefresh = false}) async {
    if (_loadedOnce && !forceRefresh) return;
    _loading = true;
    notifyListeners();
    try {
      final result = await _fetchPage(0);
      _items
        ..clear()
        ..addAll(result.content);
      _page = result.page;
      _totalPages = result.totalPages;
      _loadedOnce = true;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadNextPage() async {
    if (!hasMore || _loading) return;
    _loading = true;
    notifyListeners();
    try {
      final result = await _fetchPage(_page + 1);
      _items.addAll(result.content);
      _page = result.page;
      _totalPages = result.totalPages;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<TransactionPage> _fetchPage(int page) async {
    final response = await _dio.get(
      '/api/transactions',
      queryParameters: {'page': page, 'size': 20},
    );
    return TransactionPage.fromJson(response.data['data']);
  }

  /// Called after a POST elsewhere (payment, bill pay, savings deposit...)
  /// returns the resulting Transaction — no need to refetch page 0.
  void prepend(AppTransaction transaction) {
    _items.insert(0, transaction);
    notifyListeners();
  }
}
