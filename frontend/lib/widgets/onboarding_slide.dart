import 'package:flutter/material.dart';

class OnboardingSlide extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final String tag;
  final Color primaryColor;
  final Color secondaryColor;

  const OnboardingSlide({
    super.key,
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          _AnimatedIconBox(emoji: emoji),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: Colors.white.withOpacity(0.35)),
            ),
            child: Text(
              tag,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              height: 1.2,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 15,
              height: 1.6,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedIconBox extends StatefulWidget {
  final String emoji;
  const _AnimatedIconBox({required this.emoji});

  @override
  State<_AnimatedIconBox> createState() => _AnimatedIconBoxState();
}

class _AnimatedIconBoxState extends State<_AnimatedIconBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _floatAnim;
  late Animation<double> _rotateAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    _floatAnim = Tween<double>(
      begin: 0,
      end: -10,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _rotateAnim = Tween<double>(
      begin: -0.03,
      end: 0.03,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, _floatAnim.value),
        child: Transform.rotate(angle: _rotateAnim.value, child: child),
      ),
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.white.withOpacity(0.35), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 30,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Center(
          child: Text(widget.emoji, style: const TextStyle(fontSize: 52)),
        ),
      ),
    );
  }
}
