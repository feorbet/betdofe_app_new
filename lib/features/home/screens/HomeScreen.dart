import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:table_calendar/table_calendar.dart';
import 'dart:async';
import 'package:betdofe_app_new/core/widgets/MainScaffold.dart';
import 'package:betdofe_app_new/constants.dart';
import 'package:betdofe_app_new/features/home/screens/TransactionScreen.dart';
import 'package:betdofe_app_new/utils/utils.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool isValuesVisible = true;

  String filterType = 'Todos';
  List<String> filterOptions = [
    'Todos',
    'Casa de Aposta',
    'Por Conta',
    'Por Aposta',
    'Por Data',
    'Valor Ganho',
    'Valor Perdido',
  ];

  String saldoFilter = 'Geral';
  List<String> saldoFilterOptions = [
    'Geral',
    'Por Conta',
    'Por Aposta',
    'Por Dia',
  ];

  Set<String> selectedBettingHouses = {};
  Set<String> selectedAccounts = {};
  DateTime? startDateFilter;
  DateTime? endDateFilter;

  List<String> availableBettingHouses = [];
  List<String> availableAccounts = [];

  final ValueNotifier<double> saldoPorConta = ValueNotifier<double>(0.0);
  final ValueNotifier<double> saldoPorAposta = ValueNotifier<double>(0.0);
  final ValueNotifier<double> saldoGeral = ValueNotifier<double>(0.0);
  final ValueNotifier<double> saldoDoDia = ValueNotifier<double>(0.0);
  final ValueNotifier<double> totalGanhosPorConta = ValueNotifier<double>(0.0);
  final ValueNotifier<double> totalPerdasPorConta = ValueNotifier<double>(0.0);
  final ValueNotifier<double> totalGanhosPorAposta = ValueNotifier<double>(0.0);
  final ValueNotifier<double> totalPerdasPorAposta = ValueNotifier<double>(0.0);
  final ValueNotifier<double> totalGanhosDia = ValueNotifier<double>(0.0);
  final ValueNotifier<double> totalPerdasDia = ValueNotifier<double>(0.0);

  final NumberFormat currencyFormatter = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
  );

  List<Map<String, dynamic>> _transactions = [];
  Timer? _dayChangeTimer;
  DateTime _lastCheckedDate = DateTime.now();
  bool _isLoadingTransactions = false;
  late Future<void> _transactionFuture;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        systemNavigationBarColor: AppConstants.lightGreen,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
    _transactionFuture = _loadTransactions();
    _dayChangeTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      final now = DateTime.now();
      final currentDay = DateTime(now.year, now.month, now.day);
      final lastCheckedDay = DateTime(
        _lastCheckedDate.year,
        _lastCheckedDate.month,
        _lastCheckedDate.day,
      );
      if (currentDay != lastCheckedDay && !_isLoadingTransactions) {
        _lastCheckedDate = now;
        setState(() {
          _transactionFuture = _loadTransactions();
        });
      }
    });
  }

  @override
  void dispose() {
    _dayChangeTimer?.cancel();
    saldoPorConta.dispose();
    saldoPorAposta.dispose();
    saldoGeral.dispose();
    saldoDoDia.dispose();
    totalGanhosPorConta.dispose();
    totalPerdasPorConta.dispose();
    totalGanhosPorAposta.dispose();
    totalPerdasPorAposta.dispose();
    totalGanhosDia.dispose();
    totalPerdasDia.dispose();
    super.dispose();
  }

  Future<void> _loadTransactions() async {
    if (_isLoadingTransactions) return;

    _isLoadingTransactions = true;
    if (mounted) setState(() {});

    final user = _auth.currentUser;
    if (user == null) {
      _isLoadingTransactions = false;
      if (mounted) setState(() {});
      return;
    }

    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    List<Map<String, dynamic>> transactions = [];
    Set<String> bettingHouses = {};
    Set<String> accounts = {};

    try {
      final positiveSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('positive_transactions')
          .where('timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where('timestamp',
              isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
          .get();

      for (var doc in positiveSnapshot.docs) {
        final data = doc.data();
        transactions.add({
          'id': doc.id,
          'collection': 'positive_transactions',
          'data': data,
        });
        if (data['bettingHouse'] != null) {
          bettingHouses.add(data['bettingHouse'].toString());
        }
        if (data['account'] != null) accounts.add(data['account'].toString());
      }

      final negativeSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('negative_transactions')
          .where('timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where('timestamp',
              isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
          .get();

      for (var doc in negativeSnapshot.docs) {
        final data = doc.data();
        transactions.add({
          'id': doc.id,
          'collection': 'negative_transactions',
          'data': data,
        });
        if (data['bettingHouse'] != null) {
          bettingHouses.add(data['bettingHouse'].toString());
        }
        if (data['account'] != null) accounts.add(data['account'].toString());
      }

      final perBetSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('per_bet')
          .where('timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where('timestamp',
              isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
          .get();

      for (var doc in perBetSnapshot.docs) {
        final data = doc.data();
        transactions.add({'id': doc.id, 'collection': 'per_bet', 'data': data});
        if (data['bettingHouse'] != null) {
          bettingHouses.add(data['bettingHouse'].toString());
        }
        if (data['account'] != null) accounts.add(data['account'].toString());
      }

      if (mounted) {
        setState(() {
          _transactions = transactions;
          availableBettingHouses = bettingHouses.toList();
          availableAccounts = accounts.toList();
          _isLoadingTransactions = false;
        });
      }

      _calculateSaldo(transactions);
    } catch (e) {
      print('Erro ao carregar transações: $e');
      _isLoadingTransactions = false;
      if (mounted) setState(() {});
    }
  }

  void _calculateSaldo(List<Map<String, dynamic>> transactions) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    double ganhosPorContaMes = 0.0;
    double investidoPorContaMes = 0.0;
    double comissaoPorContaMes = 0.0;
    double perdasPorContaMes = 0.0;
    double ganhosPorApostaMes = 0.0;
    double investidoPorApostaMes = 0.0;
    double comissaoPorApostaMes = 0.0;
    double perdasPorApostaMes = 0.0;

    double ganhosPorContaDia = 0.0;
    double investidoPorContaDia = 0.0;
    double comissaoPorContaDia = 0.0;
    double perdasPorContaDia = 0.0;
    double ganhosPorApostaDia = 0.0;
    double investidoPorApostaDia = 0.0;
    double comissaoPorApostaDia = 0.0;
    double perdasPorApostaDia = 0.0;

    for (var transaction in transactions) {
      final timestamp = transaction['data']['timestamp'] as Timestamp?;
      final transactionDate = timestamp?.toDate();
      if (transactionDate == null) continue;

      if (transactionDate.isAfter(startOfMonth) &&
          transactionDate.isBefore(endOfMonth)) {
        if (transaction['collection'] == 'positive_transactions') {
          ganhosPorContaMes +=
              (transaction['data']['value'] as num?)?.toDouble() ?? 0.0;
          investidoPorContaMes +=
              (transaction['data']['investedValue'] as num?)?.toDouble() ?? 0.0;
          comissaoPorContaMes +=
              (transaction['data']['commission'] as num?)?.toDouble() ?? 0.0;
        } else if (transaction['collection'] == 'negative_transactions') {
          perdasPorContaMes +=
              (transaction['data']['value'] as num?)?.toDouble().abs() ?? 0.0;
          comissaoPorContaMes +=
              (transaction['data']['commission'] as num?)?.toDouble() ?? 0.0;
        } else if (transaction['collection'] == 'per_bet') {
          double gainedValue =
              (transaction['data']['gainedValue'] as num?)?.toDouble() ?? 0.0;
          double investedValue =
              (transaction['data']['investedValue'] as num?)?.toDouble() ?? 0.0;
          double commission =
              (transaction['data']['commission'] as num?)?.toDouble() ?? 0.0;
          if (gainedValue >= 0) {
            ganhosPorApostaMes += gainedValue;
            investidoPorApostaMes += investedValue;
            comissaoPorApostaMes += commission;
          } else {
            perdasPorApostaMes += gainedValue.abs();
            comissaoPorApostaMes += commission;
          }
        }
      }

      if (transactionDate.isAfter(startOfDay) &&
          transactionDate.isBefore(endOfDay)) {
        if (transaction['collection'] == 'positive_transactions') {
          ganhosPorContaDia +=
              (transaction['data']['value'] as num?)?.toDouble() ?? 0.0;
          investidoPorContaDia +=
              (transaction['data']['investedValue'] as num?)?.toDouble() ?? 0.0;
          comissaoPorContaDia +=
              (transaction['data']['commission'] as num?)?.toDouble() ?? 0.0;
        } else if (transaction['collection'] == 'negative_transactions') {
          perdasPorContaDia +=
              (transaction['data']['value'] as num?)?.toDouble().abs() ?? 0.0;
          comissaoPorContaDia +=
              (transaction['data']['commission'] as num?)?.toDouble() ?? 0.0;
        } else if (transaction['collection'] == 'per_bet') {
          double gainedValue =
              (transaction['data']['gainedValue'] as num?)?.toDouble() ?? 0.0;
          double investedValue =
              (transaction['data']['investedValue'] as num?)?.toDouble() ?? 0.0;
          double commission =
              (transaction['data']['commission'] as num?)?.toDouble() ?? 0.0;
          if (gainedValue >= 0) {
            ganhosPorApostaDia += gainedValue;
            investidoPorApostaDia += investedValue;
            comissaoPorApostaDia += commission;
          } else {
            perdasPorApostaDia += gainedValue.abs();
            comissaoPorApostaDia += commission;
          }
        }
      }
    }

    saldoPorConta.value =
        (ganhosPorContaMes - investidoPorContaMes - comissaoPorContaMes) -
            perdasPorContaMes;
    saldoPorAposta.value =
        (ganhosPorApostaMes - investidoPorApostaMes - comissaoPorApostaMes) -
            perdasPorApostaMes;
    saldoGeral.value = saldoPorConta.value + saldoPorAposta.value;

    saldoDoDia.value = ((ganhosPorContaDia -
                investidoPorContaDia -
                comissaoPorContaDia) -
            perdasPorContaDia) +
        ((ganhosPorApostaDia - investidoPorApostaDia - comissaoPorApostaDia) -
            perdasPorApostaDia);

    totalGanhosPorConta.value = ganhosPorContaMes;
    totalPerdasPorConta.value = perdasPorContaMes;
    totalGanhosPorAposta.value = ganhosPorApostaMes;
    totalPerdasPorAposta.value = perdasPorApostaMes;

    totalGanhosDia.value = ganhosPorContaDia + ganhosPorApostaDia;
    totalPerdasDia.value = perdasPorContaDia + perdasPorApostaDia;
  }

  void _updateGanhosPerdas(List<Map<String, dynamic>> transactions) {
    _calculateSaldo(transactions);
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
        setState(() {
          _transactionFuture = _loadTransactions();
        });
      }
    } catch (e) {
      print('Erro ao excluir transação: $e');
      showAppMessage(context, 'Erro ao excluir transação: $e', isError: true);
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bom dia';
    if (hour < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  void _toggleValuesVisibility() {
    setState(() {
      isValuesVisible = !isValuesVisible;
    });
  }

  void _showBettingHouseFilter(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.transparent,
              contentPadding: EdgeInsets.zero,
              title: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppConstants.lightGreen,
                      AppConstants.primaryColor
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(AppConstants.borderRadius),
                    topRight: Radius.circular(AppConstants.borderRadius),
                  ),
                ),
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                child: const Text(
                  'Filtrar por Casa de Aposta',
                  style: TextStyle(
                    color: AppConstants.white,
                    fontSize: 16,
                  ),
                ),
              ),
              content: Container(
                width: double.maxFinite,
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppConstants.lightGreen,
                      AppConstants.primaryColor
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: availableBettingHouses.map((house) {
                      return CheckboxListTile(
                        title: Text(
                          house,
                          style: const TextStyle(
                            color: AppConstants.white,
                            fontSize: 14,
                          ),
                        ),
                        value: selectedBettingHouses.contains(house),
                        activeColor: AppConstants.white,
                        checkColor: AppConstants.textBlack,
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true) {
                              selectedBettingHouses.add(house);
                            } else {
                              selectedBettingHouses.remove(house);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
              ),
              actions: [
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppConstants.lightGreen,
                        AppConstants.primaryColor
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(AppConstants.borderRadius),
                      bottomRight: Radius.circular(AppConstants.borderRadius),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          setState(() {
                            filterType = 'Casa de Aposta';
                          });
                        },
                        child: const Text(
                          'Aplicar',
                          style: TextStyle(color: AppConstants.white),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Cancelar',
                          style: TextStyle(color: AppConstants.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      setState(() {});
    });
  }

  void _showAccountFilter(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.transparent,
              contentPadding: EdgeInsets.zero,
              title: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppConstants.lightGreen,
                      AppConstants.primaryColor
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(AppConstants.borderRadius),
                    topRight: Radius.circular(AppConstants.borderRadius),
                  ),
                ),
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                child: const Text(
                  'Filtrar por Conta',
                  style: TextStyle(
                    color: AppConstants.white,
                    fontSize: 16,
                  ),
                ),
              ),
              content: Container(
                width: double.maxFinite,
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppConstants.lightGreen,
                      AppConstants.primaryColor
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: availableAccounts.map((account) {
                      return CheckboxListTile(
                        title: Text(
                          account,
                          style: const TextStyle(
                            color: AppConstants.white,
                            fontSize: 14,
                          ),
                        ),
                        value: selectedAccounts.contains(account),
                        activeColor: AppConstants.white,
                        checkColor: AppConstants.textBlack,
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true) {
                              selectedAccounts.add(account);
                            } else {
                              selectedAccounts.remove(account);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
              ),
              actions: [
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppConstants.lightGreen,
                        AppConstants.primaryColor
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(AppConstants.borderRadius),
                      bottomRight: Radius.circular(AppConstants.borderRadius),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          setState(() {
                            filterType = 'Por Conta';
                          });
                        },
                        child: const Text(
                          'Aplicar',
                          style: TextStyle(color: AppConstants.white),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Cancelar',
                          style: TextStyle(color: AppConstants.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      setState(() {});
    });
  }

  void _showDateFilter(BuildContext context) {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    DateTime? tempStartDate = startDateFilter ?? startOfMonth;
    DateTime? tempEndDate = endDateFilter ?? endOfMonth;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.transparent,
              contentPadding: EdgeInsets.zero,
              title: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppConstants.lightGreen,
                      AppConstants.primaryColor
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(AppConstants.borderRadius),
                    topRight: Radius.circular(AppConstants.borderRadius),
                  ),
                ),
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                child: const Text(
                  'Filtrar por Data',
                  style: TextStyle(
                    color: AppConstants.white,
                    fontSize: 16,
                  ),
                ),
              ),
              content: Container(
                width: double.maxFinite,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppConstants.lightGreen,
                      AppConstants.primaryColor
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Padding(
                        padding:
                            EdgeInsets.only(top: AppConstants.defaultPadding),
                        child: Text(
                          'Data Inicial',
                          style: TextStyle(
                            color: AppConstants.white,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            builder: (context) {
                              return Container(
                                padding: const EdgeInsets.all(
                                    AppConstants.defaultPadding),
                                child: TableCalendar(
                                  firstDay: startOfMonth,
                                  lastDay: endOfMonth,
                                  focusedDay: tempStartDate!,
                                  selectedDayPredicate: (day) {
                                    return isSameDay(day, tempStartDate);
                                  },
                                  onDaySelected: (newSelectedDay, focusedDay) {
                                    setState(() {
                                      tempStartDate = newSelectedDay;
                                      if (tempEndDate != null &&
                                          tempStartDate!
                                              .isAfter(tempEndDate!)) {
                                        tempEndDate = tempStartDate;
                                      }
                                    });
                                    Navigator.pop(context);
                                  },
                                  locale: 'pt_BR',
                                  headerStyle: const HeaderStyle(
                                    formatButtonVisible: false,
                                    titleCentered: true,
                                  ),
                                  calendarStyle: const CalendarStyle(
                                    todayDecoration: BoxDecoration(
                                      color: AppConstants.green,
                                      shape: BoxShape.circle,
                                    ),
                                    selectedDecoration: BoxDecoration(
                                      color: Colors.blue,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        child: Text(
                          DateFormat('dd/MM/yyyy').format(tempStartDate!),
                          style: const TextStyle(color: AppConstants.white),
                        ),
                      ),
                      const SizedBox(height: AppConstants.defaultPadding),
                      const Text(
                        'Data Final',
                        style: TextStyle(
                          color: AppConstants.white,
                          fontSize: 14,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            builder: (context) {
                              return Container(
                                padding: const EdgeInsets.all(
                                    AppConstants.defaultPadding),
                                child: TableCalendar(
                                  firstDay: tempStartDate!,
                                  lastDay: endOfMonth,
                                  focusedDay: tempEndDate ?? endOfMonth,
                                  selectedDayPredicate: (day) {
                                    return isSameDay(day, tempEndDate);
                                  },
                                  onDaySelected: (newSelectedDay, focusedDay) {
                                    setState(() {
                                      tempEndDate = newSelectedDay;
                                    });
                                    Navigator.pop(context);
                                  },
                                  locale: 'pt_BR',
                                  headerStyle: const HeaderStyle(
                                    formatButtonVisible: false,
                                    titleCentered: true,
                                  ),
                                  calendarStyle: const CalendarStyle(
                                    todayDecoration: BoxDecoration(
                                      color: AppConstants.green,
                                      shape: BoxShape.circle,
                                    ),
                                    selectedDecoration: BoxDecoration(
                                      color: Colors.blue,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        child: Text(
                          tempEndDate != null
                              ? DateFormat('dd/MM/yyyy').format(tempEndDate!)
                              : 'Selecione',
                          style: const TextStyle(color: AppConstants.white),
                        ),
                      ),
                      const SizedBox(height: AppConstants.defaultPadding),
                    ],
                  ),
                ),
              ),
              actions: [
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppConstants.lightGreen,
                        AppConstants.primaryColor
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(AppConstants.borderRadius),
                      bottomRight: Radius.circular(AppConstants.borderRadius),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() {
                            startDateFilter = tempStartDate;
                            endDateFilter = tempEndDate;
                            filterType = 'Por Data';
                          });
                          Navigator.pop(context);
                        },
                        child: const Text(
                          'Aplicar',
                          style: TextStyle(color: AppConstants.white),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Cancelar',
                          style: TextStyle(color: AppConstants.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(
          context,
          '/login',
        );
      });
      return const SizedBox.shrink();
    }

    return MainScaffold(
      selectedIndex: 0,
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
          IconButton(
            icon: const Icon(
              Icons.logout,
              color: AppConstants.white,
            ),
            onPressed: () => _logout(context),
            tooltip: 'Sair da conta',
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 260),
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
                    PopupMenuButton<String>(
                      icon: const Icon(
                        Icons.filter_list,
                        color: AppConstants.textGrey,
                      ),
                      onSelected: (value) {
                        if (value == 'Casa de Aposta') {
                          _showBettingHouseFilter(context);
                        } else if (value == 'Por Conta') {
                          _showAccountFilter(context);
                        } else if (value == 'Por Data') {
                          _showDateFilter(context);
                        } else {
                          setState(() {
                            filterType = value;
                            selectedBettingHouses.clear();
                            selectedAccounts.clear();
                            startDateFilter = null;
                            endDateFilter = null;
                          });
                        }
                      },
                      itemBuilder: (context) => filterOptions.map((option) {
                        IconData icon;
                        switch (option) {
                          case 'Todos':
                            icon = Icons.all_inclusive;
                            break;
                          case 'Casa de Aposta':
                            icon = Icons.sports_soccer;
                            break;
                          case 'Por Conta':
                            icon = Icons.account_balance;
                            break;
                          case 'Por Aposta':
                            icon = Icons.casino;
                            break;
                          case 'Por Data':
                            icon = Icons.calendar_today;
                            break;
                          case 'Valor Ganho':
                            icon = Icons.trending_up;
                            break;
                          case 'Valor Perdido':
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
              ),
              const SizedBox(height: AppConstants.smallSpacing),
              Expanded(
                child: FutureBuilder<void>(
                  future: _transactionFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Erro: ${snapshot.error}'));
                    }
                    return _buildTransactionHistory();
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
              child: Row(
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
                                  _getGreeting(),
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  user.displayName ?? 'Apostador',
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
                                const SizedBox(height: 2),
                                PopupMenuButton<String>(
                                  icon: const Icon(
                                    Icons.filter_list,
                                    color: Colors.white70,
                                    size: 20,
                                  ),
                                  onSelected: (value) {
                                    setState(() {
                                      saldoFilter = value;
                                    });
                                  },
                                  itemBuilder: (context) =>
                                      saldoFilterOptions.map((option) {
                                    IconData icon;
                                    switch (option) {
                                      case 'Geral':
                                        icon = Icons.account_balance_wallet;
                                        break;
                                      case 'Por Conta':
                                        icon = Icons.account_balance;
                                        break;
                                      case 'Por Aposta':
                                        icon = Icons.casino;
                                        break;
                                      case 'Por Dia':
                                        icon = Icons.today;
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
                                          const SizedBox(
                                            width: AppConstants.smallSpacing,
                                          ),
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
                          ],
                        ),
                        const SizedBox(height: AppConstants.smallSpacing),
                        Center(
                          child: Text(
                            saldoFilter == 'Por Conta'
                                ? 'Saldo por Conta'
                                : saldoFilter == 'Por Aposta'
                                    ? 'Saldo por Aposta'
                                    : saldoFilter == 'Geral'
                                        ? 'Saldo Geral'
                                        : 'Saldo Por Dia',
                            style: const TextStyle(
                              color: Colors.white70,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Center(
                          child: ValueListenableBuilder<double>(
                            valueListenable: saldoFilter == 'Por Conta'
                                ? saldoPorConta
                                : saldoFilter == 'Por Aposta'
                                    ? saldoPorAposta
                                    : saldoFilter == 'Geral'
                                        ? saldoGeral
                                        : saldoDoDia,
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
                        const SizedBox(height: AppConstants.smallSpacing),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              children: [
                                const Text(
                                  'Hoje',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10,
                                  ),
                                ),
                                CircleAvatar(
                                  backgroundColor:
                                      AppConstants.white.withOpacity(0.2),
                                  radius: 16,
                                  child: const Icon(
                                    Icons.arrow_upward,
                                    color: AppConstants.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Ganhos',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                ValueListenableBuilder<double>(
                                  valueListenable: totalGanhosDia,
                                  builder: (context, value, child) {
                                    return Text(
                                      isValuesVisible
                                          ? currencyFormatter.format(value)
                                          : '****',
                                      style: const TextStyle(
                                        color: AppConstants.white,
                                        fontSize: 12,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                const Text(
                                  'Hoje',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10,
                                  ),
                                ),
                                CircleAvatar(
                                  backgroundColor:
                                      AppConstants.white.withOpacity(0.2),
                                  radius: 16,
                                  child: const Icon(
                                    Icons.arrow_downward,
                                    color: AppConstants.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Perdas',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                ValueListenableBuilder<double>(
                                  valueListenable: totalPerdasDia,
                                  builder: (context, value, child) {
                                    return Text(
                                      isValuesVisible
                                          ? currencyFormatter.format(value)
                                          : '****',
                                      style: const TextStyle(
                                        color: AppConstants.white,
                                        fontSize: 12,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      showFloatingActionButton: true,
    );
  }

  Widget _buildTransactionHistory() {
    if (_transactions.isEmpty) {
      return const Center(child: Text('Nenhuma transação encontrada.'));
    }

    List<Map<String, dynamic>> filtered = List.from(_transactions);

    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    if (filterType == 'Casa de Aposta' && selectedBettingHouses.isNotEmpty) {
      filtered = filtered.where((doc) {
        final bettingHouse = doc['data']['bettingHouse']?.toString();
        return bettingHouse != null &&
            selectedBettingHouses.contains(bettingHouse);
      }).toList();
    } else if (filterType == 'Por Conta' && selectedAccounts.isNotEmpty) {
      filtered = filtered.where((doc) {
        final account = doc['data']['account']?.toString();
        return account != null && selectedAccounts.contains(account);
      }).toList();
    } else if (filterType == 'Por Aposta') {
      filtered =
          filtered.where((doc) => doc['collection'] == 'per_bet').toList();
    } else if (filterType == 'Por Data' &&
        startDateFilter != null &&
        endDateFilter != null) {
      filtered = filtered.where((doc) {
        final timestamp = doc['data']['timestamp'] as Timestamp?;
        final transactionDate = timestamp?.toDate();
        if (transactionDate == null) return false;
        return transactionDate
                .isAfter(startDateFilter!.subtract(const Duration(days: 1))) &&
            transactionDate
                .isBefore(endDateFilter!.add(const Duration(days: 1)));
      }).toList();
    } else if (filterType == 'Valor Ganho') {
      filtered = filtered.where((doc) {
        final collection = doc['collection'] as String;
        final data = doc['data'] as Map<String, dynamic>;
        final double value = collection == 'per_bet'
            ? (data['gainedValue'] as num?)?.toDouble() ?? 0.0
            : (data['value'] as num?)?.toDouble() ?? 0.0;
        final double investedValue = collection == 'per_bet'
            ? (data['investedValue'] as num?)?.toDouble() ?? 0.0
            : (data['investedValue'] as num?)?.toDouble() ?? 0.0;
        final double commission = collection == 'per_bet'
            ? (data['commission'] as num?)?.toDouble() ?? 0.0
            : (data['commission'] as num?)?.toDouble() ?? 0.0;

        final double valorLiquido;
        if (collection == 'per_bet') {
          valorLiquido = value - (investedValue + commission);
        } else if (collection == 'positive_transactions') {
          valorLiquido = (value - commission) - investedValue;
        } else {
          valorLiquido = value - commission;
        }

        return valorLiquido >= 0;
      }).toList();
    } else if (filterType == 'Valor Perdido') {
      filtered = filtered.where((doc) {
        final collection = doc['collection'] as String;
        final data = doc['data'] as Map<String, dynamic>;
        final double value = collection == 'per_bet'
            ? (data['gainedValue'] as num?)?.toDouble() ?? 0.0
            : (data['value'] as num?)?.toDouble() ?? 0.0;
        final double investedValue = collection == 'per_bet'
            ? (data['investedValue'] as num?)?.toDouble() ?? 0.0
            : (data['investedValue'] as num?)?.toDouble() ?? 0.0;
        final double commission = collection == 'per_bet'
            ? (data['commission'] as num?)?.toDouble() ?? 0.0
            : (data['commission'] as num?)?.toDouble() ?? 0.0;

        final double valorLiquido;
        if (collection == 'per_bet') {
          valorLiquido = value - (investedValue + commission);
        } else if (collection == 'positive_transactions') {
          valorLiquido = (value - commission) - investedValue;
        } else {
          valorLiquido = value - commission;
        }

        return valorLiquido < 0;
      }).toList();
    } else {
      filtered.sort((a, b) {
        final timestampA = a['data']['timestamp'] as Timestamp?;
        final timestampB = b['data']['timestamp'] as Timestamp?;
        return (timestampB?.toDate() ?? DateTime.now()).compareTo(
          timestampA?.toDate() ?? DateTime.now(),
        );
      });
    }

    if (filtered.isEmpty) {
      return const Center(
        child: Text('Nenhuma transação encontrada após filtro.'),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        setState(() {
          _transactionFuture = _loadTransactions();
        });
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.defaultPadding * 1.5,
          vertical: AppConstants.smallSpacing,
        ),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final transaction = filtered[index];
          final data = transaction['data'] as Map<String, dynamic>;
          final collection = transaction['collection'] as String;
          final docId = transaction['id'] as String;
          final isPerBet = collection == 'per_bet';
          final value = isPerBet
              ? (data['gainedValue'] as num?)?.toDouble() ?? 0.0
              : (data['value'] as num?)?.toDouble() ?? 0.0;
          final investedValue = isPerBet
              ? (data['investedValue'] as num?)?.toDouble() ?? 0.0
              : (data['investedValue'] as num?)?.toDouble() ?? 0.0;
          final commission = isPerBet
              ? (data['commission'] as num?)?.toDouble() ?? 0.0
              : (data['commission'] as num?)?.toDouble() ?? 0.0;

          // Calcular o valor líquido para determinar isPositive
          final double valorLiquido;
          if (collection == 'per_bet') {
            valorLiquido = value - (investedValue + commission);
          } else if (collection == 'positive_transactions') {
            valorLiquido = (value - commission) - investedValue;
          } else {
            // negative_transactions
            valorLiquido = value - commission;
          }

          // Determinar isPositive com base no valor líquido
          final isPositive = valorLiquido >= 0;

          final date = data['date']?.toString() ?? '';
          final account = data['account']?.toString() ?? 'Sem conta';
          final bettingHouse = data['bettingHouse']?.toString() ?? 'Sem casa';
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
      valorLiquido = value -
          (investedValue +
              commission); // valor total - (valor investido + comissão)
    } else if (collection == 'positive_transactions') {
      valorLiquido = (value - commission) -
          investedValue; // (valor bruto - comissão) - valor investido
    } else {
      // negative_transactions
      valorLiquido = value - commission; // valor bruto - comissão
    }

    // Determinar a cor com base no valor líquido
    final color = valorLiquido >= 0 ? AppConstants.green : AppConstants.red;

    // Formatando o valor líquido para exibição
    final String amountLiquido = valorLiquido >= 0
        ? '+ ${currencyFormatter.format(valorLiquido)}'
        : '- ${currencyFormatter.format(valorLiquido.abs())}';

    return GestureDetector(
      onTap: () => _showTransactionDetails(data, collection, isGain),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppConstants.defaultPadding),
        height: 100, // Altura fixa para todos os itens
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
                    backgroundColor: AppConstants.textGrey200,
                    child: Icon(
                      collection == 'per_bet'
                          ? Icons.sports_soccer // Ícone original para per_bet
                          : Icons
                              .account_circle, // Ícone original para outras transações
                      color: Colors.black54,
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
                  amountLiquido, // Exibir o valor líquido
                  style: TextStyle(
                    color: color, // Cor baseada no valor líquido
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
                            setState(() {
                              _transactionFuture = _loadTransactions();
                            });
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

  Future<void> _logout(BuildContext context) async {
    try {
      await _auth.signOut();
      if (!mounted) return;
      showAppMessage(context, 'Logout realizado com sucesso!');
      Navigator.pushReplacementNamed(
        context,
        '/login',
      );
    } catch (e) {
      print('Erro ao fazer logout: $e');
      if (!mounted) return;
      showAppMessage(context, 'Erro ao fazer logout: $e', isError: true);
    }
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
