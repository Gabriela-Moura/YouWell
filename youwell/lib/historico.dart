import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:youwell/services/monitor_alertas.dart';

class HistoricoScreen extends StatefulWidget {
  const HistoricoScreen({super.key});

  @override
  State<HistoricoScreen> createState() => _HistoricoScreenState();
}

class _HistoricoScreenState extends State<HistoricoScreen> {
  static const Color _verde = Color(0xFF0A5540);

  List<Map<String, dynamic>> historico = [];
  bool carregando = true;
  String? erro;
  Timer? _timerAtualizacao;

  @override
  void initState() {
    super.initState();
    carregarHistorico();
    _timerAtualizacao = Timer.periodic(const Duration(minutes: 1), (_) {
      carregarHistorico(mostrarCarregamento: false);
    });
  }

  @override
  void dispose() {
    _timerAtualizacao?.cancel();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // AUXILIARES
  // ---------------------------------------------------------------------------

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

  String _nomeIndicador(String indicador) {
    switch (indicador) {
      case 'temperatura':
        return 'Temperatura';
      case 'ruido':
        return 'Ruído';
      default:
        return 'Qualidade do ar';
    }
  }

  String _unidade(String indicador) {
    switch (indicador) {
      case 'temperatura':
        return ' °C';
      case 'ruido':
        return ' dB';
      default:
        return '';
    }
  }

  String _rotulo(String gravidade) {
    switch (gravidade) {
      case 'critico':
        return 'Crítico';
      case 'limite':
        return 'No limite';
      default:
        return 'Atenção';
    }
  }

  Color _corTela(String gravidade) {
    switch (gravidade) {
      case 'critico':
        return Colors.red;
      case 'limite':
        return Colors.deepOrange;
      default:
        return Colors.orange;
    }
  }

  PdfColor _corPdf(String gravidade) {
    switch (gravidade) {
      case 'critico':
        return PdfColors.red700;
      case 'limite':
        return PdfColors.deepOrange700;
      default:
        return PdfColors.orange700;
    }
  }

  int _contar(String gravidade) =>
      historico.where((a) => a['gravidade'] == gravidade).length;

  // ---------------------------------------------------------------------------
  // CARREGAMENTO
  // ---------------------------------------------------------------------------

  Future<void> carregarHistorico({bool mostrarCarregamento = true}) async {
    if (mostrarCarregamento) {
      setState(() => carregando = true);
    }

    try {
      final registros = await MonitorAlertas.buscarHistoricoAlertas();
      if (!mounted) return;

      setState(() {
        historico = registros;
        carregando = false;
        erro = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        erro = 'Não foi possível carregar o histórico do banco de dados.\n$e';
        carregando = false;
      });
    }
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

  // ---------------------------------------------------------------------------
  // PDF
  // ---------------------------------------------------------------------------

  pw.Widget _celulaPdf(
    String texto, {
    bool negrito = false,
    PdfColor? cor,
    pw.TextAlign alinhamento = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(
        texto,
        textAlign: alinhamento,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: negrito ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: cor,
        ),
      ),
    );
  }

  pw.Widget _resumoPdf(String titulo, int valor, PdfColor cor) {
    return pw.Expanded(
      child: pw.Container(
        margin: const pw.EdgeInsets.only(right: 8),
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: cor, width: 1),
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(titulo, style: const pw.TextStyle(fontSize: 10)),
            pw.SizedBox(height: 4),
            pw.Text(
              '$valor',
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
                color: cor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> baixarPDF() async {
    // Fonte com suporte a acentos. Se não for possível baixá-la
    // (ex.: sem internet), usa a fonte padrão do PDF.
    pw.Font fonteNormal;
    pw.Font fonteNegrito;

    try {
      fonteNormal = await PdfGoogleFonts.nunitoRegular();
      fonteNegrito = await PdfGoogleFonts.nunitoBold();
    } catch (_) {
      fonteNormal = pw.Font.helvetica();
      fonteNegrito = pw.Font.helveticaBold();
    }

    final documento = pw.Document(
      title: 'YouWell - Histórico de alertas',
      author: 'YouWell',
    );

    final grupos = agruparPorDia();
    final verdePdf = PdfColor.fromInt(0xFF0A5540);
    final agora = DateTime.now();
    final geradoEm =
        '${agora.day.toString().padLeft(2, '0')}/'
        '${agora.month.toString().padLeft(2, '0')}/'
        '${agora.year} '
        '${agora.hour.toString().padLeft(2, '0')}:'
        '${agora.minute.toString().padLeft(2, '0')}';

    documento.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          theme: pw.ThemeData.withFont(
            base: fonteNormal,
            bold: fonteNegrito,
          ),
        ),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Página ${context.pageNumber} de ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
        ),
        build: (context) => [
          // CABEÇALHO
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: verdePdf,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'YouWell',
                  style: pw.TextStyle(
                    fontSize: 12,
                    color: PdfColors.white,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Histórico de alertas ambientais',
                  style: pw.TextStyle(
                    fontSize: 20,
                    color: PdfColors.white,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  'Período: últimos 30 dias   |   Gerado em: $geradoEm',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.white,
                  ),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 14),

          // RESUMO
          pw.Row(
            children: [
              _resumoPdf('Total de alertas', historico.length, verdePdf),
              _resumoPdf('Críticos', _contar('critico'), _corPdf('critico')),
              _resumoPdf('No limite', _contar('limite'), _corPdf('limite')),
              _resumoPdf('Atenção', _contar('atencao'), _corPdf('atencao')),
            ],
          ),

          pw.SizedBox(height: 14),

          pw.Text(
            'Critérios: Crítico = acima do limite; No limite = igual ao limite; '
            'Atenção = a partir de '
            '${(MonitorAlertas.fracaoAtencao * 100).round()}% do limite.',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),

          pw.SizedBox(height: 14),

          if (historico.isEmpty)
            pw.Text('Nenhum alerta registrado no período.'),

          // UMA TABELA POR DIA
          ...grupos.entries.expand((grupo) {
            return [
              pw.Container(
                width: double.infinity,
                margin: const pw.EdgeInsets.only(top: 6, bottom: 6),
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 5,
                ),
                color: PdfColors.grey200,
                child: pw.Text(
                  '${formatarData(grupo.key)}  -  '
                  '${grupo.value.length} alerta(s)',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Table(
                border: pw.TableBorder.all(
                  color: PdfColors.grey400,
                  width: 0.5,
                ),
                columnWidths: const {
                  0: pw.FixedColumnWidth(42),
                  1: pw.FlexColumnWidth(2.2),
                  2: pw.FlexColumnWidth(2),
                  3: pw.FlexColumnWidth(1.3),
                  4: pw.FlexColumnWidth(1.3),
                  5: pw.FlexColumnWidth(1.4),
                },
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: verdePdf),
                    children: [
                      _celulaPdf('Hora', negrito: true, cor: PdfColors.white),
                      _celulaPdf('Setor', negrito: true, cor: PdfColors.white),
                      _celulaPdf(
                        'Indicador',
                        negrito: true,
                        cor: PdfColors.white,
                      ),
                      _celulaPdf('Valor', negrito: true, cor: PdfColors.white),
                      _celulaPdf('Limite', negrito: true, cor: PdfColors.white),
                      _celulaPdf(
                        'Situação',
                        negrito: true,
                        cor: PdfColors.white,
                      ),
                    ],
                  ),
                  ...grupo.value.map((alerta) {
                    final indicador = alerta['indicador'].toString();
                    final gravidade = alerta['gravidade'].toString();
                    final unidade = _unidade(indicador);
                    final limite = MonitorAlertas.limites[indicador];

                    return pw.TableRow(
                      children: [
                        _celulaPdf('${alerta['hora']}'),
                        _celulaPdf('${alerta['setor']}'),
                        _celulaPdf(_nomeIndicador(indicador)),
                        _celulaPdf(
                          '${alerta['valor']}$unidade',
                          negrito: true,
                        ),
                        _celulaPdf(limite == null ? '-' : '$limite$unidade'),
                        _celulaPdf(
                          _rotulo(gravidade),
                          negrito: true,
                          cor: _corPdf(gravidade),
                        ),
                      ],
                    );
                  }),
                ],
              ),
              pw.SizedBox(height: 10),
            ];
          }),
        ],
      ),
    );

    await Printing.layoutPdf(
      name: 'historico_alertas_youwell.pdf',
      onLayout: (format) async => documento.save(),
    );
  }

  // ---------------------------------------------------------------------------
  // TELA
  // ---------------------------------------------------------------------------

  Widget _contador(String titulo, int valor) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$valor',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            titulo,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final grupos = agruparPorDia();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de alertas'),
        backgroundColor: _verde,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: carregando ? null : carregarHistorico,
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar histórico',
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
                      onPressed: carregarHistorico,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _verde,
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
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _contador('Críticos', _contar('critico')),
                          _contador('No limite', _contar('limite')),
                          _contador('Atenção', _contar('atencao')),
                        ],
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: historico.isEmpty ? null : baixarPDF,
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('Baixar relatório PDF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _verde,
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
                                  final indicador = alerta['indicador']
                                      .toString();
                                  final gravidade = alerta['gravidade']
                                      .toString();
                                  final cor = _corTela(gravidade);

                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    child: ListTile(
                                      leading: Icon(
                                        gravidade == 'critico'
                                            ? Icons.error
                                            : Icons.warning_amber,
                                        color: cor,
                                      ),
                                      title: Text(
                                        '${alerta['setor']} - '
                                        '${_nomeIndicador(indicador)}',
                                      ),
                                      subtitle: Text(
                                        '${alerta['mensagem']}\n'
                                        'Valor: ${alerta['valor']}'
                                        '${_unidade(indicador)} | '
                                        'Hora: ${alerta['hora']}',
                                      ),
                                      trailing: Text(
                                        _rotulo(gravidade).toUpperCase(),
                                        style: TextStyle(
                                          color: cor,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
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