import 'package:flutter/material.dart';
import '../../screens/home_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // esconde aquela faixa vermelha de DEBUG que aparece no canto superior direito do app quando você roda o Flutter em modo de desenvolvimento.
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
    );
  }
}