import 'package:flutter/material.dart';
import 'package:youwell/admin.dart';
import 'package:youwell/main.dart';
import 'package:youwell/temperatura_screen.dart';
import 'package:youwell/screens/home_screen.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:youwell/qualidade_ar.dart';
import 'package:youwell/ruido.dart';
import 'package:youwell/alertas.dart';
import 'package:youwell/historico.dart';

class SetorScreen extends StatelessWidget {
  final String nomeSetor;
  final String nomeUsuario;

  const SetorScreen({super.key, required this.nomeSetor, required this.nomeUsuario});

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
                color: Color.fromARGB(255, 10, 85, 64),
              ),

              child: Text(
                nomeSetor,

                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),

              title: const Text(
                "Início",
                style: TextStyle(color: Color.fromARGB(255, 3, 3, 3)),
              ),

              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.thermostat),

              title: const Text(
                "Temperatura",
                style: TextStyle(color: Color.fromARGB(255, 3, 3, 3)),
              ),

              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TemperaturaScreen(nomeSetor: nomeSetor, nomeUsuario: nomeUsuario),
                  ),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.air),

              title: const Text(
                "Qualidade do Ar",
                style: TextStyle(color: Color.fromARGB(255, 38, 23, 23)),
              ),

              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ArScreen(nomeSetor: nomeSetor, nomeUsuario: nomeUsuario)),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.volume_up),

              title: const Text(
                "Ruído",
                style: TextStyle(color: Color.fromARGB(255, 3, 3, 3)),
              ),

              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RuidoScreen(nomeSetor: nomeSetor, nomeUsuario: nomeUsuario)),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.access_alarm),

              title: const Text(
                "Alertas",
                style: TextStyle(color: Color.fromARGB(255, 3, 3, 3)),
              ),

              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AlertaScreen()),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.picture_as_pdf),

              title: const Text(
                "Histórico Geral (PDF)",
                style: TextStyle(color: Color.fromARGB(255, 3, 3, 3)),
              ),

              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HistoricoScreen()),
                );
              },
            ),
          ],
        ),
      ),

      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 10, 85, 64),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),

        title: Text(nomeSetor, style: TextStyle(color: Colors.white)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Row(
              children: [
                Text(
                  "Olá $nomeUsuario",
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.white,
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

      body: SingleChildScrollView(
        child: Padding(
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
              Container(
                width: double.infinity,
                height: 300,
                padding: const EdgeInsets.all(20),

                decoration: BoxDecoration(
                  color: const Color.fromARGB(157, 184, 184, 184),
                  borderRadius: BorderRadius.circular(10),
                ),

                child: Expanded(
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
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
                onDestinationSelected: (index) {
                  if (index == 1) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AlertaScreen()),
                    );
                  }

                  if (index == 2) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => HistoricoScreen()),
                    );
                  }
                },
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.window),
                    label: 'Geral',
                  ),
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
      
    );
  }

  // CARD
  static Widget infoCard(String titulo, String valor) {
    return Expanded(
      child: Container(
        height: 120,
        margin: const EdgeInsets.only(right: 15),

        decoration: BoxDecoration(
          color: Color.fromARGB(122, 10, 85, 64),

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
