import 'package:http/http.dart' as http;
import 'dart:convert';

class VoiceRecordingService {
  static const String baseUrl = 'http://localhost:3000/api';

  Future<Map<String, dynamic>> startRecording() async {
    try {
      final response = await http.post(Uri.parse('$baseUrl/voice/start'));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to start recording');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<Map<String, dynamic>> stopRecording() async {
    try {
      final response = await http.post(Uri.parse('$baseUrl/voice/stop'));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to stop recording');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<String> processVoiceCommand(String audioPath) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/voice/process'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'audioPath': audioPath}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['command'];
      } else {
        throw Exception('Failed to process voice command');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}
