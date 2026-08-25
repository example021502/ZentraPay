import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:zentrapay_application/core/models/transaction.dart';
import 'package:zentrapay_application/core/utils/interceptor.dart';

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
  ///
  /// A contact that already appears in the list must NOT be inserted again
  /// (the Recent Payments strip derives straight from these items), so the
  /// incoming transaction is matched against existing entries by normalized
  /// identifier first, then by display name; empty/null fields never match.
  void prepend(AppTransaction transaction) {
    final exists = _items.any((item) => _sameContact(item, transaction));
    if (!exists) {
      _items.insert(0, transaction);
      notifyListeners();
    }
  }

  /// True when [a] and [b] refer to the same counterparty. Comparison is
  /// trimmed + case-insensitive; identifier wins over name, and two records
  /// without any usable field are treated as different contacts.
  static bool _sameContact(AppTransaction a, AppTransaction b) {
    final aId = a.receiverId.trim().toLowerCase();
    final bId = b.receiverId.trim().toLowerCase();
    if (aId.isNotEmpty && bId.isNotEmpty) return aId == bId;

    final aName = a.receiverName.trim().toLowerCase();
    final bName = b.receiverName.trim().toLowerCase();
    if (aName.isNotEmpty && bName.isNotEmpty) return aName == bName;

    return false;
  }
}
