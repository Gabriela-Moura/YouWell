import 'package:flutter/material.dart';
import 'package:youwell/admin.dart';
import 'package:youwell/main.dart';
import 'package:youwell/temperatura_screen.dart';
import 'package:youwell/screens/home_screen.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:youwell/setor_screen.dart';
import 'package:youwell/simulacaoBD/dados_sensores.dart';
import 'package:youwell/temperatura_screen.dart';
import 'package:youwell/qualidade_ar.dart';
import 'package:youwell/ruido.dart';
import 'package:youwell/alertas.dart';
import 'package:youwell/historico.dart';

void main() {
  runApp(MyApp());
}

class AlertaScreen extends StatelessWidget {
  const AlertaScreen ({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // esconde aquela faixa vermelha de DEBUG que aparece no canto superior direito do app quando você roda o Flutter em modo de desenvolvimento.
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
    );
  }
}