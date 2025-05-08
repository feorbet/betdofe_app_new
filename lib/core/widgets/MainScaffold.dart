import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:betdofe_app_new/core/widgets/FooterBar.dart';
import 'package:betdofe_app_new/constants.dart';

class MainScaffold extends StatelessWidget {
  final int selectedIndex;
  final PreferredSizeWidget? appBar;
  final Widget body;
  final bool showFloatingActionButton;
  final Widget? drawer;
  final Widget? floatingActionButton;
  final VoidCallback? onFabPressed;

  const MainScaffold({
    super.key,
    required this.selectedIndex,
    this.appBar,
    required this.body,
    this.showFloatingActionButton = true,
    this.drawer,
    this.floatingActionButton,
    this.onFabPressed,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('Usuário não autenticado, redirecionando para login');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
          (Route<dynamic> route) => false,
        );
      });
      return const Center(child: CircularProgressIndicator());
    }

    print('Usuário autenticado: ${user.uid}');
    return ScaffoldMessenger(
      child: Stack(
        children: [
          Scaffold(
            appBar: appBar,
            body: Container(
              color: Colors.white,
              child: body,
            ),
            drawer: drawer,
            bottomNavigationBar: FooterBar(
              selectedIndex: selectedIndex,
              onTap: (index) {
                switch (index) {
                  case 0:
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/home',
                      (Route<dynamic> route) => false,
                    );
                    break;
                  case 1:
                    Navigator.pushNamed(context, '/chart');
                    break;
                  case 2:
                    Navigator.pushNamed(context, '/account_management');
                    break;
                  case 3:
                    Navigator.pushNamed(context, '/goals');
                    break;
                }
              },
            ),
            backgroundColor: Colors.white,
            resizeToAvoidBottomInset: false, // Alterado para false
          ),
          if (showFloatingActionButton)
            Positioned(
              bottom: 28, // Ajustado para alinhar com o FooterBar
              left: 0,
              right: 0,
              child: Center(
                child: floatingActionButton ??
                    FloatingActionButton(
                      onPressed: onFabPressed ??
                          () {
                            Navigator.pushNamed(context, '/transaction');
                          },
                      backgroundColor: AppConstants.primaryColor,
                      shape: const CircleBorder(),
                      child: const Icon(
                        Icons.add,
                        color: AppConstants.white,
                        size: 24,
                      ),
                    ),
              ),
            ),
        ],
      ),
    );
  }
}
