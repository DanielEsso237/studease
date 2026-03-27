import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'pages/login_page.dart';
import 'pages/chat_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final isLogged = await AuthService.isLoggedIn();
  runApp(StudEaseApp(startOnChat: isLogged));
}

class StudEaseApp extends StatelessWidget {
  final bool startOnChat;
  const StudEaseApp({super.key, required this.startOnChat});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: startOnChat ? const ChatPage() : const LoginPage(),
    );
  }
}
