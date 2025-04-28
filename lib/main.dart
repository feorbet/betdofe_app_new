import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart'; // Adicionado para inicializar formatação de data
import 'package:betdofe_app_new/features/auth/screens/LoginScreen.dart';
import 'package:betdofe_app_new/features/auth/screens/OnboardingScreen.dart';
import 'package:betdofe_app_new/features/home/screens/HomeScreen.dart';
import 'package:betdofe_app_new/features/home/screens/ChartScreen.dart';
import 'package:betdofe_app_new/features/home/screens/TransactionScreen.dart';
import 'package:betdofe_app_new/features/home/screens/AccountManagementScreen.dart';
import 'package:betdofe_app_new/features/goals/screens/GoalsScreen.dart';
import 'package:betdofe_app_new/features/splash/SplashScreen.dart';
import 'package:betdofe_app_new/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await initializeDateFormatting(
      'pt_BR', null); // Inicializa formatação de data para português do Brasil
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: appTheme(),
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/home': (context) => const HomeScreen(),
        '/chart': (context) => const ChartScreen(),
        '/account_management': (context) => const AccountManagementScreen(),
        '/transaction': (context) => const TransactionScreen(),
        '/goals': (context) => const GoalsScreen(),
      },
    );
  }
}

ThemeData appTheme() {
  return ThemeData(
    primaryColor: AppConstants.primaryColor,
    scaffoldBackgroundColor: AppConstants.lightGreenShade1,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: FadeUpwardsPageTransitionsBuilder(),
      },
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: AppConstants.white,
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.defaultPadding,
          vertical: 15,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        textStyle: AppConstants.buttonTextStyle,
      ),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(fontSize: 16, color: AppConstants.textBlack),
      bodyMedium: AppConstants.bodyStyle,
      headlineSmall: AppConstants.headingStyle,
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        borderSide: const BorderSide(color: AppConstants.textGrey),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        borderSide: const BorderSide(color: AppConstants.textGrey300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        borderSide: const BorderSide(color: AppConstants.textGrey),
      ),
      filled: true,
      fillColor: Colors.grey[100],
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppConstants.primaryColor,
      titleTextStyle: TextStyle(
        color: AppConstants.white,
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
      iconTheme: IconThemeData(color: AppConstants.white),
      centerTitle: true,
    ),
  );
}
