import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'pages/login_page.dart';
import 'pages/chat_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final isLogged = await AuthService.isLoggedIn();
  runApp(StudEaseApp(startOnChat: isLogged));
}

class StudEaseApp extends StatefulWidget {
  final bool startOnChat;
  const StudEaseApp({super.key, required this.startOnChat});

  static _StudEaseAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<_StudEaseAppState>();

  @override
  State<StudEaseApp> createState() => _StudEaseAppState();
}

class _StudEaseAppState extends State<StudEaseApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void setThemeMode(ThemeMode mode) => setState(() => _themeMode = mode);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      themeMode: _themeMode,
      theme: ThemeData.light(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
      home: widget.startOnChat ? const ChatPage() : const LoginPage(),
    );
  }
}
