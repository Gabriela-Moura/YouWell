import 'package:flutter/material.dart';
import 'package:youwell/main.dart';
import 'package:youwell/setor_screen.dart';
import 'package:youwell/simulacaoBD/dados_sensores.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  // LISTA LOCAL (FAKE)
  // List<Map<String, dynamic>> setores
  // Cria uma lista de objetos (Map) para armazenar
  // os setores do sistema. Cada setor possui
  // informações como id e nome.
  //
  //O tipo da chave é string
  /// Exemplo:
  /// {
  ///   "id": 1,
  ///   "nome": "Setor A"
  /// }

  List<Map<String, dynamic>> setores = [
    {"id": 1, "nome": "Setor A"},

    {"id": 2, "nome": "Setor B"},

    {"id": 3, "nome": "Setor C"},

    {"id": 4, "nome": "Setor D"},

    {"id": 5, "nome": "Setor E"},

    {"id": 6, "nome": "Setor F"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),

      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 10, 85, 64),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),

        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 20),

            child: Row(
              children: [
                Text(
                  "Olá ADMIN",
                  style: TextStyle(
                    color: Color.fromARGB(255, 249, 250, 250),
                    fontSize: 20,
                  ),
                ),

                SizedBox(width: 10),

                CircleAvatar(child: Icon(Icons.person)),
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
              // LISTA DE SETORES
              Expanded(
                child: ListView.builder(
                  itemCount: setores.length,

                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,

                          MaterialPageRoute(
                            builder: (context) =>
                                SetorScreen(nomeSetor: setores[index]["nome"]),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 20),

                        height: 120,

                        padding: const EdgeInsets.all(15),

                        decoration: BoxDecoration(
                          color: Colors.grey[400],

                          borderRadius: BorderRadius.circular(10),
                        ),

                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,

                          children: [
                            Text(
                              setores[index]["nome"],

                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
