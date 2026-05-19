import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart'; // ← importa tu ApiService

class AuthService {
  // ─── REGISTER ───────────────────────────────────────────────────
  static Future<Map<String, dynamic>> register(
    String nombre,
    String correo,
    String password,
  ) async {
    try {
      await ApiService.post('/estudiantes/register', {
        'nombre': nombre,
        'correo': correo,
        'password': password,
      });
      return {'success': true};
    } on Exception catch (e) {
      return {'success': false, 'message': e.toString()};
    } catch (_) {
      return {'success': false, 'message': 'No se pudo conectar con el servidor.'};
    }
  }

  // ─── LOGIN ──────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> login(
    String correo,
    String password,
  ) async {
    try {
      // 1. Obtener el token
      final loginData = await ApiService.post('/estudiantes/login', {
        'correo': correo,
        'password': password,
      });

      final token = loginData['access_token'];

      // 2. Buscar datos del estudiante por correo
      final List estudiantes = await ApiService.get('/estudiantes/');
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
    } on Exception catch (e) {
      return {'success': false, 'message': e.toString()};
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
      final List estudiantes = await ApiService.get('/estudiantes/');
      final estudiante = estudiantes.firstWhere(
        (e) => e['correo_usuario'] == correo,
        orElse: () => null,
      );

      if (estudiante == null) {
        return {'success': false, 'message': 'Estudiante no encontrado.'};
      }

      final id = estudiante['id_estudiante'];

      // 2. Subir la foto usando multipart (ApiService no cubre multipart,
      //    así que usamos http directamente pero con la URL de la nube)
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiService.baseUrl}/estudiantes/upload-profile-pic/$id'),
      );
      request.files.add(await http.MultipartFile.fromPath('file', filePath));

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'profile_pic_url': data['url']};
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Error al subir la imagen.',
      };
    } on Exception catch (e) {
      return {'success': false, 'message': e.toString()};
    } catch (_) {
      return {'success': false, 'message': 'No se pudo conectar con el servidor.'};
    }
  }

  // ─── CAMBIAR CONTRASEÑA ─────────────────────────────────────────
  static Future<Map<String, dynamic>> changePassword(
    String correo,
    String passwordActual,
    String passwordNueva,
  ) async {
    try {
      await ApiService.put('/estudiantes/change-password', {
        'correo': correo,
        'password_actual': passwordActual,
        'password_nueva': passwordNueva,
      });
      return {'success': true, 'message': 'Contraseña actualizada correctamente.'};
    } on Exception catch (e) {
      return {'success': false, 'message': e.toString()};
    } catch (_) {
      return {'success': false, 'message': 'No se pudo conectar con el servidor.'};
    }
  }
}