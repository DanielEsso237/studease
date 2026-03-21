import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import '../config/app_config.dart';
import '../widgets/name_field.dart';
import '../widgets/email_field.dart';
import '../widgets/password_field.dart';
import '../widgets/confirm_password_field.dart';
import '../widgets/signup_button.dart';
import '../widgets/google_login_button.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  late VideoPlayerController _videoController;

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool obscurePassword = true;
  bool obscureConfirm = true;
  bool isLoading = false;

  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmError;

  static final _emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');

  String? _validateName(String v) =>
      v.trim().isEmpty ? "Le nom d'utilisateur est requis" : null;

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

  String? _validateConfirm(String v) {
    if (v.isEmpty) return "Veuillez confirmer le mot de passe";
    if (v != passwordController.text)
      return "Les mots de passe ne correspondent pas";
    return null;
  }

  bool get isFormValid =>
      _validateName(nameController.text) == null &&
      _validateEmail(emailController.text) == null &&
      _validatePassword(passwordController.text) == null &&
      _validateConfirm(confirmPasswordController.text) == null;

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

    nameController.addListener(
      () => setState(() => _nameError = _validateName(nameController.text)),
    );
    emailController.addListener(
      () => setState(() => _emailError = _validateEmail(emailController.text)),
    );
    passwordController.addListener(
      () => setState(() {
        _passwordError = _validatePassword(passwordController.text);
        if (confirmPasswordController.text.isNotEmpty) {
          _confirmError = _validateConfirm(confirmPasswordController.text);
        }
      }),
    );
    confirmPasswordController.addListener(
      () => setState(
        () => _confirmError = _validateConfirm(confirmPasswordController.text),
      ),
    );
  }

  @override
  void dispose() {
    _videoController.dispose();
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    setState(() {
      _nameError = _validateName(nameController.text);
      _emailError = _validateEmail(emailController.text);
      _passwordError = _validatePassword(passwordController.text);
      _confirmError = _validateConfirm(confirmPasswordController.text);
    });

    if (!isFormValid) return;

    FocusScope.of(context).unfocus();
    setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(AppConfig.registerUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': nameController.text.trim(),
          'email': emailController.text.trim().toLowerCase(),
          'password': passwordController.text,
        }),
      );

      final body = jsonDecode(response.body);

      if (response.statusCode == 201) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Compte créé avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else if (response.statusCode == 409) {
        // Email déjà utilisé
        setState(() => _emailError = "Cette adresse email est déjà utilisée");
      } else {
        final msg = body['error'] ?? 'Une erreur est survenue';
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
                      "Créer un compte",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 25),

                    NameField(
                      controller: nameController,
                      errorText: _nameError,
                    ),
                    const SizedBox(height: 16),

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
                    const SizedBox(height: 16),

                    ConfirmPasswordField(
                      controller: confirmPasswordController,
                      obscureText: obscureConfirm,
                      toggleObscure: () =>
                          setState(() => obscureConfirm = !obscureConfirm),
                      errorText: _confirmError,
                    ),
                    const SizedBox(height: 24),

                    isLoading
                        ? const SizedBox(
                            height: 45,
                            child: Center(child: CircularProgressIndicator()),
                          )
                        : Opacity(
                            opacity: isFormValid ? 1.0 : 0.45,
                            child: SignupButton(
                              onPressed: isFormValid ? _signup : null,
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
                        const Text("Déjà un compte ? "),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Text(
                            "Se connecter",
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
