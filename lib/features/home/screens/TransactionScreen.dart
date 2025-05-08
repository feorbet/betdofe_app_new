import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter/services.dart';
import 'package:betdofe_app_new/core/widgets/MainScaffold.dart';
import 'package:betdofe_app_new/constants.dart';
import 'package:betdofe_app_new/utils/utils.dart';

class TransactionScreen extends StatefulWidget {
  final VoidCallback? onTransactionAdded;
  final Map<String, dynamic>? initialData; // Dados para edição
  final String? transactionId; // ID da transação para edição
  final bool isEditing; // Indica se está editando

  const TransactionScreen({
    super.key,
    this.onTransactionAdded,
    this.initialData,
    this.transactionId,
    this.isEditing = false,
  });

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String currentTab = 'Por Conta';
  bool isPositive = true;

  final TextEditingController valueController = TextEditingController();
  final TextEditingController investedValueController = TextEditingController();
  final TextEditingController commissionController = TextEditingController();
  final TextEditingController dateController = TextEditingController();

  final TextEditingController homeTeamController = TextEditingController();
  final TextEditingController awayTeamController = TextEditingController();
  final TextEditingController perBetInvestedValueController =
      TextEditingController();
  final TextEditingController perBetCommissionController =
      TextEditingController();

  String? selectedAccount;
  String? selectedBettingHouse;

  final FocusNode _valueFocusNode = FocusNode();
  final FocusNode _investedValueFocusNode = FocusNode();
  final FocusNode _commissionFocusNode = FocusNode();
  final FocusNode _perBetInvestedValueFocusNode = FocusNode();
  final FocusNode _perBetCommissionFocusNode = FocusNode();

  List<String> accounts = [];
  List<String> bettingHouses = [];

  double _value = 0.0;

  final currencyFormatter =
      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Inicializar campos com valores padrão ou com dados para edição
    if (widget.initialData != null) {
      // Determinar o tipo de transação e se é positiva ou negativa
      if (widget.initialData!.containsKey('homeTeam')) {
        currentTab = 'Por Aposta';
        _tabController?.index = 1;
        homeTeamController.text =
            widget.initialData!['homeTeam']?.toString() ?? '';
        awayTeamController.text =
            widget.initialData!['awayTeam']?.toString() ?? '';
        perBetInvestedValueController.text = currencyFormatter.format(
            (widget.initialData!['investedValue'] as num?)?.toDouble() ?? 0.0);
        perBetCommissionController.text = currencyFormatter.format(
            (widget.initialData!['commission'] as num?)?.toDouble() ?? 0.0);
        _value =
            (widget.initialData!['gainedValue'] as num?)?.toDouble() ?? 0.0;
        isPositive = _value >= 0;
      } else {
        currentTab = 'Por Conta';
        _tabController?.index = 0;
        selectedAccount = widget.initialData!['account']?.toString();
        selectedBettingHouse = widget.initialData!['bettingHouse']?.toString();
        investedValueController.text = currencyFormatter.format(
            (widget.initialData!['investedValue'] as num?)?.toDouble() ?? 0.0);
        commissionController.text = currencyFormatter.format(
            (widget.initialData!['commission'] as num?)?.toDouble() ?? 0.0);
        _value = (widget.initialData!['value'] as num?)?.toDouble() ?? 0.0;
        isPositive = _value >= 0;
      }
      valueController.text = currencyFormatter.format(_value.abs());
      dateController.text = widget.initialData!['date']?.toString() ?? '';
    } else {
      dateController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
      valueController.text = currencyFormatter.format(0);
      investedValueController.text = currencyFormatter.format(0);
      commissionController.text = currencyFormatter.format(0);
      perBetInvestedValueController.text = currencyFormatter.format(0);
      perBetCommissionController.text = currencyFormatter.format(0);
    }

    _loadActiveAccounts();

    valueController.addListener(() {
      String raw = valueController.text.replaceAll(RegExp(r'[^0-9]'), '');
      if (raw.isEmpty) raw = '0';
      double parsed = double.parse(raw) / 100;
      String formatted = currencyFormatter.format(parsed);
      if (valueController.text != formatted) {
        valueController.value = TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length),
        );
      }
    });

    investedValueController.addListener(() {
      String raw =
          investedValueController.text.replaceAll(RegExp(r'[^0-9]'), '');
      if (raw.isEmpty) raw = '0';
      double parsed = double.parse(raw) / 100;
      String formatted = currencyFormatter.format(parsed);
      if (investedValueController.text != formatted) {
        investedValueController.value = TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length),
        );
      }
    });

    commissionController.addListener(() {
      String raw = commissionController.text.replaceAll(RegExp(r'[^0-9]'), '');
      if (raw.isEmpty) raw = '0';
      double parsed = double.parse(raw) / 100;
      String formatted = currencyFormatter.format(parsed);
      if (commissionController.text != formatted) {
        commissionController.value = TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length),
        );
      }
    });

    perBetInvestedValueController.addListener(() {
      String raw =
          perBetInvestedValueController.text.replaceAll(RegExp(r'[^0-9]'), '');
      if (raw.isEmpty) raw = '0';
      double parsed = double.parse(raw) / 100;
      String formatted = currencyFormatter.format(parsed);
      if (perBetInvestedValueController.text != formatted) {
        perBetInvestedValueController.value = TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length),
        );
      }
    });

    perBetCommissionController.addListener(() {
      String raw =
          perBetCommissionController.text.replaceAll(RegExp(r'[^0-9]'), '');
      if (raw.isEmpty) raw = '0';
      double parsed = double.parse(raw) / 100;
      String formatted = currencyFormatter.format(parsed);
      if (perBetCommissionController.text != formatted) {
        perBetCommissionController.value = TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length),
        );
      }
    });

    _valueFocusNode.addListener(() {
      if (!_valueFocusNode.hasFocus) {
        String raw = valueController.text.replaceAll(RegExp(r'[^0-9]'), '');
        if (raw.isEmpty) raw = '0';
        double parsed = double.parse(raw) / 100;
        _value = isPositive ? parsed.abs() : -parsed.abs();
        valueController.text = currencyFormatter.format(_value.abs());
      }
    });

    _investedValueFocusNode.addListener(() {
      if (!_investedValueFocusNode.hasFocus) {
        String raw =
            investedValueController.text.replaceAll(RegExp(r'[^0-9]'), '');
        if (raw.isEmpty) raw = '0';
        double parsed = double.parse(raw) / 100;
        investedValueController.text = currencyFormatter.format(parsed);
      }
    });

    _commissionFocusNode.addListener(() {
      if (!_commissionFocusNode.hasFocus) {
        String raw =
            commissionController.text.replaceAll(RegExp(r'[^0-9]'), '');
        if (raw.isEmpty) raw = '0';
        double parsed = double.parse(raw) / 100;
        commissionController.text = currencyFormatter.format(parsed);
      }
    });

    _perBetInvestedValueFocusNode.addListener(() {
      if (!_perBetInvestedValueFocusNode.hasFocus) {
        String raw = perBetInvestedValueController.text
            .replaceAll(RegExp(r'[^0-9]'), '');
        if (raw.isEmpty) raw = '0';
        double parsed = double.parse(raw) / 100;
        perBetInvestedValueController.text = currencyFormatter.format(parsed);
      }
    });

    _perBetCommissionFocusNode.addListener(() {
      if (!_perBetCommissionFocusNode.hasFocus) {
        String raw =
            perBetCommissionController.text.replaceAll(RegExp(r'[^0-9]'), '');
        if (raw.isEmpty) raw = '0';
        double parsed = double.parse(raw) / 100;
        perBetCommissionController.text = currencyFormatter.format(parsed);
      }
    });
  }

  Future<void> _loadActiveAccounts() async {
    final user = _auth.currentUser;
    if (user == null) {
      print('Usuário não autenticado ao carregar contas ativas');
      if (mounted) {
        showAppMessage(
            context, 'Usuário não autenticado ao carregar contas ativas',
            isError: true);
      }
      return;
    }

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('accounts')
          .where('status', isEqualTo: 'Ativa')
          .get();
      print('Contas ativas carregadas: ${snapshot.docs.length} contas');
      if (mounted) {
        setState(() {
          accounts = snapshot.docs.map((doc) => doc['name'] as String).toList();
          // Se estiver editando, manter a conta selecionada
          if (widget.initialData != null &&
              widget.initialData!['account'] != null) {
            selectedAccount = widget.initialData!['account']?.toString();
            _loadBettingHousesForAccount(selectedAccount!);
          }
        });
      }
    } catch (e) {
      print('Erro ao carregar contas ativas: $e');
      if (mounted) {
        showAppMessage(context, 'Erro ao carregar contas ativas: $e',
            isError: true);
      }
    }
  }

  Future<void> _loadBettingHousesForAccount(String accountName) async {
    final user = _auth.currentUser;
    if (user == null) {
      print('Usuário não autenticado ao carregar casas de aposta');
      if (mounted) {
        showAppMessage(
            context, 'Usuário não autenticado ao carregar casas de aposta',
            isError: true);
      }
      return;
    }

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('accounts')
          .where('name', isEqualTo: accountName)
          .get();
      if (snapshot.docs.isNotEmpty) {
        final accountData = snapshot.docs.first.data();
        final bettingHouse = accountData['bettingHouse'] as String?;
        print(
            'Casa de aposta carregada para a conta $accountName: $bettingHouse');
        if (mounted) {
          setState(() {
            bettingHouses = bettingHouse != null ? [bettingHouse] : [];
            // Se estiver editando, manter a casa de aposta selecionada
            if (widget.initialData != null &&
                widget.initialData!['bettingHouse'] != null) {
              selectedBettingHouse =
                  widget.initialData!['bettingHouse']?.toString();
            } else {
              selectedBettingHouse =
                  bettingHouses.isNotEmpty ? bettingHouses[0] : null;
            }
          });
        }
      } else {
        print('Nenhuma casa de aposta encontrada para a conta $accountName');
        if (mounted) {
          setState(() {
            bettingHouses = [];
            selectedBettingHouse = null;
          });
        }
      }
    } catch (e) {
      print('Erro ao carregar casa de aposta: $e');
      if (mounted) {
        showAppMessage(context, 'Erro ao carregar casa de aposta: $e',
            isError: true);
      }
    }
  }

  void _clearFields() {
    setState(() {
      valueController.text = currencyFormatter.format(0);
      investedValueController.text = currencyFormatter.format(0);
      commissionController.text = currencyFormatter.format(0);
      dateController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
      homeTeamController.clear();
      awayTeamController.clear();
      selectedAccount = null;
      selectedBettingHouse = null;
      bettingHouses = [];
      perBetInvestedValueController.text = currencyFormatter.format(0);
      perBetCommissionController.text = currencyFormatter.format(0);
    });
  }

  @override
  void dispose() {
    _valueFocusNode.dispose();
    _investedValueFocusNode.dispose();
    _commissionFocusNode.dispose();
    _perBetInvestedValueFocusNode.dispose();
    _perBetCommissionFocusNode.dispose();
    valueController.dispose();
    investedValueController.dispose();
    commissionController.dispose();
    dateController.dispose();
    homeTeamController.dispose();
    awayTeamController.dispose();
    perBetInvestedValueController.dispose();
    perBetCommissionController.dispose();
    _tabController?.dispose();
    super.dispose();
  }

  void _selectDate(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: TableCalendar(
            firstDay: DateTime(2000),
            lastDay: DateTime(2101),
            focusedDay: DateTime.now(),
            selectedDayPredicate: (day) {
              return isSameDay(
                day,
                DateTime.parse(DateFormat('yyyy-MM-dd').format(
                  DateTime.parse(
                      dateController.text.split('/').reversed.join('-')),
                )),
              );
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                dateController.text =
                    DateFormat('dd/MM/yyyy').format(selectedDay);
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
  }

  Future<void> _updateAccountStatus(
      String accountName, String newStatus) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('accounts')
          .where('name', isEqualTo: accountName)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final accountDocId = snapshot.docs.first.id;
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('accounts')
            .doc(accountDocId)
            .update({
          'status': newStatus,
          'timestamp': FieldValue.serverTimestamp(),
        });
        print('Status da conta $accountName atualizado para $newStatus');
        if (mounted) {
          showAppMessage(
              context, 'Status da conta atualizado para $newStatus!');
        }
      } else {
        print('Conta $accountName não encontrada');
        if (mounted) {
          showAppMessage(context, 'Conta $accountName não encontrada',
              isError: true);
        }
      }
    } catch (e) {
      print('Erro ao atualizar status da conta: $e');
      if (mounted) {
        showAppMessage(context, 'Erro ao atualizar status da conta: $e',
            isError: true);
      }
    }
  }

  Future<void> _showConfirmationDialog() async {
    bool? keepActive = await showDialog<bool>(
      context: context,
      barrierDismissible:
          false, // Impede que o diálogo seja fechado ao clicar fora
      builder: (context) => AlertDialog(
        backgroundColor: AppConstants.primaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Transação salva com sucesso!\nA conta continua Ativa?',
              textAlign: TextAlign.center, // Centraliza o texto
              style: TextStyle(
                color: AppConstants.white,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: AppConstants.mediumSpacing),
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.center, // Centraliza os botões
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.green,
                    foregroundColor: AppConstants.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppConstants.borderRadius),
                    ),
                  ),
                  child: const Text(
                    'SIM',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: AppConstants.mediumSpacing),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.red,
                    foregroundColor: AppConstants.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppConstants.borderRadius),
                    ),
                  ),
                  child: const Text(
                    'NÃO',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (keepActive == true) {
      // Se SIM, apenas limpa os campos e aguarda nova operação
      _clearFields();
    } else if (keepActive == false) {
      // Se NÃO, altera o status da conta para "Inativa" e limpa os campos
      if (currentTab == 'Por Conta' && selectedAccount != null) {
        await _updateAccountStatus(selectedAccount!, 'Inativa');
      }
      _clearFields();
    }
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    final panelTopPosition = screenHeight * 0.05;
    final fieldsPaddingTop = screenHeight * 0.22;

    return MainScaffold(
      selectedIndex: -1,
      showFloatingActionButton: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppConstants.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.isEditing ? 'Editar Transação' : 'Transações',
          style: const TextStyle(
            color: AppConstants.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppConstants.primaryColor,
        iconTheme: const IconThemeData(color: AppConstants.white),
        bottom: _tabController != null
            ? TabBar(
                controller: _tabController,
                labelColor: AppConstants.white,
                unselectedLabelColor: Colors.white70,
                indicatorColor: AppConstants.white,
                tabs: const [
                  Tab(text: 'Por Conta'),
                  Tab(text: 'Por Aposta'),
                ],
                onTap: (index) {
                  setState(() {
                    currentTab = index == 0 ? 'Por Conta' : 'Por Aposta';
                  });
                },
              )
            : null,
      ),
      body: Stack(
        children: [
          Positioned(
            top: panelTopPosition,
            left: screenWidth * 0.05,
            right: screenWidth * 0.05,
            child: _buildRendimientosPanel(),
          ),
          Padding(
            padding: EdgeInsets.only(
              top: fieldsPaddingTop,
              left: screenWidth * 0.05,
              right: screenWidth * 0.05,
              bottom: 56, // Espaço para o FooterBar
            ),
            child: SingleChildScrollView(
              child: Container(
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (currentTab == 'Por Conta') ...[
                      _buildDropdownField('', accounts, selectedAccount,
                          (value) {
                        setState(() {
                          selectedAccount = value;
                          if (value != null) {
                            _loadBettingHousesForAccount(value);
                          }
                        });
                      }),
                      SizedBox(height: screenHeight * 0.015),
                      _buildDropdownField(
                          'Casa de Aposta', bettingHouses, selectedBettingHouse,
                          (value) {
                        setState(() {
                          selectedBettingHouse = value;
                        });
                      }, enabled: false),
                      SizedBox(height: screenHeight * 0.015),
                      _buildLabeledInput(
                        'Investido R\$',
                        Icons.trending_up,
                        investedValueController,
                        true,
                        _investedValueFocusNode,
                        isPositive,
                      ),
                      SizedBox(height: screenHeight * 0.015),
                      _buildLabeledInput(
                        'Comissão R\$',
                        Icons.monetization_on,
                        commissionController,
                        true,
                        _commissionFocusNode,
                        isPositive,
                      ),
                      SizedBox(height: screenHeight * 0.015),
                      _buildDateInput(),
                      SizedBox(height: screenHeight * 0.03),
                      Center(
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              await _saveTransaction();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppConstants.primaryColor,
                              foregroundColor: AppConstants.white,
                            ),
                            child: Text(
                                widget.isEditing ? 'Atualizar' : 'Confirmar'),
                          ),
                        ),
                      ),
                    ],
                    if (currentTab == 'Por Aposta') ...[
                      _buildLabeledInput('Time da Casa', Icons.sports_soccer,
                          homeTeamController, false, null, true),
                      const SizedBox(height: AppConstants.mediumSpacing),
                      _buildLabeledInput('Time Visitante', Icons.sports_soccer,
                          awayTeamController, false, null, true),
                      const SizedBox(height: AppConstants.mediumSpacing),
                      _buildLabeledInput(
                          'Investido R\$',
                          Icons.trending_up,
                          perBetInvestedValueController,
                          true,
                          _perBetInvestedValueFocusNode,
                          isPositive),
                      const SizedBox(height: AppConstants.mediumSpacing),
                      _buildLabeledInput(
                          'Comissão R\$',
                          Icons.monetization_on,
                          perBetCommissionController,
                          true,
                          _perBetCommissionFocusNode,
                          isPositive),
                      const SizedBox(height: AppConstants.mediumSpacing),
                      _buildDateInput(),
                      const SizedBox(height: AppConstants.largeSpacing),
                      Center(
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              await _saveTransaction();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppConstants.primaryColor,
                              foregroundColor: AppConstants.white,
                            ),
                            child: Text(
                                widget.isEditing ? 'Atualizar' : 'Confirmar'),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRendimientosPanel() {
    final Color backgroundColor =
        isPositive ? AppConstants.primaryColor : AppConstants.red;
    final IconData thumbIcon = isPositive ? Icons.thumb_up : Icons.thumb_down;
    final String panelTitle = isPositive ? 'Valor Ganho' : 'Valor Perdido';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.defaultPadding,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: Row(
        children: [
          Column(
            children: [
              const Text(
                'Positivo',
                style: TextStyle(fontSize: 12, color: AppConstants.white),
              ),
              IconButton(
                icon: Icon(
                  thumbIcon,
                  color: AppConstants.white,
                  size: 40,
                ),
                onPressed: () {
                  setState(() {
                    isPositive = !isPositive;
                    final raw =
                        valueController.text.replaceAll(RegExp(r'[^0-9]'), '');
                    double parsed = raw.isEmpty ? 0.0 : double.parse(raw) / 100;
                    _value = isPositive ? parsed.abs() : -parsed.abs();
                    valueController.text =
                        currencyFormatter.format(_value.abs());
                  });
                },
              ),
              const Text(
                'Negativo',
                style: TextStyle(fontSize: 12, color: AppConstants.white),
              ),
            ],
          ),
          const SizedBox(width: AppConstants.defaultPadding),
          Expanded(
            child: Column(
              children: [
                Text(
                  panelTitle,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppConstants.white,
                  ),
                ),
                const SizedBox(height: AppConstants.smallSpacing),
                TextField(
                  controller: valueController,
                  focusNode: _valueFocusNode,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.white,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'R\$ 0,00',
                    hintStyle: const TextStyle(color: Colors.white70),
                    fillColor: Colors.transparent,
                    filled: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateInput() {
    return GestureDetector(
      onTap: () => _selectDate(context),
      child: AbsorbPointer(
        child: TextField(
          controller: dateController,
          decoration: const InputDecoration(
            hintText: 'Data',
            prefixIcon: Icon(Icons.calendar_today),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField(String label, List<String> options,
      String? selectedValue, ValueChanged<String?> onChanged,
      {bool enabled = true}) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppConstants.mediumSpacing),
      decoration: BoxDecoration(
        color: enabled ? Colors.grey[100] : Colors.grey[200],
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButton<String>(
        value: selectedValue,
        hint: Text(label.isEmpty ? 'Selecione a conta' : label),
        icon: const Icon(Icons.arrow_drop_down),
        underline: const SizedBox(),
        isExpanded: true,
        onChanged: enabled ? onChanged : null,
        items: options
            .map((opt) => DropdownMenuItem(
                  value: opt,
                  child: Text(opt),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildLabeledInput(
    String label,
    IconData icon,
    TextEditingController controller,
    bool isCurrency, [
    FocusNode? focusNode,
    bool enabled = true,
  ]) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      keyboardType: isCurrency ? TextInputType.number : TextInputType.text,
      inputFormatters: isCurrency
          ? [FilteringTextInputFormatter.digitsOnly]
          : (label == 'Time da Casa' || label == 'Time Visitante')
              ? [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                  TextInputFormatter.withFunction((oldValue, newValue) {
                    return TextEditingValue(
                      text: newValue.text.toUpperCase(),
                      selection: newValue.selection,
                    );
                  }),
                ]
              : null,
      onChanged: isCurrency
          ? (value) {
              String raw = controller.text.replaceAll(RegExp(r'[^0-9]'), '');
              if (raw.isEmpty) raw = '0';
              double parsed = double.parse(raw) / 100;
              controller.text = currencyFormatter.format(parsed);
              controller.selection =
                  TextSelection.collapsed(offset: controller.text.length);
            }
          : null,
      decoration: InputDecoration(
        hintText: label == 'Investido R\$' || label == 'Comissão R\$'
            ? 'R\$ 0,00'
            : label,
        prefixText: null,
        suffixText: label == 'Investido R\$'
            ? 'Investido'
            : label == 'Comissão R\$'
                ? 'Comissão'
                : null,
        suffixStyle: (label == 'Investido R\$' || label == 'Comissão R\$')
            ? const TextStyle(color: Colors.black54)
            : null,
        prefixIcon: Icon(icon, color: AppConstants.textGrey),
      ),
    );
  }

  Future<void> _saveTransaction() async {
    final user = _auth.currentUser;
    if (user == null) {
      print('Usuário não está logado');
      if (mounted) {
        showAppMessage(context, 'Usuário não está logado', isError: true);
      }
      return;
    }

    if (currentTab == 'Por Conta') {
      if (valueController.text.isEmpty) {
        if (mounted) {
          showAppMessage(context, 'Preencha o Valor Ganho/Perdido!',
              isError: true);
        }
        return;
      }
      if (dateController.text.isEmpty) {
        if (mounted) {
          showAppMessage(context, 'Preencha a Data!', isError: true);
        }
        return;
      }
      if (selectedAccount == null) {
        if (mounted) {
          showAppMessage(context, 'Selecione uma Conta!', isError: true);
        }
        return;
      }
      if (selectedBettingHouse == null) {
        if (mounted) {
          showAppMessage(context, 'Selecione uma Casa de Aposta!',
              isError: true);
        }
        return;
      }
      if (isPositive && investedValueController.text.isEmpty) {
        if (mounted) {
          showAppMessage(context, 'Preencha o Valor Investido!', isError: true);
        }
        return;
      }

      String rawValue = valueController.text.replaceAll(RegExp(r'[^0-9]'), '');
      String rawInvested =
          investedValueController.text.replaceAll(RegExp(r'[^0-9]'), '');
      String rawCommission =
          commissionController.text.replaceAll(RegExp(r'[^0-9]'), '');
      double value = rawValue.isEmpty ? 0 : double.parse(rawValue) / 100;
      double invested =
          rawInvested.isEmpty ? 0 : double.parse(rawInvested) / 100;
      double commission =
          rawCommission.isEmpty ? 0 : double.parse(rawCommission) / 100;

      if (isPositive && value <= (invested + commission)) {
        if (mounted) {
          showAppMessage(context,
              'O Valor Ganho não pode ser menor ou igual à soma do Valor Investido e da Comissão!',
              isError: true);
        }
        return;
      }

      try {
        double formattedValue = isPositive ? value.abs() : -value.abs();
        String collection =
            isPositive ? 'positive_transactions' : 'negative_transactions';

        if (widget.isEditing && widget.transactionId != null) {
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection(collection)
              .doc(widget.transactionId)
              .update({
            'value': formattedValue,
            'date': dateController.text,
            'account': selectedAccount,
            'bettingHouse': selectedBettingHouse,
            'investedValue': isPositive ? invested : 0,
            'commission': commission,
            'timestamp': FieldValue.serverTimestamp(),
          });
          print('Transação atualizada com sucesso: ${widget.transactionId}');
          if (mounted) {
            showAppMessage(context, 'Transação atualizada com sucesso!');
          }
        } else {
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection(collection)
              .add({
            'value': formattedValue,
            'date': dateController.text,
            'account': selectedAccount,
            'bettingHouse': selectedBettingHouse,
            'investedValue': isPositive ? invested : 0,
            'commission': commission,
            'timestamp': FieldValue.serverTimestamp(),
          });
          print('Nova transação salva com sucesso para o usuário ${user.uid}');
          if (mounted) {
            showAppMessage(context, 'Transação salva com sucesso!');
          }
        }

        if (widget.onTransactionAdded != null) {
          widget.onTransactionAdded!();
        }
        if (mounted) {
          await _showConfirmationDialog();
        }
      } catch (e) {
        print('Erro ao salvar transação no Firestore: $e');
        if (mounted) {
          showAppMessage(context, 'Erro ao salvar transação: $e',
              isError: true);
        }
      }
    } else if (currentTab == 'Por Aposta') {
      if (homeTeamController.text.isEmpty) {
        if (mounted) {
          showAppMessage(context, 'Preencha o Time da Casa!', isError: true);
        }
        return;
      }
      if (awayTeamController.text.isEmpty) {
        if (mounted) {
          showAppMessage(context, 'Preencha o Time Visitante!', isError: true);
        }
        return;
      }
      if (perBetInvestedValueController.text.isEmpty) {
        if (mounted) {
          showAppMessage(context, 'Preencha o Valor Investido!', isError: true);
        }
        return;
      }
      if (valueController.text.isEmpty) {
        if (mounted) {
          showAppMessage(context, 'Preencha o Valor Ganho/Perdido!',
              isError: true);
        }
        return;
      }
      if (dateController.text.isEmpty) {
        if (mounted) {
          showAppMessage(context, 'Preencha a Data!', isError: true);
        }
        return;
      }

      String rawValue = valueController.text.replaceAll(RegExp(r'[^0-9]'), '');
      String rawInvested =
          perBetInvestedValueController.text.replaceAll(RegExp(r'[^0-9]'), '');
      String rawCommission =
          perBetCommissionController.text.replaceAll(RegExp(r'[^0-9]'), '');
      double value = rawValue.isEmpty ? 0 : double.parse(rawValue) / 100;
      double invested =
          rawInvested.isEmpty ? 0 : double.parse(rawInvested) / 100;
      double commission =
          rawCommission.isEmpty ? 0 : double.parse(rawCommission) / 100;

      if (isPositive && value <= (invested + commission)) {
        if (mounted) {
          showAppMessage(context,
              'O Valor Ganho não pode ser menor ou igual à soma do Valor Investido e da Comissão!',
              isError: true);
        }
        return;
      }

      try {
        double formattedValue = isPositive ? value : -value;

        if (widget.isEditing && widget.transactionId != null) {
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('per_bet')
              .doc(widget.transactionId)
              .update({
            'homeTeam': homeTeamController.text,
            'awayTeam': awayTeamController.text,
            'investedValue': invested,
            'gainedValue': formattedValue,
            'commission': commission,
            'date': dateController.text,
            'timestamp': FieldValue.serverTimestamp(),
          });
          print(
              'Transação "Por Aposta" atualizada com sucesso: ${widget.transactionId}');
          if (mounted) {
            showAppMessage(context, 'Transação atualizada com sucesso!');
          }
        } else {
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('per_bet')
              .add({
            'homeTeam': homeTeamController.text,
            'awayTeam': awayTeamController.text,
            'investedValue': invested,
            'gainedValue': formattedValue,
            'commission': commission,
            'date': dateController.text,
            'timestamp': FieldValue.serverTimestamp(),
          });
          print(
              'Nova transação "Por Aposta" salva com sucesso para o usuário ${user.uid}');
          if (mounted) {
            showAppMessage(context, 'Transação salva com sucesso!');
          }
        }

        if (widget.onTransactionAdded != null) {
          widget.onTransactionAdded!();
        }
        // Não exibir diálogo de confirmação para "Por Aposta", apenas limpar os campos
        _clearFields();
      } catch (e) {
        print('Erro ao salvar transação no Firestore: $e');
        if (mounted) {
          showAppMessage(context, 'Erro ao salvar transação: $e',
              isError: true);
        }
      }
    }
  }
}
