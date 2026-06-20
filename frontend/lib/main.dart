import 'package:flutter/material.dart';
import 'services/server_config_service.dart';
import 'views/classificacao_view.dart';
import 'views/server_settings_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ServerConfigService.initialize();
  runApp(const MeuCampeonatoApp());
}

class MeuCampeonatoApp extends StatelessWidget {
  const MeuCampeonatoApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Verifica se o servidor já foi configurado
    final isConfigured = ServerConfigService.isServerConfigured();

    return MaterialApp(
      title: 'Sistema de Torneio FRC/OBR',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      // Se não estiver configurado, mostra tela de settings; caso contrário, mostra classificação
      home: isConfigured ? const ClassificacaoView() : const ServerSettingsView(),
    );
  }
}