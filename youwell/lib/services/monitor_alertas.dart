import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:youwell/alertas.dart';

class MonitorAlertas {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static const String urlMedicoes =
      'https://devsbee.com.br/You-Well/controllers/buscar_historico_medicoes.php';

  static const String urlSetores =
      'https://devsbee.com.br/You-Well/controllers/buscar_setor.php';

  static const Map<String, double> limites = {
    'temperatura': 25.0,
    'ruido': 65.0,
    'qualidade_ar': 70.0,
  };

  // Quantos alertas "já vistos" ficam salvos no aparelho por usuário.
  static const int _maxVistosSalvos = 1000;

  static Timer? _timer;
  static int? _idUsuario;
  static bool _monitorandoTodosSetores = false;
  static bool _monitorAtivo = false;

  // Muda a cada parar()/iniciar, para descartar respostas de uma sessão antiga.
  static int _sessao = 0;

  static bool _consultando = false;
  static bool _dialogAberto = false;

  // Alertas que o gerente já visualizou (salvos no aparelho).
  static final Set<String> _vistos = {};

  // Alertas que estão na fila ou aparecendo na tela agora (ainda não vistos).
  static final Set<String> _pendentes = {};

  static final List<Map<String, dynamic>> _fila = [];

  static String _chavePrefs(int idUsuario) => 'alertas_vistos_usuario_$idUsuario';

  /// Inicia o monitoramento dos setores pelos quais o gerente é responsável.
  static Future<void> iniciarGerente({required int idUsuario}) async {
    await _iniciar(idUsuario: idUsuario);
  }

  /// Inicia o monitoramento de todos os setores para o administrador.
  static Future<void> iniciarAdmin({int? idUsuario}) async {
    await _iniciar(idUsuario: idUsuario, todosSetores: true);
  }

  static Future<void> _iniciar({
    int? idUsuario,
    bool todosSetores = false,
  }) async {
    parar();
    final sessao = _sessao;

    _idUsuario = idUsuario;
    _monitorandoTodosSetores = todosSetores;
    _monitorAtivo = true;
    await _carregarVistos();

    // Se parar() ou outro iniciar foi chamado durante o await, desiste.
    if (sessao != _sessao) return;

    consultar();
    _timer = Timer.periodic(const Duration(seconds: 20), (_) => consultar());
  }

  static void parar() {
    _sessao++;
    _timer?.cancel();
    _timer = null;
    _consultando = false;
    _idUsuario = null;
    _monitorandoTodosSetores = false;
    _monitorAtivo = false;
    _vistos.clear();
    _pendentes.clear();
    _fila.clear();
    // Os alertas vistos continuam salvos no aparelho (SharedPreferences).
  }

  static Future<void> _carregarVistos() async {
    _vistos.clear();
    final idUsuario = _idUsuario;
    if (idUsuario == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      _vistos.addAll(prefs.getStringList(_chavePrefs(idUsuario)) ?? []);
      debugPrint('ALERTAS JÁ VISTOS CARREGADOS: ${_vistos.length}');
    } catch (e) {
      debugPrint('Erro ao carregar alertas vistos: $e');
    }
  }

  static Future<void> _marcarComoVisto(
    String chave,
    int? idUsuario,
    int sessao,
  ) async {
    _pendentes.remove(chave);

    if (sessao == _sessao) _vistos.add(chave);
    if (idUsuario == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _chavePrefs(idUsuario);

      final lista = List<String>.from(prefs.getStringList(key) ?? <String>[]);
      if (!lista.contains(chave)) lista.add(chave);

      final aparada = lista.length > _maxVistosSalvos
          ? lista.sublist(lista.length - _maxVistosSalvos)
          : lista;

      await prefs.setStringList(key, aparada);
    } catch (e) {
      debugPrint('Erro ao salvar alerta visto: $e');
    }
  }

  // Sem idUsuario, o endpoint retorna todos os setores (admin).
  static Future<List<Map<String, dynamic>>> _buscarSetores(
    int? idUsuario,
  ) async {
    final resposta = await http
        .post(
          Uri.parse(urlSetores),
          headers: {'Accept': 'application/json'},
          body: idUsuario == null
              ? null
              : {'id_usuario': idUsuario.toString()},
        )
        .timeout(const Duration(seconds: 15));

    if (resposta.statusCode != 200) {
      throw Exception('Erro HTTP ${resposta.statusCode} ao buscar setores');
    }

    final dados = jsonDecode(utf8.decode(resposta.bodyBytes));

    if (dados is! Map || dados['success'] != true) {
      throw Exception('Não foi possível buscar os setores.');
    }

    final lista = dados['setores'];
    if (lista is! List) return [];

    final setores = <Map<String, dynamic>>[];

    for (final setor in lista) {
      if (setor is! Map) continue;

      final id = int.tryParse(setor['id_setor']?.toString() ?? '');
      if (id == null) continue;

      setores.add({'id_setor': id, 'nome': setor['nome']?.toString() ?? ''});
    }

    return setores;
  }

  // Consulta as medições de um setor e devolve os alertas que ainda não foram vistos.
  static Future<List<Map<String, dynamic>>> _consultarSetor(
    Map<String, dynamic> setor,
  ) async {
    final int idSetor = setor['id_setor'];
    final String nomeSetor = setor['nome'];

    try {
      final resposta = await http
          .post(
            Uri.parse(urlMedicoes),
            body: {'id_setor': idSetor.toString()},
          )
          .timeout(const Duration(seconds: 15));

      if (resposta.statusCode != 200) {
        throw Exception('Erro HTTP: ${resposta.statusCode}');
      }

      final dados = jsonDecode(utf8.decode(resposta.bodyBytes));

      if (dados is! Map || dados['success'] != true) {
        throw Exception('Resposta inválida ao consultar medições.');
      }

      final novos = <Map<String, dynamic>>[];

      for (final indicador in limites.keys) {
        final medicoes = dados[indicador];
        if (medicoes is! List) continue;

        for (final item in medicoes) {
          if (item is! Map) continue;

          final valor = double.tryParse(item['valor']?.toString() ?? '');
          final dataHora = item['data_hora']?.toString();

          if (valor == null || dataHora == null) continue;
          if (valor <= limites[indicador]!) continue;

          final identificador =
              item['id_leitura']?.toString() ?? '$indicador|$valor|$dataHora';

          // A chave inclui o setor, para não confundir alertas de setores diferentes.
          final chave = '$idSetor|$indicador|$identificador';

          if (_vistos.contains(chave) || _pendentes.contains(chave)) continue;

          novos.add({
            'chave': chave,
            'id_setor': idSetor,
            'nome_setor': nomeSetor,
            'indicador': indicador,
            'valor': valor,
            'data_hora': dataHora,
          });
        }
      }

      return novos;
    } catch (e) {
      debugPrint('Erro ao consultar o setor $idSetor ($nomeSetor): $e');
      return [];
    }
  }

  static Future<void> consultar() async {
    final idUsuario = _idUsuario;

    if (_consultando || !_monitorAtivo) return;

    debugPrint(
      _monitorandoTodosSetores
          ? 'CONSULTANDO ALERTAS DE TODOS OS SETORES...'
          : 'CONSULTANDO ALERTAS DO GERENTE $idUsuario...',
    );

    _consultando = true;
    final sessao = _sessao;

    try {
      // Busca os setores a cada ciclo: se o gerente ganhar um setor novo,
      // ele passa a ser monitorado sem precisar fazer login de novo.
      final setores = await _buscarSetores(
        _monitorandoTodosSetores ? null : idUsuario,
      );
      debugPrint('SETORES MONITORADOS: ${setores.map((s) => s['nome']).toList()}');

      final resultados = await Future.wait(setores.map(_consultarSetor));

      // O gerente saiu ou outro usuário entrou durante a consulta.
      if (sessao != _sessao) return;

      var adicionados = 0;

      for (final lista in resultados) {
        for (final alerta in lista) {
          final chave = alerta['chave'] as String;

          if (_vistos.contains(chave) || _pendentes.contains(chave)) continue;

          _pendentes.add(chave);
          _fila.add(alerta);
          adicionados++;
        }
      }

      debugPrint('NOVOS ALERTAS ENCONTRADOS: $adicionados');

      _mostrarProximo();
    } catch (e) {
      debugPrint('Erro no monitoramento de alertas: $e');
    } finally {
      if (sessao == _sessao) _consultando = false;
    }
  }

  static void _mostrarProximo() {
    if (_dialogAberto || _fila.isEmpty) return;

    final contexto = navigatorKey.currentContext;

    if (contexto == null) return;

    final alerta = _fila.removeAt(0);

    final String chave = alerta['chave'];
    final int idSetor = alerta['id_setor'];
    final String nomeSetor = alerta['nome_setor'];

    // Guardados agora, pois podem mudar até o diálogo ser fechado.
    final idUsuario = _idUsuario;
    final sessao = _sessao;

    String nomeIndicador;
    String unidade;

    switch (alerta['indicador']) {
      case 'temperatura':
        nomeIndicador = 'Temperatura elevada';
        unidade = '°C';
        break;

      case 'ruido':
        nomeIndicador = 'Ruído elevado';
        unidade = 'dB';
        break;

      default:
        nomeIndicador = 'Qualidade do ar inadequada';
        unidade = '';
    }

    _dialogAberto = true;

    showDialog(
      context: contexto,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          icon: const Icon(
            Icons.warning_amber_rounded,
            color: Colors.red,
            size: 55,
          ),
          title: const Text(
            'Novo alerta identificado!',
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                nomeSetor,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                nomeIndicador,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Valor registrado: ${alerta['valor']}$unidade',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'Limite configurado: '
                '${limites[alerta['indicador']]}$unidade',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Fechar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0A5540),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();

                navigatorKey.currentState?.push(
                  MaterialPageRoute(
                    builder: (_) =>
                        AlertaScreen(idSetor: idSetor, nomeSetor: nomeSetor),
                  ),
                );
              },
              child: const Text('Ver alertas'),
            ),
          ],
        );
      },
    ).then((_) async {
      // Qualquer saída do diálogo (Fechar, Ver alertas ou botão voltar)
      // conta como "visualizado" e nunca mais é mostrado.
      await _marcarComoVisto(chave, idUsuario, sessao);

      _dialogAberto = false;
      _mostrarProximo();
    });
  }
}