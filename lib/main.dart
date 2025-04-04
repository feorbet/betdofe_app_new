import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:betdofe_app_new/firebase_options.dart';
import 'package:betdofe_app_new/screens/splash_screen.dart';
import 'package:betdofe_app_new/screens/onboarding_screen.dart';
import 'package:betdofe_app_new/screens/login_screen.dart';
import 'package:betdofe_app_new/screens/register_screen.dart';
import 'package:betdofe_app_new/screens/home_screen.dart'; // Importe o HomeScreen

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(), // Rota adicionada
      },
    );
  }
}