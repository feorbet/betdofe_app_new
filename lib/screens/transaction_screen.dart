import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter/services.dart';

class TransactionScreen extends StatefulWidget {
  const TransactionScreen({super.key});

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final Color primaryColor = const Color(0xFF1B5E20);
  final Color lightGreen = const Color(0xFF2E7D32);

  String currentTab = 'Por Conta'; // Aba inicial
  bool isPositive = true;

  // Controladores para "Por Conta" e "Por Aposta"
  final TextEditingController valueController = TextEditingController();
  final TextEditingController investedValueController = TextEditingController();
  final TextEditingController dateController = TextEditingController();

  // Controladores para "Por Aposta"
  final TextEditingController homeTeamController = TextEditingController();
  final TextEditingController awayTeamController = TextEditingController();
  final TextEditingController oddController = TextEditingController();
  final TextEditingController perBetInvestedValueController =
      TextEditingController();

  String? selectedAccount;
  String? selectedBettingHouse;

  final FocusNode _valueFocusNode = FocusNode();
  final FocusNode _investedValueFocusNode = FocusNode();
  final FocusNode _perBetInvestedValueFocusNode = FocusNode();

  List<String> accounts = [];
  List<String> bettingHouses = [];

  double _value = 0.0;

  final currencyFormatter =
      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  @override
  void initState() {
    super.initState();

    dateController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
    valueController.text = currencyFormatter.format(0);
    investedValueController.text = currencyFormatter.format(0);
    perBetInvestedValueController.text = currencyFormatter.format(0);

    // Carregar contas ativas do Firestore para "Por Conta"
    _loadActiveAccounts();

    // Listeners para "Por Conta" e "Por Aposta"
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_valueFocusNode);
    });

    _valueFocusNode.addListener(() {
      if (!_valueFocusNode.hasFocus) {
        String raw = valueController.text.replaceAll(RegExp(r'[^0-9]'), '');
        if (raw.isEmpty) raw = '0';
        double parsed = double.parse(raw) / 100;
        _value = isPositive ? parsed.abs() : -parsed.abs();
        valueController.text = currencyFormatter.format(_value);
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

    _perBetInvestedValueFocusNode.addListener(() {
      if (!_perBetInvestedValueFocusNode.hasFocus) {
        String raw = perBetInvestedValueController.text
            .replaceAll(RegExp(r'[^0-9]'), '');
        if (raw.isEmpty) raw = '0';
        double parsed = double.parse(raw) / 100;
        perBetInvestedValueController.text = currencyFormatter.format(parsed);
      }
    });
  }

  // Carregar contas ativas do Firestore
  Future<void> _loadActiveAccounts() async {
    final snapshot = await _firestore
        .collection('accounts')
        .where('status', isEqualTo: 'Ativo')
        .get();
    setState(() {
      accounts = snapshot.docs.map((doc) => doc['name'] as String).toList();
    });
  }

  // Carregar casas de aposta associadas à conta selecionada
  Future<void> _loadBettingHousesForAccount(String accountName) async {
    final snapshot = await _firestore
        .collection('accounts')
        .where('name', isEqualTo: accountName)
        .get();
    if (snapshot.docs.isNotEmpty) {
      final accountData = snapshot.docs.first.data();
      final bettingHouse = accountData['bettingHouse'] as String?;
      setState(() {
        bettingHouses = bettingHouse != null ? [bettingHouse] : [];
        selectedBettingHouse =
            bettingHouses.isNotEmpty ? bettingHouses[0] : null;
      });
    } else {
      setState(() {
        bettingHouses = [];
        selectedBettingHouse = null;
      });
    }
  }

  @override
  void dispose() {
    _valueFocusNode.dispose();
    _investedValueFocusNode.dispose();
    _perBetInvestedValueFocusNode.dispose();
    valueController.dispose();
    investedValueController.dispose();
    dateController.dispose();
    homeTeamController.dispose();
    awayTeamController.dispose();
    oddController.dispose();
    perBetInvestedValueController.dispose();
    super.dispose();
  }

  void _showTab(String tab) {
    setState(() {
      currentTab = tab;
    });
  }

  void _selectDate(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
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
                color: Colors.green,
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

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    final waveHeight = screenHeight * 0.3;
    final panelTopPosition = screenHeight * 0.17;
    final fieldsPaddingTop = screenHeight * 0.35;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          ClipPath(
            clipper: TopCurveClipper(),
            child: Container(
              height: waveHeight,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [lightGreen, primaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          Positioned(
            top: screenHeight * 0.06,
            left: 0,
            right: 0,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildTabButton('Por Conta'),
                  _buildTabButton('Por Aposta'),
                ],
              ),
            ),
          ),
          // Painel de rendimentos agora aparece em ambas as abas
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
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (currentTab == 'Por Conta') ...[
                    _buildDropdownField('Conta', accounts, selectedAccount,
                        (value) {
                      setState(() {
                        selectedAccount = value;
                        if (value != null) {
                          _loadBettingHousesForAccount(value);
                        }
                      });
                    }),
                    SizedBox(height: screenHeight * 0.02),
                    _buildDropdownField(
                        'Casa de Aposta', bettingHouses, selectedBettingHouse,
                        (value) {
                      setState(() {
                        selectedBettingHouse = value;
                      });
                    }),
                    SizedBox(height: screenHeight * 0.02),
                    _buildLabeledInput(
                      'Valor Investido',
                      Icons.trending_up,
                      investedValueController,
                      true,
                      _investedValueFocusNode,
                      isPositive,
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    _buildDateInput(),
                    SizedBox(height: screenHeight * 0.04),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildCircleButton(Icons.check, Colors.green, () async {
                          if (valueController.text.isNotEmpty &&
                              dateController.text.isNotEmpty) {
                            String rawText = valueController.text
                                .replaceAll(RegExp(r'[^0-9]'), '');
                            if (rawText.isEmpty) rawText = '0';
                            double value = double.parse(rawText) / 100;
                            double formattedValue =
                                isPositive ? value.abs() : -value.abs();

                            String investedText = investedValueController.text
                                .replaceAll(RegExp(r'[^0-9]'), '');
                            if (investedText.isEmpty) investedText = '0';
                            double invested = double.parse(investedText) / 100;

                            // Exibir caixa de diálogo para "Por Conta"
                            bool? isAccountActive = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('A conta encontra-se Ativa?'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text('SIM'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('NÃO'),
                                  ),
                                ],
                              ),
                            );

                            if (isAccountActive == false &&
                                selectedAccount != null) {
                              final accountSnapshot = await _firestore
                                  .collection('accounts')
                                  .where('name', isEqualTo: selectedAccount)
                                  .get();
                              if (accountSnapshot.docs.isNotEmpty) {
                                await _firestore
                                    .collection('accounts')
                                    .doc(accountSnapshot.docs.first.id)
                                    .update({'status': 'Inativo'});
                              }
                            }

                            await _firestore.collection('transactions').add({
                              'value': formattedValue,
                              'date': dateController.text,
                              'account': selectedAccount,
                              'bettingHouse': selectedBettingHouse,
                              'investedValue': invested,
                              'timestamp': FieldValue.serverTimestamp(),
                            });
                            if (!mounted) return;
                            Navigator.pop(context);
                          }
                        }),
                        _buildCircleButton(Icons.close, Colors.red, () {
                          Navigator.pop(context);
                        }),
                      ],
                    ),
                  ],
                  if (currentTab == 'Por Aposta') ...[
                    _buildLabeledInput('Time da Casa', Icons.sports_soccer,
                        homeTeamController, false, null, true),
                    const SizedBox(height: 16),
                    _buildLabeledInput('Time Visitante', Icons.sports_soccer,
                        awayTeamController, false, null, true),
                    const SizedBox(height: 16),
                    _buildLabeledInput(
                        'Odd', Icons.numbers, oddController, false, null, true),
                    const SizedBox(height: 16),
                    _buildLabeledInput(
                        'Valor Investido',
                        Icons.trending_up,
                        perBetInvestedValueController,
                        true,
                        _perBetInvestedValueFocusNode,
                        isPositive),
                    const SizedBox(height: 16),
                    _buildDateInput(),
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildCircleButton(Icons.check, Colors.green, () async {
                          if (homeTeamController.text.isNotEmpty &&
                              awayTeamController.text.isNotEmpty &&
                              oddController.text.isNotEmpty &&
                              perBetInvestedValueController.text.isNotEmpty) {
                            String rawText = valueController.text
                                .replaceAll(RegExp(r'[^0-9]'), '');
                            if (rawText.isEmpty) rawText = '0';
                            double value = double.parse(rawText) / 100;
                            double formattedValue =
                                isPositive ? value.abs() : -value.abs();

                            String investedRaw = perBetInvestedValueController
                                .text
                                .replaceAll(RegExp(r'[^0-9]'), '');
                            if (investedRaw.isEmpty) investedRaw = '0';
                            double invested = double.parse(investedRaw) / 100;

                            await _firestore.collection('per_bet').add({
                              'homeTeam': homeTeamController.text,
                              'awayTeam': awayTeamController.text,
                              'odd': double.parse(oddController.text),
                              'investedValue': invested,
                              'gainedValue': formattedValue,
                              'date': dateController.text,
                              'timestamp': FieldValue.serverTimestamp(),
                            });
                            if (!mounted) return;
                            Navigator.pop(context);
                          }
                        }),
                        _buildCircleButton(Icons.close, Colors.red, () {
                          Navigator.pop(context);
                        }),
                      ],
                    ),
                  ],
                  SizedBox(height: screenHeight * 0.1),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

// Botões das abas
  Widget _buildTabButton(String label) {
    final bool isSelected = currentTab == label;
    return GestureDetector(
      onTap: () => _showTab(label),
      child: Padding(
        padding: const EdgeInsets.only(
            bottom: 12.0), // Aumentando o espaço abaixo do texto
        child: Transform.translate(
          offset: const Offset(0, 0), // Ajuste fino, se necessário
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white70,
              fontWeight: FontWeight.bold,
              fontSize: 16,
              decoration: isSelected ? TextDecoration.underline : null,
              decorationColor: isSelected ? Colors.white : null,
              decorationThickness: isSelected ? 2.0 : null,
              decorationStyle: isSelected ? TextDecorationStyle.solid : null,
              shadows: isSelected
                  ? [
                      const Shadow(
                        color: Colors.white,
                        blurRadius: 4.0,
                        offset: Offset(0, 0),
                      ),
                    ]
                  : null,
            ),
            textAlign: TextAlign.center,
            strutStyle: const StrutStyle(
              height: 2.0,
            ),
          ),
        ),
      ),
    );
  }

  // Painel de Rendimientos com botão de Joinha e valor em moeda
  Widget _buildRendimientosPanel() {
    final Color backgroundColor = isPositive ? primaryColor : Colors.red;
    final IconData thumbIcon = isPositive ? Icons.thumb_up : Icons.thumb_down;
    final String panelTitle = isPositive ? 'Valor Ganho' : 'Valor Perdido';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            children: [
              const Text('Positivo',
                  style: TextStyle(fontSize: 12, color: Colors.white)),
              IconButton(
                icon: Icon(thumbIcon, color: Colors.white, size: 40),
                onPressed: () {
                  setState(() {
                    isPositive = !isPositive;
                    final raw =
                        valueController.text.replaceAll(RegExp(r'[^0-9]'), '');
                    double parsed = raw.isEmpty ? 0.0 : double.parse(raw) / 100;
                    _value = isPositive ? parsed.abs() : -parsed.abs();
                    valueController.text = currencyFormatter.format(_value);
                  });
                },
              ),
              const Text('Negativo',
                  style: TextStyle(fontSize: 12, color: Colors.white)),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              children: [
                Text(
                  panelTitle,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: valueController,
                  focusNode: _valueFocusNode,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'R\$ 0,00',
                    hintStyle: TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Campo de seleção de data com botão de calendário
  Widget _buildDateInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Data', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _selectDate(context),
          child: AbsorbPointer(
            child: TextField(
              controller: dateController,
              decoration: InputDecoration(
                hintText: 'Hoje',
                prefixIcon: const Icon(Icons.calendar_today),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Dropdown de seleção (Conta / Casa de Aposta / etc.)
  Widget _buildDropdownField(String label, List<String> options,
      String? selectedValue, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButton<String>(
            value: selectedValue,
            hint: Text('Selecione $label'),
            icon: const Icon(Icons.arrow_drop_down),
            underline: const SizedBox(),
            isExpanded: true,
            onChanged: onChanged,
            items: options
                .map((opt) => DropdownMenuItem(
                      value: opt,
                      child: Text(opt),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }

  // Botões redondos (Confirmar / Cancelar)
  Widget _buildCircleButton(
      IconData icon, Color color, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: onPressed,
      ),
    );
  }

  // Campo de entrada genérico (nome, senha, etc.) com ícone
  Widget _buildLabeledInput(
    String label,
    IconData icon,
    TextEditingController controller,
    bool isCurrency, [
    FocusNode? focusNode,
    bool enabled = true,
  ]) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          focusNode: focusNode,
          enabled: enabled,
          keyboardType: isCurrency ? TextInputType.number : TextInputType.text,
          inputFormatters:
              isCurrency ? [FilteringTextInputFormatter.digitsOnly] : null,
          onChanged: isCurrency
              ? (value) {
                  String raw =
                      controller.text.replaceAll(RegExp(r'[^0-9]'), '');
                  if (raw.isEmpty) raw = '0';
                  double parsed = double.parse(raw) / 100;
                  controller.text = currencyFormatter.format(parsed);
                  controller.selection =
                      TextSelection.collapsed(offset: controller.text.length);
                }
              : null,
          decoration: InputDecoration(
            hintText: isCurrency ? 'R\$ 0,00' : label,
            prefixIcon: Icon(icon),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            filled: true,
            fillColor: Colors.grey[100],
          ),
        ),
      ],
    );
  }
}

// Curva personalizada para o cabeçalho
class TopCurveClipper extends CustomClipper<Path> {
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
