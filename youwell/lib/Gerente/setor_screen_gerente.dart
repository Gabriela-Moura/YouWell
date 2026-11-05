import 'package:flutter/material.dart';
import 'package:youwell/admin.dart';
import 'package:youwell/gerente.dart';
import 'package:youwell/main.dart';
import 'package:youwell/Gerente/temperatura_screen.dart';
import 'package:youwell/screens/home_screen.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:youwell/Gerente/qualidade_ar.dart';
import 'package:youwell/Gerente/ruido.dart';
import 'package:youwell/alertas.dart';
import 'package:youwell/admin.dart';
import 'package:youwell/historico.dart';
import 'dart:convert';
import 'package:youwell/services/api_service.dart';
import 'package:http/http.dart' as http;

class SetorScreen extends StatefulWidget {
  final String nomeSetor;
  final String nomeUsuario;
  final int idSetor;

  const SetorScreen({
    super.key,
    required this.nomeSetor,
    required this.nomeUsuario,
    required this.idSetor,
  });

  @override
  State<SetorScreen> createState() => _SetorScreenState();
}

class _SetorScreenState extends State<SetorScreen> {
  Map<String, dynamic>? medicoes;
  bool carregando = true;
  String? erro;

  Map<String, dynamic>? historico;
  bool carregandoHistorico = true;
  String? erroHistorico;

  @override
  void initState() {
    super.initState();
    buscarMedicoes();
    buscarHistorico();
  }

  Future<void> buscarMedicoes() async {
    try {
      final resposta = await http.post(
        Uri.parse(
          'https://devsbee.com.br/You-Well/controllers/buscar_medicoes.php',
        ),
        body: {'id_setor': widget.idSetor.toString()},
      );

      if (resposta.statusCode != 200) {
        throw Exception('Erro ao acessar o servidor PHP.');
      }

      final dados = jsonDecode(resposta.body);

      if (dados['success'] != true) {
        throw Exception(
          dados['mensagem'] ?? 'Não foi possível buscar os dados.',
        );
      }

      if (!mounted) return;

      setState(() {
        medicoes = Map<String, dynamic>.from(dados);
        carregando = false;
        erro = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        carregando = false;
        erro = 'Não foi possível carregar as medições.';
      });

      debugPrint('Erro ao buscar medições: $e');
    }
  }

  Future<void> buscarHistorico() async {
    try {
      final resposta = await http.post(
        Uri.parse(
          'https://devsbee.com.br/You-Well/controllers/buscar_medicoes.php',
        ),
        body: {'id_setor': widget.idSetor.toString()},
      );

      if (resposta.statusCode != 200) {
        throw Exception('Erro ao acessar o histórico.');
      }

      final dados = jsonDecode(resposta.body);

      if (dados['success'] != true) {
        throw Exception(
          dados['mensagem'] ?? 'Não foi possível buscar o histórico.',
        );
      }

      if (!mounted) return;

      setState(() {
        historico = Map<String, dynamic>.from(dados);
        carregandoHistorico = false;
        erroHistorico = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        carregandoHistorico = false;
        erroHistorico = 'Não foi possível carregar o gráfico.';
      });

      debugPrint('Erro ao buscar histórico: $e');
    }
  }

  List<dynamic> _listaHistorico(String tipo) {
    final dados = historico?[tipo];

    if (dados is List) {
      return dados;
    }

    return [];
  }

  List<FlSpot> _criarSpots(String tipo) {
    final lista = _listaHistorico(tipo);

    return List.generate(lista.length, (index) {
      final valor = double.tryParse(lista[index]['valor'].toString()) ?? 0;

      return FlSpot(index.toDouble(), valor);
    });
  }

  double get _menorValorGrafico {
    final valores = <double>[];
    for (final tipo in ['temperatura', 'ruido', 'qualidade_ar']) {
      for (final spot in _criarSpots(tipo)) {
        valores.add(spot.y);
      }
    }
    return valores.isEmpty
        ? 0
        : valores.reduce((a, b) => a < b ? a : b);
  }

  double get _maiorValorGrafico {
    final valores = <double>[];
    for (final tipo in ['temperatura', 'ruido', 'qualidade_ar']) {
      for (final spot in _criarSpots(tipo)) {
        valores.add(spot.y);
      }
    }
    return valores.isEmpty
        ? 100
        : valores.reduce((a, b) => a > b ? a : b);
  }

  String _horarioNoIndice(double indice) {
    final temperatura = _listaHistorico('temperatura');
    final ruido = _listaHistorico('ruido');
    final qualidadeAr = _listaHistorico('qualidade_ar');

    final listas = [temperatura, ruido, qualidadeAr];

    // Procura o horário disponível para este ponto.
    for (final lista in listas) {
      final i = indice.toInt();

      if (indice == i.toDouble() && i >= 0 && i < lista.length) {
        final dataHora = DateTime.tryParse(lista[i]['data_hora'].toString());

        if (dataHora != null) {
          return '${dataHora.hour.toString().padLeft(2, '0')}:'
              '${dataHora.minute.toString().padLeft(2, '0')}';
        }
      }
    }

    return '';
  }

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
    final quantidadePontos = [
      _listaHistorico('temperatura').length,
      _listaHistorico('ruido').length,
      _listaHistorico('qualidade_ar').length,
    ].reduce((a, b) => a > b ? a : b);

    final maxXGrafico = quantidadePontos > 1
        ? (quantidadePontos - 1).toDouble()
        : 1.0;

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
                'Olá, ${widget.nomeUsuario}',

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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GerenteScreen(
                      setorGerente: widget.nomeSetor,
                      nomeGerente: widget.nomeUsuario,
                      idSetor: widget.idSetor,
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
                      nomeSetor: widget.nomeSetor,
                      nomeUsuario: widget.nomeUsuario,
                      idSetor: widget.idSetor,
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
                      nomeSetor: widget.nomeSetor,
                      nomeUsuario: widget.nomeUsuario,
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
                      nomeSetor: widget.nomeSetor,
                      nomeUsuario: widget.nomeUsuario,
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
                      nomeSetor: widget.nomeSetor,
                      nomeUsuario: widget.nomeUsuario,
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
                  MaterialPageRoute(
                    builder: (context) => AlertaScreen(
                      idSetor: widget.idSetor,
                      nomeSetor: widget.nomeSetor,
                    ),
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
          ],
        ),
      ),

      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 10, 85, 64),
        iconTheme: const IconThemeData(color: Colors.white),

        title: Text(widget.nomeSetor, style: TextStyle(color: Colors.white)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Row(
              children: [
                Text(
                  "Olá, ${widget.nomeUsuario}",
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
              SizedBox(
                height: 90,
                width: double.infinity,
                child: Row(
                  children: [
                    infoCard(
                      "Temperatura",
                      carregando
                          ? "Carregando"
                          : erro != null
                          ? "--"
                          : medicoes?['temperatura'] == null
                          ? "Sem dados"
                          : "${medicoes!['temperatura']['valor']} °C",
                      Icons.thermostat,
                    ),
                    infoCard(
                      "Qualidade do ar",
                      carregando
                          ? "Carregando"
                          : erro != null
                          ? "--"
                          : medicoes?['qualidade_ar'] == null
                          ? "Sem dados"
                          : "${medicoes!['qualidade_ar']['valor']}%",
                      Icons.air,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              SizedBox(
                height: 90,
                width: double.infinity,
                child: Row(
                  children: [
                    infoCard(
                      "Ruído",
                      carregando
                          ? "Carregando"
                          : erro != null
                          ? "--"
                          : medicoes?['ruido'] == null
                          ? "Sem dados"
                          : "${medicoes!['ruido']['valor']} dB",
                      Icons.volume_up,
                    ),
                  ],
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
                            minY: _menorValorGrafico - 5,
                            maxY: _maiorValorGrafico + 5,
                            minX: 0,
                            maxX: maxXGrafico,
                            gridData: FlGridData(
                              show: true,
                              horizontalInterval: 5,
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
                                  interval: 5,
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
                                  getTitlesWidget: (value, meta) {
                                    final horario = _horarioNoIndice(value);

                                    if (horario.isEmpty) {
                                      return const SizedBox.shrink();
                                    }

                                    return SideTitleWidget(
                                      meta: meta,
                                      child: Text(
                                        horario,
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 10,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            lineBarsData: [
                              LineChartBarData(
                                spots: _criarSpots('temperatura'),
                                isCurved: true,
                                color: Colors.deepOrange,
                                barWidth: 3,
                                dotData: const FlDotData(show: true),
                              ),
                              LineChartBarData(
                                spots: _criarSpots('ruido'),
                                isCurved: true,
                                color: Colors.blue,
                                barWidth: 3,
                                dotData: const FlDotData(show: true),
                              ),
                              LineChartBarData(
                                spots: _criarSpots('qualidade_ar'),
                                isCurved: true,
                                color: Colors.teal,
                                barWidth: 3,
                                dotData: const FlDotData(show: true),
                              ),
                            ],
                          ),
                        ),
                      ),
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
