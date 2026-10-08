import 'package:flutter/material.dart';
import 'package:youwell/main.dart';
import 'package:youwell/setor_screen.dart';

class GerenteScreen extends StatefulWidget {
  final String setorGerente;

  const GerenteScreen({ super.key, required this.setorGerente,});

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
                const Text(
                  "Olá GERENTE",
                  style: TextStyle(
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