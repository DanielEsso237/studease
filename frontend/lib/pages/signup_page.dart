import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../widgets/email_field.dart';
import '../widgets/password_field.dart';
import '../widgets/login_button.dart';
import '../widgets/google_login_button.dart';
import '../widgets/confirm_password_field.dart';
import '../widgets/full_name_field.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({Key? key}) : super(key: key);

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  late VideoPlayerController _controller;
  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool obscurePassword = true;
  bool obscureConfirm = true;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset(
      "assets/animations/animated_logo.mp4",
    )..initialize().then((_) => setState(() {}));
    _controller.setLooping(true);
    _controller.setVolume(0);
    _controller.play();

    fullNameController.addListener(_updateState);
    emailController.addListener(_updateState);
    passwordController.addListener(_updateState);
    confirmPasswordController.addListener(_updateState);
  }

  void _updateState() => setState(() {});

  @override
  void dispose() {
    _controller.dispose();
    fullNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  bool get _isFormValid {
    final name = fullNameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;
    final confirm = confirmPasswordController.text;

    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');

    return name.isNotEmpty &&
        emailRegex.hasMatch(email) &&
        password.length >= 6 &&
        password == confirm;
  }

  void _onSignupPressed() {
    setState(() => isLoading = true);
    Future.delayed(const Duration(seconds: 2), () {
      setState(() => isLoading = false);
      // Ici tu peux naviguer vers la page principale ou login
    });
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
              if (_controller.value.isInitialized)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: SizedBox(
                    width: screenWidth * 0.7,
                    child: AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: VideoPlayer(_controller),
                    ),
                  ),
                ),
              FractionallySizedBox(
                widthFactor: screenWidth > 500 ? 0.5 : 0.9,
                child: Container(
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
                        "Créer un compte Studease",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 25),
                      FullNameField(controller: fullNameController),
                      const SizedBox(height: 16),
                      EmailField(controller: emailController),
                      const SizedBox(height: 16),
                      PasswordField(
                        controller: passwordController,
                        obscureText: obscurePassword,
                        toggleObscure: () {
                          setState(() => obscurePassword = !obscurePassword);
                        },
                      ),
                      const SizedBox(height: 16),
                      ConfirmPasswordField(
                        controller: confirmPasswordController,
                        obscureText: obscureConfirm,
                        toggleObscure: () {
                          setState(() => obscureConfirm = !obscureConfirm);
                        },
                      ),
                      const SizedBox(height: 20),
                      isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : LoginButton(
                              onPressed: _isFormValid ? _onSignupPressed : null,
                              label: "Créer un compte",
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
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text("Déjà un compte ? "),
                          Text(
                            "Se connecter",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
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
