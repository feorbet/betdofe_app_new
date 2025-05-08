import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:betdofe_app_new/core/widgets/MainScaffold.dart';
import 'package:betdofe_app_new/constants.dart';
import 'package:betdofe_app_new/utils/utils.dart';
import 'package:intl/intl.dart';
import 'package:betdofe_app_new/features/home/screens/BettingHouseDetailsScreen.dart';

class ChartScreen extends StatefulWidget {
  const ChartScreen({super.key});

  @override
  State<ChartScreen> createState() => _ChartScreenState();
}

class _ChartScreenState extends State<ChartScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, double> bettingHouseData = {};
  Map<String, Color> bettingHouseColors = {};
  bool isLoading = true;
  String filterType = 'Todos';
  int touchedIndex = -1;
  double startDegreeOffset = 90.0;
  int currentMonthOffset = 0;
  DateTime selectedMonth = DateTime.now();

  final List<String> filterOptions = [
    'Todos',
    'Positivas',
    'Negativas',
    'Por Aposta'
  ];

  final NumberFormat currencyFormatter = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
  );

  @override
  void initState() {
    super.initState();
    _loadBettingHouseData();
  }

  Future<void> _loadBettingHouseData() async {
    setState(() => isLoading = true);
    final user = _auth.currentUser;
    if (user == null) {
      if (mounted) {
        print('Usuário não autenticado.');
        showAppMessage(context, 'Usuário não autenticado!', isError: true);
        setState(() => isLoading = false);
      }
      return;
    }

    print('Usuário autenticado: ${user.uid}');

    final startOfMonth = DateTime(selectedMonth.year, selectedMonth.month, 1);
    final endOfMonth = DateTime(selectedMonth.year, selectedMonth.month + 1, 0);

    Map<String, double> tempData = {};
    Map<String, Color> tempColors = {};

    try {
      print('Buscando casas de aposta para o usuário ${user.uid}...');
      final bettingHousesSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('betting_houses')
          .get();

      for (var doc in bettingHousesSnapshot.docs) {
        final data = doc.data();
        final name = data['bettingHouseName']?.toString();
        final colorValue = data['color'];
        if (name != null && colorValue != null) {
          try {
            if (colorValue is String) {
              tempColors[name] =
                  Color(int.parse(colorValue.replaceFirst('#', '0xFF')));
            } else if (colorValue is int) {
              tempColors[name] = Color(colorValue);
            }
          } catch (e) {
            print('Erro ao parsear cor para $name: $e');
            tempColors[name] = AppConstants.primaryColor;
          }
        }
      }

      tempColors['SEM CASA'] = AppConstants.textGrey;
      tempColors['POR APOSTAS'] = AppConstants.orange;

      print(
          'Buscando transações positivas entre $startOfMonth e $endOfMonth...');
      if (filterType == 'Todos' || filterType == 'Positivas') {
        final snapshot = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('positive_transactions')
            .where('timestamp',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
            .where('timestamp',
                isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
            .get();
        for (var doc in snapshot.docs) {
          final data = doc.data();
          final house = data['bettingHouse']?.toString() ?? 'SEM CASA';
          final value = (data['value'] as num?)?.toDouble() ?? 0.0;
          final investedValue =
              (data['investedValue'] as num?)?.toDouble() ?? 0.0;
          final commission = (data['commission'] as num?)?.toDouble() ?? 0.0;
          final netValue = value - investedValue - commission;
          tempData[house] = (tempData[house] ?? 0.0) + netValue;
        }
      }

      print(
          'Buscando transações negativas entre $startOfMonth e $endOfMonth...');
      if (filterType == 'Todos' || filterType == 'Negativas') {
        final snapshot = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('negative_transactions')
            .where('timestamp',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
            .where('timestamp',
                isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
            .get();
        for (var doc in snapshot.docs) {
          final data = doc.data();
          final house = data['bettingHouse']?.toString() ?? 'SEM CASA';
          final value = (data['value'] as num?)?.toDouble().abs() ?? 0.0;
          final commission = (data['commission'] as num?)?.toDouble() ?? 0.0;
          final netValue = -value - commission;
          tempData[house] = (tempData[house] ?? 0.0) + netValue;
        }
      }

      print(
          'Buscando transações por aposta entre $startOfMonth e $endOfMonth...');
      if (filterType == 'Todos' || filterType == 'Por Aposta') {
        final snapshot = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('per_bet')
            .where('timestamp',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
            .where('timestamp',
                isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
            .get();
        for (var doc in snapshot.docs) {
          final data = doc.data();
          const house = 'POR APOSTAS';
          final gainedValue = (data['gainedValue'] as num?)?.toDouble() ?? 0.0;
          final investedValue =
              (data['investedValue'] as num?)?.toDouble() ?? 0.0;
          final commission = (data['commission'] as num?)?.toDouble() ?? 0.0;
          final netValue = gainedValue - investedValue - commission;
          tempData[house] = (tempData[house] ?? 0.0) + netValue;
        }
      }

      if (tempData.isEmpty) {
        tempData['Nenhuma Transação'] = 1.0;
        tempColors['Nenhuma Transação'] = AppConstants.textGrey;
        if (mounted) {
          showAppMessage(
              context, 'Nenhuma transação encontrada para o período.');
        }
      }

      if (mounted) {
        setState(() {
          bettingHouseData = tempData;
          bettingHouseColors = tempColors;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Erro ao carregar dados: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
          bettingHouseData = {'Nenhuma Transação': 1.0};
          bettingHouseColors = {'Nenhuma Transação': AppConstants.textGrey};
          showAppMessage(context, 'Erro ao carregar dados: $e', isError: true);
        });
      }
    }
  }

  String _getMonthName(DateTime date) {
    const months = [
      'Janeiro',
      'Fevereiro',
      'Março',
      'Abril',
      'Maio',
      'Junho',
      'Julho',
      'Agosto',
      'Setembro',
      'Outubro',
      'Novembro',
      'Dezembro'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final sortedData = bettingHouseData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final totalValue =
        bettingHouseData.values.fold<double>(0.0, (sum, value) => sum + value);

    return MainScaffold(
      selectedIndex: 1,
      appBar: AppBar(
        backgroundColor: AppConstants.primaryColor,
        title: const Text('Resultados'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                filterType = value;
                _loadBettingHouseData();
              });
            },
            icon: const Icon(Icons.filter_list, color: AppConstants.white),
            itemBuilder: (context) => filterOptions.map((option) {
              return PopupMenuItem(
                value: option,
                child: Text(
                  option,
                  style: const TextStyle(color: AppConstants.textBlack),
                ),
              );
            }).toList(),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Parte fixa: Seletor de mês e gráfico
                Container(
                  padding: const EdgeInsets.all(AppConstants.defaultPadding),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppConstants.primaryColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back,
                                    color: AppConstants.white),
                                onPressed: () {
                                  setState(() {
                                    currentMonthOffset--;
                                    selectedMonth = DateTime.now().add(Duration(
                                        days: 30 * currentMonthOffset));
                                    _loadBettingHouseData();
                                  });
                                },
                              ),
                              Text(
                                _getMonthName(selectedMonth),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppConstants.white,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.arrow_forward,
                                    color: AppConstants.white),
                                onPressed: () {
                                  setState(() {
                                    currentMonthOffset++;
                                    selectedMonth = DateTime.now().add(Duration(
                                        days: 30 * currentMonthOffset));
                                    _loadBettingHouseData();
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 300,
                        child: PieChart(
                          PieChartData(
                            startDegreeOffset: startDegreeOffset,
                            sections: sortedData.asMap().entries.map((entry) {
                              final index = entry.key;
                              final data = entry.value;
                              final color = bettingHouseColors[data.key] ??
                                  AppConstants.textGrey;
                              final isTouched = touchedIndex == index;
                              final total = bettingHouseData.values
                                  .map((e) => e.abs())
                                  .fold(0.0, (a, b) => a + b);
                              final percent = (data.value.abs() / total) * 100;

                              return PieChartSectionData(
                                color: color,
                                value: data.value.abs(),
                                title: percent < 5
                                    ? ''
                                    : '${data.key}\n${percent.toStringAsFixed(1)}%',
                                titleStyle: const TextStyle(
                                  color: AppConstants.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                                radius: isTouched ? 95 : 80,
                                titlePositionPercentageOffset:
                                    0.55, // Centraliza o texto
                              );
                            }).toList(),
                            pieTouchData: PieTouchData(
                              touchCallback: (event, response) {
                                setState(() {
                                  if (response?.touchedSection != null) {
                                    touchedIndex = response!
                                        .touchedSection!.touchedSectionIndex;
                                  } else {
                                    touchedIndex = -1;
                                  }
                                });
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Divider(),
                    ],
                  ),
                ),
                // Parte rolável: Legenda
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.defaultPadding),
                    children: [
                      ...sortedData.map((data) {
                        final color = bettingHouseColors[data.key] ??
                            AppConstants.textGrey;
                        return GestureDetector(
                          onTap: data.key == 'Nenhuma Transação'
                              ? null
                              : () {
                                  print(
                                      'Navegando para BettingHouseDetailsScreen com casa de aposta: ${data.key}, mês: $selectedMonth');
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          BettingHouseDetailsScreen(
                                        bettingHouse: data.key,
                                        selectedMonth: selectedMonth,
                                      ),
                                    ),
                                  );
                                },
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                                backgroundColor: color, radius: 10),
                            title: Text(
                              data.key,
                              style: const TextStyle(fontSize: 10),
                            ),
                            trailing: Text(
                              currencyFormatter.format(data.value),
                              style: TextStyle(
                                color: data.value < 0
                                    ? AppConstants.red
                                    : AppConstants.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                            dense: true,
                          ),
                        );
                      }),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const CircleAvatar(
                            backgroundColor: Colors.black, radius: 10),
                        title: const Text(
                          'Total',
                          style: TextStyle(fontSize: 10),
                        ),
                        trailing: Text(
                          currencyFormatter.format(totalValue),
                          style: const TextStyle(
                            color: AppConstants.primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                        dense: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
