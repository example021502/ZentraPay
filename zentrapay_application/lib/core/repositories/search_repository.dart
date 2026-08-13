import 'package:dio/dio.dart';
import 'package:zentrapay_application/core/models/search_result.dart';
import 'package:zentrapay_application/core/utils/interceptor.dart';

/// Search-by-query is inherently not a "load once" resource (a new query is
/// a new request by definition) — this just centralizes the endpoint call
/// so every screen that searches contacts (Pay, Remit, transfer picker)
/// shares one implementation instead of three copies.
class SearchRepository {
  static final Dio _dio = ApiClient().dio;

  static Future<ContactSearchResult> search(String query) async {
    if (query.trim().isEmpty) return ContactSearchResult.empty();
    final response = await _dio.get('/api/search-contacts/$query');
    print("THE SEARCH RESULTS ARE:: $response");
    return ContactSearchResult.fromJson(response.data['data']);
  }
}
