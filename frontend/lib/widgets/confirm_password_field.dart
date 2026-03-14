import 'package:flutter/material.dart';

class ConfirmPasswordField extends StatelessWidget {
  final TextEditingController controller;
  final bool obscureText;
  final VoidCallback toggleObscure;

  const ConfirmPasswordField({
    Key? key,
    required this.controller,
    required this.obscureText,
    required this.toggleObscure,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: "Confirmer le mot de passe",
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        suffixIcon: IconButton(
          icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility),
          onPressed: toggleObscure,
        ),
      ),
    );
  }
}
