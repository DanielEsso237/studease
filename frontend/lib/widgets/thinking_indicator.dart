import 'package:flutter/material.dart';

class ThinkingIndicator extends StatefulWidget {
  const ThinkingIndicator({super.key});

  @override
  State<ThinkingIndicator> createState() => _ThinkingIndicatorState();
}

class _ThinkingIndicatorState extends State<ThinkingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  final List<String> _phrases = [
    "Réflexion en cours…",
    "Je cherche la meilleure réponse…",
    "Ça arrive tout de suite…",
    "Presque terminé…",
    "Encore un petit instant…",
  ];

  int _currentPhraseIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 2600));
      if (!mounted) return false;
      setState(() {
        _currentPhraseIndex = (_currentPhraseIndex + 1) % _phrases.length;
      });
      return true;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.white,
            child: ClipOval(
              child: Image.asset(
                'assets/images/bot.png',
                width: 36,
                height: 36,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.70,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F0F5),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  FadeTransition(
                    opacity: _animation,
                    child: const Icon(
                      Icons.auto_awesome,
                      size: 18,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 450),
                      child: Text(
                        _phrases[_currentPhraseIndex],
                        key: ValueKey<int>(_currentPhraseIndex),
                        softWrap: true,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
