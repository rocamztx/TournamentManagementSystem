import 'dart:async';

import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/classificacao_model.dart';
import 'server_settings_view.dart';

class _JuizColors {
  static const Color background = Color(0xFF040D1A);
  static const Color cardBg = Color(0xFF0A1628);
  static const Color divider = Color(0xFF1E3A5F);
  static const Color textDark = Color(0xFFE2E8F0);
  static const Color textMuted = Color(0xFF64748B);
  static const Color techBlue = Color(0xFF2563EB);
}

class ModoJuizView extends StatefulWidget {
  final VoidCallback onAtualizarTabelas;

  const ModoJuizView({super.key, required this.onAtualizarTabelas});

  @override
  State<ModoJuizView> createState() => _ModoJuizViewState();
}

class _ModoJuizViewState extends State<ModoJuizView> {
  final ApiService _api_service = ApiService();

  List<ClassificacaoModel> _equipesBanco = [];
  bool _carregandoEquipes = true;
  String? _erroCarregarEquipes;

  bool _cronometroAtivo = false;
  Duration _tempoDecorrido = Duration.zero;
  Timer? _timer;

  int _roundSelecionado = 1;

  int? _pontuacaoInicial;
  int? _checkPoint1;
  int? _checkPoint2;
  int? _checkPoint3;
  int? _chegada;
  int? _bonusTempo;

  @override
  void initState() {
    super.initState();
    _carregarEquipes();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _pararCronometro() {
    if (!_cronometroAtivo) return;
    _timer?.cancel();
    _timer = null;
    if (mounted) {
      setState(() => _cronometroAtivo = false);
    }
  }

  void _iniciarCronometro() {
    if (_cronometroAtivo) return;
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted) {
        _timer?.cancel();
        return;
      }
      setState(() => _tempoDecorrido += const Duration(milliseconds: 100));
    });
    if (mounted) {
      setState(() => _cronometroAtivo = true);
    }
  }

  void _toggleCronometro() {
    if (_cronometroAtivo) {
      _pararCronometro();
    } else {
      _iniciarCronometro();
    }
  }

  Future<void> _carregarEquipes() async {
    try {
      final lista = await _api_service.obterEquipesParaSelecao(modalidade: 'seguidor_linha');
      if (!mounted) return;

      setState(() {
        _equipesBanco = lista;
        _carregandoEquipes = false;
        _erroCarregarEquipes = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _equipesBanco = [];
        _carregandoEquipes = false;
        _erroCarregarEquipes = e.toString();
      });
    }
  }

  Future<void> _recarregarEquipes() async {
    if (mounted) {
      setState(() {
        _carregandoEquipes = true;
        _erroCarregarEquipes = null;
      });
    }

    await _carregarEquipes();
  }

  int get _pontuacaoCalculada {
    return (_pontuacaoInicial ?? 0) +
        (_checkPoint1 ?? 0) +
        (_checkPoint2 ?? 0) +
        (_checkPoint3 ?? 0) +
        (_chegada ?? 0) +
        (_bonusTempo ?? 0);
  }

  void _resetarFormulario() {
    _timer?.cancel();
    _timer = null;
    setState(() {
      _pontuacaoInicial = null;
      _checkPoint1 = null;
      _checkPoint2 = null;
      _checkPoint3 = null;
      _chegada = null;
      _bonusTempo = null;
      _tempoDecorrido = Duration.zero;
      _cronometroAtivo = false;
    });
  }

  Future<void> _dialogoFinalizacao() async {
    final double? tempoEscolhido = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Finalizar Round'),
        content: Text(
          'Tempo registrado: ${(_tempoDecorrido.inMilliseconds / 1000).toStringAsFixed(1)} s.\nDeseja usar esse tempo ou 180s?',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(ctx, _tempoDecorrido.inMilliseconds / 1000),
            child: const Text('Usar tempo atual'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 180.0),
            child: const Text('Usar 180 segundos'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );

    if (tempoEscolhido == null) return;

    if (_equipesBanco.isEmpty || _erroCarregarEquipes != null) {
      await _recarregarEquipes();
      if (!mounted) return;
    }

    final ClassificacaoModel?
    selecionada = await showModalBottomSheet<ClassificacaoModel>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, modalSetState) {
          Future<void> recarregarNoModal() async {
            modalSetState(() {
              _carregandoEquipes = true;
              _erroCarregarEquipes = null;
            });
            await _carregarEquipes();
            if (mounted && ctx.mounted) {
              modalSetState(() {});
            }
          }

          if (_carregandoEquipes) {
            return const SizedBox(
              height: 220,
              child: Center(child: CircularProgressIndicator(color: _JuizColors.textDark)),
            );
          }

          return SizedBox(
            height: MediaQuery.of(ctx).size.height * 0.6,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Selecione a equipe',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Recarregar equipes',
                        onPressed: recarregarNoModal,
                        icon: const Icon(Icons.refresh),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _equipesBanco.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.group_off,
                                  size: 48,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _erroCarregarEquipes ??
                                      'Nenhuma equipe encontrada no servidor.',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.grey),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: recarregarNoModal,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Tentar novamente'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _equipesBanco.length,
                          itemBuilder: (_, i) {
                            final eq = _equipesBanco[i];
                            return ListTile(
                              title: Text(eq.nomeDaEquipe),
                              subtitle: Text('ID: ${eq.id}'),
                              onTap: () => Navigator.pop(ctx, eq),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );

    if (selecionada == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResumoScreen(
          nomeEquipe: selecionada.nomeDaEquipe,
          equipeId: selecionada.id,
          tempoFinal: tempoEscolhido,
          pontuacaoTotal: _pontuacaoCalculada,
          onConfirm: (equipeId, tempo) async {
            try {
              await _api_service.lancarNota(
                equipeId,
                _roundSelecionado,
                _pontuacaoCalculada,
                tempo,
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✅ Pontuação salva!')),
                );
                widget.onAtualizarTabelas();
                await _carregarEquipes();
                _resetarFormulario();
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            } catch (e) {
              if (mounted)
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Erro ao salvar: $e')));
            }
          },
        ),
      ),
    );
  }

  Future<void> _salvarPontuacao() async {
    if (_cronometroAtivo) {
      _pararCronometro();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⏱️ Cronômetro pausado automaticamente'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
    await _dialogoFinalizacao();
  }

  @override
  Widget build(BuildContext context) {
    if (_carregandoEquipes) {
      return Container(
        color: _JuizColors.background,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: _JuizColors.techBlue),
              SizedBox(height: 16),
              Text(
                'Carregando equipes...',
                style: TextStyle(fontSize: 16, color: _JuizColors.textMuted),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      color: _JuizColors.background,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: _JuizColors.divider),
              ),
              color: _JuizColors.cardBg,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Modo Juiz',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: _JuizColors.textDark,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Registro rápido do round',
                          style: TextStyle(fontSize: 13, color: _JuizColors.textMuted),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          tooltip: 'Alterar IP do servidor',
                          icon: const Icon(
                            Icons.router,
                            size: 28,
                            color: Color(0xFF2563EB),
                          ),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ServerSettingsView(),
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Modo Telão',
                          icon: const Icon(
                            Icons.tv,
                            size: 28,
                            color: _JuizColors.techBlue,
                          ),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  TelaoScreen(equipes: _equipesBanco),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 0,
              color: _JuizColors.cardBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: _JuizColors.divider),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _construirDisplayTempo(),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: Icon(
                          _cronometroAtivo ? Icons.pause : Icons.play_arrow,
                        ),
                        label: Text(
                          _cronometroAtivo
                              ? 'PAUSAR CRONÔMETRO'
                              : 'INICIAR CRONÔMETRO',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _cronometroAtivo
                              ? Colors.orange
                              : Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _toggleCronometro,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _construirSecaoTitulo('Selecione o Round'),
            Row(
              children: [
                Expanded(child: _construirBotaoRound(1, 'ROUND 1')),
                const SizedBox(width: 12),
                Expanded(child: _construirBotaoRound(2, 'ROUND 2')),
                const SizedBox(width: 12),
                Expanded(child: _construirBotaoRound(3, 'ROUND 3')),
              ],
            ),
            const SizedBox(height: 16),
            _construirSecaoTitulo(
              'Pontuação Inicial - Round $_roundSelecionado',
            ),
            Row(
              children: [
                Expanded(
                  child: _construirBotaoEscolha(
                    valor: 10,
                    grupoAtual: _pontuacaoInicial,
                    titulo: 'SAÍDA VÁLIDA (+10)',
                    isFalha: false,
                    onSelect: (v) => setState(() => _pontuacaoInicial = v),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _construirBotaoEscolha(
                    valor: 0,
                    grupoAtual: _pontuacaoInicial,
                    titulo: 'SAÍDA INVÁLIDA (0)',
                    isFalha: true,
                    onSelect: (v) => setState(() => _pontuacaoInicial = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _construirSecaoTitulo('Check-Point 1'),
            Row(
              children: [
                Expanded(
                  child: _construirBotaoEscolha(
                    valor: 30,
                    grupoAtual: _checkPoint1,
                    titulo: '1ª TENTATIVA\n+30 PONTOS',
                    isFalha: false,
                    onSelect: (v) => setState(() => _checkPoint1 = v),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _construirBotaoEscolha(
                    valor: 20,
                    grupoAtual: _checkPoint1,
                    titulo: '2ª TENTATIVA\n+20 PONTOS',
                    isFalha: false,
                    onSelect: (v) => setState(() => _checkPoint1 = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _construirBotaoEscolha(
                    valor: 10,
                    grupoAtual: _checkPoint1,
                    titulo: '3ª TENTATIVA\n+10 PONTOS',
                    isFalha: false,
                    onSelect: (v) => setState(() => _checkPoint1 = v),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _construirBotaoEscolha(
                    valor: 0,
                    grupoAtual: _checkPoint1,
                    titulo: 'NÃO CONCLUIU\n0 PONTOS',
                    isFalha: true,
                    onSelect: (v) => setState(() => _checkPoint1 = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _construirSecaoTitulo('Check-Point 2'),
            Row(
              children: [
                Expanded(
                  child: _construirBotaoEscolha(
                    valor: 40,
                    grupoAtual: _checkPoint2,
                    titulo: '1ª TENTATIVA\n+40 PONTOS',
                    isFalha: false,
                    onSelect: (v) => setState(() => _checkPoint2 = v),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _construirBotaoEscolha(
                    valor: 30,
                    grupoAtual: _checkPoint2,
                    titulo: '2ª TENTATIVA\n+30 PONTOS',
                    isFalha: false,
                    onSelect: (v) => setState(() => _checkPoint2 = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _construirBotaoEscolha(
                    valor: 20,
                    grupoAtual: _checkPoint2,
                    titulo: '3ª TENTATIVA\n+20 PONTOS',
                    isFalha: false,
                    onSelect: (v) => setState(() => _checkPoint2 = v),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _construirBotaoEscolha(
                    valor: 0,
                    grupoAtual: _checkPoint2,
                    titulo: 'NÃO CONCLUIU\n0 PONTOS',
                    isFalha: true,
                    onSelect: (v) => setState(() => _checkPoint2 = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _construirSecaoTitulo('Chegada'),
            Row(
              children: [
                Expanded(
                  child: _construirBotaoEscolha(
                    valor: 50,
                    grupoAtual: _chegada,
                    titulo: 'PAROU 5 SEGUNDOS (+50)',
                    isFalha: false,
                    onSelect: (v) => setState(() => _chegada = v),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _construirBotaoEscolha(
                    valor: 0,
                    grupoAtual: _chegada,
                    titulo: 'NÃO CONCLUIU (0)',
                    isFalha: true,
                    onSelect: (v) => setState(() => _chegada = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _construirSecaoTitulo('Bônus de Tempo'),
            Row(
              children: [
                Expanded(
                  child: _construirBotaoEscolha(
                    valor: 50,
                    grupoAtual: _bonusTempo,
                    titulo: 'ABAIXO DE 1 MIN\n+50 PONTOS',
                    isFalha: false,
                    onSelect: (v) => setState(() => _bonusTempo = v),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _construirBotaoEscolha(
                    valor: 30,
                    grupoAtual: _bonusTempo,
                    titulo: 'ABAIXO DE 2 MIN\n+30 PONTOS',
                    isFalha: false,
                    onSelect: (v) => setState(() => _bonusTempo = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _resetarFormulario,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('VOLTAR / LIMPAR'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _salvarPontuacao,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('SALVAR'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirSecaoTitulo(String titulo) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        titulo,
        style: const TextStyle(
          fontSize: 18,
          color: _JuizColors.textDark,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _construirDisplayTempo() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        'Tempo: ${(_tempoDecorrido.inMilliseconds / 1000).toStringAsFixed(1)} s',
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: _JuizColors.techBlue,
        ),
      ),
    );
  }

  Widget _construirBotaoRound(int round, String texto) {
    bool selecionado = _roundSelecionado == round;
    return ElevatedButton(
      onPressed: () => setState(() => _roundSelecionado = round),
      style: ElevatedButton.styleFrom(
        backgroundColor: selecionado ? _JuizColors.techBlue : _JuizColors.cardBg,
        foregroundColor: selecionado ? Colors.white : _JuizColors.techBlue,
        elevation: 0,
        side: BorderSide(
          color: selecionado ? _JuizColors.techBlue : _JuizColors.divider,
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(
        texto,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _construirBotaoEscolha({
    required int valor,
    required int? grupoAtual,
    required String titulo,
    required bool isFalha,
    required Function(int) onSelect,
  }) {
    bool selecionado = grupoAtual == valor;
    Color corAtiva = isFalha ? const Color(0xFFDC2626) : _JuizColors.techBlue;
    return ElevatedButton(
      onPressed: () => onSelect(valor),
      style: ElevatedButton.styleFrom(
        backgroundColor: selecionado ? corAtiva : _JuizColors.cardBg,
        foregroundColor: selecionado ? Colors.white : corAtiva,
        elevation: 0,
        side: BorderSide(color: selecionado ? corAtiva : _JuizColors.divider),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(
        titulo,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class ResumoScreen extends StatelessWidget {
  final String nomeEquipe;
  final int? equipeId;
  final double tempoFinal;
  final int pontuacaoTotal;
  final Future<void> Function(int, double)? onConfirm;

  const ResumoScreen({
    super.key,
    required this.nomeEquipe,
    this.equipeId,
    required this.tempoFinal,
    required this.pontuacaoTotal,
    this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _JuizColors.background,
      appBar: AppBar(
        title: const Text('Resumo do Round'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: _JuizColors.cardBg,
        foregroundColor: _JuizColors.textDark,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card da Equipe
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: _JuizColors.cardBg,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Equipe',
                      style: TextStyle(
                        fontSize: 14,
                        color: _JuizColors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      nomeEquipe,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: _JuizColors.techBlue,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Cards de Tempo e Pontuação lado a lado
            Row(
              children: [
                Expanded(
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    color: _JuizColors.cardBg,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tempo Registrado',
                            style: TextStyle(
                              fontSize: 13,
                              color: _JuizColors.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${tempoFinal.toStringAsFixed(1)}s',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: _JuizColors.techBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    color: _JuizColors.cardBg,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Pontuação',
                            style: TextStyle(
                              fontSize: 13,
                              color: _JuizColors.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$pontuacaoTotal pts',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF22C55E),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Resumo Detalhado
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: _JuizColors.cardBg,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Resumo Completo',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _JuizColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildResumoRow('Equipe', nomeEquipe),
                    const SizedBox(height: 12),
                    _buildResumoRow(
                      'Tempo',
                      '${tempoFinal.toStringAsFixed(1)} segundos',
                    ),
                    const SizedBox(height: 12),
                    _buildResumoRow(
                      'Pontuação Total',
                      '$pontuacaoTotal pontos',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Botão de Confirmação
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (onConfirm != null && equipeId != null) {
                    await onConfirm!(equipeId!, tempoFinal);
                  } else if (context.mounted) {
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF22C55E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '✓ Confirmar e Enviar',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Botão de Cancelamento
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: const BorderSide(color: _JuizColors.divider, width: 1),
                ),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _JuizColors.textMuted,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF102A43),
          ),
        ),
      ],
    );
  }
}

class TelaoScreen extends StatefulWidget {
  final List<ClassificacaoModel> equipes;
  const TelaoScreen({super.key, required this.equipes});

  @override
  State<TelaoScreen> createState() => _TelaoScreenState();
}

class _TelaoScreenState extends State<TelaoScreen> {
  late final PageController _pageController;
  Timer? _pageTimer;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pageTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      final pages = (widget.equipes.length / 16).ceil().clamp(1, 99);
      _page = (_page + 1) % pages;
      _pageController.animateToPage(
        _page,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _pageTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = (widget.equipes.length / 16).ceil();
    return Scaffold(
      appBar: AppBar(title: const Text('Telão')),
      body: PageView.builder(
        controller: _pageController,
        itemCount: pages,
        itemBuilder: (_, pageIndex) {
          final start = pageIndex * 16;
          final end = (start + 16).clamp(0, widget.equipes.length);
          final slice = widget.equipes.sublist(start, end);
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 2.2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: slice.length,
            itemBuilder: (_, i) {
              final e = slice[i];
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 6,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e.nomeDaEquipe,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Text(
                      '${e.notaTotal} pts',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
