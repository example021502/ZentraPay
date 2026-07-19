import 'package:http/http.dart' as http;
import 'dart:convert';

class MilestonesService {
  static const String baseUrl = 'http://localhost:3000/api';

  Future<List<Map<String, dynamic>>> getGoals() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/milestones/goals'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load goals');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<Map<String, dynamic>> createGoal(Map<String, dynamic> goalData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/milestones/goals'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(goalData),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to create goal');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<Map<String, dynamic>> updateGoal(
    String goalId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/milestones/goals/$goalId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(updates),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to update goal');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<void> deleteGoal(String goalId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/milestones/goals/$goalId'),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete goal');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}
