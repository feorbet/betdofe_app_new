import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BettingHouseRegisterScreen extends StatefulWidget {
  const BettingHouseRegisterScreen({super.key});

  @override
  State<BettingHouseRegisterScreen> createState() =>
      _BettingHouseRegisterScreenState();
}

class _BettingHouseRegisterScreenState
    extends State<BettingHouseRegisterScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final TextEditingController bettingHouseNameController =
      TextEditingController();
  String? selectedColor;

  final Color primaryColor = const Color(0xFF1B5E20);

  // Lista de cores primárias para o dropdown
  final List<Map<String, dynamic>> colors = [
    {'name': 'Vermelho', 'value': Colors.red},
    {'name': 'Azul', 'value': Colors.blue},
    {'name': 'Verde', 'value': Colors.green},
    {'name': 'Amarelo', 'value': Colors.yellow},
    {'name': 'Laranja', 'value': Colors.orange},
    {'name': 'Roxo', 'value': Colors.purple},
  ];

  // Variável para controlar se estamos editando ou adicionando
  String? _editingDocId;

  @override
  void initState() {
    super.initState();
    bettingHouseNameController.text = '';
    // Exibir mensagem "Selecione a cor" ao carregar a tela
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione a cor'),
          duration: Duration(seconds: 3),
        ),
      );
    });
  }

  @override
  void dispose() {
    bettingHouseNameController.dispose();
    super.dispose();
  }

  // Função para excluir uma casa de aposta
  Future<void> _deleteBettingHouse(String docId) async {
    try {
      await _firestore.collection('bettingHouses').doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Casa de aposta excluída com sucesso!')),
      );
    } catch (e) {
      print('Erro ao excluir casa de aposta: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao excluir casa de aposta: $e')),
      );
    }
  }

  // Função para cadastrar ou atualizar uma casa de aposta
  Future<void> _saveBettingHouse() async {
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuário não autenticado!')),
      );
      return;
    }

    final bettingHouseName =
        bettingHouseNameController.text.trim().toUpperCase();
    final color = selectedColor ?? colors[0]['value'].toString();

    if (bettingHouseName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('O nome da casa de aposta é obrigatório!')),
      );
      return;
    }

    try {
      // Encontrar o nome da cor com base no valor selecionado
      final selectedColorName = colors.firstWhere(
        (colorMap) => colorMap['value'].toString() == color,
        orElse: () => colors[0],
      )['name'] as String;

      if (_editingDocId == null) {
        // Modo de cadastro (adicionar novo)
        await _firestore.collection('bettingHouses').add({
          'bettingHouseName': bettingHouseName,
          'color': selectedColorName,
          'userId': user.uid,
          'timestamp': FieldValue.serverTimestamp(),
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Casa de aposta cadastrada com sucesso!')),
        );
        // Limpar os campos após o cadastro bem-sucedido
        setState(() {
          bettingHouseNameController.clear();
          selectedColor = null;
        });
      } else {
        // Modo de edição (atualizar existente)
        await _firestore.collection('bettingHouses').doc(_editingDocId).update({
          'bettingHouseName': bettingHouseName,
          'color': selectedColorName,
          'userId': user.uid,
          'timestamp': FieldValue.serverTimestamp(),
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Casa de aposta atualizada com sucesso!')),
        );
        setState(() {
          _editingDocId = null;
          bettingHouseNameController.clear();
          selectedColor = null;
        });
      }
      if (!mounted) return;
    } catch (e) {
      print('Erro ao salvar casa de aposta: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar casa de aposta: $e')),
      );
    }
  }

  // Função para carregar os dados para edição
  void _editBettingHouse(String docId, Map<String, dynamic> data) {
    setState(() {
      _editingDocId = docId;
      bettingHouseNameController.text =
          data['bettingHouseName']?.toUpperCase() ?? '';
      final colorName = data['color'] as String? ?? colors[0]['name'];
      final colorMap = colors.firstWhere(
        (color) => color['name'] == colorName,
        orElse: () => colors[0],
      );
      selectedColor = colorMap['value'].toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Casas de Aposta',
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Formulário de Cadastro
            _buildLabeledInput('Casa de Aposta', Icons.sports_soccer,
                bettingHouseNameController),
            const SizedBox(height: 12),
            _buildDropdownField('Cor', colors, selectedColor, (value) {
              setState(() {
                selectedColor = value;
              });
            }),
            const SizedBox(height: 25),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildCircleButton(
                    Icons.check, Colors.green, _saveBettingHouse),
                const SizedBox(width: 20),
                _buildCircleButton(Icons.close, Colors.red, () {
                  Navigator.pop(context);
                }),
              ],
            ),
            const SizedBox(height: 20),
            // Lista de Casas de Aposta Cadastradas
            Center(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                color: primaryColor,
                child: const Center(
                  child: Text(
                    'Casas de Aposta',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('bettingHouses')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final bettingHouses = snapshot.data!.docs;
                if (bettingHouses.isEmpty) {
                  return const Center(
                      child: Text('Nenhuma casa de aposta cadastrada.'));
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: bettingHouses.length,
                  itemBuilder: (context, index) {
                    final data =
                        bettingHouses[index].data() as Map<String, dynamic>;
                    final docId = bettingHouses[index].id;
                    final bettingHouseName =
                        data['bettingHouseName'] ?? 'Sem nome';
                    return Dismissible(
                      key: Key(docId),
                      background: Container(
                        color: Colors.green,
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(left: 20),
                        child: const Icon(Icons.edit, color: Colors.white),
                      ),
                      secondaryBackground: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (direction) {
                        if (direction == DismissDirection.endToStart) {
                          _deleteBettingHouse(docId);
                        }
                      },
                      confirmDismiss: (direction) async {
                        if (direction == DismissDirection.startToEnd) {
                          _editBettingHouse(docId, data);
                          return false;
                        } else {
                          return await showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Confirmar Exclusão'),
                              content: Text(
                                  'Deseja excluir a casa de aposta "$bettingHouseName"?'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Cancelar'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Excluir'),
                                ),
                              ],
                            ),
                          );
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(8),
                        color: index % 2 == 0 ? Colors.grey[100] : Colors.white,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              bettingHouseName,
                              style: const TextStyle(fontSize: 12),
                            ),
                            Container(
                              width: 16,
                              height: 16,
                              color: _parseColor(data['color']),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Função para mapear o nome da cor para o objeto Color
  Color _parseColor(String? colorName) {
    if (colorName == null) {
      print('colorName é null');
      return Colors.grey;
    }
    try {
      print('Tentando mapear cor: $colorName');
      final colorMap = colors.firstWhere(
        (color) => color['name'] == colorName,
        orElse: () => {'value': Colors.grey},
      );
      final colorValue = colorMap['value'] as Color;
      print('Cor mapeada: $colorValue');
      return colorValue;
    } catch (e) {
      print('Erro ao mapear cor: $e');
      return Colors.grey;
    }
  }

  Widget _buildLabeledInput(
    String label,
    IconData icon,
    TextEditingController controller,
  ) {
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
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\s]')),
              TextInputFormatter.withFunction((oldValue, newValue) {
                return TextEditingValue(
                  text: newValue.text.toUpperCase(),
                  selection: newValue.selection,
                );
              }),
            ],
            decoration: InputDecoration(
              hintText: 'Digite a casa de aposta', // Placeholder ajustado
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

  Widget _buildDropdownField(String label, List<Map<String, dynamic>> options,
      String? selectedValue, ValueChanged<String?> onChanged) {
    String validSelectedValue = selectedValue != null &&
            options.any((opt) => opt['value'].toString() == selectedValue)
        ? selectedValue
        : options.first['value'].toString();

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
                        value: opt['value'].toString(),
                        child: Row(
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              color: opt['value'],
                            ),
                            const SizedBox(width: 10),
                            Text(
                              opt['name'],
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
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
