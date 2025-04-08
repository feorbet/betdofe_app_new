import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class AccountRegisterScreen extends StatefulWidget {
  const AccountRegisterScreen({super.key});

  @override
  State<AccountRegisterScreen> createState() => _AccountRegisterScreenState();
}

class _AccountRegisterScreenState extends State<AccountRegisterScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController bettingHouseController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController pixKeyController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController whatsappController = TextEditingController();

  final Color primaryColor = const Color(0xFF1B5E20);

  String? selectedBettingHouse;
  List<String> bettingHouses = [];
  String status = 'Ativa';
  String filterStatus = 'Todas';
  String? _editingDocId;

  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    dateController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
    _loadBettingHouses();
  }

  @override
  void dispose() {
    nameController.dispose();
    bettingHouseController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    pixKeyController.dispose();
    dateController.dispose();
    whatsappController.dispose();
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _loadBettingHouses() async {
    final snapshot = await _firestore.collection('bettingHouses').get();
    setState(() {
      bettingHouses = snapshot.docs
          .map((doc) => doc['bettingHouseName'] as String)
          .toList();
      if (bettingHouses.isNotEmpty) selectedBettingHouse = bettingHouses.first;
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

  // Função para limpar os campos manualmente
  void _clearFields() {
    setState(() {
      nameController.clear();
      bettingHouseController.clear();
      usernameController.clear();
      passwordController.clear();
      pixKeyController.clear();
      whatsappController.clear();
      dateController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
      selectedBettingHouse =
          bettingHouses.isNotEmpty ? bettingHouses.first : null;
      status = 'Ativa';
    });
  }

  // Função para excluir uma conta
  Future<void> _deleteAccount(String docId) async {
    try {
      await _firestore.collection('accounts').doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Conta excluída com sucesso!')),
      );
    } catch (e) {
      print('Erro ao excluir conta: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao excluir conta: $e')),
      );
    }
  }

  // Função para carregar os dados para edição
  void _editAccount(String docId, Map<String, dynamic> data) {
    setState(() {
      _editingDocId = docId;
      nameController.text = data['name'] ?? '';
      bettingHouseController.text = data['bettingHouse'] ?? '';
      usernameController.text = data['username'] ?? '';
      passwordController.text = data['password'] ?? '';
      pixKeyController.text = data['pixKey'] ?? '';
      whatsappController.text = data['whatsapp'] ?? '';
      dateController.text =
          data['date'] ?? DateFormat('dd/MM/yyyy').format(DateTime.now());
      selectedBettingHouse = data['bettingHouse'] ??
          (bettingHouses.isNotEmpty ? bettingHouses.first : null);
      status = data['status'] ?? 'Ativa';
      if (_tabController != null) {
        _tabController!.index = 0; // Voltar para a aba "Cadastro"
      }
    });
  }

  // Função para abrir o WhatsApp
  Future<void> _openWhatsApp(String phoneNumber) async {
    final url = Uri.parse('https://wa.me/$phoneNumber');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Não foi possível abrir o WhatsApp. Verifique se o aplicativo está instalado.')),
        );
      }
    } catch (e) {
      print('Erro ao abrir WhatsApp: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao abrir o WhatsApp')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Cadastrar Contas',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        bottom: _tabController != null
            ? TabBar(
                controller: _tabController,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                indicatorColor: Colors.white,
                tabs: const [
                  Tab(text: 'Cadastro'),
                  Tab(text: 'Lista de Contas'),
                ],
              )
            : null,
      ),
      body: _tabController != null
          ? TabBarView(
              controller: _tabController,
              children: [
                // Aba "Cadastro"
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabeledInput('Nome', Icons.person, nameController),
                      const SizedBox(height: 12),
                      _buildDropdownField(
                          'Casa de Aposta', bettingHouses, selectedBettingHouse,
                          (value) {
                        setState(() {
                          selectedBettingHouse = value;
                        });
                      }),
                      const SizedBox(height: 12),
                      _buildLabeledInput(
                          'Usuário', Icons.account_circle, usernameController),
                      const SizedBox(height: 12),
                      _buildLabeledInput(
                          'Senha', Icons.lock, passwordController),
                      const SizedBox(height: 12),
                      _buildLabeledInput(
                          'Chave Pix', Icons.vpn_key, pixKeyController),
                      const SizedBox(height: 12),
                      _buildLabeledInput(
                          'WhatsApp', Icons.phone, whatsappController,
                          isPhone: true),
                      const SizedBox(height: 12),
                      _buildDateInput(),
                      const SizedBox(height: 12),
                      _buildDropdownField(
                          'Status', ['Ativa', 'Inativa', 'Espera'], status,
                          (value) {
                        setState(() {
                          status = value!;
                        });
                      }),
                      const SizedBox(height: 25),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildCircleButton(Icons.check, Colors.green,
                              () async {
                            final user = _auth.currentUser;
                            if (user == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Usuário não autenticado!')),
                              );
                              return;
                            }

                            final name = nameController.text.trim();
                            final username = usernameController.text.trim();
                            final password = passwordController.text.trim();
                            final pixKey = pixKeyController.text.trim();
                            final whatsapp = whatsappController.text.trim();
                            final date = dateController.text;

                            if (name.isEmpty ||
                                selectedBettingHouse == null ||
                                username.isEmpty ||
                                password.isEmpty ||
                                pixKey.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Preencha todos os campos obrigatórios!')),
                              );
                              return;
                            }

                            if (whatsapp.isNotEmpty &&
                                !whatsapp.startsWith('+')) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'O número de WhatsApp deve estar no formato internacional (ex.: +5511999999999)')),
                              );
                              return;
                            }

                            try {
                              if (_editingDocId == null) {
                                // Modo de cadastro (adicionar novo)
                                await _firestore.collection('accounts').add({
                                  'name': name,
                                  'bettingHouse': selectedBettingHouse,
                                  'username': username,
                                  'password': password,
                                  'pixKey': pixKey,
                                  'whatsapp': whatsapp,
                                  'date': date,
                                  'status': status,
                                  'userId': user.uid,
                                  'timestamp': FieldValue.serverTimestamp(),
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Conta cadastrada com sucesso!')),
                                );
                                // Limpar os campos após o cadastro bem-sucedido
                                _clearFields();
                              } else {
                                // Modo de edição (atualizar existente)
                                await _firestore
                                    .collection('accounts')
                                    .doc(_editingDocId)
                                    .update({
                                  'name': name,
                                  'bettingHouse': selectedBettingHouse,
                                  'username': username,
                                  'password': password,
                                  'pixKey': pixKey,
                                  'whatsapp': whatsapp,
                                  'date': date,
                                  'status': status,
                                  'userId': user.uid,
                                  'timestamp': FieldValue.serverTimestamp(),
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Conta atualizada com sucesso!')),
                                );
                                _editingDocId = null;
                                _clearFields();
                              }
                            } catch (e) {
                              print('Erro ao salvar conta: $e');
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text('Erro ao salvar conta: $e')),
                              );
                            }
                          }),
                          const SizedBox(width: 20),
                          _buildCircleButton(
                              Icons.refresh, Colors.grey, _clearFields),
                          const SizedBox(width: 20),
                          _buildCircleButton(Icons.close, Colors.red, () {
                            Navigator.pop(context);
                          }),
                        ],
                      ),
                    ],
                  ),
                ),
                // Aba "Lista de Contas"
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDropdownField(
                          'Filtrar por Status',
                          ['Todas', 'Ativa', 'Inativa', 'Espera'],
                          filterStatus, (value) {
                        setState(() {
                          filterStatus = value!;
                        });
                      }),
                      const SizedBox(height: 10),
                      StreamBuilder<QuerySnapshot>(
                        stream: _firestore
                            .collection('accounts')
                            .orderBy('timestamp', descending: true)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          final accounts = snapshot.data!.docs;
                          final filteredAccounts = filterStatus == 'Todas'
                              ? accounts
                              : accounts
                                  .where((doc) =>
                                      (doc.data()
                                          as Map<String, dynamic>)['status'] ==
                                      filterStatus)
                                  .toList();
                          if (filteredAccounts.isEmpty) {
                            return const Center(
                                child: Text('Nenhuma conta encontrada.'));
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total de Contas: ${filteredAccounts.length}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: filteredAccounts.length,
                                itemBuilder: (context, index) {
                                  final data = filteredAccounts[index].data()
                                      as Map<String, dynamic>;
                                  final docId = filteredAccounts[index].id;
                                  final accountName =
                                      data['name'] ?? 'Sem nome';
                                  final bettingHouse = data['bettingHouse'] ??
                                      'Sem casa de aposta';
                                  final accountStatus =
                                      data['status'] ?? 'Ativa';
                                  final whatsapp =
                                      data['whatsapp'] ?? 'Não informado';
                                  return Dismissible(
                                    key: Key(docId),
                                    background: Container(
                                      color: Colors.green,
                                      alignment: Alignment.centerLeft,
                                      padding: const EdgeInsets.only(left: 20),
                                      child: const Icon(Icons.edit,
                                          color: Colors.white),
                                    ),
                                    secondaryBackground: Container(
                                      color: Colors.red,
                                      alignment: Alignment.centerRight,
                                      padding: const EdgeInsets.only(right: 20),
                                      child: const Icon(Icons.delete,
                                          color: Colors.white),
                                    ),
                                    onDismissed: (direction) {
                                      if (direction ==
                                          DismissDirection.endToStart) {
                                        _deleteAccount(docId);
                                      }
                                    },
                                    confirmDismiss: (direction) async {
                                      if (direction ==
                                          DismissDirection.startToEnd) {
                                        _editAccount(docId, data);
                                        return false;
                                      } else {
                                        return await showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text(
                                                'Confirmar Exclusão'),
                                            content: Text(
                                                'Deseja excluir a conta "$accountName"?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(
                                                    context, false),
                                                child: const Text('Cancelar'),
                                              ),
                                              TextButton(
                                                onPressed: () => Navigator.pop(
                                                    context, true),
                                                child: const Text('Excluir'),
                                              ),
                                            ],
                                          ),
                                        );
                                      }
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(
                                          vertical: 4),
                                      padding: const EdgeInsets.all(8),
                                      color: index % 2 == 0
                                          ? Colors.grey[100]
                                          : Colors.white,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                accountName,
                                                style: const TextStyle(
                                                    fontSize: 12),
                                              ),
                                              Text(
                                                'Casa: $bettingHouse',
                                                style: const TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.grey),
                                              ),
                                              GestureDetector(
                                                onTap: () {
                                                  if (whatsapp !=
                                                      'Não informado') {
                                                    _openWhatsApp(whatsapp);
                                                  }
                                                },
                                                child: Text(
                                                  'WhatsApp: $whatsapp',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: whatsapp !=
                                                            'Não informado'
                                                        ? Colors.blue
                                                        : Colors.grey,
                                                    decoration: whatsapp !=
                                                            'Não informado'
                                                        ? TextDecoration
                                                            .underline
                                                        : null,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          Text(
                                            accountStatus,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: accountStatus == 'Ativa'
                                                  ? Colors.green
                                                  : accountStatus == 'Inativa'
                                                      ? Colors.red
                                                      : Colors.orange,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildLabeledInput(
    String label,
    IconData icon,
    TextEditingController controller, {
    bool isPhone = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 45,
          child: TextField(
            controller: controller,
            keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
            inputFormatters: label == 'Nome'
                ? [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                    TextInputFormatter.withFunction((oldValue, newValue) {
                      return TextEditingValue(
                        text: newValue.text.toUpperCase(),
                        selection: newValue.selection,
                      );
                    }),
                  ]
                : isPhone
                    ? [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
                      ]
                    : null,
            decoration: InputDecoration(
              hintText: label == 'Casa de Aposta'
                  ? 'Digite a casa de aposta'
                  : label == 'WhatsApp'
                      ? '+5511999999999'
                      : label,
              hintStyle: const TextStyle(fontSize: 14),
              prefixIcon: Icon(icon, size: 20),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 12,
                horizontal: 12,
              ),
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
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildDateInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Data',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 45,
          child: GestureDetector(
            onTap: () => _selectDate(context),
            child: AbsorbPointer(
              child: TextField(
                controller: dateController,
                decoration: InputDecoration(
                  hintText: 'Hoje',
                  hintStyle: const TextStyle(fontSize: 14),
                  prefixIcon: const Icon(Icons.calendar_today, size: 20),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 12,
                  ),
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
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField(String label, List<String> options,
      String? selectedValue, ValueChanged<String?> onChanged) {
    String? validSelectedValue =
        selectedValue != null && options.contains(selectedValue)
            ? selectedValue
            : options.isNotEmpty
                ? options.first
                : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 45,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: DropdownButton<String>(
              value: validSelectedValue,
              hint: Text(
                'Selecione $label',
                style: const TextStyle(fontSize: 14),
              ),
              icon: const Icon(Icons.arrow_drop_down, size: 24),
              underline: const SizedBox(),
              isExpanded: true,
              onChanged: onChanged,
              items: options
                  .map((opt) => DropdownMenuItem(
                        value: opt,
                        child: Text(
                          opt,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCircleButton(
      IconData icon, Color color, VoidCallback onPressed) {
    return Container(
      width: 45,
      height: 45,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 24),
        onPressed: onPressed,
      ),
    );
  }
}
