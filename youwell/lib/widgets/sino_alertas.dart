import 'package:flutter/material.dart';
import 'package:youwell/services/monitor_alertas.dart';

/// Sininho para a AppBar: mostra os alertas não lidos do usuário atual.
/// Ao tocar, abre a tela com os setores monitorados.
class SinoAlertas extends StatelessWidget {
  const SinoAlertas({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: MonitorAlertas.naoLidos,
      builder: (context, quantidade, _) {
        return IconButton(
          tooltip: quantidade > 0
              ? '$quantidade alertas não lidos'
              : 'Nenhum alerta novo',
          onPressed: MonitorAlertas.abrirAlertas,
          icon: Badge(
            isLabelVisible: quantidade > 0,
            label: Text(quantidade > 99 ? '99+' : '$quantidade'),
            child: Icon(
              quantidade > 0
                  ? Icons.notifications_active
                  : Icons.notifications_none,
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }
}
