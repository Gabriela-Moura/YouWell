import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AlertaScreen extends StatefulWidget {
  final int? idSetor;
  final String nomeSetor;

  const AlertaScreen({super.key, this.idSetor, required this.nomeSetor});

  @override
  State<AlertaScreen> createState() => _AlertaScreenState();
}

class _AlertaScreenState extends State<AlertaScreen> {
  List<Map<String, dynamic>> alertas = [];

  bool carregando = true;
  String? erro;

  // Endereço do PHP hospedado no cPanel.
  static const String url =
      'https://devsbee.com.br/You-Well/controllers/buscar_historico_medicoes.php';

  // Limites máximos configurados para o projeto.
  static const Map<String, double> limites = {
    'temperatura': 25.0,
    'ruido': 65.0,
    'qualidade_ar': 70.0,
  };

  @override
  void initState() {
    super.initState();
    buscarAlertas();
  }

  // CONVERTER OS DADOS RECEBIDOS DO PHP PARA UMA LISTA.
  List<Map<String, dynamic>> _converterMedicoes(dynamic resposta) {
    if (resposta is List) {
      return resposta
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    if (resposta is Map) {
      final conteudo =
          resposta['medicoes'] ?? resposta['dados'] ?? resposta['leituras'];

      if (conteudo is List) {
        return conteudo
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }

      if (resposta.containsKey('valor') && resposta.containsKey('data_hora')) {
        return [Map<String, dynamic>.from(resposta)];
      }
    }

    return [];
  }

  // BUSCAR DADOS DO BANCO REAL.
  Future<void> buscarAlertas() async {
    setState(() {
      carregando = true;
      erro = null;
    });

    try {
      final body = widget.idSetor == null || widget.idSetor! <= 0
          ? <String, String>{}
          : {'id_setor': widget.idSetor.toString()};

      debugPrint('ID DO SETOR: ${widget.idSetor}');
      debugPrint('URL: $url');

      final resposta = await http
          .post(Uri.parse(url), body: body)
          .timeout(const Duration(seconds: 20));

      debugPrint('STATUS: ${resposta.statusCode}');
      debugPrint('RESPOSTA DO PHP: ${resposta.body}');

      if (resposta.statusCode != 200) {
        throw Exception('Erro HTTP: ${resposta.statusCode}');
      }

      final resultado = jsonDecode(resposta.body);

      if (resultado is! Map) {
        throw Exception('O PHP não retornou um objeto JSON válido.');
      }

      final dados = Map<String, dynamic>.from(resultado);

      if (dados['success'] != true) {
        throw Exception(
          dados['mensagem'] ??
              dados['erro'] ??
              'Não foi possível buscar as medições.',
        );
      }

      final List<Map<String, dynamic>> novosAlertas = [];

      // ANALISAR TEMPERATURA.
      _analisarMedicoes(dados['temperatura'], 'temperatura', novosAlertas);

      // ANALISAR RUÍDO.
      _analisarMedicoes(dados['ruido'], 'ruido', novosAlertas);

      // ANALISAR QUALIDADE DO AR.
      _analisarMedicoes(dados['qualidade_ar'], 'qualidade_ar', novosAlertas);

      // ORGANIZAR DO MAIS RECENTE PARA O MAIS ANTIGO.
      novosAlertas.sort((a, b) {
        return (b['dataHora'] as DateTime).compareTo(a['dataHora'] as DateTime);
      });

      if (!mounted) return;

      setState(() {
        alertas = novosAlertas;
        carregando = false;
        erro = null;
      });
    } catch (e) {
      debugPrint('ERRO AO BUSCAR ALERTAS: $e');

      if (!mounted) return;

      setState(() {
        carregando = false;
        erro = 'Não foi possível carregar os alertas do banco de dados.\n$e';
      });
    }
  }

  // ANALISAR MEDIÇÕES E FILTRAR SOMENTE VALORES ACIMA DO LIMITE.
  void _analisarMedicoes(
    dynamic medicoes,
    String indicador,
    List<Map<String, dynamic>> listaAlertas,
  ) {
    final lista = _converterMedicoes(medicoes);
    final limite = limites[indicador]!;

    for (final item in lista) {
      final valor = double.tryParse(item['valor']?.toString() ?? '');

      if (valor == null) continue;

      // IGNORAR VALORES DENTRO DO LIMITE.
      if (valor <= limite) continue;

      final dataHora = DateTime.tryParse(item['data_hora']?.toString() ?? '');

      if (dataHora == null) continue;

      String nomeIndicador;
      String unidade;

      switch (indicador) {
        case 'temperatura':
          nomeIndicador = 'Temperatura';
          unidade = '°C';
          break;

        case 'ruido':
          nomeIndicador = 'Ruído';
          unidade = 'dB';
          break;

        default:
          nomeIndicador = 'Qualidade do ar';
          unidade = '';
      }

      listaAlertas.add({
        'setor': widget.nomeSetor,
        'indicador': indicador,
        'nomeIndicador': nomeIndicador,
        'valor': valor,
        'unidade': unidade,
        'limite': limite,
        'dataHora': dataHora,
        'gravidade': 'critico',
        'mensagem': 'Valor acima do limite máximo configurado.',
      });
    }
  }

  String _formatarData(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}/'
        '${data.year}';
  }

  String _formatarHora(DateTime data) {
    return '${data.hour.toString().padLeft(2, '0')}:'
        '${data.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Alertas ambientais',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF0A5540),
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: buscarAlertas,
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar alertas',
          ),
        ],
      ),
      body: Container(
        color: Colors.grey.shade100,
        child: carregando
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF0A5540)),
              )
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
                        size: 55,
                      ),
                      const SizedBox(height: 12),
                      Text(erro!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: buscarAlertas,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Tentar novamente'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0A5540),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : alertas.isEmpty
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 65,
                      color: Colors.green,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Nenhum alerta encontrado!',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text('Todos os valores estão dentro dos limites.'),
                  ],
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // RESUMO DOS ALERTAS.
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A5540),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.notifications_active,
                          color: Colors.white,
                          size: 35,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Alertas identificados',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                '${alertas.length} alerta(s) encontrado(s)',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'Lista de alertas',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 10),

                  // CARDS DOS ALERTAS.
                  ...alertas.map((alerta) {
                    const cor = Colors.red;
                    final dataHora = alerta['dataHora'] as DateTime;

                    return Card(
                      color: Colors.white,
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: cor.withAlpha(100), width: 1),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.error, color: cor, size: 28),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${alerta['setor']} - '
                                    '${alerta['nomeIndicador']}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 9,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    'CRÍTICO',
                                    style: TextStyle(
                                      color: Colors.red.shade700,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            Text(
                              'Valor registrado: '
                              '${alerta['valor']}'
                              '${alerta['unidade']}',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade700,
                              ),
                            ),

                            const SizedBox(height: 6),

                            Text(
                              alerta['mensagem'],
                              style: const TextStyle(fontSize: 14),
                            ),

                            Text(
                              'Limite máximo: '
                              '${alerta['limite']}'
                              '${alerta['unidade']}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black54,
                              ),
                            ),

                            const Divider(height: 22),

                            Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _formatarData(dataHora),
                                  style: const TextStyle(color: Colors.black54),
                                ),
                                const SizedBox(width: 16),
                                const Icon(
                                  Icons.access_time,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _formatarHora(dataHora),
                                  style: const TextStyle(color: Colors.black54),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
      ),
    );
  }
}
