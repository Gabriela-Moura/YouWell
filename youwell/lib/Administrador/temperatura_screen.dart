import 'package:flutter/material.dart';
import 'package:youwell/admin.dart';
import 'package:youwell/main.dart';
import 'package:youwell/Administrador/temperatura_screen.dart';
import 'package:youwell/screens/home_screen.dart';
import 'package:youwell/screens/home_screen.dart';
import 'package:youwell/Administrador/qualidade_ar.dart';
import 'package:youwell/Administrador/ruido.dart';
import 'package:youwell/alertas.dart';
import 'package:youwell/historico.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:youwell/Administrador/setor_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class TemperaturaScreen extends StatefulWidget {
  final String nomeSetor;
  final String nomeUsuario;
  final int? idSetor;

  const TemperaturaScreen({
    super.key,
    required this.nomeSetor,
    required this.nomeUsuario,
    this.idSetor,
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

  @override
  void initState() {
    super.initState();
    buscarTemperaturas();
  }

  Future<void> buscarTemperaturas() async {
    try {
      final resposta = await http
          .post(
            Uri.parse(
              'https://devsbee.com.br/You-Well/controllers/buscar_historico_medicoes.php',
            ),
            headers: {'Accept': 'application/json'},
            body: widget.idSetor == null
                ? <String, String>{}
                : {'id_setor': widget.idSetor.toString()},
          )
          .timeout(const Duration(seconds: 15));
      if (resposta.statusCode != 200) {
        throw Exception('Erro HTTP ${resposta.statusCode}: ${resposta.body}');
      }

      final dados = jsonDecode(utf8.decode(resposta.bodyBytes));
      if (dados is! Map || dados['success'] != true) {
        throw Exception(
          dados is Map
              ? dados['mensagem'] ?? 'Não foi possível carregar as medições.'
              : 'Resposta inválida do servidor.',
        );
      }
      if (!dados.containsKey('temperatura')) {
        throw const FormatException(
          'A resposta do servidor não contém medições de temperatura.',
        );
      }

      final lista = converterTemperaturas(dados['temperatura']);
      if (!mounted) return;
      setState(() {
        temperaturas = lista;
        temperaturas.sort((a, b) =>
            (a['data_hora'] ?? '').toString().compareTo((b['data_hora'] ?? '').toString()));
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

  List<Map<String, dynamic>> converterTemperaturas(dynamic resposta) {
    if (resposta is List) {
      return resposta
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

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

      if (resposta.containsKey('valor') && resposta.containsKey('data_hora')) {
        return [Map<String, dynamic>.from(resposta)];
      }

      if (resposta.values.isNotEmpty &&
          resposta.values.every((item) => item is Map)) {
        return resposta.values
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }
    }

    if (resposta == null) return [];

    throw const FormatException('Formato de medições de temperatura inválido.');
  }

  String _formatarData(String data) {
    final partes = data.split('-');
    if (partes.length != 3) return data;

    return '${partes[2].padLeft(2, '0')}/${partes[1].padLeft(2, '0')}/${partes[0]}';
  }

  List<Map<String, dynamic>> get ultimasTemperaturas {
    final lista = List<Map<String, dynamic>>.from(temperaturas);
    return lista.length > 12 ? lista.sublist(lista.length - 12) : lista;
  }

  double get menorTemperatura {
    if (ultimasTemperaturas.isEmpty) return 0;
    return ultimasTemperaturas
        .map((item) => double.tryParse(item['valor'].toString()) ?? 0)
        .reduce((a, b) => a < b ? a : b);
  }

  double get maiorTemperatura {
    if (ultimasTemperaturas.isEmpty) return 30;
    return ultimasTemperaturas
        .map((item) => double.tryParse(item['valor'].toString()) ?? 0)
        .reduce((a, b) => a > b ? a : b);
  }

  double get intervaloTemperatura {
    final diferenca = maiorTemperatura - menorTemperatura;

    if (diferenca == 0) {
      return maiorTemperatura.abs() * 0.2 > 0
          ? maiorTemperatura.abs() * 0.2
          : 1;
    }

    return diferenca / 5;
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

              title: const Text("Inicio"),

              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AdminScreen(
                      idSetor: null,
                      nomeSetor: nomeSetor,
                      nomeAdmin: nomeUsuario,
                    ),
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
                    builder: (context) => SetorScreen(
                      nomeSetor: nomeSetor,
                      nomeUsuario: nomeUsuario,
                      idSetor: widget.idSetor,
                    ),
                  ),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.thermostat),

              title: const Text(
                'Temperatura',
                style: const TextStyle(
                  color: Color.fromARGB(255, 3, 3, 3),
                  fontSize: 18,
                ),
              ),

              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TemperaturaScreen(
                      nomeSetor: nomeSetor,
                      nomeUsuario: nomeUsuario,
                      idSetor: widget.idSetor,
                    ),
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
                  MaterialPageRoute(
                    builder: (context) => ArScreen(
                      nomeSetor: nomeSetor,
                      nomeUsuario: nomeUsuario,
                      idSetor: widget.idSetor,
                    ),
                  ),
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
                  MaterialPageRoute(
                    builder: (context) => RuidoScreen(
                      nomeSetor: nomeSetor,
                      nomeUsuario: nomeUsuario,
                      idSetor: widget.idSetor,
                    ),
                  ),
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
                  MaterialPageRoute(builder: (context) => AlertaScreen(
                    nomeSetor: nomeSetor,
                    idSetor: null
                  )),
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

                SizedBox(width: 10),

                CircleAvatar(child: Icon(Icons.person)),
              ],
            ),
          ),
        ],
      ),

      body: carregando
          ? const Center(child: CircularProgressIndicator())
          : erro != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 40),
                    const SizedBox(height: 12),
                    Text(erro!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: buscarTemperaturas,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              ),
            )
          : temperaturas.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.thermostat_outlined,
                      color: Colors.grey,
                      size: 40,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Nenhuma medição de temperatura encontrada para este setor.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: buscarTemperaturas,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Atualizar'),
                    ),
                  ],
                ),
              ),
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
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 230,
                        child: LineChart(
                          LineChartData(
                            minY: menorTemperatura,
                            maxY: maiorTemperatura,
                            gridData: FlGridData(
                              show: true,
                              horizontalInterval: intervaloTemperatura,
                              getDrawingHorizontalLine: (value) => FlLine(
                                color: Colors.grey.withValues(alpha: 0.18),
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
                                    int indice = value.toInt();

                                    if (indice >= 0 &&
                                        indice < ultimasTemperaturas.length) {
                                      final dataHora = DateTime.tryParse(
                                        ultimasTemperaturas[indice]['data_hora']
                                            .toString(),
                                      );
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text(
                                          dataHora == null
                                              ? ''
                                              : '${dataHora.hour.toString().padLeft(2, '0')}:'
                                                    '${dataHora.minute.toString().padLeft(2, '0')}',
                                          style: const TextStyle(fontSize: 10),
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
                                      style: const TextStyle(fontSize: 10),
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
                                spots: ultimasTemperaturas.asMap().entries.map((item) {
                                  int indice = item.key;
                                  double temperatura =
                                      double.tryParse(item.value["valor"].toString()) ?? 0;

                                  return FlSpot(indice.toDouble(), temperatura);
                                }).toList(),

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
                          ...ultimasTemperaturas.map((dado) {
                            final dataHora = DateTime.tryParse(dado['data_hora'].toString());
                            return TableRow(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(5),
                                  child: Text(dataHora == null
                                      ? ''
                                      : _formatarData('${dataHora.year}-${dataHora.month.toString().padLeft(2, '0')}-${dataHora.day.toString().padLeft(2, '0')}')),
                                ),

                                Padding(
                                  padding: const EdgeInsets.all(5),
                                  child: Text(dataHora == null
                                      ? ''
                                      : '${dataHora.hour.toString().padLeft(2, '0')}:${dataHora.minute.toString().padLeft(2, '0')}'),
                                ),

                                Padding(
                                  padding: const EdgeInsets.all(5),
                                  child: Text("${dado["valor"]} °C"),
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
