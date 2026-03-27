import 'package:flutter/material.dart';

class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onMenuPressed;

  const ChatAppBar({super.key, required this.onMenuPressed});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 1,
      backgroundColor: Colors.white,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.menu, color: Colors.black),
        onPressed: onMenuPressed,
      ),
      title: const Text(
        "StudEase",
        style: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 20,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
