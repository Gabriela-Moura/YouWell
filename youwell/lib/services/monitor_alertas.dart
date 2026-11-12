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

  /// Quantidade de alertas que o usuário atual ainda não abriu.
  static final ValueNotifier<int> naoLidos = ValueNotifier<int>(0);

  static Timer? _timer;
  static int? _idUsuario;
  static bool _admin = false;

  // Muda a cada parar()/iniciar, para descartar respostas de uma sessão antiga.
  static int _sessao = 0;

  static bool _consultando = false;
  static bool _dialogAberto = false;

  // Alertas que já apareceram numa notificação (não aparecem de novo).
  // Salvos no aparelho.
  static final Set<String> _notificados = {};

  // Alertas que o usuário atual já abriu (somem do contador do sino).
  // Salvos no aparelho.
  static final Set<String> _lidos = {};

  // Alertas acima do limite que existem agora nos setores monitorados.
  static final Map<String, Map<String, dynamic>> _atuais = {};

  // Mantém a chave antiga, então quem já usou a versão anterior não perde o histórico.
  static String _chaveNotificados(int idUsuario) =>
      'alertas_vistos_usuario_$idUsuario';

  static String _chaveLidos(int idUsuario) =>
      'alertas_lidos_usuario_$idUsuario';

  /// Inicia o monitoramento dos setores pelos quais o gerente é responsável.
  static Future<void> iniciarGerente({required int idUsuario}) async {
    await _iniciar(idUsuario: idUsuario, admin: false);
  }

  /// Inicia o monitoramento de todos os setores para uma conta de administrador.
  static Future<void> iniciarAdmin({required int idUsuario}) async {
    await _iniciar(idUsuario: idUsuario, admin: true);
  }

  static Future<void> _iniciar({
    required int idUsuario,
    required bool admin,
  }) async {
    parar();
    final sessao = _sessao;

    _idUsuario = idUsuario;
    _admin = admin;
    await _carregarRegistros();

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
    _admin = false;
    _notificados.clear();
    _lidos.clear();
    _atuais.clear();
    naoLidos.value = 0;
    // Os registros continuam salvos no aparelho (SharedPreferences).
  }

  static Future<void> _carregarRegistros() async {
    _notificados.clear();
    _lidos.clear();

    final idUsuario = _idUsuario;
    if (idUsuario == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      _notificados.addAll(
        prefs.getStringList(_chaveNotificados(idUsuario)) ?? [],
      );
      _lidos.addAll(prefs.getStringList(_chaveLidos(idUsuario)) ?? []);
      debugPrint(
        'ALERTAS CARREGADOS: ${_notificados.length} notificados, '
        '${_lidos.length} lidos',
      );
    } catch (e) {
      debugPrint('Erro ao carregar registros de alertas: $e');
    }
  }

  static Future<void> _salvar(
    String chavePrefs,
    Set<String> conjunto,
    int sessao,
  ) async {
    if (sessao != _sessao) return;

    final lista = conjunto.toList();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(chavePrefs, lista);
    } catch (e) {
      debugPrint('Erro ao salvar registros de alertas: $e');
    }
  }

  static void _atualizarContagem() {
    naoLidos.value = _atuais.keys.where((k) => !_lidos.contains(k)).length;
  }

  /// Marca como lidos os alertas já conhecidos (de um setor ou de todos).
  /// Chamado pela tela de alertas quando ela é aberta.
  static void marcarComoLidos({int? idSetor}) {
    final idUsuario = _idUsuario;
    if (idUsuario == null) return;

    var mudou = false;

    for (final alerta in _atuais.values) {
      if (idSetor != null && alerta['id_setor'] != idSetor) continue;
      if (_lidos.add(alerta['chave'] as String)) mudou = true;
    }

    if (!mudou) return;

    _atualizarContagem();
    _salvar(_chaveLidos(idUsuario), _lidos, _sessao);
  }

  /// Abre a tela com os alertas de todos os setores monitorados.
  static void abrirAlertas() {
    final idUsuario = _idUsuario;
    if (idUsuario == null) return;

    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => AlertaScreen(
          nomeSetor: _admin ? 'Todos os setores' : 'Todos os meus setores',
          idUsuario: _admin ? null : idUsuario,
        ),
      ),
    );
  }

  // Sem idUsuario, o endpoint retorna todos os setores (admin).
  static Future<List<Map<String, dynamic>>> _buscarSetores(
    int? idUsuario,
  ) async {
    final resposta = await http
        .post(
          Uri.parse(urlSetores),
          headers: {'Accept': 'application/json'},
          body: idUsuario == null ? null : {'id_usuario': idUsuario.toString()},
        )
        .timeout(const Duration(seconds: 15));

    if (resposta.statusCode != 200) {
      throw Exception('Erro HTTP ${resposta.statusCode} ao buscar setores');
    }

    final dados = jsonDecode(utf8.decode(resposta.bodyBytes));

    if (dados is! Map || dados['success'] != true) {
      throw Exception('Não foi possível buscar os setores monitorados.');
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

  static Future<List<Map<String, dynamic>>> buscarHistoricoAlertas() async {
    final idUsuario = _idUsuario;
    if (idUsuario == null) {
      throw StateError(
        'Não há uma sessão autenticada para consultar o histórico.',
      );
    }

    final sessao = _sessao;
    final setores = await _buscarSetores(_admin ? null : idUsuario);
    final resultados = await Future.wait(
      setores.map((setor) => _buscarHistoricoSetor(setor)),
    );

    if (sessao != _sessao) {
      throw StateError('A sessão mudou durante a consulta do histórico.');
    }

    return resultados.expand((registros) => registros).toList()..sort((a, b) {
      final dataHoraA = '${a['data']} ${a['hora']}';
      final dataHoraB = '${b['data']} ${b['hora']}';
      return dataHoraB.compareTo(dataHoraA);
    });
  }

  static Future<List<Map<String, dynamic>>> _buscarHistoricoSetor(
    Map<String, dynamic> setor,
  ) async {
    final idSetor = setor['id_setor'] as int;
    final nomeSetor = setor['nome'] as String;
    final resposta = await http
        .post(
          Uri.parse(urlMedicoes),
          headers: {'Accept': 'application/json'},
          body: {'id_setor': idSetor.toString()},
        )
        .timeout(const Duration(seconds: 20));

    if (resposta.statusCode != 200) {
      throw Exception(
        'Erro HTTP ${resposta.statusCode} ao buscar histórico de $nomeSetor.',
      );
    }

    final dados = jsonDecode(utf8.decode(resposta.bodyBytes));
    if (dados is! Map || dados['success'] != true) {
      throw Exception('Não foi possível buscar o histórico de $nomeSetor.');
    }

    final limiteData = DateTime.now().subtract(const Duration(days: 30));
    final registros = <Map<String, dynamic>>[];

    for (final indicador in limites.keys) {
      final medicoes = dados[indicador];
      if (medicoes is! List) continue;

      for (final medicao in medicoes) {
        if (medicao is! Map) continue;

        final valor = double.tryParse(medicao['valor']?.toString() ?? '');
        final dataHora = DateTime.tryParse(
          medicao['data_hora']?.toString() ?? '',
        );
        if (valor == null ||
            dataHora == null ||
            valor <= limites[indicador]! ||
            dataHora.isBefore(limiteData)) {
          continue;
        }

        registros.add({
          'data':
              '${dataHora.year.toString().padLeft(4, '0')}-'
              '${dataHora.month.toString().padLeft(2, '0')}-'
              '${dataHora.day.toString().padLeft(2, '0')}',
          'hora':
              '${dataHora.hour.toString().padLeft(2, '0')}:'
              '${dataHora.minute.toString().padLeft(2, '0')}',
          'setor': nomeSetor,
          'indicador': indicador,
          'valor': valor,
          'gravidade': 'critico',
          'mensagem': 'Valor acima do limite máximo configurado.',
        });
      }
    }

    return registros;
  }

  // Devolve TODOS os alertas acima do limite de um setor.
  // Devolve null se a consulta falhou (para não apagar o que já se sabia).
  static Future<List<Map<String, dynamic>>?> _consultarSetor(
    Map<String, dynamic> setor,
  ) async {
    final int idSetor = setor['id_setor'];
    final String nomeSetor = setor['nome'];

    try {
      final resposta = await http
          .post(Uri.parse(urlMedicoes), body: {'id_setor': idSetor.toString()})
          .timeout(const Duration(seconds: 15));

      if (resposta.statusCode != 200) {
        throw Exception('Erro HTTP: ${resposta.statusCode}');
      }

      final dados = jsonDecode(utf8.decode(resposta.bodyBytes));

      if (dados is! Map || dados['success'] != true) {
        throw Exception('Resposta inválida ao consultar medições.');
      }

      final alertas = <Map<String, dynamic>>[];

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
          alertas.add({
            'chave': '$idSetor|$indicador|$identificador',
            'id_setor': idSetor,
            'nome_setor': nomeSetor,
            'indicador': indicador,
            'valor': valor,
            'data_hora': dataHora,
          });
        }
      }

      return alertas;
    } catch (e) {
      debugPrint('Erro ao consultar o setor $idSetor ($nomeSetor): $e');
      return null;
    }
  }

  static Future<void> consultar() async {
    final idUsuario = _idUsuario;

    if (_consultando || idUsuario == null) return;

    debugPrint(
      _admin
          ? 'CONSULTANDO ALERTAS DE TODOS OS SETORES (ADMIN $idUsuario)...'
          : 'CONSULTANDO ALERTAS DO GERENTE $idUsuario...',
    );

    _consultando = true;
    final sessao = _sessao;

    try {
      // Rebusca a lista a cada ciclo para incluir setores novos.
      final setores = await _buscarSetores(_admin ? null : idUsuario);
      final resultados = await Future.wait(setores.map(_consultarSetor));

      // A sessão terminou ou outro usuário entrou durante a consulta.
      if (sessao != _sessao) return;

      final idsMonitorados = setores.map((s) => s['id_setor'] as int).toSet();
      final idsConsultados = <int>{};

      // Atualiza os alertas de cada setor que respondeu.
      for (var i = 0; i < setores.length; i++) {
        final lista = resultados[i];
        if (lista == null) continue; // falhou: mantém o que já tinha

        final idSetor = setores[i]['id_setor'] as int;
        idsConsultados.add(idSetor);

        _atuais.removeWhere((_, a) => a['id_setor'] == idSetor);
        for (final alerta in lista) {
          _atuais[alerta['chave'] as String] = alerta;
        }
      }

      // Setores fora do escopo atual deixam de contar.
      _atuais.removeWhere((_, a) => !idsMonitorados.contains(a['id_setor']));

      _limparRegistrosAntigos(idUsuario, idsConsultados, sessao);
      _atualizarContagem();

      debugPrint(
        'ALERTAS ATUAIS: ${_atuais.length} '
        '(não lidos: ${naoLidos.value}) em ${setores.length} setor(es)',
      );

      _mostrarNotificacao();
    } catch (e) {
      debugPrint('Erro no monitoramento de alertas: $e');
    } finally {
      if (sessao == _sessao) _consultando = false;
    }
  }

  // Alertas que saíram do histórico do servidor não precisam mais ficar salvos.
  // Só limpa setores que responderam agora, para não perder registros se a rede falhar.
  static void _limparRegistrosAntigos(
    int idUsuario,
    Set<int> idsConsultados,
    int sessao,
  ) {
    bool podar(Set<String> conjunto) {
      final antes = conjunto.length;

      conjunto.removeWhere((chave) {
        final idSetor = int.tryParse(chave.split('|').first);
        return idSetor != null &&
            idsConsultados.contains(idSetor) &&
            !_atuais.containsKey(chave);
      });

      return conjunto.length != antes;
    }

    if (podar(_notificados)) {
      _salvar(_chaveNotificados(idUsuario), _notificados, sessao);
    }

    if (podar(_lidos)) {
      _salvar(_chaveLidos(idUsuario), _lidos, sessao);
    }
  }

  // Mostra UMA notificação com todos os alertas novos (ainda não notificados).
  static void _mostrarNotificacao() {
    if (_dialogAberto) return;

    final idUsuario = _idUsuario;
    final contexto = navigatorKey.currentContext;

    if (idUsuario == null || contexto == null) return;

    final lote = _atuais.values
        .where((a) => !_notificados.contains(a['chave']))
        .toList();

    if (lote.isEmpty) return;

    final sessao = _sessao;
    final chavesDoLote = lote.map((a) => a['chave'] as String).toList();

    // Contagens para o texto da notificação.
    final total = lote.length;
    final porSetor = <String, int>{};
    final porIndicador = <String, int>{};

    for (final alerta in lote) {
      porSetor.update(
        alerta['nome_setor'] as String,
        (v) => v + 1,
        ifAbsent: () => 1,
      );
      porIndicador.update(
        alerta['indicador'] as String,
        (v) => v + 1,
        ifAbsent: () => 1,
      );
    }

    final setoresOrdenados = porSetor.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    const nomesIndicadores = {
      'temperatura': 'Temperatura',
      'ruido': 'Ruído',
      'qualidade_ar': 'Qualidade do ar',
    };

    const verde = Color(0xFF0A5540);

    _dialogAberto = true;

    showDialog(
      context: contexto,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          actionsAlignment: MainAxisAlignment.center,
          icon: const Icon(
            Icons.notifications_active,
            color: Colors.red,
            size: 50,
          ),
          title: Text('Você possui novos alertas', textAlign: TextAlign.center),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Fechar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: verde,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                abrirAlertas();
              },
              child: const Text('Ver alertas'),
            ),
          ],
        );
      },
    ).then((_) async {
      // Qualquer saída do diálogo (Fechar, Ver alertas ou botão voltar)
      // conta como "notificado": esses alertas não aparecem de novo.
      _dialogAberto = false;

      if (sessao != _sessao) return;

      _notificados.addAll(chavesDoLote);
      await _salvar(_chaveNotificados(idUsuario), _notificados, sessao);

      // Se chegaram alertas novos enquanto o diálogo estava aberto.
      _mostrarNotificacao();
    });
  }
}
