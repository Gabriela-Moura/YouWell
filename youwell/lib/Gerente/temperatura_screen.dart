import 'package:flutter/material.dart';
import 'package:youwell/admin.dart';
import 'package:youwell/main.dart';
import 'package:youwell/login_screen.dart';
import 'package:youwell/screens/home_screen.dart';
import 'package:youwell/Gerente/qualidade_ar.dart';
import 'package:youwell/Gerente/ruido.dart';
import 'package:youwell/alertas.dart';
import 'package:youwell/historico.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:youwell/Gerente/setor_screen_gerente.dart';
import 'package:youwell/gerente.dart';
import 'package:youwell/services/api_service.dart';

import 'dart:convert';
import 'package:http/http.dart' as http;

class TemperaturaScreen extends StatefulWidget {
  final String nomeSetor;
  final String nomeUsuario;
  final int idSetor;
  final int idUsuario;
  final String? fotoPerfil;

  const TemperaturaScreen({
    super.key,
    required this.nomeSetor,
    required this.nomeUsuario,
    required this.idSetor,
    required this.idUsuario,
    this.fotoPerfil,
  });

  @override
  State<TemperaturaScreen> createState() => _TemperaturaScreenState();
}

class _TemperaturaScreenState extends State<TemperaturaScreen> {
  List<Map<String, dynamic>> temperaturas = [];

  bool carregando = true;
  String? erro;

  String get nomeSetor => widget.nomeSetor;
  String get nomeUsuario => widget.nomeUsuario;
  int get idSetor => widget.idSetor;
  int get idUsuario => widget.idUsuario;

  @override
  void initState() {
    super.initState();
    buscarTemperaturas();
  }

  // RETORNAR AS 12 MEDIÇÕES MAIS RECENTES.
  List<Map<String, dynamic>> get ultimasTemperaturas {
    final lista = List<Map<String, dynamic>>.from(temperaturas);

    lista.sort((a, b) {
      final dataA = DateTime.parse(a['data_hora'].toString());
      final dataB = DateTime.parse(b['data_hora'].toString());

      return dataA.compareTo(dataB);
    });

    if (lista.length > 12) {
      return lista.sublist(lista.length - 12);
    }

    return lista;
  }

  // MAIOR TEMPERATURA REGISTRADA.
  double get maiorTemperatura {
    final valores = ultimasTemperaturas
        .map((item) => double.parse(item['valor'].toString()))
        .toList();

    if (valores.isEmpty) return 30;

    return valores.reduce((a, b) => a > b ? a : b);
  }

  // MENOR TEMPERATURA REGISTRADA.
  double get menorTemperatura {
    final valores = ultimasTemperaturas
        .map((item) => double.parse(item['valor'].toString()))
        .toList();

    if (valores.isEmpty) return 0;

    return valores.reduce((a, b) => a < b ? a : b);
  }

  // INTERVALO AUTOMÁTICO DO EIXO Y.
  double get intervaloTemperatura {
    final diferenca = maiorTemperatura - menorTemperatura;

    if (diferenca == 0) {
      return maiorTemperatura.abs() * 0.2 > 0
          ? maiorTemperatura.abs() * 0.2
          : 1;
    }

    return diferenca / 5;
  }

  List<Map<String, dynamic>> converterTemperaturas(dynamic resposta) {
    // Caso o PHP retorne uma lista diretamente.
    if (resposta is List) {
      return resposta
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    // Caso o PHP retorne um objeto.
    if (resposta is Map) {
      final conteudo =
          resposta['medicoes'] ??
          resposta['dados'] ??
          resposta['leituras'] ??
          resposta['temperaturas'];

      if (conteudo is List) {
        return conteudo
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }

      // Caso tenha vindo apenas uma medição.
      if (resposta.containsKey('valor') && resposta.containsKey('data_hora')) {
        return [Map<String, dynamic>.from(resposta)];
      }

      // Caso as medições estejam dentro de outro objeto.
      if (resposta.values.isNotEmpty &&
          resposta.values.every((item) => item is Map)) {
        return resposta.values
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }
    }

    return [];
  }

  Future<void> buscarTemperaturas() async {
    try {
      final resposta = await http.post(
        Uri.parse(
          'https://devsbee.com.br/You-Well/controllers/buscar_historico_medicoes.php',
        ),
        body: {'id_setor': idSetor.toString()},
      );

      debugPrint('STATUS TEMPERATURA: ${resposta.statusCode}');
      debugPrint('RESPOSTA TEMPERATURA: ${resposta.body}');

      if (resposta.statusCode != 200) {
        throw Exception('Erro ao acessar o servidor PHP.');
      }

      final dados = jsonDecode(utf8.decode(resposta.bodyBytes));

      if (dados is! Map || dados['success'] != true) {
        throw Exception(
          dados is Map
              ? dados['mensagem'] ?? 'Erro ao buscar temperaturas.'
              : 'Resposta inválida do servidor.',
        );
      }

      final lista = converterTemperaturas(dados['temperatura']);

      if (!mounted) return;

      setState(() {
        temperaturas = lista;
        carregando = false;
        erro = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        carregando = false;
        erro = 'Não foi possível carregar as temperaturas.';
      });

      debugPrint('Erro ao buscar temperaturas: $e');
    }
  }

  String _formatarData(String data) {
    final partes = data.split('-');
    if (partes.length != 3) return data;

    return '${partes[2].padLeft(2, '0')}/${partes[1].padLeft(2, '0')}/${partes[0]}';
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
              leading: const Icon(Icons.home_outlined),

              title: const Text(
                "Início",
                style: TextStyle(color: Color.fromARGB(255, 3, 3, 3)),
              ),

              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GerenteScreen(
                      nomeGerente: nomeUsuario,
                      idUsuario: idUsuario,
                      fotoPerfil: widget.fotoPerfil,
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
                      idUsuario: idUsuario,
                      fotoPerfil: widget.fotoPerfil,
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
                      idUsuario: idUsuario,
                      fotoPerfil: widget.fotoPerfil,
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
                      idUsuario: idUsuario,
                      fotoPerfil: widget.fotoPerfil,
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
                      idUsuario: idUsuario,
                      fotoPerfil: widget.fotoPerfil,
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
                  MaterialPageRoute(
                    builder: (context) =>
                        AlertaScreen(idSetor: idSetor, nomeSetor: nomeSetor),
                  ),
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
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text(
                "Logout",
                style: TextStyle(
                  color: Color.fromARGB(255, 3, 3, 3),
                  fontSize: 18,
                ),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LoginScreen(
                      nomeSetor: nomeSetor,
                    ),
                  ),
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
                  style: TextStyle(fontSize: 20, color: Colors.white),
                ),

                SizedBox(width: 10),

                CircleAvatar(
                  backgroundColor: Colors.white,
                  backgroundImage: widget.fotoPerfil != null &&
                          widget.fotoPerfil!.isNotEmpty
                      ? MemoryImage(base64Decode(widget.fotoPerfil!))
                      : null,
                  child: widget.fotoPerfil == null || widget.fotoPerfil!.isEmpty
                      ? const Icon(Icons.person, color: Color.fromARGB(255, 10, 85, 64))
                      : null,
                ),
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
                    onPressed: buscarTemperaturas,
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            )
          : temperaturas.isEmpty
          ? const Center(
              child: Text('Nenhuma medição de temperatura encontrada.'),
            )
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
                                'Temperatura',
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
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 230,
                              child: LineChart(
                                LineChartData(
                                  // ESCALA AUTOMÁTICA DO EIXO Y.
                                  minY: menorTemperatura,
                                  maxY: maiorTemperatura,

                                  // INTERVALO AUTOMÁTICO.
                                  gridData: FlGridData(
                                    show: true,
                                    horizontalInterval: intervaloTemperatura,
                                    getDrawingHorizontalLine: (value) => FlLine(
                                      color: Colors.grey.withValues(
                                        alpha: 0.18,
                                      ),
                                      strokeWidth: 1,
                                    ),
                                  ),

                                  borderData: FlBorderData(show: false),

                                  titlesData: FlTitlesData(
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        interval: ultimasTemperaturas.length > 6
                                            ? 2
                                            : 1,
                                        getTitlesWidget: (value, meta) {
                                          final indice = value.toInt();

                                          if (indice >= 0 &&
                                              indice <
                                                  ultimasTemperaturas.length) {
                                            final dataHora = DateTime.parse(
                                              ultimasTemperaturas[indice]['data_hora']
                                                  .toString(),
                                            );

                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                top: 8,
                                              ),
                                              child: Text(
                                                '${dataHora.hour.toString().padLeft(2, '0')}:'
                                                '${dataHora.minute.toString().padLeft(2, '0')}',
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                ),
                                              ),
                                            );
                                          }

                                          return const SizedBox.shrink();
                                        },
                                      ),
                                    ),

                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 65,
                                        interval: intervaloTemperatura,
                                        getTitlesWidget: (value, meta) {
                                          return Text(
                                            value.toStringAsFixed(1),
                                            style: const TextStyle(
                                              fontSize: 10,
                                            ),
                                          );
                                        },
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
                                      spots: ultimasTemperaturas
                                          .asMap()
                                          .entries
                                          .map((item) {
                                            final indice = item.key;

                                            final temperatura = double.parse(
                                              item.value['valor'].toString(),
                                            );

                                            return FlSpot(
                                              indice.toDouble(),
                                              temperatura,
                                            );
                                          })
                                          .toList(),

                                      isCurved: true,
                                      color: Colors.deepOrange,
                                      barWidth: 3,

                                      dotData: const FlDotData(show: true),

                                      belowBarData: BarAreaData(
                                        show: true,
                                        color: Colors.deepOrange.withValues(
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
                                ...temperaturas.map((dado) {
                                  final dataHora = DateTime.parse(
                                    dado['data_hora'].toString(),
                                  );

                                  return TableRow(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(5),
                                        child: Text(
                                          _formatarData(
                                            '${dataHora.year}-${dataHora.month.toString().padLeft(2, '0')}-${dataHora.day.toString().padLeft(2, '0')}',
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(5),
                                        child: Text(
                                          '${dataHora.hour.toString().padLeft(2, '0')}:${dataHora.minute.toString().padLeft(2, '0')}',
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(5),
                                        child: Text('${dado['valor']} °C'),
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