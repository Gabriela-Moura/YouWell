import 'package:flutter/material.dart';
import 'package:youwell/admin.dart';
import 'package:youwell/main.dart';
import 'package:youwell/Administrador/temperatura_screen.dart';
import 'package:youwell/screens/home_screen.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:youwell/Administrador/setor_screen.dart';
import 'package:youwell/simulacaoBD/dados_sensores.dart';
import 'package:youwell/Administrador/temperatura_screen.dart';
import 'package:youwell/Administrador/qualidade_ar.dart';
import 'package:youwell/Administrador/ruido.dart';
import 'package:youwell/alertas.dart';
import 'package:youwell/historico.dart';

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class HistoricoScreen extends StatefulWidget {
  const HistoricoScreen({super.key});

  @override
  State<HistoricoScreen> createState() => _HistoricoScreenState();
}

class _HistoricoScreenState extends State<HistoricoScreen> {
  List<Map<String, dynamic>> historico = [];
  bool carregando = true;

  @override
  void initState() {
    super.initState();
    carregarHistorico();
  }

  DateTime? interpretarData(dynamic valor) {
    if (valor == null) return null;
    return DateTime.tryParse(valor.toString());
  }

  String formatarData(String data) {
    final d = interpretarData(data);
    if (d == null) return data;

    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/'
        '${d.year}';
  }

  Future<void> carregarHistorico() async {
    final prefs = await SharedPreferences.getInstance();

    final salvo = prefs.getString('historico_alertas');
    List<Map<String, dynamic>> registros = [];

    if (salvo != null) {
      final decodificado = jsonDecode(salvo) as List;

      registros = decodificado
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    // Mantém somente os registros dos últimos 30 dias.
    final limite = DateTime.now().subtract(const Duration(days: 30));

    registros.removeWhere((registro) {
      final data = interpretarData(registro['data']);
      return data == null ||
          data.isBefore(DateTime(limite.year, limite.month, limite.day));
    });

    registros.sort((a, b) {
      final dataA = '${a['data']} ${a['hora']}';
      final dataB = '${b['data']} ${b['hora']}';
      return dataB.compareTo(dataA);
    });

    await prefs.setString('historico_alertas', jsonEncode(registros));

    if (!mounted) return;

    setState(() {
      historico = registros;
      carregando = false;
    });
  }

  Map<String, List<Map<String, dynamic>>> agruparPorDia() {
    final Map<String, List<Map<String, dynamic>>> grupos = {};

    for (final alerta in historico) {
      final data = alerta['data'].toString();
      grupos.putIfAbsent(data, () => []);
      grupos[data]!.add(alerta);
    }

    return grupos;
  }

  Future<void> baixarPDF() async {
    final documento = pw.Document();
    final grupos = agruparPorDia();

    documento.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Text(
            'YouWell - Historico de Alertas',
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Text('Periodo: ultimos 30 dias'),
          pw.Text('Total de alertas: ${historico.length}'),
          pw.SizedBox(height: 20),

          if (historico.isEmpty)
            pw.Text('Nenhum alerta registrado no periodo.'),

          ...grupos.entries.expand(
            (grupo) => [
              pw.Header(level: 1, text: formatarData(grupo.key)),
              ...grupo.value.map((alerta) {
                final indicador = alerta['indicador'] == 'temperatura'
                    ? 'Temperatura'
                    : alerta['indicador'] == 'ruido'
                    ? 'Ruido'
                    : 'Qualidade do ar';

                final unidade = alerta['indicador'] == 'temperatura'
                    ? ' C'
                    : alerta['indicador'] == 'ruido'
                    ? ' dB'
                    : '';

                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 12),
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(border: pw.Border.all()),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        '${alerta['setor']} - $indicador',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text('Valor: ${alerta['valor']}$unidade'),
                      pw.Text('Horario: ${alerta['hora']}'),
                      pw.Text('Gravidade: ${alerta['gravidade']}'),
                      pw.Text('${alerta['mensagem']}'),
                    ],
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => documento.save());
  }

  @override
  Widget build(BuildContext context) {
    final grupos = agruparPorDia();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de alertas'),
        backgroundColor: const Color(0xFF0A5540),
        foregroundColor: Colors.white,
      ),
      body: carregando
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A5540),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Registros dos últimos 30 dias',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${historico.length} alerta(s) registrado(s)',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 23,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: baixarPDF,
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('Baixar relatório PDF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0A5540),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(14),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                Expanded(
                  child: historico.isEmpty
                      ? const Center(
                          child: Text(
                            'Nenhum alerta registrado nos últimos 30 dias.',
                            textAlign: TextAlign.center,
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.all(16),
                          children: grupos.entries.map((grupo) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  child: Text(
                                    formatarData(grupo.key),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),

                                ...grupo.value.map((alerta) {
                                  final critico =
                                      alerta['gravidade'] == 'critico';

                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    child: ListTile(
                                      leading: Icon(
                                        critico
                                            ? Icons.error
                                            : Icons.warning_amber,
                                        color: critico
                                            ? Colors.red
                                            : Colors.orange,
                                      ),
                                      title: Text(
                                        '${alerta['setor']} - '
                                        '${alerta['indicador']}',
                                      ),
                                      subtitle: Text(
                                        '${alerta['mensagem']}\n'
                                        'Valor: ${alerta['valor']} | '
                                        'Hora: ${alerta['hora']}',
                                      ),
                                      isThreeLine: true,
                                    ),
                                  );
                                }),
                              ],
                            );
                          }).toList(),
                        ),
                ),
              ],
            ),
    );
  }
}
