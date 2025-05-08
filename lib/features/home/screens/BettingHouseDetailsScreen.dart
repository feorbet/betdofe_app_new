import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:betdofe_app_new/constants.dart';
import 'package:betdofe_app_new/utils/utils.dart';
import 'package:intl/intl.dart';
import 'package:betdofe_app_new/features/home/screens/TransactionScreen.dart';
import 'package:betdofe_app_new/core/widgets/MainScaffold.dart';

class BettingHouseDetailsScreen extends StatefulWidget {
  final String bettingHouse;
  final DateTime selectedMonth;

  const BettingHouseDetailsScreen({
    super.key,
    required this.bettingHouse,
    required this.selectedMonth,
  });

  @override
  State<BettingHouseDetailsScreen> createState() =>
      _BettingHouseDetailsScreenState();
}

class _BettingHouseDetailsScreenState extends State<BettingHouseDetailsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> transactions = [];
  bool isLoading = true;
  String searchQuery = '';
  String detailFilterType = 'Todos';
  bool isValuesVisible = true;
  int currentMonthOffset = 0;
  late DateTime selectedMonth;

  final List<String> detailFilterOptions = [
    'Todos',
    'Ganhos',
    'Perdas',
  ];

  final NumberFormat currencyFormatter = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
  );

  final ValueNotifier<double> totalValue = ValueNotifier<double>(0.0);
  final ValueNotifier<double> totalGanhos = ValueNotifier<double>(0.0);
  final ValueNotifier<double> totalPerdas = ValueNotifier<double>(0.0);

  @override
  void initState() {
    super.initState();
    selectedMonth = widget.selectedMonth;
    print(
        'Inicializando BettingHouseDetailsScreen para casa de aposta: ${widget.bettingHouse}, mês: ${selectedMonth}');
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => isLoading = true);
    transactions.clear();

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

    try {
      // Buscar todas as transações positivas do mês
      print(
          'Buscando transações positivas entre $startOfMonth e $endOfMonth...');
      final positiveSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('positive_transactions')
          .where('timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where('timestamp',
              isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
          .get();

      print(
          'Encontradas ${positiveSnapshot.docs.length} transações positivas.');
      for (var doc in positiveSnapshot.docs) {
        final data = doc.data();
        print('Transação positiva encontrada: $data');
        transactions.add({
          'id': doc.id,
          'collection': 'positive_transactions',
          'data': data,
        });
      }

      // Buscar todas as transações negativas do mês
      print(
          'Buscando transações negativas entre $startOfMonth e $endOfMonth...');
      final negativeSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('negative_transactions')
          .where('timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where('timestamp',
              isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
          .get();

      print(
          'Encontradas ${negativeSnapshot.docs.length} transações negativas.');
      for (var doc in negativeSnapshot.docs) {
        final data = doc.data();
        print('Transação negativa encontrada: $data');
        transactions.add({
          'id': doc.id,
          'collection': 'negative_transactions',
          'data': data,
        });
      }

      // Buscar todas as transações por aposta do mês (se for POR APOSTAS)
      if (widget.bettingHouse == 'POR APOSTAS') {
        print(
            'Buscando transações por aposta entre $startOfMonth e $endOfMonth...');
        final perBetSnapshot = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('per_bet')
            .where('timestamp',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
            .where('timestamp',
                isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
            .get();

        print(
            'Encontradas ${perBetSnapshot.docs.length} transações por aposta.');
        for (var doc in perBetSnapshot.docs) {
          final data = doc.data();
          print('Transação por aposta encontrada: $data');
          transactions.add({
            'id': doc.id,
            'collection': 'per_bet',
            'data': data,
          });
        }
      } else {
        // Filtrar transações por casa de aposta (exceto POR APOSTAS)
        transactions = transactions.where((transaction) {
          final bettingHouse = transaction['data']['bettingHouse']?.toString();
          final isMatch = bettingHouse == widget.bettingHouse ||
              (widget.bettingHouse == 'SEM CASA' && bettingHouse == null);
          print(
              'Comparando bettingHouse: $bettingHouse com ${widget.bettingHouse}, resultado: $isMatch');
          return isMatch;
        }).toList();
      }

      if (transactions.isEmpty) {
        print(
            'Nenhuma transação encontrada para ${widget.bettingHouse} após filtragem.');
        if (mounted) {
          showAppMessage(context,
              'Nenhuma transação encontrada para ${widget.bettingHouse}.');
        }
      } else {
        print(
            'Total de transações carregadas após filtragem: ${transactions.length}');
      }

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }

      _calculateTotalValue(transactions);
    } catch (e) {
      print('Erro ao carregar transações para ${widget.bettingHouse}: $e');
      if (mounted) {
        showAppMessage(context, 'Erro ao carregar transações: $e',
            isError: true);
        setState(() => isLoading = false);
      }
    }
  }

  void _calculateTotalValue(List<Map<String, dynamic>> transactions) {
    double total = 0.0;
    double ganhos = 0.0;
    double perdas = 0.0;

    for (var transaction in transactions) {
      final collection = transaction['collection'];
      final data = transaction['data'];
      final value = collection == 'per_bet'
          ? (data['gainedValue'] as num?)?.toDouble() ?? 0.0
          : (data['value'] as num?)?.toDouble() ?? 0.0;
      final investedValue = collection == 'per_bet'
          ? (data['investedValue'] as num?)?.toDouble() ?? 0.0
          : (data['investedValue'] as num?)?.toDouble() ?? 0.0;
      final commission = collection == 'per_bet'
          ? (data['commission'] as num?)?.toDouble() ?? 0.0
          : (data['commission'] as num?)?.toDouble() ?? 0.0;

      final double netValue;
      if (collection == 'per_bet') {
        netValue = value - (investedValue + commission);
      } else if (collection == 'positive_transactions') {
        netValue = (value - commission) - investedValue;
      } else {
        netValue = -value - commission; // negative_transactions
      }

      total += netValue;

      if (netValue >= 0) {
        ganhos += netValue;
      } else {
        perdas += netValue.abs();
      }
    }

    totalValue.value = total;
    totalGanhos.value = ganhos;
    totalPerdas.value = perdas;
  }

  Future<void> _deleteTransaction(String collection, String docId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection(collection)
          .doc(docId)
          .delete();
      print('Transação $docId excluída com sucesso da coleção $collection');
      showAppMessage(context, 'Transação excluída com sucesso!');
      if (mounted) {
        _loadTransactions();
      }
    } catch (e) {
      print('Erro ao excluir transação: $e');
      showAppMessage(context, 'Erro ao excluir transação: $e', isError: true);
    }
  }

  List<FlSpot> _generateLineChartData(
      List<Map<String, dynamic>> transactions, bool isGain) {
    transactions.sort((a, b) {
      final timestampA = a['data']['timestamp'] as Timestamp?;
      final timestampB = b['data']['timestamp'] as Timestamp?;
      return (timestampA?.toDate() ?? DateTime.now())
          .compareTo(timestampB?.toDate() ?? DateTime.now());
    });

    List<FlSpot> spots = [];
    double cumulativeValue = 0.0;
    int dayIndex = 0;

    for (var transaction in transactions) {
      final data = transaction['data'];
      final collection = transaction['collection'];
      final timestamp = data['timestamp'] as Timestamp?;
      final transactionDate = timestamp?.toDate();
      if (transactionDate == null) continue;

      final value = collection == 'per_bet'
          ? (data['gainedValue'] as num?)?.toDouble() ?? 0.0
          : (data['value'] as num?)?.toDouble() ?? 0.0;
      final investedValue = collection == 'per_bet'
          ? (data['investedValue'] as num?)?.toDouble() ?? 0.0
          : (data['investedValue'] as num?)?.toDouble() ?? 0.0;
      final commission = collection == 'per_bet'
          ? (data['commission'] as num?)?.toDouble() ?? 0.0
          : (data['commission'] as num?)?.toDouble() ?? 0.0;
      final netValue = collection == 'per_bet'
          ? value - investedValue - commission
          : collection == 'positive_transactions'
              ? (value - commission) - investedValue
              : -value - commission;

      final isPositive = netValue >= 0;
      if ((isGain && isPositive) || (!isGain && !isPositive)) {
        cumulativeValue += netValue;
        dayIndex = transactionDate.day - 1;
        spots.add(FlSpot(dayIndex.toDouble(), cumulativeValue));
      }
    }

    return spots;
  }

  void _toggleValuesVisibility() {
    setState(() {
      isValuesVisible = !isValuesVisible;
    });
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

  Widget _getGainTitlesWidget(double value, TitleMeta meta) {
    return const Text(
      'Ganhos',
      style: TextStyle(
        color: Colors.white,
        fontSize: 12,
      ),
    );
  }

  Widget _getLossTitlesWidget(double value, TitleMeta meta) {
    return const Text(
      'Perdas',
      style: TextStyle(
        color: Colors.white,
        fontSize: 12,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredTransactions = transactions;

    if (searchQuery.isNotEmpty) {
      filteredTransactions = filteredTransactions.where((transaction) {
        final data = transaction['data'];
        final collection = transaction['collection'];
        final title = collection == 'per_bet'
            ? '${data['homeTeam']} vs ${data['awayTeam']}'
            : data['bettingHouse']?.toString() ?? 'Sem casa';
        return title.toLowerCase().contains(searchQuery.toLowerCase());
      }).toList();
    }

    if (detailFilterType == 'Ganhos') {
      filteredTransactions = filteredTransactions.where((transaction) {
        final data = transaction['data'];
        final collection = transaction['collection'];
        final value = collection == 'per_bet'
            ? (data['gainedValue'] as num?)?.toDouble() ?? 0.0
            : (data['value'] as num?)?.toDouble() ?? 0.0;
        final investedValue = collection == 'per_bet'
            ? (data['investedValue'] as num?)?.toDouble() ?? 0.0
            : (data['investedValue'] as num?)?.toDouble() ?? 0.0;
        final commission = collection == 'per_bet'
            ? (data['commission'] as num?)?.toDouble() ?? 0.0
            : (data['commission'] as num?)?.toDouble() ?? 0.0;
        final netValue = collection == 'per_bet'
            ? value - investedValue - commission
            : collection == 'positive_transactions'
                ? (value - commission) - investedValue
                : -value - commission;
        return netValue >= 0;
      }).toList();
    } else if (detailFilterType == 'Perdas') {
      filteredTransactions = filteredTransactions.where((transaction) {
        final data = transaction['data'];
        final collection = transaction['collection'];
        final value = collection == 'per_bet'
            ? (data['gainedValue'] as num?)?.toDouble() ?? 0.0
            : (data['value'] as num?)?.toDouble() ?? 0.0;
        final investedValue = collection == 'per_bet'
            ? (data['investedValue'] as num?)?.toDouble() ?? 0.0
            : (data['investedValue'] as num?)?.toDouble() ?? 0.0;
        final commission = collection == 'per_bet'
            ? (data['commission'] as num?)?.toDouble() ?? 0.0
            : (data['commission'] as num?)?.toDouble() ?? 0.0;
        final netValue = collection == 'per_bet'
            ? value - investedValue - commission
            : collection == 'positive_transactions'
                ? (value - commission) - investedValue
                : -value - commission;
        return netValue < 0;
      }).toList();
    }

    filteredTransactions.sort((a, b) {
      final timestampA = a['data']['timestamp'] as Timestamp?;
      final timestampB = b['data']['timestamp'] as Timestamp?;
      return (timestampB?.toDate() ?? DateTime.now()).compareTo(
        timestampA?.toDate() ?? DateTime.now(),
      );
    });

    _calculateTotalValue(filteredTransactions);

    // Calcular as porcentagens
    double totalAbs = totalGanhos.value + totalPerdas.value;
    double ganhosPercent =
        totalAbs > 0 ? (totalGanhos.value / totalAbs) * 100 : 0;
    double perdasPercent =
        totalAbs > 0 ? (totalPerdas.value / totalAbs) * 100 : 0;

    return MainScaffold(
      selectedIndex: 1, // Mesma posição do ChartScreen na barra de navegação
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppConstants.darkerLightGreen, AppConstants.darkerGreen],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: AppConstants.white),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.filter_list,
              color: AppConstants.white,
            ),
            onSelected: (value) {
              setState(() {
                detailFilterType = value;
              });
            },
            itemBuilder: (context) => detailFilterOptions.map((option) {
              IconData icon;
              switch (option) {
                case 'Todos':
                  icon = Icons.all_inclusive;
                  break;
                case 'Ganhos':
                  icon = Icons.trending_up;
                  break;
                case 'Perdas':
                  icon = Icons.trending_down;
                  break;
                default:
                  icon = Icons.filter_list;
              }
              return PopupMenuItem<String>(
                value: option,
                child: Row(
                  children: [
                    Icon(
                      icon,
                      color: AppConstants.white,
                      size: 20,
                    ),
                    const SizedBox(width: AppConstants.smallSpacing),
                    Text(
                      option,
                      style: const TextStyle(
                        color: AppConstants.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            color: AppConstants.primaryColor,
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                AppConstants.borderRadius,
              ),
            ),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              const SizedBox(
                  height:
                      260), // Ajustado para o tamanho do painel com o gráfico
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.defaultPadding,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Histórico de Transações',
                      style: AppConstants.bodyBoldStyle,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppConstants.smallSpacing),
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : filteredTransactions.isEmpty
                        ? const Center(
                            child: Text('Nenhuma transação encontrada.'),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadTransactions,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppConstants.defaultPadding * 1.5,
                                vertical: AppConstants.smallSpacing,
                              ),
                              itemCount: filteredTransactions.length,
                              itemBuilder: (context, index) {
                                final transaction = filteredTransactions[index];
                                final data =
                                    transaction['data'] as Map<String, dynamic>;
                                final collection =
                                    transaction['collection'] as String;
                                final docId = transaction['id'] as String;
                                final isPerBet = collection == 'per_bet';
                                final value = isPerBet
                                    ? (data['gainedValue'] as num?)
                                            ?.toDouble() ??
                                        0.0
                                    : (data['value'] as num?)?.toDouble() ??
                                        0.0;
                                final investedValue = isPerBet
                                    ? (data['investedValue'] as num?)
                                            ?.toDouble() ??
                                        0.0
                                    : (data['investedValue'] as num?)
                                            ?.toDouble() ??
                                        0.0;
                                final commission = isPerBet
                                    ? (data['commission'] as num?)
                                            ?.toDouble() ??
                                        0.0
                                    : (data['commission'] as num?)
                                            ?.toDouble() ??
                                        0.0;

                                // Calcular o valor líquido para determinar isPositive
                                final double valorLiquido;
                                if (collection == 'per_bet') {
                                  valorLiquido =
                                      value - (investedValue + commission);
                                } else if (collection ==
                                    'positive_transactions') {
                                  valorLiquido =
                                      (value - commission) - investedValue;
                                } else {
                                  valorLiquido = value - commission;
                                }

                                // Determinar isPositive com base no valor líquido
                                final isPositive = valorLiquido >= 0;

                                final date = data['date']?.toString() ?? '';
                                final account =
                                    data['account']?.toString() ?? 'Sem conta';
                                final bettingHouse =
                                    data['bettingHouse']?.toString() ??
                                        'Sem casa';
                                final title = isPerBet
                                    ? '${data['homeTeam']} vs ${data['awayTeam']}'
                                    : bettingHouse;

                                return _buildTransactionTile(
                                  title,
                                  date,
                                  isPositive,
                                  value: value,
                                  account: account,
                                  investedValue: investedValue,
                                  commission: commission,
                                  index: index,
                                  collection: collection,
                                  docId: docId,
                                  data: data,
                                );
                              },
                            ),
                          ),
              ),
            ],
          ),
          Stack(
            children: [
              ClipPath(
                clipper: HeaderClipper(),
                child: Container(
                  height: 160,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppConstants.darkerLightGreen,
                        AppConstants.darkerGreen
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              margin: const EdgeInsets.symmetric(
                horizontal: AppConstants.defaultPadding,
              ),
              padding: const EdgeInsets.symmetric(
                vertical: 4,
                horizontal: AppConstants.defaultPadding,
              ),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppConstants.lightGreen, AppConstants.primaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.bettingHouse,
                                      style: const TextStyle(
                                        color: AppConstants.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  children: [
                                    GestureDetector(
                                      onTap: _toggleValuesVisibility,
                                      child: Icon(
                                        isValuesVisible
                                            ? Icons.visibility
                                            : Icons.visibility_off,
                                        color: Colors.white70,
                                        size: 20,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: AppConstants.smallSpacing),
                            Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: AppConstants.primaryColor,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.arrow_back,
                                          color: AppConstants.white),
                                      onPressed: () {
                                        setState(() {
                                          currentMonthOffset--;
                                          selectedMonth = DateTime.now().add(
                                              Duration(
                                                  days:
                                                      30 * currentMonthOffset));
                                          _loadTransactions();
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
                                          selectedMonth = DateTime.now().add(
                                              Duration(
                                                  days:
                                                      30 * currentMonthOffset));
                                          _loadTransactions();
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: AppConstants.smallSpacing),
                            Center(
                              child: Text(
                                'Saldo Líquido',
                                style: const TextStyle(
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Center(
                              child: ValueListenableBuilder<double>(
                                valueListenable: totalValue,
                                builder: (context, value, child) {
                                  return Text(
                                    isValuesVisible
                                        ? currencyFormatter.format(value)
                                        : '****',
                                    style: TextStyle(
                                      color: value < 0
                                          ? AppConstants.red
                                          : AppConstants.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.smallSpacing),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        children: [
                          Text(
                            '${ganhosPercent.toStringAsFixed(1)}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          SizedBox(
                            width: 40,
                            height: 40,
                            child: BarChart(
                              BarChartData(
                                alignment: BarChartAlignment.center,
                                maxY: totalGanhos.value > 0
                                    ? totalGanhos.value * 1.2
                                    : 1,
                                barGroups: [
                                  BarChartGroupData(
                                    x: 0,
                                    barRods: [
                                      BarChartRodData(
                                        toY: totalGanhos.value,
                                        color: AppConstants.green,
                                        width: 16,
                                        borderRadius:
                                            const BorderRadius.all(Radius.zero),
                                      ),
                                    ],
                                  ),
                                ],
                                titlesData: FlTitlesData(
                                  leftTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  rightTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  topTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: _getGainTitlesWidget,
                                    ),
                                  ),
                                ),
                                borderData: FlBorderData(show: false),
                                gridData: const FlGridData(show: false),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Text(
                            '${perdasPercent.toStringAsFixed(1)}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          SizedBox(
                            width: 40,
                            height: 40,
                            child: BarChart(
                              BarChartData(
                                alignment: BarChartAlignment.center,
                                maxY: totalPerdas.value > 0
                                    ? totalPerdas.value * 1.2
                                    : 1,
                                barGroups: [
                                  BarChartGroupData(
                                    x: 0,
                                    barRods: [
                                      BarChartRodData(
                                        toY: totalPerdas.value,
                                        color: AppConstants.red,
                                        width: 16,
                                        borderRadius:
                                            const BorderRadius.all(Radius.zero),
                                      ),
                                    ],
                                  ),
                                ],
                                titlesData: FlTitlesData(
                                  leftTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  rightTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  topTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: _getLossTitlesWidget,
                                    ),
                                  ),
                                ),
                                borderData: FlBorderData(show: false),
                                gridData: const FlGridData(show: false),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionTile(
    String title,
    String date,
    bool isGain, {
    required double value,
    required String account,
    required double investedValue,
    required double commission,
    required int index,
    required String collection,
    required String docId,
    required Map<String, dynamic> data,
  }) {
    // Calcular o valor líquido
    final double valorLiquido;
    if (collection == 'per_bet') {
      valorLiquido = value - (investedValue + commission);
    } else if (collection == 'positive_transactions') {
      valorLiquido = (value - commission) - investedValue;
    } else {
      valorLiquido = value - commission;
    }

    // Determinar a cor do fundo e o ícone com base no valor líquido
    final backgroundColor =
        valorLiquido >= 0 ? AppConstants.green : AppConstants.red;
    final icon = valorLiquido >= 0 ? Icons.trending_up : Icons.trending_down;

    // Formatando o valor líquido para exibição
    final String amountLiquido = valorLiquido >= 0
        ? '+ ${currencyFormatter.format(valorLiquido)}'
        : '- ${currencyFormatter.format(valorLiquido.abs())}';

    return GestureDetector(
      onTap: () => _showTransactionDetails(data, collection, isGain),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppConstants.defaultPadding),
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black45,
              blurRadius: 10,
              offset: const Offset(0, 4),
              spreadRadius: 2,
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    backgroundColor: backgroundColor,
                    child: Icon(
                      icon,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: AppConstants.smallSpacing),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Data: $date',
                                style: const TextStyle(fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (collection != 'per_bet') ...[
                                Text(
                                  'Conta: $account',
                                  style: const TextStyle(fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 0,
              right: AppConstants.defaultPadding + 20,
              bottom: 0,
              child: Center(
                child: Text(
                  amountLiquido,
                  style: TextStyle(
                    color: backgroundColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                icon: const Icon(
                  Icons.more_vert,
                  color: Colors.black54,
                  size: 20,
                ),
                onSelected: (value) async {
                  if (value == 'edit') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TransactionScreen(
                          onTransactionAdded: () {
                            _loadTransactions();
                          },
                          initialData: data,
                          transactionId: docId,
                          isEditing: true,
                        ),
                      ),
                    );
                  } else if (value == 'delete') {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: AppConstants.primaryColor,
                        title: const Text(
                          'Confirmar Exclusão',
                          style: TextStyle(color: AppConstants.white),
                        ),
                        content: const Text(
                          'Deseja excluir esta transação?',
                          style: TextStyle(color: AppConstants.white),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text(
                              'Cancelar',
                              style: TextStyle(color: AppConstants.white),
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text(
                              'Excluir',
                              style: TextStyle(color: AppConstants.white),
                            ),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await _deleteTransaction(collection, docId);
                    }
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem<String>(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(
                          Icons.edit,
                          color: AppConstants.green,
                          size: 20,
                        ),
                        SizedBox(width: AppConstants.smallSpacing),
                        Text(
                          'Editar',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete,
                          color: AppConstants.red,
                          size: 20,
                        ),
                        SizedBox(width: AppConstants.smallSpacing),
                        Text(
                          'Excluir',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                color: Colors.white,
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    AppConstants.borderRadius,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTransactionDetails(
      Map<String, dynamic> data, String collection, bool isPositive) {
    // Calcular o valor líquido e manter o valor bruto
    final double value = collection == 'per_bet'
        ? (data['gainedValue'] as num?)?.toDouble() ?? 0.0
        : (data['value'] as num?)?.toDouble() ?? 0.0;
    final double investedValue =
        (data['investedValue'] as num?)?.toDouble() ?? 0.0;
    final double commission = (data['commission'] as num?)?.toDouble() ?? 0.0;
    final double valorLiquido;
    if (collection == 'per_bet') {
      valorLiquido = value - (investedValue + commission);
    } else if (collection == 'positive_transactions') {
      valorLiquido = (value - commission) - investedValue;
    } else {
      valorLiquido = value - commission;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppConstants.primaryColor,
        title: Text(
          collection == 'per_bet'
              ? 'Detalhes da Aposta'
              : 'Detalhes da Transação',
          style: const TextStyle(color: AppConstants.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (collection == 'per_bet') ...[
                Text(
                  'Time da Casa: ${data['homeTeam'] ?? 'Não informado'}',
                  style: const TextStyle(color: AppConstants.white),
                ),
                const SizedBox(height: AppConstants.smallSpacing),
                Text(
                  'Time Visitante: ${data['awayTeam'] ?? 'Não informado'}',
                  style: const TextStyle(color: AppConstants.white),
                ),
                const SizedBox(height: AppConstants.smallSpacing),
              ] else ...[
                Text(
                  'Casa de Aposta: ${data['bettingHouse'] ?? 'Sem casa'}',
                  style: const TextStyle(color: AppConstants.white),
                ),
                const SizedBox(height: AppConstants.smallSpacing),
                Text(
                  'Conta: ${data['account'] ?? 'Sem conta'}',
                  style: const TextStyle(color: AppConstants.white),
                ),
                const SizedBox(height: AppConstants.smallSpacing),
              ],
              Text(
                'Data: ${data['date'] ?? 'Não informado'}',
                style: const TextStyle(color: AppConstants.white),
              ),
              const SizedBox(height: AppConstants.smallSpacing),
              Text(
                collection == 'per_bet'
                    ? 'Valor Bruto Ganho/Perdido: ${currencyFormatter.format(value)}'
                    : 'Valor Bruto: ${currencyFormatter.format(value)}',
                style: TextStyle(
                  color: value >= 0 ? AppConstants.green : AppConstants.red,
                ),
              ),
              const SizedBox(height: AppConstants.smallSpacing),
              Text(
                collection == 'per_bet'
                    ? 'Valor Líquido Ganho/Perdido: ${currencyFormatter.format(valorLiquido)}'
                    : 'Valor Líquido: ${currencyFormatter.format(valorLiquido)}',
                style: TextStyle(
                  color:
                      valorLiquido >= 0 ? AppConstants.green : AppConstants.red,
                ),
              ),
              const SizedBox(height: AppConstants.smallSpacing),
              Text(
                'Valor Investido: ${currencyFormatter.format(data['investedValue']?.toDouble() ?? 0.0)}',
                style: const TextStyle(color: AppConstants.white),
              ),
              const SizedBox(height: AppConstants.smallSpacing),
              Text(
                'Comissão: ${currencyFormatter.format(data['commission']?.toDouble() ?? 0.0)}',
                style: const TextStyle(color: AppConstants.white),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Fechar',
              style: TextStyle(color: AppConstants.white),
            ),
          ),
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
    path.quadraticBezierTo(
      size.width / 2,
      size.height + 40,
      size.width,
      size.height - 40,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
