import 'package:flutter/material.dart';
import 'package:youwell/main.dart';
import 'package:youwell/admin.dart';
import 'package:youwell/gerente.dart';
import 'package:youwell/simulacaoBD/dados_sensores.dart';

void main() {
  runApp(LoginScreen());
}

class LoginScreen extends StatelessWidget {
  LoginScreen({super.key});

  final logincontrollerForm = TextEditingController();
  final senhacontrollerForm = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  void fazerLogin(BuildContext context) {
    String nomeDigitado = logincontrollerForm.text;
    String senhaDigitada = senhacontrollerForm.text;

    // Procura o gerente no banco de dados simulado
    final gerenteEncontrado = dadosGerentes.where(
      (gerente) =>
          gerente["nome"] == nomeDigitado &&
          gerente["senha"] == senhaDigitada,
    );

    if (gerenteEncontrado.isNotEmpty) {
      final gerente = gerenteEncontrado.first;

      if (gerente["papel"] == "gerente") {
        // Pega o setor que veio do banco simulado
        String setorGerente = gerente["setor"];

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GerenteScreen(
              setorGerente: setorGerente,
            ),
          ),
        );

        return;
      }
    }

    // Se não encontrou o usuário
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Nome ou senha incorretos"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 10, 85, 64),

      body: SafeArea(
        child: Center(
          child: Container(
            height: 450,
            width: 350,

            padding: const EdgeInsets.all(5),

            decoration: BoxDecoration(
              color: const Color.fromARGB(163, 220, 220, 220),
              borderRadius: BorderRadius.circular(15),
            ),

            child: Padding(
              padding: const EdgeInsets.all(20),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,

                children: [
                  Form(
                    key: _formKey,

                    child: Column(
                      children: [
                        const Text(
                          "Login:",
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.white,
                          ),
                        ),

                        TextFormField(
                          controller: logincontrollerForm,

                          decoration: const InputDecoration(
                            labelText: "Nome",
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.white,
                          ),

                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Campo obrigatório";
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 20),

                        const Text(
                          "Senha:",
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.white,
                          ),
                        ),

                        TextFormField(
                          controller: senhacontrollerForm,

                          decoration: const InputDecoration(
                            labelText: "Senha",
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.white,
                          ),

                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Campo obrigatório";
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 20),

                        ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              fazerLogin(context);
                            }
                          },

                          child: const Text(
                            "Entrar",
                            style: TextStyle(fontSize: 16),
                          ),
                        ),

                        const SizedBox(height: 30),

                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MyApp(),
                              ),
                            );
                          },

                          child: const Text("Voltar"),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}