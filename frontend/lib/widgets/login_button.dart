import 'package:flutter/material.dart';

class LoginButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;

  const LoginButton({Key? key, required this.onPressed, required this.label})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 45,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          disabledBackgroundColor: Colors.black.withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: onPressed != null ? 2 : 0,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: onPressed != null ? Colors.white : Colors.white70,
          ),
        ),
      ),
    );
  }
}
