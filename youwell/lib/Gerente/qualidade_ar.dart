import 'package:flutter/material.dart';
import 'package:youwell/Gerente/temperatura_screen.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:youwell/Gerente/setor_screen_gerente.dart';
import 'package:youwell/Gerente/ruido.dart';
import 'package:youwell/alertas.dart';
import 'package:youwell/historico.dart';
import 'package:youwell/gerente.dart';
import 'package:youwell/login_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ArScreen extends StatefulWidget {
  final String nomeSetor;
  final String nomeUsuario;
  final int idSetor;
  final int idUsuario;
  final String? fotoPerfil;

  const ArScreen({
    super.key,
    required this.nomeSetor,
    required this.nomeUsuario,
    required this.idSetor,
    required this.idUsuario,
    this.fotoPerfil,
  });

  @override
  State<ArScreen> createState() => _ArScreenState();
}

class _ArScreenState extends State<ArScreen> {
  List<Map<String, dynamic>> qualidadeAr = [];
  bool carregando = true;
  String? erro;

  String get nomeSetor => widget.nomeSetor;
  String get nomeUsuario => widget.nomeUsuario;
  int get idSetor => widget.idSetor;
  int get idUsuario => widget.idUsuario;

  List<Map<String, dynamic>> get ultimasMedicoes {
    final lista = List<Map<String, dynamic>>.from(qualidadeAr);
    lista.sort((a, b) =>
        (a['data_hora'] ?? '').toString().compareTo(
              (b['data_hora'] ?? '').toString(),
            ));
    return lista.length > 12 ? lista.sublist(lista.length - 12) : lista;
  }

  List<double> get valoresQualidade =>
      ultimasMedicoes
          .map((item) => double.tryParse(item['valor'].toString()) ?? 0)
          .toList();

  double get menorQualidade {
    if (valoresQualidade.isEmpty) return 0;
    return valoresQualidade.reduce((a, b) => a < b ? a : b);
  }

  double get maiorQualidade {
    if (valoresQualidade.isEmpty) return 100;
    return valoresQualidade.reduce((a, b) => a > b ? a : b);
  }

  @override
  void initState() {
    super.initState();
    buscarQualidadeAr();
  }

  Future<void> buscarQualidadeAr() async {
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
          dados['mensagem'] ??
              'Não foi possível buscar os dados da qualidade do ar.',
        );
      }

      final List lista = dados['qualidade_ar'] ?? [];
      if (!mounted) return;

      setState(() {
        qualidadeAr = lista
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
        qualidadeAr.sort((a, b) =>
            (a['data_hora'] ?? '').toString().compareTo(
                  (b['data_hora'] ?? '').toString(),
                ));
        carregando = false;
        erro = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        carregando = false;
        erro = 'Não foi possível carregar os dados da qualidade do ar.';
      });
      debugPrint('Erro ao buscar qualidade do ar: $e');
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
                  style: const TextStyle(fontSize: 20, color: Colors.white),
                ),
                const SizedBox(width: 10),
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
                    onPressed: buscarQualidadeAr,
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            )
          : qualidadeAr.isEmpty
          ? const Center(
              child: Text('Nenhuma medição de qualidade do ar encontrada.'),
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
                                'Qualidade do Ar',
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
                                  minY: menorQualidade - 5,
                                  maxY: maiorQualidade + 5,
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
                                              indice < ultimasMedicoes.length) {
                                            final dataHora = _obterDataHora(
                                              ultimasMedicoes[indice],
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
                                      spots: ultimasMedicoes.asMap().entries.map((
                                        item,
                                      ) {
                                        int indice = item.key;
                                        double ar =
                                            double.tryParse(
                                              item.value["valor"].toString(),
                                            ) ??
                                            0;

                                        return FlSpot(indice.toDouble(), ar);
                                      }).toList(),

                                      isCurved: true,
                                      color: Colors.teal,
                                      barWidth: 3,
                                      dotData: const FlDotData(show: true),
                                      belowBarData: BarAreaData(
                                        show: true,
                                        color: Colors.teal.withValues(
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
                                ...ultimasMedicoes.map((dado) {
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
                                        child: Text('${dado["valor"]}%'),
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