import 'package:flutter/material.dart';

class GerenteScreen extends StatelessWidget {
  const GerenteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Área do Gerente"),
      ),
      body: const Center(
        child: Text(
          "Bem-vindo, gerente!",
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}