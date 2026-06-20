import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import '../config/network_config.dart';
import '../services/api_service.dart';
import '../models/classificacao_model.dart';
import 'modo_juiz_view.dart';
import 'telao_view.dart'; // Importação do Telão

class AppColors {
  static const Color primaryNavy = Color(0xFF1A365D);
  static const Color techBlue = Color(0xFF2563EB);
  static const Color background = Color(0xFFF8FAFC);
  static const Color textDark = Color(0xFF1E293B);
  static const Color goldRow = Color(0xFFFEF9E7);
  static const Color silverRow = Color(0xFFF1F5F9);
  static const Color bronzeRow = Color(0xFFFDF4E3);
  static const Color goldMedal = Color(0xFFF59E0B);
  static const Color silverMedal = Color(0xFF94A3B8);
  static const Color bronzeMedal = Color(0xFFB45309);
}

class ClassificacaoView extends StatefulWidget {
  const ClassificacaoView({super.key});

  @override
  State<ClassificacaoView> createState() => _ClassificacaoViewState();
}

class _ClassificacaoViewState extends State<ClassificacaoView> {
  final ApiService _apiService = ApiService();
  StompClient? _client;

  // Variável de Estado que segura a requisição
  Future<List<ClassificacaoModel>>? _dadosTabela;

  @override
  void initState() {
    super.initState();
    _recarregarDados(); // Carrega os dados pela primeira vez ao abrir o app
    _conectarWebSocket();
  }

  @override
  void dispose() {
    _client?.deactivate();
    super.dispose();
  }

  /// O Gatilho Mestre: Quando chamado, força as tabelas a buscarem dados frescos no Java
  void _recarregarDados() {
    setState(() {
      _dadosTabela = _apiService.obterClassificacaoGeral();
    });
  }

  void _conectarWebSocket() {
    _client = StompClient(
      config: StompConfig(
        url: '${NetworkConfig.baseUrl}/ws-torneio',
        useSockJS: true,
        reconnectDelay: const Duration(seconds: 5),
        onConnect: (frame) {
          _client?.subscribe(
            destination: '/topic/classificacao',
            callback: (frame) {
              if (!mounted || frame.body == null) return;

              final List<dynamic> json = jsonDecode(frame.body!);
              final lista = json
                  .map((item) => ClassificacaoModel.fromJson(item))
                  .toList();

              setState(() {
                _dadosTabela = Future.value(lista);
              });
            },
          );

          _client?.send(destination: '/app/solicitar-classificacao', body: '');
        },
        onWebSocketError: (_) {
          if (mounted) {
            _recarregarDados();
          }
        },
      ),
    );

    _client?.activate();
  }

  Color _obterCorDaLinha(int index) {
    if (index == 0) return AppColors.goldRow;
    if (index == 1) return AppColors.silverRow;
    if (index == 2) return AppColors.bronzeRow;
    return Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        // BOTÃO ADICIONADO PARA ACESSO AO TELÃO
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: AppColors.techBlue,
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TelaoView()),
          ),
          label: const Text(
            'ABRIR TELÃO',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          icon: const Icon(Icons.tv, color: Colors.white),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 40.0, bottom: 20.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.emoji_events,
                        color: AppColors.primaryNavy,
                        size: 50,
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'Torneio Robô Seguidor de Linha',
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryNavy,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'SISTEMA DE PONTUAÇÃO E CLASSIFICAÇÃO',
                    style: TextStyle(
                      fontSize: 14,
                      letterSpacing: 1.5,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: const TabBar(
                labelColor: AppColors.techBlue,
                unselectedLabelColor: Colors.grey,
                indicatorColor: AppColors.techBlue,
                indicatorWeight: 3,
                labelStyle: TextStyle(fontWeight: FontWeight.bold),
                tabs: [
                  Tab(text: 'CLASSIFICAÇÃO GERAL'),
                  Tab(text: 'PONTUAÇÃO POR EQUIPE'),
                  Tab(text: 'MODO JUIZ'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.techBlue,
                notificationPredicate: (notification) =>
                    notification.metrics.axis == Axis.vertical,
                onRefresh: () async {
                  _recarregarDados();
                  await Future.delayed(const Duration(milliseconds: 500));
                },
                child: TabBarView(
                  children: [
                    _construirTabelaClassificacao(),
                    _construirGridEquipes(),
                    // Injetamos o Modo Juiz e entregamos o controle remoto (_recarregarDados) pra ele!
                    ModoJuizView(onAtualizarTabelas: _recarregarDados),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirTabelaClassificacao() {
    return FutureBuilder<List<ClassificacaoModel>>(
      future: _dadosTabela,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(
            child: CircularProgressIndicator(color: AppColors.techBlue),
          );
        if (snapshot.hasError)
          return Center(
            child: Text(
              'Erro: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        if (!snapshot.hasData || snapshot.data!.isEmpty)
          return const Center(child: Text('Nenhuma equipe pontuou ainda.'));

        final lista = snapshot.data!;
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: DataTable(
                headingRowColor: const WidgetStatePropertyAll(
                  AppColors.primaryNavy,
                ),
                headingTextStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
                dataRowMinHeight: 65,
                dataRowMaxHeight: 65,
                columns: const [
                  DataColumn(label: Text('POSIÇÃO')),
                  DataColumn(label: Text('EQUIPE')),
                  DataColumn(label: Text('ROUND 1')),
                  DataColumn(label: Text('ROUND 2')),
                  DataColumn(label: Text('ROUND 3')),
                  DataColumn(label: Text('TOTAL')),
                  DataColumn(label: Text('AÇÕES')),
                ],
                rows: List<DataRow>.generate(lista.length, (index) {
                  final item = lista[index];
                  return DataRow(
                    color: WidgetStatePropertyAll(_obterCorDaLinha(index)),
                    cells: [
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _construirEmblemaCircular(index + 1),
                            if (index <= 2)
                              Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: Icon(
                                  Icons.military_tech,
                                  size: 28,
                                  color: index == 0
                                      ? AppColors.goldMedal
                                      : index == 1
                                      ? AppColors.silverMedal
                                      : AppColors.bronzeMedal,
                                ),
                              ),
                          ],
                        ),
                      ),
                      DataCell(
                        Text(
                          item.nomeDaEquipe,
                          style: const TextStyle(
                            color: AppColors.textDark,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          '${item.notaRound1}',
                          style: const TextStyle(color: AppColors.textDark),
                        ),
                      ),
                      DataCell(
                        Text(
                          '${item.notaRound2}',
                          style: const TextStyle(color: AppColors.textDark),
                        ),
                      ),
                      DataCell(
                        Text(
                          '${item.notaRound3}',
                          style: const TextStyle(color: AppColors.textDark),
                        ),
                      ),
                      DataCell(
                        _construirEmblemaCircular(item.notaTotal, isNota: true),
                      ),
                      DataCell(
                        TextButton.icon(
                          onPressed: () => _mostrarDialogEdicao(context, item),
                          icon: const Icon(
                            Icons.edit_note,
                            color: AppColors.techBlue,
                            size: 22,
                          ),
                          label: const Text(
                            'EDITAR',
                            style: TextStyle(
                              color: AppColors.techBlue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _construirGridEquipes() {
    return FutureBuilder<List<ClassificacaoModel>>(
      future: _dadosTabela,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(
            child: CircularProgressIndicator(color: AppColors.techBlue),
          );
        if (snapshot.hasError)
          return Center(
            child: Text(
              'Erro: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        if (!snapshot.hasData || snapshot.data!.isEmpty)
          return const Center(child: Text('Nenhuma equipe pontuou ainda.'));

        final lista = snapshot.data!;
        return GridView.builder(
          padding: const EdgeInsets.all(40),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 400,
            crossAxisSpacing: 24,
            mainAxisSpacing: 24,
            childAspectRatio: 2.1,
          ),
          itemCount: lista.length,
          itemBuilder: (context, index) {
            final equipe = lista[index];
            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _mostrarDialogEdicao(context, equipe),
                borderRadius: BorderRadius.circular(12),
                splashColor: AppColors.techBlue.withOpacity(0.1),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x08000000),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        equipe.nomeDaEquipe,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Pontuação Total:',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          _construirEmblemaCircular(equipe.notaTotal),
                        ],
                      ),
                      Row(
                        children: [
                          _construirPilulaRound('R1: ${equipe.notaRound1}'),
                          const SizedBox(width: 8),
                          _construirPilulaRound('R2: ${equipe.notaRound2}'),
                          const SizedBox(width: 8),
                          _construirPilulaRound('R3: ${equipe.notaRound3}'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _mostrarDialogEdicao(BuildContext context, ClassificacaoModel equipe) {
    final TextEditingController nomeController = TextEditingController(
      text: equipe.nomeDaEquipe,
    );

    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          titlePadding: const EdgeInsets.only(
            left: 24,
            top: 24,
            right: 24,
            bottom: 8,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 16,
          ),
          title: Text(
            'Editar Equipe',
            style: const TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.w800,
              fontSize: 22,
            ),
          ),
          content: SizedBox(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nomeController,
                  decoration: InputDecoration(
                    labelText: 'Nome da Equipe',
                    labelStyle: TextStyle(color: Colors.grey.shade600),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: AppColors.techBlue,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Nota: Use o Modo Juiz para uma experiência otimizada de pontuação.',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Pontuação Total: ${equipe.notaTotal} pontos',
                        style: const TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '(2 melhores rounds)',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _construirPilulaRoundAzul(
                            'R1: ${equipe.notaRound1}pts',
                          ),
                          const SizedBox(width: 12),
                          _construirPilulaRoundAzul(
                            'R2: ${equipe.notaRound2}pts',
                          ),
                          const SizedBox(width: 12),
                          _construirPilulaRoundAzul(
                            'R3: ${equipe.notaRound3}pts',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.only(right: 24, bottom: 24),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'CANCELAR',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.techBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                try {
                  await _apiService.atualizarNomeEquipe(
                    equipe.id,
                    nomeController.text.trim(),
                  );
                  Navigator.pop(ctx);
                  _recarregarDados();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Nome da equipe atualizado!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('❌ Erro: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text(
                'SALVAR',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _construirEmblemaCircular(int numero, {bool isNota = false}) {
    return Container(
      width: isNota ? 50 : 36,
      height: 36,
      decoration: BoxDecoration(
        color: isNota ? Colors.white.withOpacity(0.5) : AppColors.techBlue,
        shape: isNota ? BoxShape.rectangle : BoxShape.circle,
        borderRadius: isNota ? BorderRadius.circular(8) : null,
        border: isNota
            ? Border.all(color: AppColors.techBlue.withOpacity(0.3))
            : null,
      ),
      child: Center(
        child: Text(
          '$numero',
          style: TextStyle(
            color: isNota ? AppColors.techBlue : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _construirPilulaRound(String texto) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
        color: AppColors.background,
      ),
      child: Text(
        texto,
        style: TextStyle(
          color: Colors.grey.shade700,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _construirPilulaRoundAzul(String texto) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Text(
        texto,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
