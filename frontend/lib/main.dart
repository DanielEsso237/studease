import 'package:flutter/material.dart';
import 'pages/login_page.dart';

void main() {
  runApp(const StudEaseApp());
}

class StudEaseApp extends StatelessWidget {
  const StudEaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'StudEase',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const LoginPage(), // Page principale = LoginPage
    );
  }
}
