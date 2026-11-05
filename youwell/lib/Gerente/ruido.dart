import 'package:flutter/material.dart';
import 'package:youwell/Gerente/temperatura_screen.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:youwell/Gerente/setor_screen_gerente.dart';
import 'package:youwell/Gerente/qualidade_ar.dart';
import 'package:youwell/alertas.dart';
import 'package:youwell/historico.dart';
import 'package:youwell/gerente.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class RuidoScreen extends StatefulWidget {
  final String nomeSetor;
  final String nomeUsuario;
  final int idSetor;

  const RuidoScreen({
    super.key,
    required this.nomeSetor,
    required this.nomeUsuario,
    required this.idSetor,
  });

  @override
  State<RuidoScreen> createState() => _RuidoScreenState();
}

class _RuidoScreenState extends State<RuidoScreen> {
  List<Map<String, dynamic>> ruidos = [];
  bool carregando = true;
  String? erro;

  String get nomeSetor => widget.nomeSetor;
  String get nomeUsuario => widget.nomeUsuario;
  int get idSetor => widget.idSetor;

  @override
  void initState() {
    super.initState();
    buscarRuidos();
  }

  Future<void> buscarRuidos() async {
    try {
      final resposta = await http.post(
        Uri.parse(
          'https://devsbee.com.br/You-Well/controllers/buscar_medicoes.php',
        ),
        body: {'id_setor': idSetor.toString()},
      );

      if (resposta.statusCode != 200) {
        throw Exception('Erro ao acessar o servidor PHP.');
      }

      final dados = jsonDecode(resposta.body);
      if (dados['success'] != true) {
        throw Exception(
          dados['mensagem'] ?? 'Não foi possível buscar os dados de ruído.',
        );
      }

      final List lista = dados['ruido'] ?? [];
      if (!mounted) return;

      setState(() {
        ruidos = lista.map((item) => Map<String, dynamic>.from(item)).toList();
        carregando = false;
        erro = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        carregando = false;
        erro = 'Não foi possível carregar os dados de ruído.';
      });
      debugPrint('Erro ao buscar ruídos: $e');
    }
  }

  String _formatarData(String data) {
    final partes = data.split('-');
    if (partes.length != 3) return data;

    return '${partes[2].padLeft(2, '0')}/${partes[1].padLeft(2, '0')}/${partes[0]}';
  }

  DateTime? _obterDataHora(Map<String, dynamic> dado) {
    return DateTime.tryParse(dado['data_hora']?.toString() ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),

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

                style: const TextStyle(
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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GerenteScreen(
                      setorGerente: nomeSetor,
                      nomeGerente: nomeUsuario,
                      idSetor: idSetor,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.window),

              title: const Text(
                "Geral",
                style: TextStyle(color: Color.fromARGB(255, 3, 3, 3)),
              ),

              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SetorScreen(
                      nomeSetor: nomeSetor,
                      nomeUsuario: nomeUsuario,
                      idSetor: idSetor,
                    ),
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
                    builder: (context) => TemperaturaScreen(
                      nomeSetor: nomeSetor,
                      nomeUsuario: nomeUsuario,
                      idSetor: idSetor,
                    ),
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
                  MaterialPageRoute(
                    builder: (context) => ArScreen(
                      nomeSetor: nomeSetor,
                      nomeUsuario: nomeUsuario,
                      idSetor: idSetor,
                    ),
                  ),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.volume_up),

              title: const Text("Ruído"),

              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RuidoScreen(
                      nomeSetor: nomeSetor,
                      nomeUsuario: nomeUsuario,
                      idSetor: idSetor,
                    ),
                  ),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.access_alarm),

              title: const Text("Alertas"),

              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AlertaScreen(
                    idSetor: idSetor,
                    nomeSetor: nomeSetor,
                  )),
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

        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Row(
              children: [
                Text(
                  "Olá, $nomeUsuario",
                  style: const TextStyle(fontSize: 20, color: Colors.white),
                ),
                const SizedBox(width: 10),
                const CircleAvatar(child: Icon(Icons.person)),
              ],
            ),
          ),
        ],
      ),

      body: carregando
          ? const Center(child: CircularProgressIndicator())
          : erro != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(erro!),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: buscarRuidos,
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            )
          : ruidos.isEmpty
          ? const Center(child: Text('Nenhuma medição de ruído encontrada.'))
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
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
                            const Center(
                              child: Text(
                                'Ruído',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color.fromARGB(255, 10, 85, 64),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Center(
                              child: Text(
                                'Variação ao longo do dia',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 230,
                              child: LineChart(
                                LineChartData(
                                  minY: 40,
                                  maxY: 80,
                                  gridData: FlGridData(
                                    show: true,
                                    horizontalInterval: 5,
                                    verticalInterval: 2,
                                    getDrawingHorizontalLine: (value) => FlLine(
                                      color: Colors.grey.withValues(
                                        alpha: 0.18,
                                      ),
                                      strokeWidth: 1,
                                    ),
                                    getDrawingVerticalLine: (value) => FlLine(
                                      color: Colors.grey.withValues(
                                        alpha: 0.12,
                                      ),
                                      strokeWidth: 1,
                                    ),
                                  ),
                                  borderData: FlBorderData(show: false),
                                  titlesData: FlTitlesData(
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        interval: 1,

                                        getTitlesWidget: (value, meta) {
                                          int indice = value.toInt();

                                          if (indice >= 0 &&
                                              indice < ruidos.length) {
                                            final dataHora = _obterDataHora(
                                              ruidos[indice],
                                            );
                                            return Text(
                                              dataHora == null
                                                  ? ''
                                                  : '${dataHora.hour.toString().padLeft(2, '0')}:${dataHora.minute.toString().padLeft(2, '0')}',
                                            );
                                          }

                                          return const Text("");
                                        },
                                      ),
                                    ),

                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 45,
                                        interval: 5,
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
                                      spots: ruidos.asMap().entries.map((item) {
                                        int indice = item.key;
                                        double ruido =
                                            double.tryParse(
                                              item.value["valor"].toString(),
                                            ) ??
                                            0;

                                        return FlSpot(indice.toDouble(), ruido);
                                      }).toList(),

                                      isCurved: true,
                                      color: Colors.blue,
                                      barWidth: 3,
                                      dotData: const FlDotData(show: true),
                                      belowBarData: BarAreaData(
                                        show: true,
                                        color: Colors.blue.withValues(
                                          alpha: 0.12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

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
                            const Center(
                              child: Text(
                                'Histórico detalhado',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color.fromARGB(255, 10, 85, 64),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
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
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),

                                    Padding(
                                      padding: EdgeInsets.all(5),
                                      child: Text(
                                        "Hora",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),

                                    Padding(
                                      padding: EdgeInsets.all(5),
                                      child: Text(
                                        "Valor",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                // DADOS
                                ...ruidos.map((dado) {
                                  final dataHora = _obterDataHora(dado);
                                  return TableRow(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(5),
                                        child: Text(
                                          dataHora == null
                                              ? ''
                                              : _formatarData(
                                                  '${dataHora.year}-${dataHora.month.toString().padLeft(2, '0')}-${dataHora.day.toString().padLeft(2, '0')}',
                                                ),
                                        ),
                                      ),

                                      Padding(
                                        padding: const EdgeInsets.all(5),
                                        child: Text(
                                          dataHora == null
                                              ? ''
                                              : '${dataHora.hour.toString().padLeft(2, '0')}:${dataHora.minute.toString().padLeft(2, '0')}',
                                        ),
                                      ),

                                      Padding(
                                        padding: const EdgeInsets.all(5),
                                        child: Text('${dado["valor"]} dB'),
                                      ),
                                    ],
                                  );
                                }),
                              ],
                            ),
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
}
