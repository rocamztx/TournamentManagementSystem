import 'package:flutter/material.dart';
import 'views/classificacao_view.dart';

void main() {
  runApp(const MeuCampeonatoApp());
}

class MeuCampeonatoApp extends StatelessWidget {
  const MeuCampeonatoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sistema de Torneio FRC/OBR',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      // Define a nossa tela de classificação como a página inicial do app!
      home: const ClassificacaoView(),
    );
  }
}