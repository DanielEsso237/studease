import 'package:flutter/material.dart';
import '../pages/login_page.dart';

void main() {
  runApp(const StudEaseApp());
}

class StudEaseApp extends StatelessWidget {
  const StudEaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const LoginPage(), // Page principale = LoginPage
    );
  }
}
