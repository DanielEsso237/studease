import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/onboarding_slide.dart';
import '../pages/login_page.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();

  int _currentPage = 0;

  static const Color _primaryBlue = Color(0xFF1a6fff);
  static const Color _darkBlue = Color(0xFF0047cc);

  static const List<Map<String, String>> _slides = [
    {
      'emoji': '🎓',
      'title': 'Bienvenue sur StudEase',
      'subtitle':
          'Ton assistant officiel de la Faculté des Sciences de l\'Université d\'Ebolowa',
      'tag': 'FS-UEb',
    },
    {
      'emoji': '💬',
      'title': 'Réponses instantanées\n24h/24',
      'subtitle':
          'Procédures, frais, calendrier, salles… toutes les infos de la fac en un seul message',
      'tag': 'Disponible',
    },
    {
      'emoji': '🚀',
      'title': 'Prêt à\ncommencer ?',
      'subtitle':
          'Connecte-toi et pose ta première question. La connaissance est à portée de doigt.',
      'tag': 'Démarrer',
    },
  ];

  late AnimationController _bgController;
  late Animation<double> _bgAnimation;
  late AnimationController _btnController;
  late Animation<double> _btnAnimation;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _bgAnimation = CurvedAnimation(
      parent: _bgController,
      curve: Curves.easeOut,
    );

    _btnController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _btnAnimation = Tween<double>(
      begin: 1.0,
      end: 1.04,
    ).animate(CurvedAnimation(parent: _btnController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pageController.dispose();
    _bgController.dispose();
    _btnController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
    _bgController.forward(from: 0);
  }

  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _goToLogin();
    }
  }

  void _goToLogin() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => const LoginPage(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildBackground(),
          _buildDecorativeShapes(),
          Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  itemCount: _slides.length,
                  itemBuilder: (_, index) {
                    final slide = _slides[index];
                    return OnboardingSlide(
                      emoji: slide['emoji']!,
                      title: slide['title']!,
                      subtitle: slide['subtitle']!,
                      tag: slide['tag']!,
                      primaryColor: _primaryBlue,
                      secondaryColor: _darkBlue,
                    );
                  },
                ),
              ),
              _buildBottomSection(),
            ],
          ),
          _buildSkipButton(),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _currentPage == 0
              ? [const Color(0xFF1a6fff), const Color(0xFF0035a8)]
              : _currentPage == 1
              ? [const Color(0xFF0057e0), const Color(0xFF001f6e)]
              : [const Color(0xFF0047cc), const Color(0xFF00144d)],
        ),
      ),
    );
  }

  Widget _buildDecorativeShapes() {
    return Stack(
      children: [
        Positioned(
          top: -80,
          right: -80,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.07 + _currentPage * 0.02),
            ),
          ),
        ),
        Positioned(
          bottom: 140,
          left: -80,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.05 + _currentPage * 0.01),
            ),
          ),
        ),
        Positioned(
          top: 200,
          left: -40,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.04),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSkipButton() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      right: 20,
      child: AnimatedOpacity(
        opacity: _currentPage < _slides.length - 1 ? 1 : 0,
        duration: const Duration(milliseconds: 300),
        child: GestureDetector(
          onTap: _goToLogin,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: Colors.white.withOpacity(0.25)),
            ),
            child: const Text(
              'Passer',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomSection() {
    final isLast = _currentPage == _slides.length - 1;

    return Padding(
      padding: EdgeInsets.only(
        left: 28,
        right: 28,
        bottom: MediaQuery.of(context).padding.bottom + 32,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [_buildDots(), _buildNextButton(isLast)],
          ),
          if (isLast) ...[const SizedBox(height: 16), _buildFullStartButton()],
        ],
      ),
    );
  }

  Widget _buildDots() {
    return Row(
      children: List.generate(_slides.length, (index) {
        final isActive = index == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.only(right: 6),
          width: isActive ? 28 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.white.withOpacity(0.35),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Widget _buildNextButton(bool isLast) {
    if (isLast) return const SizedBox.shrink();

    return GestureDetector(
      onTap: _nextPage,
      child: AnimatedBuilder(
        animation: _btnAnimation,
        builder: (_, child) =>
            Transform.scale(scale: _btnAnimation.value, child: child),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.arrow_forward_rounded,
            color: Color(0xFF1a6fff),
            size: 26,
          ),
        ),
      ),
    );
  }

  Widget _buildFullStartButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _goToLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1a6fff),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Commencer',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
            SizedBox(width: 8),
            Text('🚀', style: TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}
