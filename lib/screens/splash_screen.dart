import 'package:flutter/material.dart';
import 'dart:math';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();

    Future.delayed(const Duration(seconds: 5), () {
      Navigator.of(context).pushReplacementNamed('/onboarding');
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Shader _createSheen(Rect bounds, double animationValue) {
    final width = bounds.width;
    final sheenWidth = width * 0.1;
    final startX = width * animationValue - sheenWidth;

    return LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        Colors.transparent,
        Colors.white.withOpacity(0.3),
        Colors.transparent,
      ],
      stops: const [0.0, 0.5, 1.0],
      transform: GradientRotation(pi / 8),
    ).createShader(Rect.fromLTWH(startX, 0, sheenWidth, bounds.height));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/stadium_background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return ShaderMask(
                shaderCallback: (bounds) =>
                    _createSheen(bounds, _controller.value),
                blendMode: BlendMode.srcATop,
                child: child,
              );
            },
            child: Image.asset(
              'assets/logo.png',
              width: 300, // Tamanho fixo para garantir que fique maior
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}