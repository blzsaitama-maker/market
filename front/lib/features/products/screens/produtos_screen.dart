
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class BarcodeTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final newText = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    if (newText.length > 16) {
      return oldValue;
    }

    var formattedText = '';
    for (var i = 0; i < newText.length; i++) {
      formattedText += newText[i];
      if ((i + 1) % 4 == 0 && (i + 1) != newText.length) {
        formattedText += '-';
      }
    }

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    String newText = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    if (newText.isEmpty) {
      return const TextEditingValue(
        text: '0.00',
        selection: TextSelection.collapsed(offset: 4),
      );
    }

    double value = double.parse(newText) / 100.0;
    String formattedText = value.toStringAsFixed(2);

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}

class ProdutosScreen extends StatefulWidget {
  const ProdutosScreen({super.key});

  @override
  State<ProdutosScreen> createState() => _ProdutosScreenState();
}

class _ProdutosScreenState extends State<ProdutosScreen> {
  final _formKey = GlobalKey<FormState>();

  // --- FOCUS NODES ---
  final _salePriceFocusNode = FocusNode();
  final _purchasePriceFocusNode = FocusNode();

  // --- CONTROLLERS E ESTADO DO FORMULÁRIO ---
  final _idController = TextEditingController();
  final _nameController = TextEditingController();
  final _barcodeController = TextEditingController();

  final _salePriceController = TextEditingController();
  final _purchasePriceController = TextEditingController();
  final _quantityReceivedController = TextEditingController();
  final _quantityInStoreController = TextEditingController();
  final _quantityInStockController = TextEditingController();

  String? _selectedCategory;
  String? _selectedSupplier;
  DateTime? _expirationDate;

  // --- DADOS MOCK (SIMULAÇÃO DE BANCO DE DADOS) ---
  final List<String> _categories = [
    'Eletrônicos',
    'Roupas',
    'Alimentos',
    'Higiene'
  ];
  final List<String> _suppliers = [
    'Fornecedor A',
    'Fornecedor B',
    'Fornecedor C'
  ];

  final List<Map<String, dynamic>> _mockDb = [
    {
      "id": 1,
      "name": "Laptop Pro",
      "description": "Laptop de alta performance",
      "barcode": "123456789",
      "sale_price": 7500.00,
      "purchase_price": 5000.00,
      "category": "Eletrônicos",
      "supplier": "Fornecedor A",
      "expiration_date": null,
      "quantity_received": 50,
      "quantity_in_store": 10,
      "quantity_in_stock": 40,
    },
    {
      "id": 2,
      "name": "Arroz Integral",
      "description": "Pacote de 1kg de arroz integral",
      "barcode": "987654321",
      "sale_price": 10.00,
      "purchase_price": 6.50,
      "category": "Alimentos",
      "supplier": "Fornecedor B",
      "expiration_date": DateTime(2026, 12, 31),
      "quantity_received": 200,
      "quantity_in_store": 50,
      "quantity_in_stock": 150,
    }
  ];

  // --- LÓGICA DE BUSCA E ESTADO ---
  Map<String, dynamic>? _loadedProduct;
  Timer? _debounce;
  bool _isFormEnabled = false;

  @override
  void initState() {
    super.initState();
    _idController.addListener(_onSearchChanged);
    _nameController.addListener(_onSearchChanged);
    _barcodeController.addListener(_onSearchChanged);
    _salePriceFocusNode.addListener(_onSalePriceFocusChange);
    _purchasePriceFocusNode.addListener(_onPurchasePriceFocusChange);
  }

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    _barcodeController.dispose();

    _salePriceController.dispose();
    _purchasePriceController.dispose();
    _quantityReceivedController.dispose();
    _quantityInStoreController.dispose();
    _quantityInStockController.dispose();
    _debounce?.cancel();
    _salePriceFocusNode.removeListener(_onSalePriceFocusChange);
    _purchasePriceFocusNode.removeListener(_onPurchasePriceFocusChange);
    _salePriceFocusNode.dispose();
    _purchasePriceFocusNode.dispose();
    super.dispose();
  }

  void _onSalePriceFocusChange() {
    if (_salePriceFocusNode.hasFocus) {
      // Select all text when field gains focus
      _salePriceController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _salePriceController.text.length,
      );
    } else {
      // On focus loss, if the field is empty, set to 0.00
      // The formatter should handle most cases, but this is a fallback.
      if (_salePriceController.text.isEmpty) {
          _salePriceController.text = '0.00';
      }
    }
  }

  void _onPurchasePriceFocusChange() {
    if (_purchasePriceFocusNode.hasFocus) {
      // Select all text when field gains focus
      _purchasePriceController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _purchasePriceController.text.length,
      );
    } else {
      // On focus loss, if the field is empty, set to 0.00
      if (_purchasePriceController.text.isEmpty) {
          _purchasePriceController.text = '0.00';
      }
    }
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 700), () {
      final idQuery = _idController.text;
      final nameQuery = _nameController.text;
      final barcodeQuery = _barcodeController.text;

      if ((idQuery.isNotEmpty ||
              nameQuery.isNotEmpty ||
              barcodeQuery.isNotEmpty) &&
          !_isFormEnabled) {
        _searchProduct(
            idQuery: idQuery,
            nameQuery: nameQuery,
            barcodeQuery: barcodeQuery);
      }
    });
  }

  void _searchProduct(
      {String? idQuery, String? nameQuery, String? barcodeQuery}) {
    Map<String, dynamic>? foundProduct;
    try {
      foundProduct = _mockDb.firstWhere(
        (p) =>
            (idQuery != null &&
                idQuery.isNotEmpty &&
                p['id'].toString() == idQuery) ||
            (nameQuery != null &&
                nameQuery.isNotEmpty &&
                p['name'].toString().toLowerCase() == nameQuery.toLowerCase()) ||
            (barcodeQuery != null &&
                barcodeQuery.isNotEmpty &&
                p['barcode'] == barcodeQuery),
      );
    } catch (e) {
      foundProduct = null;
    }

    if (foundProduct != null) {
      _populateForm(foundProduct);
    } else {
      setState(() {
        _isFormEnabled = true;
      });
    }
  }

  void _populateForm(Map<String, dynamic> product) {
    setState(() {
      _loadedProduct = product;
      _idController.text = product['id'].toString();
      _nameController.text = product['name'];
      _barcodeController.text = product['barcode'];

      _salePriceController.text = product['sale_price'].toStringAsFixed(2);
      _purchasePriceController.text =
          product['purchase_price'].toStringAsFixed(2);
      _quantityReceivedController.text = product['quantity_received'].toString();
      _quantityInStoreController.text = product['quantity_in_store'].toString();
      _quantityInStockController.text = product['quantity_in_stock'].toString();
      _selectedCategory = product['category'];
      _selectedSupplier = product['supplier'];
      _expirationDate = product['expiration_date'];
      _isFormEnabled = true;
    });
  }

  void _clearForm() {
    setState(() {
      _formKey.currentState?.reset();
      _idController.clear();
      _nameController.clear();
      _barcodeController.clear();

      _salePriceController.text = '0.00';
      _purchasePriceController.text = '0.00';
      _quantityReceivedController.clear();
      _quantityInStoreController.clear();
      _quantityInStockController.clear();
      _selectedCategory = null;
      _selectedSupplier = null;
      _expirationDate = null;
      _loadedProduct = null;
      _isFormEnabled = false;
    });
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;

    if (_loadedProduct != null) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Confirmar Alteração'),
          content: const Text('Deseja salvar as alterações neste produto?'),
          actions: [
            TextButton(
                child: const Text('Não'),
                onPressed: () => Navigator.of(ctx).pop()),
            TextButton(
              child: const Text('Sim'),
              onPressed: () {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content:
                          Text('Produto atualizado com sucesso (simulação)!')),
                );
                _clearForm();
              },
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Produto cadastrado com sucesso (simulação)!')),
      );
      _clearForm();
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _expirationDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _expirationDate) {
      setState(() {
        _expirationDate = picked;
      });
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadastrar/Editar Produto'),
        backgroundColor: const Color(0xFF4169E1),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Novo Produto',
            onPressed: _clearForm,
          ),
        ],
      ),
      backgroundColor: const Color(0xFF4169E1),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // --- LINHA DE BUSCA ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Código de Barras',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        TextFormField(
                          autofocus: true,
                          controller: _barcodeController,
                          decoration: InputDecoration(
                            fillColor: Colors.white,
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          style: const TextStyle(color: Colors.black),
                          keyboardType: TextInputType.number,
                          inputFormatters: [BarcodeTextInputFormatter()],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Nome do Produto',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            fillColor: Colors.white,
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          style: const TextStyle(color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ID',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        TextFormField(
                          controller: _idController,
                          decoration: InputDecoration(
                            fillColor: Colors.white,
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          style: const TextStyle(color: Colors.black),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: Colors.white54),
              const SizedBox(height: 16),

              // --- RESTANTE DO FORMULÁRIO ---

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Preço de Venda',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        TextFormField(
                          focusNode: _salePriceFocusNode,
                          controller: _salePriceController,
                          decoration: InputDecoration(
                            fillColor: _isFormEnabled ? Colors.white : Colors.grey.shade200,
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          style: TextStyle(
                              color: _isFormEnabled ? Colors.black : Colors.grey),
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [CurrencyInputFormatter()],
                          validator: (value) => _isFormEnabled &&
                                  (value == null || value.isEmpty || value == '0.00')
                              ? 'Obrigatório'
                              : null,
                          enabled: _isFormEnabled,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Preço de Compra',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        TextFormField(
                          focusNode: _purchasePriceFocusNode,
                          controller: _purchasePriceController,
                          decoration: InputDecoration(
                            fillColor: _isFormEnabled ? Colors.white : Colors.grey.shade200,
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          style: TextStyle(
                              color: _isFormEnabled ? Colors.black : Colors.grey),
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [CurrencyInputFormatter()],
                          validator: (value) => _isFormEnabled &&
                                  (value == null || value.isEmpty || value == '0.00')
                              ? 'Obrigatório'
                              : null,
                          enabled: _isFormEnabled,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Categoria',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                            fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: InputDecoration(
                      fillColor: _isFormEnabled ? Colors.white : Colors.grey.shade200,
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    dropdownColor: Colors.white,
                    style:
                        TextStyle(color: _isFormEnabled ? Colors.black : Colors.grey),
                    items: _categories.map((String category) {
                      return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category,
                              style: const TextStyle(color: Colors.black)));
                    }).toList(),
                    onChanged: _isFormEnabled
                        ? (newValue) => setState(() => _selectedCategory = newValue)
                        : null,
                    validator: (value) =>
                        _isFormEnabled && value == null ? 'Selecione' : null,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Fornecedor',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                            fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    value: _selectedSupplier,
                    decoration: InputDecoration(
                      fillColor: _isFormEnabled ? Colors.white : Colors.grey.shade200,
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    dropdownColor: Colors.white,
                    style:
                        TextStyle(color: _isFormEnabled ? Colors.black : Colors.grey),
                    items: _suppliers.map((String supplier) {
                      return DropdownMenuItem<String>(
                          value: supplier,
                          child: Text(supplier,
                              style: const TextStyle(color: Colors.black)));
                    }).toList(),
                    onChanged: _isFormEnabled
                        ? (newValue) => setState(() => _selectedSupplier = newValue)
                        : null,
                    validator: (value) =>
                        _isFormEnabled && value == null ? 'Selecione' : null,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Column(
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 130,
                        child: const Text('Qtd. Recebida:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold,
                            fontSize: 16,)),
                      ),
                      SizedBox(
                        width: 120,
                        child: TextFormField(
                          controller: _quantityReceivedController,
                          decoration: InputDecoration(
                            fillColor: _isFormEnabled ? Colors.white : Colors.grey.shade200,
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          style: TextStyle(
                              color: _isFormEnabled ? Colors.black : Colors.grey),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          enabled: _isFormEnabled,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      SizedBox(
                        width: 130,
                        child: const Text('Qtd. na Loja:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold,
                            fontSize: 16,)),
                      ),
                      SizedBox(
                        width: 120,
                        child: TextFormField(
                          controller: _quantityInStoreController,
                          decoration: InputDecoration(
                            fillColor: _isFormEnabled ? Colors.white : Colors.grey.shade200,
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          style: TextStyle(
                              color: _isFormEnabled ? Colors.black : Colors.grey),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          enabled: _isFormEnabled,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      SizedBox(
                        width: 130,
                        child: const Text('Qtd. no Estoque:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold,
                            fontSize: 16,)),
                      ),
                      SizedBox(
                        width: 120,
                        child: TextFormField(
                          controller: _quantityInStockController,
                          decoration: InputDecoration(
                            fillColor: _isFormEnabled ? Colors.white : Colors.grey.shade200,
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          style: TextStyle(
                              color: _isFormEnabled ? Colors.black : Colors.grey),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          enabled: _isFormEnabled,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Card(
                    color: Colors.white.withOpacity(0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _expirationDate == null
                                ? 'Validade: Indeterminada'
                                : 'Validade: ${DateFormat('dd/MM/yyyy').format(_expirationDate!)}',
                            style: const TextStyle(color: Colors.white, fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              TextButton(
                                onPressed: _isFormEnabled ? () => _selectDate(context) : null,
                                child: Text('Selecionar', style: TextStyle(color: _isFormEnabled ? Colors.white : Colors.grey)),
                              ),
                              if (_isFormEnabled && _expirationDate != null)
                                IconButton(
                                  icon: const Icon(Icons.clear, color: Colors.white, size: 20),
                                  tooltip: 'Limpar validade',
                                  onPressed: () {
                                    setState(() {
                                      _expirationDate = null;
                                    });
                                  },
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _isFormEnabled ? _submitForm : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF4169E1),
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 80),
                      disabledBackgroundColor: Colors.grey.shade300,
                    ),
                    child: const Text('Registrar', style: TextStyle(fontSize: 22)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}