import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Color primaryColor = const Color(0xFF2FA49C);
  final Color darkPrimary = const Color(0xFF1A6E65);

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bom dia';
    if (hour < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    final userName = user?.displayName ?? 'Apostador';

    return Scaffold(
      backgroundColor: Colors.white,
      extendBody: true,
      body: Stack(
        children: [
          // Fundo com curva
          ClipPath(
            clipper: HeaderClipper(),
            child: Container(
              height: 260,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryColor, darkPrimary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 0),
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
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.notifications_none,
                          color: Colors.white),
                    )
                  ],
                ),
              ),
            ),
          ),

          // Painel de saldo
          Positioned(
            top: 160,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: primaryColor,
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
                  const Text('Total Balance',
                      style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 8),
                  const Text('R\$ 1.556,00',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Column(
                        children: [
                          Icon(Icons.arrow_downward, color: Colors.white),
                          SizedBox(height: 4),
                          Text('Ganhos',
                              style: TextStyle(color: Colors.white70)),
                          Text('R\$ 1.840,00',
                              style: TextStyle(color: Colors.white)),
                        ],
                      ),
                      Column(
                        children: [
                          Icon(Icons.arrow_upward, color: Colors.white),
                          SizedBox(height: 4),
                          Text('Perdas',
                              style: TextStyle(color: Colors.white70)),
                          Text('R\$ 284,00',
                              style: TextStyle(color: Colors.white)),
                        ],
                      )
                    ],
                  )
                ],
              ),
            ),
          ),

          // Conteúdo abaixo do painel
          Positioned.fill(
            top: 300,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cabeçalho fixo
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('Histórico de Apostas',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('Ver tudo',
                          style: TextStyle(color: Colors.grey, fontSize: 14))
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Lista rolável
                  Expanded(
                    child: ListView(
                      children: [
                        _buildTransactionTile('Flamengo x Palmeiras', 'Hoje',
                            '+ R\$ 850,00', true),
                        _buildTransactionTile('Corinthians x São Paulo',
                            'Ontem', '- R\$ 85,00', false, 'Pendente'),
                        _buildTransactionTile('Grêmio x Inter', '30 Jan 2022',
                            '+ R\$ 1.406,00', true),
                        _buildTransactionTile('Santos x Bahia', '16 Jan 2022',
                            '- R\$ 119,00', false),
                        _buildTransactionTile('Atlético MG x Cruzeiro', 'Ontem',
                            '- R\$ 85,00', false, 'Perdeu'),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: primaryColor,
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Container(
          height: 60,
          decoration: const BoxDecoration(color: Colors.white),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const [
              Icon(Icons.home, color: Colors.grey),
              Icon(Icons.bar_chart, color: Colors.grey),
              SizedBox(width: 40), // espaço para o FAB
              Icon(Icons.attach_money, color: Colors.grey),
              Icon(Icons.person, color: Colors.grey),
            ],
          ),
        ),
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

// CLIPPER PARA A CURVA DO TOPO
class HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 60);
    path.quadraticBezierTo(
        size.width / 2, size.height, size.width, size.height - 60);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
