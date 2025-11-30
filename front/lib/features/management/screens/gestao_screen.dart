import 'package:flutter/material.dart';

class GestaoScreen extends StatelessWidget {
  const GestaoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestão'),
        backgroundColor: const Color(0xFF4169E1),
      ),
      body: const Center(
        child: Text('Página de Gestão', style: TextStyle(fontSize: 24, color: Colors.white)),
      ),
      backgroundColor: const Color(0xFF4169E1),
    );
  }
}
