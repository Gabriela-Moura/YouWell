import 'package:flutter/material.dart';
import 'package:youwell/simulacaoBD/dados_sensores.dart';

class UsuarioTi extends StatefulWidget {
  const UsuarioTi({super.key});

  @override
  State<UsuarioTi> createState() => _UsuarioTiState();
}

class _UsuarioTiState extends State<UsuarioTi> {
  final nomeController = TextEditingController();

  void criarSetor() {
    String nome = nomeController.text.trim();

    if (nome.isEmpty) {
      return;
    }

    int novoId = setores.isEmpty
        ? 1
        : setores.map((setor) => setor["id"] as int).reduce((a, b) => a > b ? a : b) + 1;

    setState(() {
      setores.add({
        "id": novoId,
        "nome": nome,
      });
    });

    nomeController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Setor criado com sucesso!"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Criar Setor"),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [

            TextField(
              controller: nomeController,
              decoration: const InputDecoration(
                labelText: "Nome do setor",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: criarSetor,
              child: const Text("Criar Setor"),
            ),

          ],
        ),
      ),
    );
  }
}