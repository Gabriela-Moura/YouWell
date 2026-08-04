import 'package:flutter/material.dart';
import 'package:youwell/main_original.dart';
import '../sobre_nos.dart';
import '../login_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 10, 85, 64),

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(200),
              child: Image.asset(
                'assets/images/logo_branco.png',
                width: 150,
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
                      MaterialPageRoute(builder: (context) => LoginScreen()),
                    );
                  },

                  child: const Text("Entrar"),
                ),

                SizedBox(width: 5),

                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SobreNos()),
                    );
                  },

                  child: const Text("Saiba mais"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
