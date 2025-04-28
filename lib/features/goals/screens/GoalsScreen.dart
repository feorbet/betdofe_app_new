import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:betdofe_app_new/core/widgets/MainScaffold.dart';
import 'package:betdofe_app_new/constants.dart';
import 'dart:math';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Map<String, dynamic>? currentGoal;
  double progressPercentage = 0.0;
  double dailyTarget = 0.0;
  double dailyProgressPercentage = 0.0;
  double dailyLossPercentage = 0.0;
  double totalAchieved = 0.0;
  double totalLoss = 0.0;
  double dailyLoss = 0.0;
  bool stopLossTriggered = false;
  String selectedMonth = 'Abril';
  final List<String> months = [
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
    'Dezembro',
  ];

  Map<DateTime, double> dailyNetEarnings = {};
  Map<DateTime, double> dailyLosses = {};
  double monthlyNetEarnings = 0.0;
  double monthlyLosses = 0.0;
  double todayNetEarnings = 0.0;

  @override
  void initState() {
    super.initState();
    _loadCurrentGoal();
    _loadTransactions();
  }

  Future<void> _loadCurrentGoal() async {
    final user = _auth.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuário não autenticado!')),
        );
      }
      return;
    }

    try {
      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('goals')
          .doc('history')
          .collection(selectedMonth)
          .doc('current_goal')
          .get();

      if (doc.exists && mounted) {
        setState(() {
          currentGoal = doc.data();
          if (currentGoal!['type'] == 'Diária') {
            _updateDailyTarget();
          }
        });
      } else {
        if (mounted) {
          setState(() {
            currentGoal = null;
            progressPercentage = 0.0;
            dailyTarget = 0.0;
            dailyProgressPercentage = 0.0;
            dailyLossPercentage = 0.0;
            totalAchieved = 0.0;
            totalLoss = 0.0;
            dailyLoss = 0.0;
            stopLossTriggered = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar meta: $e')),
        );
      }
    }
  }

  int _calculateTotalOperatingDays() {
    if (currentGoal == null || currentGoal!['operatingDays'] == null) return 0;

    List<String> operatingDays =
        List<String>.from(currentGoal!['operatingDays']);
    DateTime today = DateTime.now();
    DateTime startOfMonth = DateTime(today.year, today.month, 1);
    DateTime endOfMonth = DateTime(today.year, today.month + 1, 1);

    int totalDays = 0;
    for (String day in operatingDays) {
      DateTime operatingDay = DateTime.parse(day);
      if (operatingDay.isAfter(startOfMonth) &&
          operatingDay.isBefore(endOfMonth)) {
        totalDays++;
      }
    }
    return totalDays;
  }

  void _updateDailyTarget() {
    if (currentGoal == null) return;

    int totalOperatingDays = _calculateTotalOperatingDays();
    if (totalOperatingDays == 0) {
      dailyTarget = 0.0;
      return;
    }

    dailyTarget = currentGoal!['targetValue'] / totalOperatingDays;

    DateTime today = DateTime.now();
    DateTime todayKey = DateTime(today.year, today.month, today.day);
    double todayNetEarnings = dailyNetEarnings[todayKey] ?? 0.0;

    dailyProgressPercentage =
        dailyTarget > 0 ? (todayNetEarnings / dailyTarget) * 100 : 0.0;
  }

  Future<void> _loadTransactions() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      int monthIndex = months.indexOf(selectedMonth) + 1;
      DateTime startOfMonth = DateTime(2025, monthIndex, 1);
      DateTime endOfMonth = DateTime(2025, monthIndex + 1, 1);

      final positiveSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('positive_transactions')
          .where('timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where('timestamp', isLessThan: Timestamp.fromDate(endOfMonth))
          .get();

      Map<DateTime, double> tempEarnings = {};
      double totalEarnings = 0.0;
      for (var doc in positiveSnapshot.docs) {
        Timestamp timestamp = doc['timestamp'] as Timestamp;
        DateTime date = timestamp.toDate();
        DateTime dateKey = DateTime(date.year, date.month, date.day);
        double amount = doc.data().containsKey('amount')
            ? (doc['amount'] as num).toDouble()
            : doc.data().containsKey('value')
                ? (doc['value'] as num).toDouble()
                : 0.0;
        tempEarnings[dateKey] = (tempEarnings[dateKey] ?? 0.0) + amount;
        totalEarnings += amount;
      }

      final negativeSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('negative_transactions')
          .where('timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where('timestamp', isLessThan: Timestamp.fromDate(endOfMonth))
          .get();

      Map<DateTime, double> tempLosses = {};
      double totalLosses = 0.0;
      for (var doc in negativeSnapshot.docs) {
        Timestamp timestamp = doc['timestamp'] as Timestamp;
        DateTime date = timestamp.toDate();
        DateTime dateKey = DateTime(date.year, date.month, date.day);
        double amount = doc.data().containsKey('amount')
            ? (doc['amount'] as num).toDouble()
            : doc.data().containsKey('value')
                ? (doc['value'] as num).toDouble()
                : 0.0;
        tempLosses[dateKey] = (tempLosses[dateKey] ?? 0.0) + amount;
        totalLosses += amount;
      }

      final perBetSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('per_bet')
          .where('timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where('timestamp', isLessThan: Timestamp.fromDate(endOfMonth))
          .get();

      for (var doc in perBetSnapshot.docs) {
        Timestamp timestamp = doc['timestamp'] as Timestamp;
        DateTime date = timestamp.toDate();
        DateTime dateKey = DateTime(date.year, date.month, date.day);
        double gainedValue = (doc['gainedValue'] as num?)?.toDouble() ?? 0.0;
        if (gainedValue >= 0) {
          tempEarnings[dateKey] = (tempEarnings[dateKey] ?? 0.0) + gainedValue;
          totalEarnings += gainedValue;
        } else {
          tempLosses[dateKey] =
              (tempLosses[dateKey] ?? 0.0) + gainedValue.abs();
          totalLosses += gainedValue.abs();
        }
      }

      Map<DateTime, double> tempNetEarnings = {};
      for (var dateKey in tempEarnings.keys) {
        double earnings = tempEarnings[dateKey] ?? 0.0;
        double losses = tempLosses[dateKey] ?? 0.0;
        tempNetEarnings[dateKey] = earnings - losses;
      }
      for (var dateKey in tempLosses.keys) {
        if (!tempNetEarnings.containsKey(dateKey)) {
          double losses = tempLosses[dateKey] ?? 0.0;
          tempNetEarnings[dateKey] = -losses;
        }
      }

      double totalNetEarnings =
          tempNetEarnings.values.fold(0.0, (a, b) => a + b);

      DateTime today = DateTime.now();
      DateTime todayKey = DateTime(today.year, today.month, today.day);

      if (mounted) {
        setState(() {
          dailyNetEarnings = tempNetEarnings;
          dailyLosses = tempLosses;
          monthlyNetEarnings = totalNetEarnings;
          monthlyLosses = totalLosses;
          totalAchieved = totalNetEarnings;
          totalLoss = totalLosses;
          progressPercentage =
              currentGoal != null && currentGoal!['targetValue'] > 0
                  ? (totalAchieved / currentGoal!['targetValue']) * 100
                  : 0.0;
          todayNetEarnings = dailyNetEarnings[todayKey] ?? 0.0;
          dailyLoss = dailyLosses[todayKey] ?? 0.0;
          dailyProgressPercentage =
              dailyTarget > 0 ? (todayNetEarnings / dailyTarget) * 100 : 0.0;
          dailyLossPercentage =
              currentGoal != null && currentGoal!['stopLoss'] > 0
                  ? (dailyLoss.abs() / currentGoal!['stopLoss']) * 100
                  : 0.0;
          if (currentGoal != null &&
              currentGoal!['stopLoss'] != null &&
              dailyLoss.abs() >= currentGoal!['stopLoss']) {
            stopLossTriggered = true;
          }
        });
        if (currentGoal != null && currentGoal!['type'] == 'Diária') {
          _updateDailyTarget();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar transações: $e')),
        );
      }
    }
  }

  void _navigateMonth(bool next) {
    setState(() {
      int currentIndex = months.indexOf(selectedMonth);
      if (next) {
        currentIndex = (currentIndex + 1) % months.length;
      } else {
        currentIndex = (currentIndex - 1 + months.length) % months.length;
      }
      selectedMonth = months[currentIndex];
      _loadCurrentGoal();
      _loadTransactions();
    });
  }

  void _showDefineGoalDialog() {
    final TextEditingController targetValueController = TextEditingController();
    final TextEditingController stopLossController = TextEditingController();
    String? selectedType = 'Diária';
    List<DateTime> selectedDays = [];
    DateTime focusedDay = DateTime.now();
    DateTime? selectedDay;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: const Text(
                'Definir Nova Meta',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.textBlack,
                ),
              ),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.9,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: _buildLabeledInput(
                          'Valor do Objetivo (R\$)',
                          targetValueController,
                          Icons.attach_money,
                          isNumber: true,
                        ),
                      ),
                      const SizedBox(height: AppConstants.smallSpacing),
                      SizedBox(
                        width: double.infinity,
                        child: _buildLabeledInput(
                          'Stop Loss (R\$)',
                          stopLossController,
                          Icons.warning,
                          isNumber: true,
                        ),
                      ),
                      const SizedBox(height: AppConstants.smallSpacing),
                      SizedBox(
                        width: double.infinity,
                        child: _buildDropdownField(
                          'Tipo da Meta',
                          ['Diária', 'Semanal', 'Mensal'],
                          selectedType,
                          (value) {
                            setDialogState(() {
                              selectedType = value;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: AppConstants.mediumSpacing),
                      const Text(
                        'Selecione os Dias de Operação',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppConstants.textBlack,
                        ),
                      ),
                      const SizedBox(height: AppConstants.smallSpacing),
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.8,
                        child: TableCalendar(
                          firstDay: DateTime.now(),
                          lastDay:
                              DateTime.now().add(const Duration(days: 365)),
                          focusedDay: focusedDay,
                          selectedDayPredicate: (day) {
                            return selectedDays.any((selectedDay) =>
                                day.year == selectedDay.year &&
                                day.month == selectedDay.month &&
                                day.day == selectedDay.day);
                          },
                          onDaySelected: (newSelectedDay, newFocusedDay) {
                            setDialogState(() {
                              if (selectedDays.any((day) =>
                                  day.year == newSelectedDay.year &&
                                  day.month == newSelectedDay.month &&
                                  day.day == newSelectedDay.day)) {
                                selectedDays.removeWhere((day) =>
                                    day.year == newSelectedDay.year &&
                                    day.month == newSelectedDay.month &&
                                    day.day == newSelectedDay.day);
                              } else {
                                selectedDays.add(newSelectedDay);
                              }
                              focusedDay = newFocusedDay;
                              selectedDay = newSelectedDay;
                            });
                          },
                          calendarStyle: const CalendarStyle(
                            todayDecoration: BoxDecoration(
                              color: AppConstants.primaryColor,
                              shape: BoxShape.circle,
                            ),
                            selectedDecoration: BoxDecoration(
                              color: AppConstants.lightGreenShade1,
                              shape: BoxShape.circle,
                            ),
                          ),
                          headerStyle: const HeaderStyle(
                            formatButtonVisible: false,
                            titleCentered: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(color: AppConstants.textBlack),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final user = _auth.currentUser;
                    if (user == null) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Usuário não autenticado!')),
                        );
                      }
                      return;
                    }

                    final targetValue =
                        double.tryParse(targetValueController.text.trim());
                    final stopLossValue =
                        double.tryParse(stopLossController.text.trim());

                    if (targetValue == null || selectedType == null) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Insira um valor válido e selecione o tipo da meta!')),
                        );
                      }
                      return;
                    }

                    if (stopLossValue == null) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Insira um valor válido para o Stop Loss!')),
                        );
                      }
                      return;
                    }

                    if (selectedDays.isEmpty) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Selecione pelo menos um dia de operação!')),
                        );
                      }
                      return;
                    }

                    try {
                      await _firestore
                          .collection('users')
                          .doc(user.uid)
                          .collection('goals')
                          .doc('history')
                          .collection(selectedMonth)
                          .doc('current_goal')
                          .set({
                        'targetValue': targetValue,
                        'stopLoss': stopLossValue,
                        'type': selectedType,
                        'operatingDays': selectedDays
                            .map((day) => day.toIso8601String())
                            .toList(),
                        'timestamp': FieldValue.serverTimestamp(),
                      });
                      Navigator.pop(context);
                      if (mounted) {
                        _loadCurrentGoal();
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Erro ao salvar meta: $e')),
                        );
                      }
                    }
                  },
                  child: const Text('Confirmar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    DateTime today = DateTime.now();
    DateTime todayKey = DateTime(today.year, today.month, today.day);
    double todayNetEarnings = dailyNetEarnings[todayKey] ?? 0.0;

    return MainScaffold(
      selectedIndex: 3,
      appBar: AppBar(
        title: const Text(
          'Metas',
          style: TextStyle(
            color: AppConstants.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppConstants.primaryColor,
        iconTheme: const IconThemeData(
          color: AppConstants.white,
        ),
      ),
      body: Container(
        color: AppConstants.lightGreenShade1.withOpacity(0.2),
        child: Column(
          children: [
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              color: AppConstants.primaryColor,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_left,
                      color: AppConstants.white,
                      size: 30,
                    ),
                    onPressed: () => _navigateMonth(false),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      selectedMonth,
                      style: const TextStyle(
                        color: AppConstants.textBlack,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_right,
                      color: AppConstants.white,
                      size: 30,
                    ),
                    onPressed: () => _navigateMonth(true),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Center(
                  child: stopLossTriggered
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Limite de Perda Ultrapassado!',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                            const SizedBox(height: AppConstants.smallSpacing),
                            Text(
                              'Perda atual: R\$ ${dailyLoss.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 16,
                                color: AppConstants.textBlack,
                              ),
                            ),
                            Text(
                              'Stop Loss: R\$ ${currentGoal!['stopLoss'].toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 16,
                                color: AppConstants.textBlack,
                              ),
                            ),
                            const SizedBox(height: AppConstants.mediumSpacing),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppConstants.primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 10),
                              ),
                              onPressed: _showDefineGoalDialog,
                              child: const Text(
                                'Redefinir Meta',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        )
                      : currentGoal == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'Nenhuma meta definida',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: AppConstants.textBlack,
                                  ),
                                ),
                                const SizedBox(
                                    height: AppConstants.smallSpacing),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppConstants.primaryColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 10),
                                  ),
                                  onPressed: _showDefineGoalDialog,
                                  child: const Text(
                                    'Definir meta',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width:
                                      MediaQuery.of(context).size.width * 0.9,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 20),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(15),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 15, vertical: 5),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text(
                                              'Meta Total',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: AppConstants.textBlack,
                                              ),
                                            ),
                                            Text(
                                              '${progressPercentage.toStringAsFixed(1)}%',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: AppConstants.textBlack,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 15),
                                        child: Container(
                                          height: 30,
                                          decoration: BoxDecoration(
                                            color: Colors.grey[200],
                                            borderRadius:
                                                BorderRadius.circular(15),
                                          ),
                                          child: Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              FractionallySizedBox(
                                                alignment: Alignment.centerLeft,
                                                widthFactor: min(
                                                    1,
                                                    max(
                                                        0,
                                                        progressPercentage /
                                                            100)),
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    color: AppConstants
                                                        .primaryColor,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            15),
                                                  ),
                                                ),
                                              ),
                                              if (progressPercentage > 20)
                                                Positioned(
                                                  left: 10,
                                                  child: Text(
                                                    'R\$ ${totalAchieved.toStringAsFixed(2)}',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 15, vertical: 5),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text(
                                              'Meta Diária',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: AppConstants.textBlack,
                                              ),
                                            ),
                                            Text(
                                              '${dailyProgressPercentage.toStringAsFixed(1)}%',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: AppConstants.textBlack,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 15),
                                        child: Container(
                                          height: 30,
                                          decoration: BoxDecoration(
                                            color: Colors.grey[200],
                                            borderRadius:
                                                BorderRadius.circular(15),
                                          ),
                                          child: Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              FractionallySizedBox(
                                                alignment: Alignment.centerLeft,
                                                widthFactor: min(
                                                    1,
                                                    max(
                                                        0,
                                                        dailyProgressPercentage /
                                                            100)),
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    color: Colors.blueAccent,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            15),
                                                  ),
                                                ),
                                              ),
                                              if (dailyProgressPercentage > 20)
                                                Positioned(
                                                  left: 10,
                                                  child: Text(
                                                    'R\$ ${todayNetEarnings.toStringAsFixed(2)}',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              if (dailyProgressPercentage <
                                                      20 &&
                                                  dailyProgressPercentage > 0)
                                                Positioned(
                                                  left: 10,
                                                  child: Text(
                                                    'R\$ ${todayNetEarnings.toStringAsFixed(2)}',
                                                    style: const TextStyle(
                                                      color: Colors.black,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              if (dailyProgressPercentage <= 0)
                                                Positioned(
                                                  right: 10,
                                                  child: Text(
                                                    'R\$ ${dailyTarget.toStringAsFixed(2)}',
                                                    style: const TextStyle(
                                                      color: Colors.black,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 15, vertical: 5),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text(
                                              'Stop Loss',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: AppConstants.textBlack,
                                              ),
                                            ),
                                            Text(
                                              '${dailyLossPercentage.toStringAsFixed(1)}%',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: AppConstants.textBlack,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 15),
                                        child: Container(
                                          height: 30,
                                          decoration: BoxDecoration(
                                            color: Colors.grey[200],
                                            borderRadius:
                                                BorderRadius.circular(15),
                                          ),
                                          child: Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              FractionallySizedBox(
                                                alignment: Alignment.centerLeft,
                                                widthFactor: min(
                                                    1,
                                                    max(
                                                        0,
                                                        dailyLossPercentage /
                                                            100)),
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    color: Colors.red,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            15),
                                                  ),
                                                ),
                                              ),
                                              if (dailyLossPercentage > 20)
                                                Positioned(
                                                  left: 10,
                                                  child: Text(
                                                    'R\$ ${dailyLoss.abs().toStringAsFixed(2)}',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(
                                    height: AppConstants.mediumSpacing),
                                Container(
                                  width:
                                      MediaQuery.of(context).size.width * 0.9,
                                  padding: const EdgeInsets.all(15),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Resumo',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppConstants.textBlack,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        'Meta Total: R\$ ${currentGoal!['targetValue'].toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: AppConstants.textBlack,
                                        ),
                                      ),
                                      Text(
                                        'Meta Diária: R\$ ${todayNetEarnings.toStringAsFixed(2)} / ${dailyTarget.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: AppConstants.textBlack,
                                        ),
                                      ),
                                      Text(
                                        'Stop Loss: R\$ ${dailyLoss.toStringAsFixed(2)} / ${currentGoal!['stopLoss'].toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'Meta Atual: R\$ ${totalAchieved.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: AppConstants.textBlack,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(
                                    height: AppConstants.mediumSpacing),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppConstants.primaryColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 10),
                                  ),
                                  onPressed: _showDefineGoalDialog,
                                  child: const Text(
                                    'Redefinir Meta',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ),
                              ],
                            ),
                ),
              ),
            ),
          ],
        ),
      ),
      onFabPressed: _showDefineGoalDialog,
    );
  }

  Widget _buildLabeledInput(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool isNumber = false,
  }) {
    return SizedBox(
      height: 50,
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        inputFormatters: isNumber
            ? [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ]
            : null,
        style: const TextStyle(
          fontSize: 14,
          color: AppConstants.textBlack,
          fontWeight: FontWeight.bold,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: AppConstants.textGrey200,
          hintText: label,
          hintStyle: const TextStyle(
            fontSize: 14,
            color: AppConstants.textGrey,
            fontWeight: FontWeight.bold,
          ),
          prefixIcon: Icon(
            icon,
            size: 20,
            color: AppConstants.textGrey,
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: AppConstants.mediumSpacing,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField(
    String label,
    List<String> options,
    String? selectedValue,
    ValueChanged<String?> onChanged, {
    Key? key,
  }) {
    String? validSelectedValue =
        selectedValue != null && options.contains(selectedValue)
            ? selectedValue
            : null;

    return SizedBox(
      height: 50,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.mediumSpacing,
        ),
        decoration: BoxDecoration(
          color: AppConstants.textGrey200,
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton2<String>(
            key: key,
            value: validSelectedValue,
            hint: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: AppConstants.textGrey,
                fontWeight: FontWeight.bold,
              ),
            ),
            iconStyleData: const IconStyleData(
              icon: Icon(
                Icons.arrow_drop_down,
                size: 24,
                color: AppConstants.textGrey,
              ),
            ),
            onChanged: onChanged,
            items: options
                .map(
                  (opt) => DropdownMenuItem<String>(
                    value: opt,
                    child: Text(
                      opt,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppConstants.textBlack,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                )
                .toList(),
            isExpanded: true,
            dropdownStyleData: DropdownStyleData(
              maxHeight: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                color: AppConstants.white,
              ),
              offset: const Offset(0, 0),
              scrollbarTheme: ScrollbarThemeData(
                radius: const Radius.circular(40),
                thickness: WidgetStateProperty.all(6),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
