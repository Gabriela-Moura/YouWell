import 'package:flutter/material.dart';
import 'package:youwell/admin.dart';
import 'package:youwell/main.dart';
import 'package:fl_chart/fl_chart.dart';

class SetorScreen extends StatelessWidget {
  final String nomeSetor;

  const SetorScreen({super.key, required this.nomeSetor});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 230, 230, 230),

      // MENU HAMBÚRGUER
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 161, 161, 161),
              ),

              child: Text(
                nomeSetor,

                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            ListTile(
              leading: const Icon(Icons.thermostat),

              title: const Text("Temperatura"),

              onTap: () {},
            ),

            ListTile(
              leading: const Icon(Icons.water_drop),

              title: const Text("Umidade"),

              onTap: () {},
            ),

            ListTile(
              leading: const Icon(Icons.air),

              title: const Text("Qualidade do ar"),

              onTap: () {},
            ),

            ListTile(
              leading: const Icon(Icons.volume_up),

              title: const Text("Ruído"),

              onTap: () {},
            ),

            ListTile(
              leading: const Icon(Icons.people),

              title: const Text("Funcionários"),

              onTap: () {},
            ),

            ListTile(
              leading: const Icon(Icons.access_alarm),

              title: const Text("Alertas"),

              onTap: () {},
            ),

            ListTile(
              leading: const Icon(Icons.picture_as_pdf),

              title: const Text("Histórico Geral (PDF)"),

              onTap: () {},
            ),
          ],
        ),
      ),

      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 10, 85, 64),

        title: Text(nomeSetor),

        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 20),

            child: Row(
              children: [
                Text("Olá ADMIN", style: TextStyle(fontSize: 20)),

                SizedBox(width: 10),

                CircleAvatar(child: Icon(Icons.person)),
              ],
            ),
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [
            // CARDS
            Row(
              children: [
                infoCard("Temperatura", "25°C"),
                infoCard("Umidade", "70%"),
              ],
            ),

            SizedBox(height: 10),

            Row(
              children: [
                infoCard("Qualidade do ar", "70%"),
                infoCard("Ruído", "30dB"),
              ],
            ),

            const SizedBox(height: 20),

            // GRÁFICO
            Expanded(
              child: Container(
                width: double.infinity,

                decoration: BoxDecoration(
                  color: Colors.grey[400],

                  borderRadius: BorderRadius.circular(10),
                ),

                padding: const EdgeInsets.all(20),

                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(show: true),

                    borderData: FlBorderData(show: true),

                    titlesData: FlTitlesData(show: true),

                    lineBarsData: [
                      // TEMPERATURA
                      LineChartBarData(
                        spots: [
                          FlSpot(0, 22),
                          FlSpot(1, 23),
                          FlSpot(2, 24),
                          FlSpot(3, 25),
                          FlSpot(4, 24),
                          FlSpot(5, 23),
                        ],

                        isCurved: true,

                        barWidth: 4,
                      ),

                      // UMIDADE
                      LineChartBarData(
                        spots: [
                          FlSpot(0, 60),
                          FlSpot(1, 62),
                          FlSpot(2, 58),
                          FlSpot(3, 70),
                          FlSpot(4, 68),
                          FlSpot(5, 65),
                        ],

                        isCurved: true,

                        barWidth: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SizedBox(height: 20),

            // BOTÕES
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},

                    child: const Padding(
                      padding: EdgeInsets.all(20),

                      child: Text("Alertas ativos"),
                    ),
                  ),
                ),

                const SizedBox(width: 20),

                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},

                    child: const Padding(
                      padding: EdgeInsets.all(5),

                      child: Text("Gerar relatório (PDF)"),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),

            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AdminScreen()),
                );
              },

              child: const Text("Voltar"),
            ),
          ],
        ),
      ),
    );
  }

  // CARD
  static Widget infoCard(String titulo, String valor) {
    return Expanded(
      child: Container(
        height: 120,

        margin: const EdgeInsets.only(right: 15),

        decoration: BoxDecoration(
          color: Colors.grey[400],

          borderRadius: BorderRadius.circular(10),
        ),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            Text(
              titulo,

              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),

            const SizedBox(height: 15),

            Text(
              valor,

              style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
