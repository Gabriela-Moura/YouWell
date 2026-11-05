import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:youwell/alertas.dart';

class MonitorAlertas {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static const String url =
      'https://devsbee.com.br/You-Well/controllers/buscar_historico_medicoes.php';

  static const Map<String, double> limites = {
    'temperatura': 25.0,
    'ruido': 65.0,
    'qualidade_ar': 70.0,
  };

  static Timer? _timer;
  static int? _idSetor;
  static String _nomeSetor = '';

  static bool _consultando = false;
  static bool _dialogAberto = false;

  static final Set<String> _alertasConhecidos = {};
  static final List<Map<String, dynamic>> _filaAlertas = [];

  static void iniciar({required int? idSetor, required String nomeSetor}) {
    parar();

    _idSetor = idSetor;
    _nomeSetor = nomeSetor;
    _alertasConhecidos.clear();
    _filaAlertas.clear();

    consultar();

    _timer = Timer.periodic(const Duration(seconds: 20), (_) => consultar());
  }

  static void parar() {
    _timer?.cancel();
    _timer = null;
    _consultando = false;
    _alertasConhecidos.clear();
    _filaAlertas.clear();
  }

  static Future<void> consultar() async {
    if (_consultando) return;
    debugPrint('CONSULTANDO ALERTAS...');

    _consultando = true;

    try {
      final body = _idSetor == null
          ? <String, String>{}
          : {'id_setor': _idSetor.toString()};

      debugPrint('ID SETOR NO MONITOR: $_idSetor');
      debugPrint('BODY ENVIADO AO PHP: $body');

      final resposta = await http
          .post(Uri.parse(url), body: body)
          .timeout(const Duration(seconds: 15));

      if (resposta.statusCode != 200) {
        throw Exception('Erro HTTP: ${resposta.statusCode}');
      }

      final dados = jsonDecode(utf8.decode(resposta.bodyBytes));
      debugPrint('DADOS RECEBIDOS NO MONITOR: $dados');

      if (dados is! Map || dados['success'] != true) {
        throw Exception('Não foi possível consultar os alertas.');
      }

      final List<Map<String, dynamic>> novos = [];

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

          final chave = '$indicador|$identificador';

          if (_alertasConhecidos.contains(chave)) continue;

          _alertasConhecidos.add(chave);

          novos.add({
            'indicador': indicador,
            'valor': valor,
            'data_hora': dataHora,
          });
        }
      }

      debugPrint('NOVOS ALERTAS ENCONTRADOS: ${novos.length}');
      _filaAlertas.addAll(novos);

      _mostrarProximo();
    } catch (e) {
      debugPrint('Erro no monitoramento de alertas: $e');
    } finally {
      _consultando = false;
    }
  }

  static void _mostrarProximo() {
    if (_dialogAberto || _filaAlertas.isEmpty) return;

    final contexto = navigatorKey.currentContext;

    if (contexto == null) return;

    final alerta = _filaAlertas.removeAt(0);

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
                _nomeSetor,
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
                        AlertaScreen(idSetor: _idSetor, nomeSetor: _nomeSetor),
                  ),
                );
              },
              child: const Text('Ver alertas'),
            ),
          ],
        );
      },
    ).then((_) {
      _dialogAberto = false;
      _mostrarProximo();
    });
  }
}
