import 'package:flutter/material.dart';
import 'package:youwell/admin.dart';
import 'package:youwell/main.dart';
import 'package:youwell/temperatura_screen.dart';
import 'package:youwell/screens/home_screen.dart';
import 'package:youwell/screens/home_screen.dart';
import 'package:youwell/temperatura_screen.dart';
import 'package:youwell/qualidade_ar.dart';
import 'package:youwell/ruido.dart';
import 'package:youwell/alertas.dart';
import 'package:youwell/historico.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:youwell/setor_screen.dart';
import 'package:youwell/simulacaoBD/dados_sensores.dart';

class TemperaturaScreen extends StatelessWidget {
  final String nomeSetor;

  const TemperaturaScreen({
    super.key,
    required this.nomeSetor,
  });

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
              leading: const Icon(Icons.home),

              title: const Text("Início"),

              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminScreen(),
                  ),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.window),

              title: const Text("Geral"),

              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminScreen(),
                  ),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.thermostat),

              title: const Text("Temperatura"),

              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TemperaturaScreen(nomeSetor:nomeSetor),
                  ),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.air),

              title: const Text("Qualidade do Ar"),

              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ArScreen(nomeSetor: nomeSetor)),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.volume_up),

              title: const Text("Ruído"),

              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RuidoScreen(nomeSetor: nomeSetor)),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.access_alarm),

              title: const Text("Alertas"),

              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AlertaScreen()),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.picture_as_pdf),

              title: const Text("Histórico Geral (PDF)"),

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

        title: Text(nomeSetor, style: TextStyle(color: Colors.white)),

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

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(
                'Temperatura',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),

              SizedBox(height: 10),

              Container(
                width: double.infinity,
                height: 300,
                padding: const EdgeInsets.all(20),

                decoration: BoxDecoration(
                  color: const Color.fromARGB(157, 184, 184, 184),
                  borderRadius: BorderRadius.circular(10),
                ),

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
                              return Text(dadosSensores[indice]["hora"]);
                            }

                            return const Text("");
                          },
                        ),
                      ),

                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 45,
                          interval: 2,
                        ),
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

              SizedBox(height: 20),

              Text(
                'Histórico detalhado',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),

              SizedBox(height: 20),

              // tabela
              Container(
                width: double.infinity,
                height: 200,
                padding: const EdgeInsets.all(20),

                decoration: BoxDecoration(
                  color: const Color.fromARGB(157, 184, 184, 184),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Table(
                      columnWidths: const {
                        0: FlexColumnWidth(1.5),
                        1: FlexColumnWidth(1),
                        2: FlexColumnWidth(1),
                      },

                      children: [
                        // CABEÇALHO
                        const TableRow(
                          children: [
                            Padding(
                              padding: EdgeInsets.all(5),
                              child: Text(
                                "Data",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),

                            Padding(
                              padding: EdgeInsets.all(5),
                              child: Text(
                                "Hora",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),

                            Padding(
                              padding: EdgeInsets.all(5),
                              child: Text(
                                "Valor",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),

                        // DADOS
                        ...dadosSensores.map((dado) {
                          return TableRow(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(5),
                                child: Text(dado["data"]),
                              ),

                              Padding(
                                padding: const EdgeInsets.all(5),
                                child: Text(dado["hora"]),
                              ),

                              Padding(
                                padding: const EdgeInsets.all(5),
                                child: Text("${dado["temperatura"]} °C"),
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: 10),

              NavigationBar(
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
            ],
          ),
        ),
      ),
    );
  }
}
