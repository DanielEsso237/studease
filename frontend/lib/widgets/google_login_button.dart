import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class GoogleLoginButton extends StatelessWidget {
  final VoidCallback onPressed;

  const GoogleLoginButton({Key? key, required this.onPressed})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 45,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset("assets/images/google.svg", height: 20),
            const SizedBox(width: 10),
            const Text("Continuer avec Google"),
          ],
        ),
      ),
    );
  }
}
