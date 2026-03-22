import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import '../config/app_config.dart';
import '../services/auth_service.dart';
import '../widgets/email_field.dart';
import '../widgets/password_field.dart';
import '../widgets/login_button.dart';
import '../widgets/google_login_button.dart';
import 'signup_page.dart';
import 'chat_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late VideoPlayerController _videoController;
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool obscurePassword = true;
  bool isLoading = false;

  String? _emailError;
  String? _passwordError;

  static final _emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

  String? _validateEmail(String v) {
    if (v.trim().isEmpty) return "L'email est requis";
    if (!_emailRegex.hasMatch(v.trim())) return "Adresse email invalide";
    return null;
  }

  String? _validatePassword(String v) {
    if (v.isEmpty) return "Le mot de passe est requis";
    if (v.length < 6) return "Au moins 6 caractères";
    return null;
  }

  bool get isFormValid =>
      _validateEmail(emailController.text) == null &&
      _validatePassword(passwordController.text) == null;

  @override
  void initState() {
    super.initState();

    _videoController =
        VideoPlayerController.asset("assets/animations/animated_logo.mp4")
          ..initialize().then((_) {
            if (mounted) setState(() {});
          });
    _videoController.setLooping(true);
    _videoController.setVolume(0);
    _videoController.play();

    emailController.addListener(
      () => setState(() => _emailError = _validateEmail(emailController.text)),
    );
    passwordController.addListener(
      () => setState(
        () => _passwordError = _validatePassword(passwordController.text),
      ),
    );
  }

  @override
  void dispose() {
    _videoController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _onLoginPressed() async {
    setState(() {
      _emailError = _validateEmail(emailController.text);
      _passwordError = _validatePassword(passwordController.text);
    });
    if (!isFormValid) return;

    FocusScope.of(context).unfocus();
    setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(AppConfig.loginUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': emailController.text.trim().toLowerCase(),
          'password': passwordController.text,
        }),
      );

      final body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        await AuthService.saveSession(
          token: body['token'],
          name: body['user']['name'],
          email: body['user']['email'],
        );
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const ChatPage()),
          (_) => false,
        );
      } else if (response.statusCode == 401) {
        setState(() {
          _emailError = "Email ou mot de passe incorrect";
          _passwordError = "Email ou mot de passe incorrect";
        });
      } else {
        final msg = body['error'] ?? 'Erreur de connexion';
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Impossible de joindre le serveur — vérifie l\'URL dans app_config.dart',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xffF7F7F8),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            children: [
              if (_videoController.value.isInitialized)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: SizedBox(
                    width: screenWidth * 0.7,
                    child: AspectRatio(
                      aspectRatio: _videoController.value.aspectRatio,
                      child: VideoPlayer(_videoController),
                    ),
                  ),
                ),

              Container(
                width: 380,
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      "Connexion à StudEase",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 25),

                    EmailField(
                      controller: emailController,
                      errorText: _emailError,
                    ),
                    const SizedBox(height: 16),

                    PasswordField(
                      controller: passwordController,
                      obscureText: obscurePassword,
                      toggleObscure: () =>
                          setState(() => obscurePassword = !obscurePassword),
                      errorText: _passwordError,
                    ),
                    const SizedBox(height: 24),

                    isLoading
                        ? const SizedBox(
                            height: 45,
                            child: Center(child: CircularProgressIndicator()),
                          )
                        : Opacity(
                            opacity: isFormValid ? 1.0 : 0.45,
                            child: LoginButton(
                              onPressed: isFormValid ? _onLoginPressed : null,
                              label: "Continuer",
                            ),
                          ),

                    const SizedBox(height: 20),
                    Row(
                      children: const [
                        Expanded(child: Divider()),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text("OU"),
                        ),
                        Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 20),

                    GoogleLoginButton(onPressed: () {}),
                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Pas de compte ? "),
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SignupPage(),
                            ),
                          ),
                          child: const Text(
                            "Créer un compte",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),
              const Text(
                "© 2026 Studease",
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
