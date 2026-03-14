import 'package:flutter/material.dart';

class FullNameField extends StatelessWidget {
  final TextEditingController controller;

  const FullNameField({Key? key, required this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: "Nom complet",
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
