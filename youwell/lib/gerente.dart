import 'package:flutter/material.dart';
import 'package:youwell/main.dart';
import 'package:youwell/Gerente/setor_screen_gerente.dart';
import 'package:youwell/login_screen.dart';
import 'package:youwell/simulacaoBD/dados_sensores.dart';

class GerenteScreen extends StatefulWidget {
  final String setorGerente;
  final String nomeGerente;

  const GerenteScreen({ super.key, required this.setorGerente, required this.nomeGerente});

  @override
  State<GerenteScreen> createState() => _GerenteScreenState();
}

class _GerenteScreenState extends State<GerenteScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 10, 85, 64),

        iconTheme: const IconThemeData(
          color: Colors.white,
        ),

        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),

            child: Row(
              children: [
                Text(
                "Olá ${widget.nomeGerente}",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                ),
              ),

                const SizedBox(width: 10),

                const CircleAvatar(
                  child: Icon(Icons.person),
                ),
              ],
            ),
          ),
        ],
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SetorScreen(
                              nomeSetor: widget.setorGerente,
                              nomeUsuario: widget.nomeGerente,
                            ),
                          ),
                        );
                      },

                      child: Container(
                        height: 120,

                        padding: const EdgeInsets.all(15),

                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(10),
                        ),

                        child: Center(
                          child: Text(
                            widget.setorGerente,

                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}