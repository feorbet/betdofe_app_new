import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import 'package:betdofe_app_new/constants.dart';

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

    // Configura o controlador de animação com duração de 4 segundos
    _controller = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(); // Repete a animação continuamente

    // Redireciona após 5 segundos com base no estado de login
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        // Verifica se há um usuário logado
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          // Usuário logado, vai direto para a tela /home
          Navigator.of(context).pushReplacementNamed('/home');
        } else {
          // Usuário não logado, vai para a tela de onboarding
          Navigator.of(context).pushReplacementNamed('/onboarding');
        }
      }
    });
  }

  @override
  void dispose() {
    // Libera o controlador de animação para evitar memory leaks
    _controller.dispose();
    super.dispose();
  }

  // Cria o efeito de brilho (sheen) sobre a logo
  Shader _createSheen(Rect bounds, double animationValue) {
    final width = bounds.width;
    final sheenWidth = width * 0.1; // Largura do brilho
    final startX = width * animationValue - sheenWidth;

    return LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        Colors.transparent,
        AppConstants.white.withOpacity(0.3), // Brilho sutil
        Colors.transparent,
      ],
      stops: const [0.0, 0.5, 1.0],
      transform: GradientRotation(pi / 8), // Rotação para efeito dinâmico
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
            image:
                AssetImage('assets/stadium_background.png'), // Fundo de estádio
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
                blendMode: BlendMode.srcATop, // Aplica o brilho sobre a logo
                child: child,
              );
            },
            child: Image.asset(
              'assets/logo.png', // Logo do app
              width: 300, // Tamanho fixo para visibilidade
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
