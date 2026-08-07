import 'package:dio/dio.dart';
import 'package:zentrapay_application/core/utils/interceptor.dart';
import 'package:zentrapay_application/core/models/card.dart';
import 'package:zentrapay_application/core/repositories/cached_resource.dart';

class CardsRepository extends CachedListResource<AppCard> {
  CardsRepository._();
  static final CardsRepository instance = CardsRepository._();

  final Dio _dio = ApiClient().dio;

  @override
  Future<List<AppCard>> fetch() async {
    final response = await _dio.get('/api/cards');
    return ((response.data['data'] as List?) ?? [])
        .map((e) => AppCard.fromJson(e))
        .toList();
  }

  Future<AppCard> createVirtualCard(String brand) async {
    final response = await _dio.post(
      '/api/cards/virtual',
      data: {'brand': brand},
    );
    final card = AppCard.fromJson(response.data['data']);
    addItem(card);
    return card;
  }

  Future<AppCard> setNfcEnabled(String cardId, bool enabled) async {
    final response = await _dio.patch(
      '/api/cards/$cardId/nfc',
      data: {'enabled': enabled},
    );
    final card = AppCard.fromJson(response.data['data']);
    replaceItem((c) => c.cardId == cardId, card);
    return card;
  }

  Future<AppCard> setQrEnabled(String cardId, bool enabled) async {
    final response = await _dio.patch(
      '/api/cards/$cardId/qr',
      data: {'enabled': enabled},
    );
    final card = AppCard.fromJson(response.data['data']);
    replaceItem((c) => c.cardId == cardId, card);
    return card;
  }
}
