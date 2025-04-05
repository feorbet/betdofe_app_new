import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final Color primaryColor = const Color(0xFF1B5E20);
  final Color darkPrimary = const Color(0xFF0D3B13);
  final Color lightGreen = const Color(0xFF2E7D32);

  int _selectedIndex = 0;
  bool isValuesVisible = true;

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bom dia';
    if (hour < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  void _toggleValuesVisibility() {
    setState(() {
      isValuesVisible = !isValuesVisible;
    });
  }

  void _logout(BuildContext context) async {
    await _auth.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    final userName = user?.displayName ?? 'Apostador';

    return Scaffold(
      backgroundColor: Colors.white,
      extendBody: true,
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: primaryColor,
              ),
              child: Text(
                'Menu',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Perfil'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sair'),
              onTap: () {
                Navigator.pop(context);
                _logout(context);
              },
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          // Camada 1 (inferior): Histórico de Transações
          Column(
            children: [
              const SizedBox(height: 360),
              // HISTÓRICO DE TRANSAÇÕES
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('Histórico de Transações',
                        style:
                            TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('Ver tudo',
                        style: TextStyle(color: Colors.grey, fontSize: 14))
                  ],
                ),
              ),

              const SizedBox(height: 5),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ListView(
                    children: [
                      _buildTransactionTile(
                          'Flamengo x Palmeiras', 'Hoje', '+ R\$ 850,00', true),
                      _buildTransactionTile('Corinthians x São Paulo', 'Ontem',
                          '- R\$ 85,00', false, 'Pendente'),
                      _buildTransactionTile(
                          'Grêmio x Inter', '30 Jan 2022', '+ R\$ 1.406,00', true),
                      _buildTransactionTile(
                          'Santos x Bahia', '16 Jan 2022', '- R\$ 119,00', false),
                      _buildTransactionTile('Atlético MG x Cruzeiro', 'Ontem',
                          '- R\$ 85,00', false, 'Perdeu'),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Camada 2: Cabeçalho com a curva (onda)
          Stack(
            children: [
              ClipPath(
                clipper: HeaderClipper(),
                child: Container(
                  height: 240,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [lightGreen, primaryColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 50, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_getGreeting(),
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 16)),
                        Text(userName,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Camada 3 (superior): Painel de Saldo sem gradiente
          Positioned(
            top: 140,
            left: 0,
            right: 0,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: primaryColor, // Cor sólida, sem gradiente
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Saldo Total',
                          style: TextStyle(color: Colors.white70)),
                      GestureDetector(
                        onTap: _toggleValuesVisibility,
                        child: Icon(
                          isValuesVisible ? Icons.visibility : Icons.visibility_off,
                          color: Colors.white70,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isValuesVisible ? 'R\$ 1.556,00' : '****',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        children: [
                          const Icon(Icons.arrow_upward, color: Colors.white),
                          const SizedBox(height: 4),
                          const Text('Ganhos',
                              style: TextStyle(color: Colors.white70)),
                          Text(
                            isValuesVisible ? 'R\$ 1.840,00' : '****',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          const Icon(Icons.arrow_downward, color: Colors.white),
                          const SizedBox(height: 4),
                          const Text('Perdas',
                              style: TextStyle(color: Colors.white70)),
                          Text(
                            isValuesVisible ? 'R\$ 284,00' : '****',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      )
                    ],
                  )
                ],
              ),
            ),
          ),

          // Camada 4 (superior): Ícone de menu
          Positioned(
            top: 50,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            ),
          ),
        ],
      ),

      // BOTÃO CENTRAL
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // NAVEGAÇÃO INFERIOR
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: ''),
          BottomNavigationBarItem(
              icon: Icon(Icons.add, color: Colors.transparent), label: ''),
          BottomNavigationBarItem(
              icon: Icon(Icons.attach_money), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: ''),
        ],
      ),
    );
  }

  static Widget _buildTransactionTile(
      String title, String date, String amount, bool isGain,
      [String? status]) {
    final color = isGain ? Colors.green : Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 5,
            spreadRadius: 1,
          )
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.grey.shade200,
            child: const Icon(Icons.sports_soccer, color: Colors.black54),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 16)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(date, style: const TextStyle(fontSize: 12)),
                    if (status != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(status,
                            style: const TextStyle(
                                fontSize: 10, color: Colors.black87)),
                      )
                    ]
                  ],
                )
              ],
            ),
          ),
          Text(amount,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }
}

// CURVA DO TOPO
class HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 40);
    path.quadraticBezierTo(
        size.width / 2, size.height + 40, size.width, size.height - 40);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}