// lib/services/auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:io' show Platform;

class AuthService {
  // Use 10.0.2.2 for the Android Emulator to connect to localhost
  final String _baseUrl = "http://10.0.2.2:1337"; // CORRECT address for the Android emulator

  final _storage = const FlutterSecureStorage();

  Future<Map<String, dynamic>> _handleAuthRequest(String url, Map<String, String> body) async {
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final token = data['token'];
        if (token != null) {
          await _storage.write(key: 'authToken', value: token);
          return {'success': true, 'token': token};
        }
      }
      // Try to provide a more specific error message from the backend
      String errorMessage = data.entries.map((e) => '${e.key}: ${e.value.join(", ")}').join("\n");
      return {'success': false, 'message': errorMessage.isNotEmpty ? errorMessage : 'An unknown error occurred'};
    } catch (e) {
      return {'success': false, 'message': 'Could not connect to the server. Please check your network connection.'};
    }
  }

  Future<Map<String, dynamic>> register(String username, String email, String password) async {
    return _handleAuthRequest(
      '$_baseUrl/api/register/',
      {'username': username, 'email': email, 'password': password, 'password2': password},
    );
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    return _handleAuthRequest(
      '$_baseUrl/api/login/',
      {'username': username, 'password': password},
    );
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    final token = await getToken();
    if (token == null) return null;

    final response = await http.get(
      Uri.parse('$_baseUrl/api/profile/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  }

  Future<void> logout() async {
    await _storage.delete(key: 'authToken');
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'authToken');
  }
}

