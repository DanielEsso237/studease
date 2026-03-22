import 'package:flutter/material.dart';

class NameField extends StatelessWidget {
  final TextEditingController controller;
  final String? errorText;

  const NameField({super.key, required this.controller, this.errorText});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: "Nom d'utilisateur",
        errorText: errorText,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: errorText != null ? Colors.red : Colors.grey.shade400,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: errorText != null ? Colors.red : Colors.blue,
            width: 2,
          ),
        ),
      ),
    );
  }
}
