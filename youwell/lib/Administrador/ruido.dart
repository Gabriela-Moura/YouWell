import 'package:flutter/material.dart';
import 'package:youwell/admin.dart';
import 'package:youwell/main.dart';
import 'package:youwell/login_screen.dart';
import 'package:youwell/Administrador/temperatura_screen.dart';
import 'package:youwell/screens/home_screen.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:youwell/Administrador/setor_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:youwell/Administrador/qualidade_ar.dart';
import 'package:youwell/Administrador/ruido.dart';
import 'package:youwell/alertas.dart';
import 'package:youwell/historico.dart';

class RuidoScreen extends StatefulWidget {
  final String nomeSetor;
  final String nomeUsuario;
  final int? idSetor;
  final String? fotoPerfil;

  const RuidoScreen({
    super.key,
    required this.nomeSetor,
    required this.nomeUsuario,
    this.idSetor,
    this.fotoPerfil,
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

  @override
  void initState() {
    super.initState();
    buscarRuidos();
  }

  Future<void> buscarRuidos() async {
    setState(() {
      carregando = true;
      erro = null;
    });

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
          .timeout(const Duration(seconds: 20));
      if (resposta.statusCode != 200) {
        throw Exception('Erro HTTP ${resposta.statusCode}: ${resposta.body}');
      }

      final dados = jsonDecode(utf8.decode(resposta.bodyBytes));
      if (dados is! Map || dados['success'] != true) {
        throw Exception(
          dados is Map
              ? dados['mensagem'] ?? 'Não foi possível buscar ruídos.'
              : 'Resposta inválida do servidor.',
        );
      }
      if (!dados.containsKey('ruido')) {
        throw const FormatException(
          'A resposta do servidor não contém medições de ruído.',
        );
      }

      final lista = converterRuidos(dados['ruido']);
      lista.sort(
        (a, b) => (a['data_hora'] ?? '').toString().compareTo(
          (b['data_hora'] ?? '').toString(),
        ),
      );
      if (!mounted) return;
      setState(() {
        ruidos = lista;
        carregando = false;
        erro = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        carregando = false;
        erro = 'Não foi possível carregar os ruídos.';
      });
      debugPrint('Erro ao buscar ruídos: $e');
    }
  }

  List<Map<String, dynamic>> converterRuidos(dynamic resposta) {
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
          resposta['ruidos'];

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

    throw const FormatException('Formato de medições de ruído inválido.');
  }

  String _formatarData(String data) {
    final partes = data.split('-');
    if (partes.length != 3) return data;

    return '${partes[2].padLeft(2, '0')}/${partes[1].padLeft(2, '0')}/${partes[0]}';
  }

  List<Map<String, dynamic>> get ultimosRuidos =>
      ruidos.length > 12 ? ruidos.sublist(ruidos.length - 12) : ruidos;

  double get menorRuido {
    if (ultimosRuidos.isEmpty) return 0;
    return ultimosRuidos
        .map((item) => double.tryParse(item['valor'].toString()) ?? 0)
        .reduce((a, b) => a < b ? a : b);
  }

  double get maiorRuido {
    if (ultimosRuidos.isEmpty) return 100;
    return ultimosRuidos
        .map((item) => double.tryParse(item['valor'].toString()) ?? 0)
        .reduce((a, b) => a > b ? a : b);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),

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
                      fotoPerfil: widget.fotoPerfil,
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
                      fotoPerfil: widget.fotoPerfil,
                    ),
                  ),
                );
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
                    builder: (context) => TemperaturaScreen(
                      nomeSetor: nomeSetor,
                      nomeUsuario: nomeUsuario,
                      idSetor: widget.idSetor,
                      fotoPerfil: widget.fotoPerfil,
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
                      fotoPerfil: widget.fotoPerfil,
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
                      fotoPerfil: widget.fotoPerfil,
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
                  MaterialPageRoute(
                    builder: (context) =>
                        AlertaScreen(idSetor: null, nomeSetor: nomeSetor),
                  ),
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
                    builder: (context) => LoginScreen(nomeSetor: nomeSetor),
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
                  "Olá $nomeUsuario",
                  style: const TextStyle(fontSize: 20, color: Colors.white),
                ),
                const SizedBox(width: 10),
                CircleAvatar(
                  backgroundColor: Colors.white,
                  backgroundImage:
                      widget.fotoPerfil != null && widget.fotoPerfil!.isNotEmpty
                      ? MemoryImage(base64Decode(widget.fotoPerfil!))
                      : null,
                  child: widget.fotoPerfil == null || widget.fotoPerfil!.isEmpty
                      ? const Icon(
                          Icons.person,
                          color: Color.fromARGB(255, 10, 85, 64),
                        )
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
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 40,
                    ),
                    const SizedBox(height: 12),
                    Text(erro!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: buscarRuidos,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              ),
            )
          : ruidos.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.volume_off, color: Colors.grey, size: 40),
                    const SizedBox(height: 12),
                    const Text(
                      'Nenhuma medição de ruído encontrada para este setor.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: buscarRuidos,
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
                                  minY: menorRuido - 5,
                                  maxY: maiorRuido + 5,
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
                                              indice < ultimosRuidos.length) {
                                            final dataHora = DateTime.tryParse(
                                              ultimosRuidos[indice]['data_hora']
                                                  .toString(),
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
                                      spots: ultimosRuidos.asMap().entries.map((
                                        item,
                                      ) {
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
                                ...ultimosRuidos.map((dado) {
                                  final dataHora = DateTime.tryParse(
                                    dado['data_hora'].toString(),
                                  );
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
                                        child: Text("${dado["valor"]} dB"),
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
