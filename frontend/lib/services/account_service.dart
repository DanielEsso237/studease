import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../services/auth_service.dart';

class AccountService {
  static Future<Map<String, String>> _headers() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static Future<Map<String, dynamic>?> getAccount() async {
    final res = await http
        .get(Uri.parse(AppConfig.accountUrl), headers: await _headers())
        .timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) return jsonDecode(res.body);
    return null;
  }

  static Future<bool> updateUsername(String name) async {
    final res = await http
        .put(
          Uri.parse(AppConfig.accountUsernameUrl),
          headers: await _headers(),
          body: jsonEncode({'name': name}),
        )
        .timeout(const Duration(seconds: 10));
    return res.statusCode == 200;
  }

  static Future<String?> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final res = await http
        .put(
          Uri.parse(AppConfig.accountPasswordUrl),
          headers: await _headers(),
          body: jsonEncode({
            'current_password': currentPassword,
            'new_password': newPassword,
          }),
        )
        .timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) return null;
    final body = jsonDecode(res.body);
    return body['error'] ?? 'Erreur inconnue';
  }

  static Future<String?> deleteAccount(String password) async {
    final res = await http
        .delete(
          Uri.parse(AppConfig.accountUrl),
          headers: await _headers(),
          body: jsonEncode({'password': password}),
        )
        .timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) return null;
    final body = jsonDecode(res.body);
    return body['error'] ?? 'Erreur inconnue';
  }

  /// Supprime toutes les conversations de l'utilisateur connecté.
  /// Retourne null si succès, sinon le message d'erreur.
  static Future<String?> deleteAllConversations() async {
    final res = await http
        .delete(
          Uri.parse(AppConfig.conversationsAllUrl),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 15));
    if (res.statusCode == 200) return null;
    try {
      final body = jsonDecode(res.body);
      return body['error'] ?? 'Erreur inconnue';
    } catch (_) {
      return 'Erreur ${res.statusCode}';
    }
  }
}
