import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../services/auth_service.dart';

class AccountService {
  static Future<Map<String, dynamic>?> getAccount() async {
    final res = await http
        .get(
          Uri.parse(AppConfig.accountUrl),
          headers: await AuthService.authHeaders(),
        )
        .timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) return jsonDecode(res.body);
    return null;
  }

  static Future<bool> updateUsername(String name) async {
    final res = await http
        .put(
          Uri.parse(AppConfig.accountUsernameUrl),
          headers: await AuthService.authHeaders(),
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
          headers: await AuthService.authHeaders(),
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
          headers: await AuthService.authHeaders(),
          body: jsonEncode({'password': password}),
        )
        .timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) return null;
    final body = jsonDecode(res.body);
    return body['error'] ?? 'Erreur inconnue';
  }

  static Future<String?> deleteAllConversations() async {
    final res = await http
        .delete(
          Uri.parse(AppConfig.conversationsAllUrl),
          headers: await AuthService.authHeaders(),
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
