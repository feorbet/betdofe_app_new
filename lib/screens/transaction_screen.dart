// home_screen.dart com TransactionScreen integrada
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

  void _showOverlay(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TransactionScreen(),
      ),
    );
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
      body: FutureBuilder<double>(
        future: _calculateMonthlyBalance(),
        builder: (context, snapshot) {
          double balance = snapshot.data ?? 0.0;
          return Stack(
            children: [
              Column(
                children: [
                  const SizedBox(height: 360),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('Histórico de Transações', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('Ver tudo', style: TextStyle(color: Colors.grey, fontSize: 14)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 5),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: _firestore.collection('transactions').orderBy('timestamp', descending: true).snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const CircularProgressIndicator();
                        final transactions = snapshot.data!.docs;
                        return ListView.builder(
                          itemCount: transactions.length,
                          itemBuilder: (context, index) {
                            final data = transactions[index].data() as Map<String, dynamic>;
                            final title = data['bettingHouse'] ?? 'Transação';
                            final date = (data['date'] ?? '').toString();
                            final value = data['value'] ?? 0.0;
                            final status = data['status'] ?? '';
                            return _buildTransactionTile(
                              title,
                              date,
                              value >= 0 ? '+ R\$ ${value.toStringAsFixed(2)}' : '- R\$ ${value.abs().toStringAsFixed(2)}',
                              value >= 0,
                              status,
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
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
                            Text(_getGreeting(), style: const TextStyle(color: Colors.white70, fontSize: 16)),
                            Text(userName, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Positioned(
                top: 140,
                left: 0,
                right: 0,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Saldo Total', style: TextStyle(color: Colors.white70)),
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
                        isValuesVisible ? 'R\$ ${balance.toStringAsFixed(2)}' : '****',
                        style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            children: [
                              const Icon(Icons.arrow_upward, color: Colors.white),
                              const SizedBox(height: 4),
                              const Text('Ganhos', style: TextStyle(color: Colors.white70)),
                              Text(
                                isValuesVisible ? 'R\$ ${balance >= 0 ? balance.toStringAsFixed(2) : '0.00'}' : '****',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              const Icon(Icons.arrow_downward, color: Colors.white),
                              const SizedBox(height: 4),
                              const Text('Perdas', style: TextStyle(color: Colors.white70)),
                              Text(
                                isValuesVisible ? 'R\$ ${balance < 0 ? balance.abs().toStringAsFixed(2) : '0.00'}' : '****',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
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
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showOverlay(context),
        backgroundColor: primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
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
          BottomNavigationBarItem(icon: Icon(Icons.add, color: Colors.transparent), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.attach_money), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: ''),
        ],
      ),
    );
  }

  Future<double> _calculateMonthlyBalance() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    final snapshot = await _firestore
        .collection('transactions')
        .where('timestamp', isGreaterThanOrEqualTo: startOfMonth)
        .where('timestamp', isLessThanOrEqualTo: endOfMonth)
        .get();

    double balance = 0.0;
    for (var doc in snapshot.docs) {
      final value = doc['value'] as double? ?? 0.0;
      balance += value;
    }
    return balance;
  }

  Widget _buildTransactionTile(
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
          ),
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
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(date, style: const TextStyle(fontSize: 12)),
                    if (status != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(status, style: const TextStyle(fontSize: 10, color: Colors.black87)),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Text(amount, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }
}

class HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 40);
    path.quadraticBezierTo(size.width / 2, size.height + 40, size.width, size.height - 40);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

// A classe TransactionScreen foi movida para o arquivo separado (ou pode ser integrada aqui se desejar)
