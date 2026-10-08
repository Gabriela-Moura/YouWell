import 'package:flutter/material.dart';
import 'package:youwell/main.dart';
import 'package:youwell/setor_screen.dart';

class UsuarioTi extends StatefulWidget {
  const UsuarioTi({super.key});

  @override
  State<UsuarioTi> createState() => _UsuarioTiState();
}

class _UsuarioTiState extends State<UsuarioTi> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 10, 85, 64),

        iconTheme: const IconThemeData(color: Colors.white),

        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),

            child: Row(
              children: [
                const Text(
                  "TI",
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),

                const SizedBox(width: 10),

                const CircleAvatar(child: Icon(Icons.person)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
