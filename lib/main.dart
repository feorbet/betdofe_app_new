import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:betdofe_app_new/screens/home_screen.dart'; // Ajuste o caminho conforme necessário
import 'package:intl/date_symbol_data_local.dart'; // Adicione esta importação

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  // Inicializa os dados de localização para pt_BR
  await initializeDateFormatting('pt_BR', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Betdofe App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomeScreen(), // Ajuste para a tela inicial do seu app
      routes: {
        // Comentei a rota do LoginScreen para evitar o erro
        // '/login': (context) => const LoginScreen(), // Descomente e ajuste conforme necessário
        // Outras rotas...
      },
    );
  }
}