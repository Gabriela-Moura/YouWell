import 'package:flutter/material.dart';
import 'package:youwell/admin.dart';
import 'package:youwell/main.dart';
import 'package:youwell/temperatura_screen.dart';
import 'package:youwell/screens/home_screen.dart';
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

              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TemperaturaScreen(),
                  ),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.air),

              title: const Text("Umidade"),

              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HomeScreen())
                );
              },
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

        title: Text(nomeSetor, style: TextStyle(color: Colors.white)),

        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 20),

            child: Row(
              children: [
                Text("Olá ADMIN", style: TextStyle(fontSize: 20, color:Colors.white)),

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
            SizedBox(
              height: 90,
              width: 300,
              child: Row(
                children: [
                  infoCard("Temperatura", "25°C"),
                  infoCard("Umidade", "70%"),
                ],
              ),
            ),

            SizedBox(height: 10),

            SizedBox(
              height: 90,
              width: 300,
              child: Row(
                children: [
                  infoCard("Qualidade do ar", "70%"),
                  infoCard("Ruído", "30dB"),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // GRÁFICO
            Expanded(
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: 100,
                  minX: 0,
                  maxX: 20,

                  // Grade
                  gridData: FlGridData(
                    show: true,
                    horizontalInterval: 25,
                    verticalInterval: 4,
                  ),

                  // Borda
                  borderData: FlBorderData(show: true),

                  // Eixos
                  titlesData: FlTitlesData(
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),

                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),

                    // Eixo Y
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 25,
                        reservedSize: 35,
                      ),
                    ),

                    // Eixo X
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 2,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}:00',
                            style: const TextStyle(fontSize: 9),
                          );
                        },
                      ),
                    ),
                  ),

                  lineBarsData: [
                    // TEMPERATURA
                    LineChartBarData(
                      spots: [
                        FlSpot(0, 25),
                        FlSpot(4, 24),
                        FlSpot(8, 26),
                        FlSpot(12, 28),
                        FlSpot(16, 27),
                        FlSpot(20, 25),
                      ],
                      isCurved: true,
                      color: Color.fromARGB(255, 255, 0, 0),
                      barWidth: 2,
                      dotData: FlDotData(show: false),
                    ),

                    // RUÍDO
                    LineChartBarData(
                      spots: [
                        FlSpot(0, 45),
                        FlSpot(4, 40),
                        FlSpot(8, 65),
                        FlSpot(12, 70),
                        FlSpot(16, 60),
                        FlSpot(20, 50),
                      ],
                      isCurved: true,
                      color: Color.fromARGB(255, 255, 230, 0),
                      barWidth: 2,
                      dotData: FlDotData(show: false),
                    ),

                    // QUALIDADE DO AR
                    LineChartBarData(
                      spots: [
                        FlSpot(0, 80),
                        FlSpot(4, 82),
                        FlSpot(8, 75),
                        FlSpot(12, 78),
                        FlSpot(16, 80),
                        FlSpot(20, 82),
                      ],
                      isCurved: true,
                      color: Color.fromARGB(255, 0, 60, 255),
                      barWidth: 2,
                      dotData: FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            NavigationBar(
              onDestinationSelected: (index) {
                if (index == 1) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AdminScreen()),
                  );
                }

                if(index == 2) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => HomeScreen())
                  );
                }
              },
              destinations: const [
                NavigationDestination(icon: Icon(Icons.home), label: 'Início'),
                NavigationDestination(
                  icon: Icon(Icons.notifications),
                  label: 'Alertas',
                ),
                NavigationDestination(
                  icon: Icon(Icons.bar_chart),
                  label: 'Relatório',
                ),
              ],
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
            Text(titulo, style: const TextStyle(fontSize: 15)),

            const SizedBox(height: 15),

            Text(
              valor,

              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}