import 'package:flutter/material.dart';
import 'package:youwell/main.dart';
import 'package:youwell/screens/home_screen.dart';
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
    String nomeDigitado = logincontrollerForm.text.trim();
    String senhaDigitada = senhacontrollerForm.text;

    // Procura o usuário no banco simulado
    final usuariosEncontrados = usuarios.where(
      (usuario) =>
          usuario["nome"] == nomeDigitado &&
          usuario["senha"] == senhaDigitada,
    );

    if (usuariosEncontrados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Nome ou senha incorretos"),
        ),
      );
      return;
    }

    final usuario = usuariosEncontrados.first;
    final papel = usuario["papel"];

    if (papel == "gerente") {
      // O usuário guarda o ID do setor
      final idSetor = usuario["setor"];

      // Busca o setor correspondente pelo ID
      final setorEncontrado = setores.where(
        (setor) => setor["id"] == idSetor,
      );

      if (setorEncontrado.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("O setor deste gerente não foi encontrado."),
          ),
        );
        return;
      }

      final nomeSetor = setorEncontrado.first["nome"] as String;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GerenteScreen(
            setorGerente: nomeSetor,
            nomeGerente: usuario["nome"],
          ),
        ),
      ); 
    } else if (papel == "admin") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AdminScreen(
            nomeAdmin: usuario["nome"],
          ),
        ),
      );
    } else if (papel == "usuario") {
      // Ainda precisamos definir qual tela esse papel deve abrir.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Login válido, mas a tela deste usuário ainda não foi definida."),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Papel de usuário não reconhecido."),
        ),
      );
    }
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