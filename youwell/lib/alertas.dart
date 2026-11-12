import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:youwell/services/monitor_alertas.dart';

class AlertaScreen extends StatefulWidget {
  final int? idSetor;
  final String nomeSetor;

  // Quando informado (e sem idSetor), mostra os alertas de TODOS os setores
  // deste gerente. Sem idSetor e sem idUsuario (admin), mostra todos os setores.
  final int? idUsuario;

  const AlertaScreen({
    super.key,
    this.idSetor,
    this.idUsuario,
    required this.nomeSetor,
  });

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

  // Lista de setores (sem parâmetros, retorna todos — o mesmo usado no admin.dart).
  static const String urlSetores =
      'https://devsbee.com.br/You-Well/controllers/buscar_setor.php';

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

  // BUSCAR TODOS OS SETORES (USADO QUANDO NÃO HÁ UM SETOR ESPECÍFICO, EX.: ADMIN).
  Future<List<Map<String, dynamic>>> _buscarTodosSetores() async {
    final resposta = await http
        .post(
          Uri.parse(urlSetores),
          headers: {'Accept': 'application/json'},
          body: widget.idUsuario != null
              ? {'id_usuario': widget.idUsuario.toString()}
              : null,
        )
        .timeout(const Duration(seconds: 20));

    debugPrint('STATUS SETORES: ${resposta.statusCode}');
    debugPrint('RESPOSTA SETORES: ${resposta.body}');

    if (resposta.statusCode != 200) {
      throw Exception('Erro HTTP ao buscar setores: ${resposta.statusCode}');
    }

    final dados = jsonDecode(utf8.decode(resposta.bodyBytes));

    if (dados is! Map || dados['success'] != true) {
      throw Exception(
        dados is Map
            ? (dados['mensagem'] ?? 'Não foi possível buscar os setores.')
            : 'O PHP não retornou um objeto JSON válido.',
      );
    }

    final lista = dados['setores'];
    if (lista is! List) return [];

    final setores = <Map<String, dynamic>>[];

    for (final setor in lista) {
      if (setor is! Map) continue;

      final id = int.tryParse(setor['id_setor']?.toString() ?? '');
      if (id == null || id <= 0) continue;

      setores.add({'id_setor': id, 'nome': setor['nome']?.toString() ?? ''});
    }

    return setores;
  }

  // BUSCAR AS MEDIÇÕES DE UM SETOR E DEVOLVER OS ALERTAS ACIMA DO LIMITE.
  Future<List<Map<String, dynamic>>> _buscarAlertasDoSetor(
    int idSetor,
    String nomeSetor,
  ) async {
    debugPrint('BUSCANDO ALERTAS DO SETOR: $idSetor ($nomeSetor)');

    final resposta = await http
        .post(Uri.parse(url), body: {'id_setor': idSetor.toString()})
        .timeout(const Duration(seconds: 20));

    debugPrint('STATUS ($nomeSetor): ${resposta.statusCode}');
    debugPrint('RESPOSTA DO PHP ($nomeSetor): ${resposta.body}');

    if (resposta.statusCode != 200) {
      throw Exception('Erro HTTP: ${resposta.statusCode}');
    }

    final resultado = jsonDecode(utf8.decode(resposta.bodyBytes));

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

    final List<Map<String, dynamic>> alertasDoSetor = [];

    _analisarMedicoes(
      dados['temperatura'],
      'temperatura',
      nomeSetor,
      alertasDoSetor,
    );
    _analisarMedicoes(dados['ruido'], 'ruido', nomeSetor, alertasDoSetor);
    _analisarMedicoes(
      dados['qualidade_ar'],
      'qualidade_ar',
      nomeSetor,
      alertasDoSetor,
    );

    return alertasDoSetor;
  }

  // BUSCAR ALERTAS: UM SETOR (GERENTE) OU TODOS OS SETORES (ADMIN).
  Future<void> buscarAlertas() async {
    setState(() {
      carregando = true;
      erro = null;
    });

    try {
      final idSetor = widget.idSetor;
      debugPrint('ID DO SETOR: $idSetor');

      final List<Map<String, dynamic>> novosAlertas = [];

      if (idSetor != null && idSetor > 0) {
        // Setor específico.
        novosAlertas.addAll(
          await _buscarAlertasDoSetor(idSetor, widget.nomeSetor),
        );
      } else {
        // Sem setor definido (admin): busca os alertas de TODOS os setores.
        final setores = await _buscarTodosSetores();
        debugPrint('SETORES ENCONTRADOS: ${setores.length}');

        final falhas = <String>[];

        final resultados = await Future.wait(
          setores.map((setor) async {
            try {
              return await _buscarAlertasDoSetor(
                setor['id_setor'] as int,
                setor['nome'] as String,
              );
            } catch (e) {
              debugPrint('ERRO NO SETOR ${setor['nome']}: $e');
              falhas.add('${setor['nome']}: $e');
              return <Map<String, dynamic>>[];
            }
          }),
        );

        for (final lista in resultados) {
          novosAlertas.addAll(lista);
        }

        // Só considera erro se NENHUM setor pôde ser consultado.
        if (setores.isNotEmpty && falhas.length == setores.length) {
          throw Exception(falhas.first);
        }
      }

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

      // Quem abriu a tela já viu os alertas: o sininho do gerente zera.
      MonitorAlertas.marcarComoLidos(
        idSetor: (idSetor != null && idSetor > 0) ? idSetor : null,
      );
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
    String nomeSetor,
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
        'setor': nomeSetor,
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