import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:betdofe_app_new/core/widgets/MainScaffold.dart';
import 'package:betdofe_app_new/constants.dart';
import 'package:betdofe_app_new/utils/utils.dart'; // Importação adicionada

class AccountManagementScreen extends StatefulWidget {
  const AccountManagementScreen({super.key});

  @override
  State<AccountManagementScreen> createState() =>
      _AccountManagementScreenState();
}

class _AccountManagementScreenState extends State<AccountManagementScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController pixKeyController = TextEditingController();
  final TextEditingController whatsappController = TextEditingController();
  final TextEditingController searchController = TextEditingController();
  final TextEditingController bettingHouseController = TextEditingController();
  Color selectedColor = AppConstants.textGrey;

  String? selectedBettingHouse;
  List<String> bettingHouses = [];
  String? status;
  final String _whatsappPrefix = '+55';
  String filterStatus = 'Todas';
  List<String> selectedBettingHouses = [];
  String? _editingDocId;
  String searchQuery = '';
  String? filterColor;
  List<String> availableColors = ['Todas'];

  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadBettingHouses();
    status = null;
    selectedBettingHouses = [];

    searchController.addListener(() {
      setState(() {
        searchQuery = searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    pixKeyController.dispose();
    whatsappController.dispose();
    bettingHouseController.dispose();
    searchController.dispose();
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _loadBettingHouses() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('betting_houses')
          .get();
      setState(() {
        bettingHouses = snapshot.docs
            .map((doc) => doc['bettingHouseName']?.toString() ?? 'Sem Nome')
            .toList();
        selectedBettingHouse = null;
        status = null;
      });
    } catch (e) {
      print('Erro ao carregar casas de aposta: $e');
      showAppMessage(context, 'Erro ao carregar casas de aposta: $e',
          isError: true);
    }
  }

  void _clearFields() {
    nameController.clear();
    usernameController.clear();
    passwordController.clear();
    pixKeyController.clear();
    whatsappController.clear();
    bettingHouseController.clear();
    selectedBettingHouse = null;
    status = null;
    selectedColor = AppConstants.textGrey;
    _editingDocId = null;
  }

  Future<void> _deleteAccount(String docId) async {
    final user = _auth.currentUser;
    if (user == null) {
      showAppMessage(context, 'Usuário não autenticado!', isError: true);
      return;
    }

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('accounts')
          .doc(docId)
          .delete();
      showAppMessage(context, 'Conta excluída com sucesso!');
    } catch (e) {
      print('Erro ao excluir conta: $e');
      showAppMessage(context, 'Erro ao excluir conta: $e', isError: true);
    }
  }

  Future<void> _deleteBettingHouse(String docId) async {
    final user = _auth.currentUser;
    if (user == null) {
      showAppMessage(context, 'Usuário não autenticado!', isError: true);
      return;
    }

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('betting_houses')
          .doc(docId)
          .delete();
      showAppMessage(context, 'Casa de aposta excluída com sucesso!');
      await _loadBettingHouses();
    } catch (e) {
      print('Erro ao excluir casa de aposta: $e');
      showAppMessage(context, 'Erro ao excluir casa de aposta: $e',
          isError: true);
    }
  }

  void _editAccount(String docId, Map<String, dynamic> data) {
    setState(() {
      _editingDocId = docId;
      nameController.text = data['name'] ?? '';
      usernameController.text = data['username'] ?? '';
      passwordController.text = data['password'] ?? '';
      pixKeyController.text = data['pixKey'] ?? '';
      String whatsapp = data['whatsapp'] ?? '';
      if (whatsapp.startsWith(_whatsappPrefix)) {
        whatsapp = whatsapp.substring(_whatsappPrefix.length);
      }
      whatsappController.text = whatsapp;
      selectedBettingHouse = data['bettingHouse'] ??
          (bettingHouses.isNotEmpty ? bettingHouses.first : null);
      status = data['status'];
      if (_tabController != null) {
        _tabController!.animateTo(0);
      }
    });
  }

  void _editBettingHouse(String docId, Map<String, dynamic> data) {
    setState(() {
      _editingDocId = docId;
      bettingHouseController.text = data['bettingHouseName'] ?? '';
      selectedColor = data['color'] != null
          ? _parseColor(data['color'])
          : AppConstants.textGrey;
      if (_tabController != null) {
        _tabController!.animateTo(1);
      }
    });
  }

  Future<void> _openWhatsApp(String phoneNumber) async {
    final cleanPhoneNumber = phoneNumber.replaceAll(RegExp(r'\s+'), '');
    final url = Uri.parse('https://wa.me/$cleanPhoneNumber');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
      } else {
        showAppMessage(context,
            'Não foi possível abrir o WhatsApp. Verifique se o aplicativo está instalado.',
            isError: true);
      }
    } catch (e) {
      print('Erro ao abrir WhatsApp: $e');
      showAppMessage(context, 'Erro ao abrir o WhatsApp. Tente novamente.',
          isError: true);
    }
  }

  void _showAccountDetails(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppConstants.primaryColor,
        title: const Text(
          'Prévia da Conta',
          style: TextStyle(color: AppConstants.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCopyableField('Nome', data['name'] ?? 'Não informado'),
              const SizedBox(height: AppConstants.smallSpacing),
              _buildCopyableField(
                  'Casa de Aposta', data['bettingHouse'] ?? 'Não informado'),
              const SizedBox(height: AppConstants.smallSpacing),
              _buildCopyableField(
                  'Usuário', data['username'] ?? 'Não informado'),
              const SizedBox(height: AppConstants.smallSpacing),
              _buildCopyableField('Senha', data['password'] ?? 'Não informado'),
              const SizedBox(height: AppConstants.smallSpacing),
              _buildCopyableField(
                  'Chave Pix', data['pixKey'] ?? 'Não informado'),
              const SizedBox(height: AppConstants.smallSpacing),
              _buildCopyableField(
                  'WhatsApp', data['whatsapp'] ?? 'Não informado'),
              const SizedBox(height: AppConstants.smallSpacing),
              _buildCopyableField('Status', data['status'] ?? 'Não informado'),
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

  Widget _buildCopyableField(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$label: $value',
          style: const TextStyle(color: AppConstants.white),
        ),
        IconButton(
          icon: const Icon(Icons.copy, color: AppConstants.white, size: 20),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: value));
            showAppMessage(context, 'Copiado para a área de transferência!');
          },
        ),
      ],
    );
  }

  void _pickColor(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Selecione uma Cor'),
          content: SingleChildScrollView(
            child: BlockPicker(
              pickerColor: selectedColor,
              onColorChanged: (color) {
                setState(() {
                  selectedColor = color;
                });
              },
              availableColors: const [
                Colors.red,
                Colors.pink,
                Colors.purple,
                Colors.deepPurple,
                Colors.indigo,
                Colors.blue,
                Colors.lightBlue,
                Colors.cyan,
                Colors.teal,
                Colors.green,
                Colors.lightGreen,
                Colors.lime,
                Colors.yellow,
                Colors.amber,
                Colors.orange,
                Colors.deepOrange,
                Colors.brown,
                Colors.grey,
                Colors.blueGrey,
                Colors.black,
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );
  }

  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2, 8).toUpperCase()}';
  }

  Color _parseColor(dynamic colorValue) {
    try {
      if (colorValue is String) {
        return Color(int.parse(colorValue.replaceFirst('#', '0xFF')));
      } else if (colorValue is int) {
        return Color(colorValue);
      }
      return AppConstants.textGrey;
    } catch (e) {
      print('Erro ao converter a cor: $e');
      return AppConstants.textGrey;
    }
  }

  void _showBettingHousesFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        List<String> tempSelectedHouses = List.from(selectedBettingHouses);
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppConstants.primaryColor,
              title: const Text(
                'Filtrar Casas de Aposta',
                style: TextStyle(color: AppConstants.white),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: bettingHouses.map((house) {
                    return CheckboxListTile(
                      title: Text(
                        house,
                        style: const TextStyle(color: AppConstants.white),
                      ),
                      value: tempSelectedHouses.contains(house),
                      onChanged: (bool? value) {
                        setDialogState(() {
                          if (value == true) {
                            tempSelectedHouses.add(house);
                          } else {
                            tempSelectedHouses.remove(house);
                          }
                        });
                      },
                      activeColor: AppConstants.white,
                      checkColor: AppConstants.primaryColor,
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(color: AppConstants.white),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      selectedBettingHouses = tempSelectedHouses;
                    });
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Aplicar',
                    style: TextStyle(color: AppConstants.white),
                  ),
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
    return MainScaffold(
      selectedIndex: 2,
      appBar: AppBar(
        title: const Text(
          'Contas',
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
        bottom: _tabController != null
            ? TabBar(
                controller: _tabController,
                labelColor: AppConstants.white,
                unselectedLabelColor: Colors.white70,
                indicatorColor: AppConstants.white,
                tabs: const [
                  Tab(text: 'Cadastro'),
                  Tab(text: 'Consulta'),
                  Tab(text: 'Casas'),
                ],
              )
            : null,
      ),
      body: _tabController != null
          ? TabBarView(
              controller: _tabController,
              children: [
                Container(
                  color: Colors.white,
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.defaultPadding,
                        vertical: 0,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.groups,
                            size: 80,
                            color: AppConstants.primaryColor,
                          ),
                          SizedBox(
                            width: double.infinity,
                            child: _buildLabeledInput(
                              'Nome da Pessoa',
                              nameController,
                              Icons.person,
                              enabled: _editingDocId == null,
                            ),
                          ),
                          const SizedBox(height: AppConstants.smallSpacing),
                          SizedBox(
                            width: double.infinity,
                            child: _buildDropdownField(
                              'Selecione a Casa',
                              bettingHouses,
                              selectedBettingHouse,
                              (value) {
                                setState(() {
                                  selectedBettingHouse = value;
                                });
                              },
                              enabled: _editingDocId == null,
                            ),
                          ),
                          const SizedBox(height: AppConstants.smallSpacing),
                          SizedBox(
                            width: double.infinity,
                            child: _buildDropdownField(
                              'Selecione o Status',
                              ['Ativa', 'Inativa', 'Espera'],
                              status,
                              (value) {
                                setState(() {
                                  status = value;
                                });
                              },
                              key: ValueKey(status ?? 'status'),
                            ),
                          ),
                          const SizedBox(height: AppConstants.smallSpacing),
                          SizedBox(
                            width: double.infinity,
                            child: _buildLabeledInput(
                              'Usuário',
                              usernameController,
                              Icons.account_circle,
                            ),
                          ),
                          const SizedBox(height: AppConstants.smallSpacing),
                          SizedBox(
                            width: double.infinity,
                            child: _buildLabeledInput(
                              'Senha',
                              passwordController,
                              Icons.lock,
                            ),
                          ),
                          const SizedBox(height: AppConstants.smallSpacing),
                          SizedBox(
                            width: double.infinity,
                            child: _buildLabeledInput(
                              'Chave Pix',
                              pixKeyController,
                              Icons.key,
                            ),
                          ),
                          const SizedBox(height: AppConstants.smallSpacing),
                          SizedBox(
                            width: double.infinity,
                            child: _buildLabeledInput(
                              'WhatsApp',
                              whatsappController,
                              Icons.phone,
                              isPhone: true,
                            ),
                          ),
                          const SizedBox(height: AppConstants.smallSpacing),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppConstants.primaryColor,
                                foregroundColor: AppConstants.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 15,
                                ),
                                textStyle: const TextStyle(fontSize: 16),
                              ),
                              onPressed: () async {
                                final user = _auth.currentUser;
                                if (user == null) {
                                  showAppMessage(
                                      context, 'Usuário não autenticado!',
                                      isError: true);
                                  return;
                                }

                                final name = nameController.text.trim();
                                final username = usernameController.text.trim();
                                final password = passwordController.text.trim();
                                final pixKey = pixKeyController.text.trim();
                                final whatsappNumber =
                                    whatsappController.text.trim();

                                if (name.isEmpty ||
                                    selectedBettingHouse == null ||
                                    status == null ||
                                    username.isEmpty ||
                                    password.isEmpty ||
                                    pixKey.isEmpty) {
                                  showAppMessage(context,
                                      'Preencha todos os campos obrigatórios!',
                                      isError: true);
                                  return;
                                }

                                String fullWhatsappNumber =
                                    whatsappNumber.isNotEmpty
                                        ? '$_whatsappPrefix$whatsappNumber'
                                        : '';

                                if (whatsappNumber.isNotEmpty &&
                                    !fullWhatsappNumber.startsWith('+')) {
                                  showAppMessage(context,
                                      'O número de WhatsApp deve estar no formato válido (ex.: 11999999999)',
                                      isError: true);
                                  return;
                                }

                                try {
                                  if (_editingDocId == null) {
                                    // Cadastrando nova conta
                                    await _firestore
                                        .collection('users')
                                        .doc(user.uid)
                                        .collection('accounts')
                                        .add({
                                      'name': name,
                                      'bettingHouse': selectedBettingHouse,
                                      'username': username,
                                      'password': password,
                                      'pixKey': pixKey,
                                      'whatsapp': fullWhatsappNumber,
                                      'status': status,
                                      'userId': user.uid,
                                      'timestamp': FieldValue.serverTimestamp(),
                                    });
                                    showAppMessage(context,
                                        'Conta cadastrada com sucesso!');
                                  } else {
                                    // Atualizando conta existente
                                    await _firestore
                                        .collection('users')
                                        .doc(user.uid)
                                        .collection('accounts')
                                        .doc(_editingDocId)
                                        .update({
                                      'username': username,
                                      'password': password,
                                      'pixKey': pixKey,
                                      'whatsapp': fullWhatsappNumber,
                                      'status': status,
                                      'userId': user.uid,
                                      'timestamp': FieldValue.serverTimestamp(),
                                    });
                                    showAppMessage(context,
                                        'Conta atualizada com sucesso!');
                                  }

                                  // Limpa os campos e muda para a aba "Consulta"
                                  setState(() {
                                    _clearFields();
                                    _editingDocId = null;
                                    if (_tabController != null) {
                                      _tabController!.animateTo(1,
                                          duration:
                                              Duration(milliseconds: 300));
                                    }
                                  });

                                  // Forçar reconstrução da interface
                                  WidgetsBinding.instance
                                      .addPostFrameCallback((_) {
                                    setState(() {});
                                  });
                                } catch (e) {
                                  print('Erro ao salvar conta: $e');
                                  showAppMessage(
                                      context, 'Erro ao salvar conta: $e',
                                      isError: true);
                                }
                              },
                              child: Text(
                                _editingDocId == null
                                    ? 'Cadastrar'
                                    : 'Atualizar',
                              ),
                            ),
                          ),
                          const SizedBox(height: AppConstants.largeSpacing),
                        ],
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppConstants.defaultPadding,
                        ),
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppConstants.primaryColor,
                            borderRadius: BorderRadius.circular(
                                AppConstants.borderRadius),
                            border: null,
                          ),
                          child: Row(
                            children: [
                              const Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: AppConstants.smallSpacing,
                                ),
                                child: Icon(
                                  Icons.search,
                                  color: AppConstants.white,
                                  size: 20,
                                ),
                              ),
                              Expanded(
                                child: TextField(
                                  controller: searchController,
                                  style: const TextStyle(
                                    color: AppConstants.white,
                                  ),
                                  decoration: const InputDecoration(
                                    hintText: 'Buscar',
                                    hintStyle: TextStyle(
                                      color: AppConstants.white,
                                      fontSize: 16,
                                    ),
                                    border: InputBorder.none,
                                    fillColor: Colors.transparent,
                                    filled: true,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppConstants.smallSpacing,
                                ),
                                child: PopupMenuButton<String>(
                                  icon: const Icon(
                                    Icons.filter_list,
                                    color: AppConstants.white,
                                    size: 20,
                                  ),
                                  onSelected: (value) {
                                    if (value == 'Casas') {
                                      _showBettingHousesFilterDialog();
                                    } else {
                                      setState(() {
                                        filterStatus = value;
                                        selectedBettingHouses = [];
                                      });
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    'Todas',
                                    'Ativa',
                                    'Inativa',
                                    'Espera',
                                    'Casas',
                                  ].map((option) {
                                    IconData icon;
                                    switch (option) {
                                      case 'Todas':
                                        icon = Icons.all_inclusive;
                                        break;
                                      case 'Ativa':
                                        icon = Icons.check_circle;
                                        break;
                                      case 'Inativa':
                                        icon = Icons.cancel;
                                        break;
                                      case 'Espera':
                                        icon = Icons.hourglass_empty;
                                        break;
                                      case 'Casas':
                                        icon = Icons.account_circle;
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
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                          right: AppConstants.defaultPadding,
                          top: 4,
                          bottom: 4,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Total: ',
                              style: TextStyle(
                                color: AppConstants.textGrey,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            StreamBuilder<QuerySnapshot>(
                              stream: _firestore
                                  .collection('users')
                                  .doc(_auth.currentUser?.uid)
                                  .collection('accounts')
                                  .snapshots(),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) {
                                  return const Text(
                                    '0',
                                    style: TextStyle(
                                      color: AppConstants.textGrey,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  );
                                }
                                final accounts = snapshot.data!.docs;
                                final filteredAccounts = filterStatus == 'Todas'
                                    ? accounts
                                    : accounts
                                        .where((doc) =>
                                            (doc.data() as Map<String,
                                                dynamic>)['status'] ==
                                            filterStatus)
                                        .toList();
                                final filteredByBettingHouse =
                                    selectedBettingHouses.isEmpty
                                        ? filteredAccounts
                                        : filteredAccounts
                                            .where((doc) =>
                                                selectedBettingHouses.contains(
                                                    (doc.data() as Map<String,
                                                            dynamic>)[
                                                        'bettingHouse']))
                                            .toList();
                                final searchedAccounts =
                                    filteredByBettingHouse.where((doc) {
                                  final data =
                                      doc.data() as Map<String, dynamic>;
                                  final name =
                                      data['name']?.toString().toLowerCase() ??
                                          '';
                                  final bettingHouse = data['bettingHouse']
                                          ?.toString()
                                          .toLowerCase() ??
                                      '';
                                  return name.contains(searchQuery) ||
                                      bettingHouse.contains(searchQuery);
                                }).toList();
                                return Text(
                                  '${searchedAccounts.length}',
                                  style: const TextStyle(
                                    color: AppConstants.textGrey,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: StreamBuilder<QuerySnapshot>(
                          stream: _firestore
                              .collection('users')
                              .doc(_auth.currentUser?.uid)
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
                                        (doc.data() as Map<String, dynamic>)[
                                            'status'] ==
                                        filterStatus)
                                    .toList();
                            final filteredByBettingHouse =
                                selectedBettingHouses.isEmpty
                                    ? filteredAccounts
                                    : filteredAccounts
                                        .where((doc) => selectedBettingHouses
                                            .contains((doc.data() as Map<String,
                                                dynamic>)['bettingHouse']))
                                        .toList();
                            final searchedAccounts =
                                filteredByBettingHouse.where((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              final name =
                                  data['name']?.toString().toLowerCase() ?? '';
                              final bettingHouse = data['bettingHouse']
                                      ?.toString()
                                      .toLowerCase() ??
                                  '';
                              return name.contains(searchQuery) ||
                                  bettingHouse.contains(searchQuery);
                            }).toList();
                            if (searchedAccounts.isEmpty) {
                              return const Center(
                                child: Text(
                                  'Nenhuma conta encontrada.',
                                  style:
                                      TextStyle(color: AppConstants.textBlack),
                                ),
                              );
                            }
                            return ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppConstants.defaultPadding * 1.5,
                                vertical: AppConstants.smallSpacing,
                              ),
                              itemCount: searchedAccounts.length,
                              itemBuilder: (context, index) {
                                final data = searchedAccounts[index].data()
                                    as Map<String, dynamic>;
                                final docId = searchedAccounts[index].id;
                                final accountName = data['name'] ?? 'Sem nome';
                                final bettingHouse = data['bettingHouse'] ??
                                    'Sem casa de aposta';
                                final accountStatus = data['status'] ?? 'Ativa';
                                final whatsapp =
                                    data['whatsapp'] ?? 'Não informado';

                                return Container(
                                  margin: const EdgeInsets.only(
                                      bottom: AppConstants.defaultPadding),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(
                                        AppConstants.borderRadius),
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
                                        padding: const EdgeInsets.all(
                                            AppConstants.defaultPadding),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            CircleAvatar(
                                              backgroundColor:
                                                  AppConstants.textGrey200,
                                              child: Icon(
                                                Icons.account_circle,
                                                color: Colors.black54,
                                              ),
                                            ),
                                            const SizedBox(
                                                width:
                                                    AppConstants.smallSpacing),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    accountName,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    'Casa: $bettingHouse\nConta: $accountName\nStatus: $accountStatus',
                                                    style: const TextStyle(
                                                        fontSize: 12),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            if (whatsapp != 'Não informado')
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    right: 8),
                                                child: GestureDetector(
                                                  onTap: () =>
                                                      _openWhatsApp(whatsapp),
                                                  child: Image.asset(
                                                    'assets/images/whatsapp_icon.png',
                                                    width: 24,
                                                    height: 24,
                                                    fit: BoxFit.contain,
                                                    errorBuilder: (context,
                                                        error, stackTrace) {
                                                      print(
                                                          'Erro ao carregar o ícone do WhatsApp: $error');
                                                      return Icon(
                                                        Icons.phone,
                                                        color: AppConstants
                                                            .primaryColor,
                                                        size: 24,
                                                      );
                                                    },
                                                  ),
                                                ),
                                              ),
                                          ],
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
                                              _editAccount(docId, data);
                                            } else if (value == 'delete') {
                                              final confirm =
                                                  await showDialog<bool>(
                                                context: context,
                                                builder: (context) =>
                                                    AlertDialog(
                                                  backgroundColor:
                                                      AppConstants.primaryColor,
                                                  title: const Text(
                                                    'Confirmar Exclusão',
                                                    style: TextStyle(
                                                        color:
                                                            AppConstants.white),
                                                  ),
                                                  content: const Text(
                                                    'Deseja excluir esta conta?',
                                                    style: TextStyle(
                                                        color:
                                                            AppConstants.white),
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              context, false),
                                                      child: const Text(
                                                        'Cancelar',
                                                        style: TextStyle(
                                                            color: AppConstants
                                                                .white),
                                                      ),
                                                    ),
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              context, true),
                                                      child: const Text(
                                                        'Excluir',
                                                        style: TextStyle(
                                                            color: AppConstants
                                                                .white),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                              if (confirm == true) {
                                                await _deleteAccount(docId);
                                              }
                                            } else if (value == 'preview') {
                                              _showAccountDetails(data);
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
                                                  SizedBox(
                                                      width: AppConstants
                                                          .smallSpacing),
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
                                                  SizedBox(
                                                      width: AppConstants
                                                          .smallSpacing),
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
                                            const PopupMenuItem<String>(
                                              value: 'preview',
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.visibility,
                                                    color: AppConstants
                                                        .primaryColor,
                                                    size: 20,
                                                  ),
                                                  SizedBox(
                                                      width: AppConstants
                                                          .smallSpacing),
                                                  Text(
                                                    'Prévia',
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
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  color: Colors.white,
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.defaultPadding,
                        vertical: AppConstants.smallSpacing,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 40),
                          const SizedBox(height: 12),
                          Icon(
                            Icons.sports_soccer,
                            color: AppConstants.primaryColor,
                            size: 80,
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 60,
                            child: TextField(
                              controller: bettingHouseController,
                              keyboardType: TextInputType.text,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'[a-zA-Z0-9\s]')),
                                TextInputFormatter.withFunction(
                                    (oldValue, newValue) {
                                  return TextEditingValue(
                                    text: newValue.text.toUpperCase(),
                                    selection: newValue.selection,
                                  );
                                }),
                              ],
                              style: const TextStyle(
                                fontSize: 16,
                                color: AppConstants.textBlack,
                                fontWeight: FontWeight.bold,
                              ),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: AppConstants.textGrey200,
                                hintText: 'Nome da Casa de Aposta',
                                hintStyle: const TextStyle(
                                  fontSize: 16,
                                  color: AppConstants.textGrey,
                                  fontWeight: FontWeight.bold,
                                ),
                                prefixIcon: const Icon(
                                  Icons.account_circle,
                                  size: 20,
                                  color: AppConstants.textGrey,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: AppConstants.mediumSpacing,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                      AppConstants.borderRadius),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppConstants.smallSpacing),
                          SizedBox(
                            width: double.infinity,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: double.infinity,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: selectedColor,
                                    borderRadius: BorderRadius.circular(
                                      AppConstants.borderRadius,
                                    ),
                                    border: Border.all(
                                      color: AppConstants.textGrey300,
                                    ),
                                  ),
                                  child: TextButton(
                                    onPressed: () => _pickColor(context),
                                    child: const Text(
                                      'Selecionar Cor',
                                      style: TextStyle(
                                        color: AppConstants.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppConstants.smallSpacing),
                          Center(
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppConstants.primaryColor,
                                  foregroundColor: AppConstants.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 15,
                                  ),
                                  textStyle: const TextStyle(fontSize: 16),
                                ),
                                onPressed: () async {
                                  final user = _auth.currentUser;
                                  if (user == null) {
                                    showAppMessage(
                                        context, 'Usuário não autenticado!',
                                        isError: true);
                                    return;
                                  }

                                  final bettingHouseName =
                                      bettingHouseController.text.trim();

                                  if (bettingHouseName.isEmpty) {
                                    showAppMessage(context,
                                        'Preencha o nome da casa de aposta!',
                                        isError: true);
                                    return;
                                  }

                                  try {
                                    if (_editingDocId == null) {
                                      await _firestore
                                          .collection('users')
                                          .doc(user.uid)
                                          .collection('betting_houses')
                                          .add({
                                        'bettingHouseName': bettingHouseName,
                                        'color': _colorToHex(selectedColor),
                                        'userId': user.uid,
                                        'timestamp':
                                            FieldValue.serverTimestamp(),
                                      });
                                      showAppMessage(context,
                                          'Casa de aposta cadastrada com sucesso!');
                                    } else {
                                      await _firestore
                                          .collection('users')
                                          .doc(user.uid)
                                          .collection('betting_houses')
                                          .doc(_editingDocId)
                                          .update({
                                        'bettingHouseName': bettingHouseName,
                                        'color': _colorToHex(selectedColor),
                                        'userId': user.uid,
                                        'timestamp':
                                            FieldValue.serverTimestamp(),
                                      });
                                      showAppMessage(context,
                                          'Casa de aposta atualizada com sucesso!');
                                    }
                                    _clearFields();
                                    await _loadBettingHouses();
                                  } catch (e) {
                                    print('Erro ao salvar casa de aposta: $e');
                                    showAppMessage(context,
                                        'Erro ao salvar casa de aposta: $e',
                                        isError: true);
                                  }
                                },
                                child: Text(
                                  _editingDocId == null
                                      ? 'Cadastrar'
                                      : 'Atualizar',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppConstants.smallSpacing),
                          Center(
                            child: IconButton(
                              icon: const Icon(
                                Icons.search,
                                size: 40,
                                color: AppConstants.primaryColor,
                              ),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => Dialog(
                                    backgroundColor: Colors.white,
                                    child: Container(
                                      padding: const EdgeInsets.all(
                                          AppConstants.defaultPadding),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: AppConstants.primaryColor,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                AppConstants.borderRadius,
                                              ),
                                              border: null,
                                            ),
                                            child: Row(
                                              children: [
                                                const Padding(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: AppConstants
                                                        .smallSpacing,
                                                  ),
                                                  child: Icon(
                                                    Icons.search,
                                                    color: AppConstants.white,
                                                    size: 16,
                                                  ),
                                                ),
                                                Expanded(
                                                  child: TextField(
                                                    controller:
                                                        searchController,
                                                    style: const TextStyle(
                                                      color: AppConstants.white,
                                                      fontSize: 12,
                                                    ),
                                                    decoration:
                                                        const InputDecoration(
                                                      hintText:
                                                          'Buscar Casa de Aposta',
                                                      hintStyle: TextStyle(
                                                        color:
                                                            AppConstants.white,
                                                        fontSize: 12,
                                                      ),
                                                      border: InputBorder.none,
                                                      fillColor:
                                                          Colors.transparent,
                                                      filled: true,
                                                    ),
                                                    onChanged: (value) {
                                                      setState(() {
                                                        searchQuery =
                                                            value.toLowerCase();
                                                      });
                                                    },
                                                  ),
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: AppConstants
                                                        .smallSpacing,
                                                  ),
                                                  child:
                                                      PopupMenuButton<String>(
                                                    icon: const Icon(
                                                      Icons.filter_list,
                                                      color: AppConstants.white,
                                                      size: 16,
                                                    ),
                                                    onSelected: (value) {
                                                      setState(() {
                                                        filterColor =
                                                            value == 'Todas'
                                                                ? null
                                                                : value;
                                                      });
                                                    },
                                                    itemBuilder: (context) {
                                                      return availableColors
                                                          .map((option) {
                                                        return PopupMenuItem<
                                                            String>(
                                                          value: option,
                                                          child: Row(
                                                            children: [
                                                              if (option !=
                                                                  'Todas')
                                                                Container(
                                                                  width: 8,
                                                                  height: 8,
                                                                  decoration:
                                                                      BoxDecoration(
                                                                    color: _parseColor(
                                                                        option),
                                                                    shape: BoxShape
                                                                        .circle,
                                                                  ),
                                                                ),
                                                              if (option !=
                                                                  'Todas')
                                                                const SizedBox(
                                                                  width: 6,
                                                                ),
                                                              Text(
                                                                option ==
                                                                        'Todas'
                                                                    ? 'Todas as Cores'
                                                                    : 'Filtrar por Cor',
                                                                style:
                                                                    const TextStyle(
                                                                  color: AppConstants
                                                                      .textBlack,
                                                                  fontSize: 12,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        );
                                                      }).toList();
                                                    },
                                                    color: AppConstants.white,
                                                    elevation: 8,
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                        AppConstants
                                                            .borderRadius,
                                                      ),
                                                    ),
                                                    padding: EdgeInsets.zero,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          StreamBuilder<QuerySnapshot>(
                                            stream: _firestore
                                                .collection('users')
                                                .doc(_auth.currentUser?.uid)
                                                .collection('betting_houses')
                                                .orderBy('timestamp',
                                                    descending: true)
                                                .snapshots(),
                                            builder: (context, snapshot) {
                                              if (!snapshot.hasData) {
                                                return const Center(
                                                  child:
                                                      CircularProgressIndicator(),
                                                );
                                              }
                                              final bettingHouses =
                                                  snapshot.data!.docs;
                                              final filteredBettingHouses =
                                                  bettingHouses.where((doc) {
                                                final data = doc.data()
                                                    as Map<String, dynamic>;
                                                final name =
                                                    data['bettingHouseName']
                                                            ?.toString()
                                                            .toLowerCase() ??
                                                        '';
                                                final color =
                                                    data['color']?.toString();
                                                final matchesSearch =
                                                    name.contains(searchQuery);
                                                final matchesColor =
                                                    filterColor == null ||
                                                        color == filterColor;
                                                return matchesSearch &&
                                                    matchesColor;
                                              }).toList();
                                              if (filteredBettingHouses
                                                  .isEmpty) {
                                                return const Center(
                                                  child: Text(
                                                    'Nenhuma casa de aposta encontrada.',
                                                    style: TextStyle(
                                                      color: AppConstants
                                                          .textBlack,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                );
                                              }
                                              return Container(
                                                constraints: BoxConstraints(
                                                  maxHeight:
                                                      MediaQuery.of(context)
                                                              .size
                                                              .height *
                                                          0.5,
                                                ),
                                                child: ListView.builder(
                                                  shrinkWrap: true,
                                                  itemCount:
                                                      filteredBettingHouses
                                                          .length,
                                                  itemBuilder:
                                                      (context, index) {
                                                    final data =
                                                        filteredBettingHouses[
                                                                    index]
                                                                .data()
                                                            as Map<String,
                                                                dynamic>;
                                                    final docId =
                                                        filteredBettingHouses[
                                                                index]
                                                            .id;
                                                    final bettingHouseName =
                                                        data['bettingHouseName'] ??
                                                            'Sem nome';
                                                    final colorValue =
                                                        data['color'] != null
                                                            ? _parseColor(
                                                                data['color'])
                                                            : AppConstants
                                                                .textGrey;
                                                    return Container(
                                                      margin: const EdgeInsets
                                                          .symmetric(
                                                        vertical: 4,
                                                      ),
                                                      padding:
                                                          const EdgeInsets.all(
                                                              6),
                                                      decoration: BoxDecoration(
                                                        color: Colors.white,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(
                                                          AppConstants
                                                              .borderRadius,
                                                        ),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: AppConstants
                                                                .textGrey400
                                                                .withOpacity(
                                                                    0.2),
                                                            blurRadius: 4,
                                                            spreadRadius: 1,
                                                            offset:
                                                                const Offset(
                                                                    0, 1),
                                                          ),
                                                        ],
                                                      ),
                                                      child: Stack(
                                                        children: [
                                                          Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .spaceBetween,
                                                            children: [
                                                              Row(
                                                                children: [
                                                                  Container(
                                                                    width: 24,
                                                                    height: 24,
                                                                    decoration:
                                                                        BoxDecoration(
                                                                      color:
                                                                          colorValue,
                                                                      shape: BoxShape
                                                                          .circle,
                                                                    ),
                                                                  ),
                                                                  const SizedBox(
                                                                    width: 6,
                                                                  ),
                                                                  Text(
                                                                    bettingHouseName,
                                                                    style: const TextStyle(
                                                                        fontSize:
                                                                            12,
                                                                        fontWeight:
                                                                            FontWeight
                                                                                .bold,
                                                                        color: AppConstants
                                                                            .textBlack),
                                                                  ),
                                                                ],
                                                              ),
                                                            ],
                                                          ),
                                                          Positioned(
                                                            top: 0,
                                                            right: 0,
                                                            bottom:
                                                                0, // Permite centralizar verticalmente
                                                            child: Center(
                                                              child:
                                                                  PopupMenuButton<
                                                                      String>(
                                                                padding:
                                                                    EdgeInsets
                                                                        .zero,
                                                                icon:
                                                                    const Icon(
                                                                  Icons
                                                                      .more_vert,
                                                                  color: Colors
                                                                      .black54,
                                                                  size: 20,
                                                                ),
                                                                onSelected:
                                                                    (value) async {
                                                                  if (value ==
                                                                      'edit') {
                                                                    _editBettingHouse(
                                                                        docId,
                                                                        data);
                                                                    Navigator.pop(
                                                                        context);
                                                                  } else if (value ==
                                                                      'delete') {
                                                                    final confirm =
                                                                        await showDialog<
                                                                            bool>(
                                                                      context:
                                                                          context,
                                                                      builder:
                                                                          (context) =>
                                                                              AlertDialog(
                                                                        backgroundColor:
                                                                            AppConstants.primaryColor,
                                                                        title:
                                                                            const Text(
                                                                          'Confirmar Exclusão',
                                                                          style:
                                                                              TextStyle(color: AppConstants.white),
                                                                        ),
                                                                        content:
                                                                            const Text(
                                                                          'Deseja excluir esta casa de aposta?',
                                                                          style:
                                                                              TextStyle(color: AppConstants.white),
                                                                        ),
                                                                        actions: [
                                                                          TextButton(
                                                                            onPressed: () =>
                                                                                Navigator.pop(context, false),
                                                                            child:
                                                                                const Text(
                                                                              'Cancelar',
                                                                              style: TextStyle(color: AppConstants.white),
                                                                            ),
                                                                          ),
                                                                          TextButton(
                                                                            onPressed: () =>
                                                                                Navigator.pop(context, true),
                                                                            child:
                                                                                const Text(
                                                                              'Excluir',
                                                                              style: TextStyle(color: AppConstants.white),
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    );
                                                                    if (confirm ==
                                                                        true) {
                                                                      _deleteBettingHouse(
                                                                          docId);
                                                                    }
                                                                  }
                                                                },
                                                                itemBuilder:
                                                                    (context) =>
                                                                        [
                                                                  const PopupMenuItem<
                                                                      String>(
                                                                    value:
                                                                        'edit',
                                                                    child: Row(
                                                                      children: [
                                                                        Icon(
                                                                          Icons
                                                                              .edit,
                                                                          color:
                                                                              AppConstants.green,
                                                                          size:
                                                                              20,
                                                                        ),
                                                                        SizedBox(
                                                                            width:
                                                                                AppConstants.smallSpacing),
                                                                        Text(
                                                                          'Editar',
                                                                          style:
                                                                              TextStyle(
                                                                            color:
                                                                                Colors.black,
                                                                            fontSize:
                                                                                14,
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                  const PopupMenuItem<
                                                                      String>(
                                                                    value:
                                                                        'delete',
                                                                    child: Row(
                                                                      children: [
                                                                        Icon(
                                                                          Icons
                                                                              .delete,
                                                                          color:
                                                                              AppConstants.red,
                                                                          size:
                                                                              20,
                                                                        ),
                                                                        SizedBox(
                                                                            width:
                                                                                AppConstants.smallSpacing),
                                                                        Text(
                                                                          'Excluir',
                                                                          style:
                                                                              TextStyle(
                                                                            color:
                                                                                Colors.black,
                                                                            fontSize:
                                                                                14,
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                ],
                                                                color: Colors
                                                                    .white,
                                                                elevation: 8,
                                                                shape:
                                                                    RoundedRectangleBorder(
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                    AppConstants
                                                                        .borderRadius,
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  },
                                                ),
                                              );
                                            },
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: const Text(
                                              'Fechar',
                                              style: TextStyle(
                                                  color: AppConstants
                                                      .primaryColor),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 60),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildLabeledInput(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool isPhone = false,
    bool enabled = true,
  }) {
    return SizedBox(
      height: 60,
      child: TextField(
        controller: controller,
        enabled: enabled,
        keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
        inputFormatters: label == 'Nome da Pessoa'
            ? [
                FilteringTextInputFormatter.allow(
                    RegExp(r'[a-zA-Z0-9\s@#$%^&*]')),
                TextInputFormatter.withFunction((oldValue, newValue) {
                  return TextEditingValue(
                    text: newValue.text.toUpperCase(),
                    selection: newValue.selection,
                  );
                }),
              ]
            : label == 'Nome da Casa de Aposta'
                ? [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\s]')),
                    TextInputFormatter.withFunction((oldValue, newValue) {
                      return TextEditingValue(
                        text: newValue.text.toUpperCase(),
                        selection: newValue.selection,
                      );
                    }),
                  ]
                : isPhone
                    ? [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                      ]
                    : null,
        style: TextStyle(
          fontSize: 16,
          color: enabled ? AppConstants.textBlack : Colors.grey,
          fontWeight: FontWeight.bold,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: enabled ? AppConstants.textGrey200 : Colors.grey[200],
          hintText: label,
          hintStyle: const TextStyle(
            fontSize: 16,
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
    bool enabled = true,
  }) {
    String? validSelectedValue =
        selectedValue != null && options.contains(selectedValue)
            ? selectedValue
            : null;

    return SizedBox(
      height: 60,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.mediumSpacing,
        ),
        decoration: BoxDecoration(
          color: enabled ? AppConstants.textGrey200 : Colors.grey[200],
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton2<String>(
            key: key,
            value: validSelectedValue,
            hint: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                color: AppConstants.textGrey,
                fontWeight: FontWeight.bold,
              ),
            ),
            iconStyleData: const IconStyleData(
              icon: Icon(
                Icons.arrow_drop_down,
                size: 20,
                color: AppConstants.textGrey,
              ),
            ),
            onChanged: enabled ? onChanged : null,
            items: options
                .map(
                  (opt) => DropdownMenuItem<String>(
                    value: opt,
                    child: Text(
                      opt,
                      style: const TextStyle(
                        fontSize: 16,
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
