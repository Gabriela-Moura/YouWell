import 'package:flutter/material.dart';
import 'package:youwell/admin.dart';
import 'package:youwell/main.dart';
import 'package:youwell/temperatura_screen.dart';
import 'package:youwell/screens/home_screen.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:youwell/setor_screen.dart';
import 'package:youwell/simulacaoBD/dados_sensores.dart';

class TemperaturaScreen extends StatelessWidget {
  const TemperaturaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 230, 230, 230),

      // MENU HAMBÚRGUER
      drawer: Drawer(
        child: ListView(
          children: [
            ListTile(
              leading: const Icon(Icons.thermostat),

              title: const Text("Temperatura"),

              onTap: () {},
            ),

            ListTile(
              leading: const Icon(Icons.air),

              title: const Text("Umidade"),

              onTap: () {},
            ),

            ListTile(
              leading: const Icon(Icons.volume_up),

              title: const Text("Ruído"),

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

        title: Text('oi', style: TextStyle(color: Colors.white)),

        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 20),

            child: Row(
              children: [
                Text(
                  "Olá ADMIN",
                  style: TextStyle(fontSize: 20, color: Colors.white),
                ),

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
            Container(
              width: double.infinity,
              height: 300,
              padding: const EdgeInsets.all(16),

              child: LineChart(
                LineChartData(
                  minY: 20,
                  maxY: 32,

                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,

                        getTitlesWidget: (value, meta) {
                          int indice = value.toInt();

                          if (indice >= 0 && indice < dadosSensores.length) {
                            return Text(dadosSensores[indice]["horario"]);
                          }

                          return const Text("");
                        },
                      ),
                    ),

                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true),
                    ),

                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),

                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),

                  lineBarsData: [
                    LineChartBarData(
                      spots: dadosSensores.asMap().entries.map((item) {
                        int indice = item.key;

                        double temperatura = item.value["temperatura"]
                            .toDouble();

                        return FlSpot(indice.toDouble(), temperatura);
                      }).toList(),

                      isCurved: true,

                      dotData: const FlDotData(show: true),

                      belowBarData: BarAreaData(show: true),
                    ),
                  ],
                ),
              ),
            ),

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
}
