import 'package:flutter/material.dart';
import 'package:youwell/admin.dart';
import 'package:youwell/gerente.dart';
import 'package:youwell/main.dart';
import 'package:youwell/Administrador/temperatura_screen.dart';
import 'package:youwell/screens/home_screen.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:youwell/Administrador/qualidade_ar.dart';
import 'package:youwell/Administrador/ruido.dart';
import 'package:youwell/alertas.dart';
import 'package:youwell/admin.dart';
import 'package:youwell/historico.dart';
import 'package:youwell/simulacaoBD/dados_sensores.dart';

class SetorScreen extends StatelessWidget {
  final String nomeSetor;
  final String nomeUsuario;

  const SetorScreen({
    super.key,
    required this.nomeSetor,
    required this.nomeUsuario,
  });

  Widget _legendaGrafico(String texto, Color cor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(texto, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    const verde = Color.fromARGB(255, 10, 85, 64);
    const fundo = Color(0xFFF4F7F5);
    return Scaffold(
      backgroundColor: fundo,

      // MENU HAMBÚRGUER
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 10, 85, 64),
              ),

              child: Text(
                'Olá, $nomeUsuario',

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
                style: TextStyle(color: Color.fromARGB(255, 3, 3, 3), fontSize: 18),
              ),

              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AdminScreen(
                      nomeSetor: nomeSetor,
                      nomeAdmin: nomeUsuario,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.window),

              title: const Text(
                "Geral",
                style: TextStyle(color: Color.fromARGB(255, 3, 3, 3), fontSize: 18),
              ),

              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SetorScreen(
                      nomeSetor: nomeSetor,
                      nomeUsuario: nomeUsuario,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.thermostat),

              title: const Text(
                "Temperatura",
                style: TextStyle(color: Color.fromARGB(255, 3, 3, 3), fontSize: 18),
              ),

              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TemperaturaScreen(
                      nomeSetor: nomeSetor,
                      nomeUsuario: nomeUsuario,
                    ),
                  ),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.air),

              title: const Text(
                "Qualidade do Ar",
                style: TextStyle(color: Color.fromARGB(255, 38, 23, 23), fontSize: 18),
              ),

              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ArScreen(
                      nomeSetor: nomeSetor,
                      nomeUsuario: nomeUsuario,
                    ),
                  ),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.volume_up),

              title: const Text(
                "Ruído",
                style: TextStyle(color: Color.fromARGB(255, 3, 3, 3), fontSize: 18),
              ),

              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RuidoScreen(
                      nomeSetor: nomeSetor,
                      nomeUsuario: nomeUsuario,
                    ),
                  ),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.access_alarm),

              title: const Text(
                "Alertas",
                style: TextStyle(color: Color.fromARGB(255, 3, 3, 3), fontSize: 18),
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
                style: TextStyle(color: Color.fromARGB(255, 3, 3, 3), fontSize: 18),
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
        iconTheme: const IconThemeData(color: Colors.white),

        title: Text(nomeSetor, style: TextStyle(color: Colors.white)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Row(
              children: [
                Text(
                  "Olá $nomeUsuario",
                  style: const TextStyle(fontSize: 20, color: Colors.white),
                ),
                const SizedBox(width: 10),
                const CircleAvatar(child: Icon(Icons.person)),
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
                width: double.infinity,
                child: Row(
                  children: [
                    infoCard("Temperatura", "25°C", Icons.thermostat),
                    infoCard("Umidade", "70%", Icons.water_drop),
                  ],
                ),
              ),

              SizedBox(height: 10),

              SizedBox(
                height: 90,
                width: double.infinity,
                child: Row(
                  children: [
                    infoCard("Qualidade do ar", "70%", Icons.air),
                    infoCard("Ruído", "30dB", Icons.volume_up),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // GRÁFICO
              Card(
                elevation: 2,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Indicadores do setor',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 10, 85, 64),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Acompanhamento ao longo do dia',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 16),

                      SizedBox(
                        height: 230,
                        child: LineChart(
                          LineChartData(
                            minY: 0,
                            maxY: 100,
                            minX: 0,
                            maxX: 20,
                            gridData: FlGridData(
                              show: true,
                              horizontalInterval: 25,
                              verticalInterval: 4,
                              getDrawingHorizontalLine: (value) => FlLine(
                                color: Colors.grey.withValues(alpha: 0.18),
                                strokeWidth: 1,
                              ),
                              getDrawingVerticalLine: (value) => FlLine(
                                color: Colors.grey.withValues(alpha: 0.12),
                                strokeWidth: 1,
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            titlesData: FlTitlesData(
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  interval: 25,
                                  reservedSize: 36,
                                  getTitlesWidget: (value, meta) => Text(
                                    value.toInt().toString(),
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  interval: 4,
                                  reservedSize: 30,
                                  getTitlesWidget: (value, meta) => Text(
                                    '${value.toInt().toString().padLeft(2, '0')}:00',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            lineBarsData: [
                              LineChartBarData(
                                spots: const [
                                  FlSpot(0, 25),
                                  FlSpot(4, 24),
                                  FlSpot(8, 26),
                                  FlSpot(12, 28),
                                  FlSpot(16, 27),
                                  FlSpot(20, 25),
                                ],
                                isCurved: true,
                                color: Colors.deepOrange,
                                barWidth: 3,
                                dotData: const FlDotData(show: true),
                              ),
                              LineChartBarData(
                                spots: const [
                                  FlSpot(0, 45),
                                  FlSpot(4, 40),
                                  FlSpot(8, 65),
                                  FlSpot(12, 70),
                                  FlSpot(16, 60),
                                  FlSpot(20, 50),
                                ],
                                isCurved: true,
                                color: Colors.blue,
                                barWidth: 3,
                                dotData: const FlDotData(show: true),
                              ),
                              LineChartBarData(
                                spots: const [
                                  FlSpot(0, 80),
                                  FlSpot(4, 82),
                                  FlSpot(8, 75),
                                  FlSpot(12, 78),
                                  FlSpot(16, 80),
                                  FlSpot(20, 82),
                                ],
                                isCurved: true,
                                color: Colors.teal,
                                barWidth: 3,
                                dotData: const FlDotData(show: true),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Legenda
                      Wrap(
                        spacing: 16,
                        runSpacing: 8,
                        children: [
                          _legendaGrafico('Temperatura', Colors.deepOrange),
                          _legendaGrafico('Ruído', Colors.blue),
                          _legendaGrafico('Qualidade do ar', Colors.teal),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // CARD
  static Widget infoCard(String titulo, String valor, IconData icone) {
    return Expanded(
      child: Card(
        elevation: 1,
        margin: const EdgeInsets.only(right: 10),
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFFE1EFE8),
                child: Icon(
                  icone,
                  color: const Color.fromARGB(255, 10, 85, 64),
                  size: 25,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      valor,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
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
