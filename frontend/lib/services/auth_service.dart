import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../pages/login_page.dart';
import '../config/app_config.dart';

class AuthService {
  static const _tokenKey = 'auth_token';
  static const _userNameKey = 'user_name';
  static const _userEmailKey = 'user_email';
  static const _avatarUrlKey = 'avatar_url';

  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId:
        "524608439249-e0ifvgqdp2ekurqp3dj9fr3qu3rgsfog.apps.googleusercontent.com",
    scopes: ['email', 'profile'],
  );

  static Future<Map<String, String>> baseHeaders() async {
    return {
      'Content-Type': 'application/json',
      'ngrok-skip-browser-warning': 'true',
    };
  }

  static Future<Map<String, String>> authHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'ngrok-skip-browser-warning': 'true',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<void> saveSession({
    required String token,
    required String name,
    required String email,
    String? avatarUrl,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userNameKey, name);
    await prefs.setString(_userEmailKey, email);
    if (avatarUrl != null) {
      await prefs.setString(_avatarUrlKey, avatarUrl);
    }
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey);
  }

  static Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userEmailKey);
  }

  static Future<String?> getAvatarUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_avatarUrlKey);
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userNameKey);
    await prefs.remove(_userEmailKey);
    await prefs.remove(_avatarUrlKey);
    await _googleSignIn.signOut();
  }

  static Future<Map<String, dynamic>?> signInWithGoogle() async {
    try {
      await _googleSignIn.signOut();
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null) return null;

      final response = await http.post(
        Uri.parse(AppConfig.googleAuthUrl),
        headers: await baseHeaders(),
        body: jsonEncode({'id_token': idToken}),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        await saveSession(
          token: body['token'],
          name: body['user']['name'],
          email: body['user']['email'],
          avatarUrl: body['user']['avatar_url'],
        );
        return body;
      }
      return null;
    } catch (e) {
      print("Google Sign-In Error: $e");
      return null;
    }
  }

  static Future<void> handleUnauthorized(BuildContext context) async {
    await logout();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }
}
