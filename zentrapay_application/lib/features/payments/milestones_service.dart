import 'package:zentrapay_application/core/utils/interceptor.dart';

class MilestonesService {
  final _dio = ApiClient().dio;

  Future<List<Map<String, dynamic>>> getGoals() async {
    try {
      final response = await _dio.get('/api/milestones/goals');
      final List<dynamic> data = response.data;
      return data.cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<Map<String, dynamic>> createGoal(Map<String, dynamic> goalData) async {
    try {
      final response = await _dio.post(
        '/api/milestones/goals',
        data: goalData,
      );
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<Map<String, dynamic>> updateGoal(
    String goalId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final response = await _dio.put(
        '/api/milestones/goals/$goalId',
        data: updates,
      );
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<void> deleteGoal(String goalId) async {
    try {
      await _dio.delete('/api/milestones/goals/$goalId');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}
