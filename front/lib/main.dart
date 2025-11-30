import 'package:flutter/material.dart';
import 'package:front/features/management/screens/gestao_screen.dart';
import 'package:front/features/products/screens/produtos_screen.dart';
import 'package:front/features/sales/screens/vendas_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF4169E1), // Royal Blue
        body: Center(
          child: Builder(builder: (context) {
            final screenWidth = MediaQuery.of(context).size.width;
            final imageSize = screenWidth * 0.2;
            final spacing = screenWidth * 0.05;
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                InkWell(
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const VendasScreen()));
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15.0),
                    child: Image.asset('lib/assets/vendas.png',
                        width: imageSize, height: imageSize),
                  ),
                ),
                SizedBox(width: spacing),
                InkWell(
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const ProdutosScreen()));
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15.0),
                    child: Image.asset('lib/assets/produtos.png',
                        width: imageSize, height: imageSize),
                  ),
                ),
                SizedBox(width: spacing),
                InkWell(
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const GestaoScreen()));
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15.0),
                    child: Image.asset('lib/assets/gestao.png',
                        width: imageSize, height: imageSize),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}