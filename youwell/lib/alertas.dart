
import 'package:flutter/material.dart';
import 'package:youwell/simulacaoBD/dados_sensores.dart';
import 'package:youwell/simulacaoBD/limites_alertas.dart';

class AlertaScreen extends StatelessWidget {
  const AlertaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final alertas = gerarAlertas();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Alertas ambientais',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF0A5540),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Container(
        color: Colors.grey.shade100,
        child: alertas.isEmpty
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
                  // Resumo dos alertas
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
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Exibe cada alerta individualmente
                  ...alertas.map((alerta) {
                    final critico = alerta['gravidade'] == 'critico';

                    final cor = critico
                        ? Colors.red.shade700
                        : Colors.orange.shade800;

                    final fundo = critico
                        ? Colors.red.shade50
                        : Colors.orange.shade50;

                    final indicador = alerta['indicador'] == 'temperatura'
                        ? 'Temperatura'
                        : alerta['indicador'] == 'ruido'
                            ? 'Ruído'
                            : 'Qualidade do ar';

                    final unidade = alerta['indicador'] == 'temperatura'
                        ? '°C'
                        : alerta['indicador'] == 'ruido'
                            ? ' dB'
                            : '';

                    return Card(
                      color: Colors.white,
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: cor.withAlpha(100),
                          width: 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  critico
                                      ? Icons.error
                                      : Icons.warning_amber_rounded,
                                  color: cor,
                                  size: 28,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${alerta['setor']} - $indicador',
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
                                    color: fundo,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    critico ? 'CRÍTICO' : 'ATENÇÃO',
                                    style: TextStyle(
                                      color: cor,
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
                              '${alerta['valor']}$unidade',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: cor,
                              ),
                            ),

                            const SizedBox(height: 6),

                            Text(
                              alerta['mensagem'],
                              style: const TextStyle(fontSize: 14),
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
                                  '${alerta['data']}',
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
                                  '${alerta['hora']}',
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

/// Analisa cada registro do banco simulado e gera os alertas.
List<Map<String, dynamic>> gerarAlertas() {
  final List<Map<String, dynamic>> alertas = [];

  for (final sensor in sensores) {
    final setor = setores.firstWhere(
      (s) => s['id'] == sensor['setor'],
      orElse: () => {
        'id': sensor['setor'],
        'nome': 'Setor desconhecido',
      },
    );

    for (final indicador in ['temperatura', 'ruido', 'ar']) {
      final valor = (sensor[indicador] as num).toDouble();
      final limite = limitesAlertas[indicador]!;

      final minimo = limite['minimo']!;
      final maximo = limite['maximo']!;
      final margem = limite['margemAtencao']!;

      String? gravidade;
      String? mensagem;

      if (valor < minimo) {
        gravidade = 'critico';
        mensagem = 'Valor abaixo do limite inferior configurado.';
      } else if (valor > maximo) {
        gravidade = 'critico';
        mensagem = 'Valor acima do limite superior configurado.';
      } else if (valor >= maximo - margem) {
        gravidade = 'atencao';
        mensagem = 'Valor próximo do limite superior configurado.';
      } else if (minimo > 0 && valor <= minimo + margem) {
        gravidade = 'atencao';
        mensagem = 'Valor próximo do limite inferior configurado.';
      }

      if (gravidade != null) {
        alertas.add({
          'idSensor': sensor['id'],
          'setor': setor['nome'],
          'idSetor': sensor['setor'],
          'indicador': indicador,
          'valor': valor,
          'data': sensor['data'],
          'hora': sensor['hora'],
          'gravidade': gravidade,
          'mensagem': mensagem,
        });
      }
    }
  }

  return alertas;
}