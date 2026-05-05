// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Cambia esto según tu entorno
  //static const String baseUrl = 'http://10.0.2.2:8000'; // Android emulador
  // static const String baseUrl = 'http://localhost:8000'; // iOS / web
  // static const String baseUrl = 'https://tu-dominio.com'; // Producción
   static const String baseUrl = 'http://127.0.0.1:8000';

  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    // 'Authorization': 'Bearer $token', // Si usas auth
  };

  // GET
  static Future<dynamic> get(String endpoint) async {
    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
    );
    return _handleResponse(response);
  }

  // POST
  static Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  static dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error ${response.statusCode}: ${response.body}');
    }
  }
}