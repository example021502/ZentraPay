import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AIAssistanceService {
  static String get baseUrl => '${dotenv.get('BASE_URL')}/api';
}
