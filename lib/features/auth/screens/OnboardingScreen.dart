import 'package:flutter/material.dart';
import 'package:betdofe_app_new/constants.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final Color brightYellowColor = Colors.yellow[600]!;

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
        child: Stack(
          children: [
            PageView(
              controller: _pageController,
              onPageChanged: (int page) {
                setState(() {
                  _currentPage = page;
                });
              },
              children: [
                buildPage(
                  image: 'assets/onboarding/money.png',
                  title: 'Controle seus ganhos',
                  subtitle:
                      'Gerencie suas apostas com precisão e acompanhe seus lucros em tempo real.',
                ),
                buildPage(
                  image: 'assets/onboarding/chart.png',
                  title: 'Acompanhe seus progressos',
                  subtitle:
                      'Visualize seus resultados com gráficos e filtros para tomar decisões inteligentes.',
                ),
                buildPage(
                  image: 'assets/onboarding/target.png',
                  title: 'Alcance seus objetivos',
                  subtitle:
                      'Defina metas, otimize suas apostas e maximize seus ganhos com eficiência.',
                ),
              ],
            ),
            Positioned(
              bottom: 80,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (index) => buildDot(index)),
              ),
            ),
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brightYellowColor,
                    foregroundColor: AppConstants.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.defaultPadding * 2,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppConstants.borderRadius),
                    ),
                  ),
                  onPressed: () {
                    if (_currentPage < 2) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      Navigator.pushReplacementNamed(context, '/login');
                    }
                  },
                  child: Text(
                    _currentPage < 2 ? 'Próximo' : 'Começar',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildPage({
    required String image,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 120, left: 16, right: 16, bottom: 80),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: brightYellowColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.smallSpacing),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.mediumSpacing),
          Image.asset(
            image,
            height: 300,
            fit: BoxFit.contain,
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget buildDot(int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5),
      width: _currentPage == index ? 12 : 8,
      height: 8,
      decoration: BoxDecoration(
        color:
            _currentPage == index ? brightYellowColor : AppConstants.textGrey,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
