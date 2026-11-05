import 'package:flutter/material.dart';
import 'package:youwell/main_original.dart';
import '../sobre_nos.dart';
import '../admin.dart';
import '../gerente.dart';
import '../login_screen.dart';
import 'package:youwell/simulacaoBD/dados_sensores.dart';

class HomeScreen extends StatelessWidget {
  final String nomeSetor;

  const HomeScreen({super.key, required this.nomeSetor});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(10, 85, 64, 1),

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(200),
              child: Image.asset(
                'assets/images/logo_branco.png',
                width: 100,
                fit: BoxFit.fitHeight,
              ),
            ),

            const Text(
              "YouWell",
              style: TextStyle(
                color: Color.fromARGB(255, 255, 255, 255),
                fontSize: 40,
                fontWeight: FontWeight.bold,
              ),
            ),

            const Text(
              "Saúde e bem estar Corporativo",
              style: TextStyle(color: Colors.white, fontSize: 25),
              textAlign: TextAlign.center,
            ),

            // const Text(
            //   "Sistema completo de monitoramento ocupacional que integra IoT, análise de dados e gestão inteligente para garantir ambientes de trabalho seguros, saudáveis e produtivos.",
            //   style: TextStyle(color: Colors.white, fontSize: 20),
            //   textAlign: TextAlign.center,
            // ),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,

              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => LoginScreen(
                        nomeSetor: nomeSetor,
                      )),
                    );
                  },

                  child: const Text("Login"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
