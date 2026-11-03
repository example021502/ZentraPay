import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:zentrapay_application/core/models/saved_card.dart';
import 'package:zentrapay_application/core/utils/interceptor.dart';
import 'package:zentrapay_application/features/wallet_topup/models/responseEntities.dart';

/// The user's saved (tokenized) cards: `GET/DELETE /api/cards/saved`, and charging one with
/// `POST /api/topup/card`. The server holds the gateway token; the app only ever sees display details.
class SavedCardsRepository with ChangeNotifier {
  SavedCardsRepository._();
  static final SavedCardsRepository instance = SavedCardsRepository._();

  final Dio _dio = ApiClient().dio;

  List<SavedCard> _cards = const [];
  bool _loaded = false;
  bool _loading = false;

  List<SavedCard> get cards => _cards;
  bool get isLoaded => _loaded;
  bool get isLoading => _loading;

  /// Cards that can be charged right now (not expired), default first.
  List<SavedCard> get usable => _cards.where((c) => !c.expired).toList();

  Future<void> ensureLoaded({bool forceRefresh = false}) async {
    if (_loaded && !forceRefresh) return;
    if (_loading) return;
    _loading = true;
    notifyListeners();
    try {
      final response = await _dio.get('/api/cards/saved');
      final data = response.data['data'];
      _cards = (data is List ? data : const <dynamic>[])
          .whereType<Map>()
          .map((m) => SavedCard.fromJson(Map<String, dynamic>.from(m)))
          .toList();
      _loaded = true;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> remove(String cardId) async {
    await _dio.delete('/api/cards/saved/$cardId');
    await ensureLoaded(forceRefresh: true);
  }

  Future<void> makeDefault(String cardId) async {
    await _dio.post('/api/cards/saved/$cardId/default');
    await ensureLoaded(forceRefresh: true);
  }

  /// Tops up the wallet by charging [cardId]; the transaction PIN authorises it. Resolves to where the
  /// top-up stands right after the charge (SUCCESS / PENDING / FAILED).
  Future<TopupVerifyResponse> charge({
    required String cardId,
    required double amount,
    required String currencyCode,
    required String pin,
  }) async {
    final response = await _dio.post(
      '/api/topup/card',
      data: {
        'cardId': cardId,
        'amount': amount,
        'currencyCode': currencyCode,
        'pin': pin,
      },
    );
    final envelope = Map<String, dynamic>.from(response.data as Map);
    return TopupVerifyResponse.fromJson(
      Map<String, dynamic>.from((envelope['data'] ?? {}) as Map),
    );
  }

  /// Forget everything (sign-out).
  void reset() {
    _cards = const [];
    _loaded = false;
    notifyListeners();
  }
}
