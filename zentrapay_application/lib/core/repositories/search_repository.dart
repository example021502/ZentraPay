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
    final trimmed = query.trim();
    if (trimmed.isEmpty) return ContactSearchResult.empty();
    // The query is part of the path (GET /api/search-contacts/{query}), so it
    // must be a single path segment. Search terms frequently contain spaces or
    // reserved characters (full names like "John Doe", formatted phone numbers,
    // zentags with dots, etc.) — interpolating them raw produces an invalid URL
    // and Dio throws a FormatException, so the search silently returns nothing.
    // Encode as a path segment; the backend's @PathVariable decodes it back.
    final encodedQuery = Uri.encodeComponent(trimmed);
    final response = await _dio.get(
      '/api/search/search-contacts/$encodedQuery',
    );
    return ContactSearchResult.fromJson(response.data['data']);
  }

  static Future<Map<String, dynamic>> targetSearch(String query) async {
    final encodedQuery = Uri.encodeComponent(query);
    final response = await _dio.get('/api/search/search-contact/$encodedQuery');
    if (!response.data['success']) {
      return Map<String, dynamic>.from({});
    }
    return Map<String, dynamic>.from(response.data['data']['contact']);
  }
}
