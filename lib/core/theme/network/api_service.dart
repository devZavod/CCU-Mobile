import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';

class ApiService {
  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
  };

  static Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}$endpoint'),
      headers: _headers,
      body: jsonEncode(body),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error ${response.statusCode}: ${response.body}');
    }
  }

  static Future<dynamic> get(String endpoint, {String? token}) async {
    final headers = {..._headers};
    if (token != null) headers['Authorization'] = 'Bearer $token';

    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}$endpoint'),
      headers: headers,
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error ${response.statusCode}: ${response.body}');
    }
  }
}