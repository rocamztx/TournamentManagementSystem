import 'package:flutter/material.dart';
import 'services/server_config_service.dart';
import 'views/server_settings_view.dart';
import 'views/modalidade_selection_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MeuCampeonatoApp());
}

class MeuCampeonatoApp extends StatefulWidget {
  const MeuCampeonatoApp({super.key});

  @override
  State<MeuCampeonatoApp> createState() => _MeuCampeonatoAppState();
}

class _MeuCampeonatoAppState extends State<MeuCampeonatoApp> {
  late Future<void> _initFuture;

  @override
  void initState() {
    super.initState();
    _initFuture = ServerConfigService.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sistema de Torneio FRC/OBR',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        scaffoldBackgroundColor: const Color(0xFF040D1A),
        useMaterial3: true,
      ),
      home: FutureBuilder<void>(
        future: _initFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const _StartupLoadingView();
          }
          // Sempre começa na tela de configuração do servidor
          return ServerSettingsView(
            onConfigurationFinished: _irParaModalidades,
          );
        },
      ),
    );
  }

  void _irParaModalidades(BuildContext ctx) {
    // Navega para a tela de modalidades substituindo a tela de configuração
    Navigator.of(ctx).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const ModalidadeSelectionView(),
        transitionDuration: const Duration(milliseconds: 500),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
          child: child,
        ),
      ),
    );
  }
}

class _StartupLoadingView extends StatelessWidget {
  const _StartupLoadingView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF040D1A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF2563EB)),
            SizedBox(height: 16),
            Text(
              'Inicializando...',
              style: TextStyle(fontSize: 16, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }
}
