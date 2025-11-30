import 'package:flutter/material.dart';

class VendasScreen extends StatelessWidget {
  const VendasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vendas'),
        backgroundColor: const Color(0xFF4169E1),
      ),
      body: const Center(
        child: Text('Página de Vendas', style: TextStyle(fontSize: 24, color: Colors.white)),
      ),
      backgroundColor: const Color(0xFF4169E1),
    );
  }
}
