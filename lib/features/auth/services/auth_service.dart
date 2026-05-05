import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  static const String baseUrl = 'http://127.0.0.1:8000';

  // ─── REGISTER ───────────────────────────────────────────────────
  static Future<Map<String, dynamic>> register(
    String nombre,
    String correo,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/estudiantes/register'),  // ← corregido
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'nombre': nombre, 'correo': correo, 'password': password}),
      );
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true};
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Error en el registro.',
      };
    } catch (_) {
      return {'success': false, 'message': 'No se pudo conectar con el servidor.'};
    }
  }

  // ─── LOGIN ──────────────────────────────────────────────────────
  // Tu API devuelve solo el token → luego buscamos los datos del estudiante
  static Future<Map<String, dynamic>> login(
    String correo,
    String password,
  ) async {
    try {
      // 1. Obtener el token
      final loginResponse = await http.post(
        Uri.parse('$baseUrl/estudiantes/login'),  // ← corregido
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'correo': correo, 'password': password}),
      );
      final loginData = jsonDecode(loginResponse.body);

      if (loginResponse.statusCode != 200) {
        return {
          'success': false,
          'message': loginData['message'] ?? 'Credenciales incorrectas.',
        };
      }

      final token = loginData['access_token'];

      // 2. Buscar datos del estudiante por correo
      final estudiantesResponse = await http.get(
        Uri.parse('$baseUrl/estudiantes/'),
        headers: {'Content-Type': 'application/json'},
      );
      final List estudiantes = jsonDecode(estudiantesResponse.body);
      final estudiante = estudiantes.firstWhere(
        (e) => e['correo_usuario'] == correo,
        orElse: () => null,
      );

      return {
        'success': true,
        'token': token,
        'name': estudiante?['nombre_estudiante'] ?? 'Estudiante',
        'user': {'email': correo},
      };
    } catch (_) {
      return {'success': false, 'message': 'No se pudo conectar con el servidor.'};
    }
  }

  // ─── SUBIR FOTO DE PERFIL ────────────────────────────────────────
 static Future<Map<String, dynamic>> uploadProfilePic(
  String correo,
  String filePath,
) async {
  try {
    // 1. Buscar el id del estudiante por correo
    final estudiantesResponse = await http.get(
      Uri.parse('$baseUrl/estudiantes/'),
    );
    final List estudiantes = jsonDecode(estudiantesResponse.body);
    final estudiante = estudiantes.firstWhere(
      (e) => e['correo_usuario'] == correo,
      orElse: () => null,
    );

    if (estudiante == null) {
      return {'success': false, 'message': 'Estudiante no encontrado.'};
    }

    final id = estudiante['id_estudiante'];

    // 2. Subir la foto usando el id
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/estudiantes/upload-profile-pic/$id'),
    );
    request.files.add(await http.MultipartFile.fromPath('file', filePath));

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return {
        'success': true,
        'profile_pic_url': data['url'],
      };
    }
    return {
      'success': false,
      'message': data['message'] ?? 'Error al subir la imagen.',
    };
  } catch (_) {
    return {'success': false, 'message': 'No se pudo conectar con el servidor.'};
  }
}

  // ─── CAMBIAR CONTRASEÑA ─────────────────────────────────────────
  // ⚠️ Este endpoint no existe aún en tu FastAPI — hay que crearlo
  static Future<Map<String, dynamic>> changePassword(
    String correo,
    String passwordActual,
    String passwordNueva,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/estudiantes/change-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'correo': correo,
          'password_actual': passwordActual,
          'password_nueva': passwordNueva,
        }),
      );
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Contraseña actualizada correctamente.'};
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Error al cambiar la contraseña.',
      };
    } catch (_) {
      return {'success': false, 'message': 'No se pudo conectar con el servidor.'};
    }
  }
}