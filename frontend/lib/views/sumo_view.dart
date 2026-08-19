import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import '../config/network_config.dart';
import '../services/api_service.dart';
import '../models/classificacao_model.dart';

// ─────────────────────────────────────────────
//  Sumô - Fase de Grupos + Mata-Mata (32 equipes)
// ─────────────────────────────────────────────

class _SumoColors {
  static const Color background = Color(0xFF040D1A);
  static const Color primaryNavy = Color(0xFFE2E8F0);
  static const Color techBlue = Color(0xFF2563EB);
  static const Color gold = Color(0xFFF59E0B);
  static const Color green = Color(0xFF22C55E);
  static const Color red = Color(0xFFDC2626);
  static const Color textDark = Color(0xFFE2E8F0);
  static const Color textMuted = Color(0xFF64748B);
  static const Color cardBg = Color(0xFF0A1628);
  static const Color border = Color(0xFF1E3A5F);
}

class SumoView extends StatefulWidget {
  const SumoView({super.key});

  @override
  State<SumoView> createState() => _SumoViewState();
}

class _SumoViewState extends State<SumoView> {
  late List<String> _teamNames;
  late List<int?> _equipePontos;
  late List<int?> _r16Results;
  late List<int?> _qfResults;
  late List<int?> _sfResults;
  int? _finalResult;
  int? _terceiroResult;

  bool _isLoading = true;
  String? _errorMsg;
  StompClient? _client;

  @override
  void initState() {
    super.initState();
    _teamNames = List.generate(32, (i) => 'Carregando...');
    _equipePontos = List.filled(32, null);
    _r16Results = List.filled(8, null);
    _qfResults = List.filled(4, null);
    _sfResults = List.filled(2, null);
    _finalResult = null;
    _terceiroResult = null;
    _carregarEquipes();
    _conectarWebSocket();
  }

  @override
  void dispose() {
    _client?.deactivate();
    super.dispose();
  }

  void _conectarWebSocket() {
    _client = StompClient(
      config: StompConfig(
        url: '${NetworkConfig.baseUrl}/ws-torneio',
        useSockJS: true,
        reconnectDelay: const Duration(seconds: 5),
        onConnect: (frame) {
          _client?.subscribe(
            destination: '/topic/bracket/sumo',
            callback: (frame) {
              if (!mounted || frame.body == null) return;
              try {
                final Map<String, dynamic> json = jsonDecode(frame.body!);
                if (json.isEmpty) return;
                setState(() {
                  _equipePontos = List<int?>.from(json['pontos'] ?? List.filled(32, null));
                  _r16Results = List<int?>.from(json['r16'] ?? List.filled(8, null));
                  _qfResults = List<int?>.from(json['qf'] ?? List.filled(4, null));
                  _sfResults = List<int?>.from(json['sf'] ?? List.filled(2, null));
                  _finalResult = json['final'];
                  _terceiroResult = json['terceiro'];
                });
              } catch (_) {}
            },
          );
          _client?.send(destination: '/app/solicitar-bracket/sumo', body: '');
        },
      ),
    );
    _client?.activate();
  }

  void _publishBracketState() {
    if (_client == null || !_client!.connected) return;
    final state = {
      'pontos': _equipePontos,
      'r16': _r16Results,
      'qf': _qfResults,
      'sf': _sfResults,
      'final': _finalResult,
      'terceiro': _terceiroResult,
    };
    _client!.send(
      destination: '/app/update-bracket/sumo',
      body: jsonEncode(state),
    );
  }

  Future<void> _carregarEquipes() async {
    try {
      final api = ApiService();
      final equipes = await api.obterEquipesParaSelecao(modalidade: 'sumo');
      setState(() {
        _isLoading = false;
        for (int i = 0; i < 32; i++) {
          _teamNames[i] = i < equipes.length ? equipes[i].nomeDaEquipe : 'Equipe ${i + 1}';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMsg = e.toString();
        _teamNames = List.generate(32, (i) => 'Equipe ${i + 1}');
      });
    }
  }

  void _setPontos(int teamIndex, int pontos) {
    setState(() {
      _equipePontos[teamIndex] = pontos;
      _r16Results = List.filled(8, null);
      _qfResults = List.filled(4, null);
      _sfResults = List.filled(2, null);
      _finalResult = null;
      _terceiroResult = null;
    });
    _publishBracketState();
  }

  void _zerarPontos(int teamIndex) {
    setState(() {
      _equipePontos[teamIndex] = null;
      _r16Results = List.filled(8, null);
      _qfResults = List.filled(4, null);
      _sfResults = List.filled(2, null);
      _finalResult = null;
      _terceiroResult = null;
    });
    _publishBracketState();
  }

  // Retorna o índice GLOBAL do 1º do grupo (maior pts), ou null
  int? _getGroupRankIdx(int groupIndex, int rank) {
    List<MapEntry<int, int>> entries = [];
    for (int i = 0; i < 4; i++) {
      int idx = groupIndex * 4 + i;
      entries.add(MapEntry(idx, _equipePontos[idx] ?? -1));
    }
    entries.sort((a, b) => b.value.compareTo(a.value));
    // só considera quem tem pontos >= 0 (jogou), null = -1 fica no fim
    if (rank < entries.length && entries[rank].value >= 0) return entries[rank].key;
    return null;
  }

  String? _getGroup1st(int groupIndex) {
    final idx = _getGroupRankIdx(groupIndex, 0);
    return idx != null ? _teamNames[idx] : null;
  }

  String? _getGroup2nd(int groupIndex) {
    final idx = _getGroupRankIdx(groupIndex, 1);
    return idx != null ? _teamNames[idx] : null;
  }

  // R16: 8 partidas — cross-pairing entre grupos adjacentes
  // Partida i: 1º do grupo (i*2) vs 2º do grupo (i*2 + 1)
  // Partida i+4: 2º do grupo (i*2) vs 1º do grupo (i*2 + 1)
  String? _getR16TeamA(int matchIndex) {
    switch (matchIndex) {
      case 0: return _getGroup1st(0); // A1
      case 1: return _getGroup1st(1); // B1
      case 2: return _getGroup1st(2); // C1
      case 3: return _getGroup1st(3); // D1
      case 4: return _getGroup1st(4); // E1
      case 5: return _getGroup1st(5); // F1
      case 6: return _getGroup1st(6); // G1
      case 7: return _getGroup1st(7); // H1
      default: return null;
    }
  }

  String? _getR16TeamB(int matchIndex) {
    switch (matchIndex) {
      case 0: return _getGroup2nd(1); // B2
      case 1: return _getGroup2nd(0); // A2
      case 2: return _getGroup2nd(3); // D2
      case 3: return _getGroup2nd(2); // C2
      case 4: return _getGroup2nd(5); // F2
      case 5: return _getGroup2nd(4); // E2
      case 6: return _getGroup2nd(7); // H2
      case 7: return _getGroup2nd(6); // G2
      default: return null;
    }
  }

  String? _getQfTeamA(int matchIndex) {
    final r16A = matchIndex * 2;
    if (_r16Results[r16A] == null) return null;
    return _r16Results[r16A] == 0 ? _getR16TeamA(r16A) : _getR16TeamB(r16A);
  }

  String? _getQfTeamB(int matchIndex) {
    final r16B = matchIndex * 2 + 1;
    if (_r16Results[r16B] == null) return null;
    return _r16Results[r16B] == 0 ? _getR16TeamA(r16B) : _getR16TeamB(r16B);
  }

  String? _getSfTeamA(int matchIndex) {
    final qfA = matchIndex * 2;
    if (_qfResults[qfA] == null) return null;
    return _qfResults[qfA] == 0 ? _getQfTeamA(qfA) : _getQfTeamB(qfA);
  }

  String? _getSfTeamB(int matchIndex) {
    final qfB = matchIndex * 2 + 1;
    if (_qfResults[qfB] == null) return null;
    return _qfResults[qfB] == 0 ? _getQfTeamA(qfB) : _getQfTeamB(qfB);
  }

  String? _getFinalTeamA() {
    if (_sfResults[0] == null) return null;
    return _sfResults[0] == 0 ? _getSfTeamA(0) : _getSfTeamB(0);
  }

  String? _getFinalTeamB() {
    if (_sfResults[1] == null) return null;
    return _sfResults[1] == 0 ? _getSfTeamA(1) : _getSfTeamB(1);
  }

  String? _getTerceiroTeamA() {
    if (_sfResults[0] == null) return null;
    return _sfResults[0] == 0 ? _getSfTeamB(0) : _getSfTeamA(0);
  }

  String? _getTerceiroTeamB() {
    if (_sfResults[1] == null) return null;
    return _sfResults[1] == 0 ? _getSfTeamB(1) : _getSfTeamA(1);
  }



  void _selectR16Winner(int matchIndex, int team) {
    setState(() {
      _r16Results[matchIndex] = team;
      _qfResults[matchIndex ~/ 2] = null;
      _sfResults[(matchIndex ~/ 2) ~/ 2] = null;
      _finalResult = null;
      _terceiroResult = null;
    });
    _publishBracketState();
  }

  void _selectQfWinner(int matchIndex, int team) {
    setState(() {
      _qfResults[matchIndex] = team;
      final nextIndex = matchIndex ~/ 2;
      _sfResults[nextIndex] = null;
      _finalResult = null;
      _terceiroResult = null;
    });
    _publishBracketState();
  }

  void _selectSfWinner(int matchIndex, int team) {
    setState(() {
      _sfResults[matchIndex] = team;
      _finalResult = null;
      _terceiroResult = null;
    });
    _publishBracketState();
  }

  void _selectFinalWinner(int team) {
    setState(() => _finalResult = team);
    _publishBracketState();
  }

  void _selectTerceiroWinner(int team) {
    setState(() => _terceiroResult = team);
    _publishBracketState();
  }

  void _resetBracket() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F1D32),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Resetar Torneio', style: TextStyle(color: _SumoColors.textDark, fontWeight: FontWeight.bold)),
        content: const Text('Tem certeza que deseja resetar grupos e brackets?', style: TextStyle(color: _SumoColors.textMuted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCELAR', style: TextStyle(color: _SumoColors.textMuted))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _SumoColors.red),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _equipePontos = List.filled(32, null);
                _r16Results = List.filled(8, null);
                _qfResults = List.filled(4, null);
                _sfResults = List.filled(2, null);
                _finalResult = null;
                _terceiroResult = null;
              });
              _publishBracketState();
            },
            child: const Text('RESETAR', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showPontuacaoDialog(int teamIndex, String teamName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F1D32),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(teamName, style: const TextStyle(color: _SumoColors.textDark, fontWeight: FontWeight.bold)),
        content: const Text('A equipe participou desta rodada?', style: TextStyle(color: _SumoColors.textMuted, fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () { Navigator.pop(ctx); _zerarPontos(teamIndex); },
            child: const Text('NÃO (Ausente)', style: TextStyle(color: _SumoColors.red)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _SumoColors.techBlue),
            onPressed: () {
              Navigator.pop(ctx);
              _showSelecionarPontosDialog(teamIndex, teamName);
            },
            child: const Text('SIM — Lançar Pontos', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSelecionarPontosDialog(int teamIndex, String teamName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F1D32),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(teamName, style: const TextStyle(color: _SumoColors.textDark, fontWeight: FontWeight.bold)),
        content: const Text('Selecione a pontuação obtida:', style: TextStyle(color: _SumoColors.textMuted)),
        actions: [
          TextButton(
            onPressed: () { Navigator.pop(ctx); _setPontos(teamIndex, 0); },
            child: const Text('0 Pontos', style: TextStyle(color: _SumoColors.textMuted, fontSize: 16)),
          ),
          TextButton(
            onPressed: () { Navigator.pop(ctx); _setPontos(teamIndex, 1); },
            child: const Text('1 Ponto', style: TextStyle(color: _SumoColors.techBlue, fontSize: 16)),
          ),
          TextButton(
            onPressed: () { Navigator.pop(ctx); _setPontos(teamIndex, 2); },
            child: const Text('2 Pontos', style: TextStyle(color: _SumoColors.techBlue, fontSize: 16)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _SumoColors.gold),
            onPressed: () { Navigator.pop(ctx); _setPontos(teamIndex, 3); },
            child: const Text('3 Pontos', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  List<int> _getGroupSortedIndices(int groupIndex) {
    List<int> indices = [0, 1, 2, 3];
    indices.sort((a, b) {
      int idxA = groupIndex * 4 + a;
      int idxB = groupIndex * 4 + b;
      int ptsA = _equipePontos[idxA] ?? -1;
      int ptsB = _equipePontos[idxB] ?? -1;
      return ptsB.compareTo(ptsA);
    });
    return indices;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _SumoColors.background,
      body: Column(
        children: [
          _buildHeader(),
          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator(color: _SumoColors.techBlue)))
          else
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildGruposSection(),
                    const Divider(color: _SumoColors.border, height: 1, thickness: 1),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: _buildBracket(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _SumoColors.border)),
      ),
      child: Row(
        children: [
          IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_rounded, color: _SumoColors.primaryNavy)),
          const SizedBox(width: 16),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('SUMÔ - FASE DE GRUPOS', style: TextStyle(color: _SumoColors.primaryNavy, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: 1.0)),
              Text('8 GRUPOS • 32 EQUIPES', style: TextStyle(color: _SumoColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 2.0)),
            ],
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: _resetBracket,
            icon: const Icon(Icons.refresh, color: _SumoColors.textMuted, size: 18),
            label: const Text('RESETAR', style: TextStyle(color: _SumoColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildGruposSection() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Fase de Grupos (Selecione 1º e 2º)', style: TextStyle(color: _SumoColors.textDark, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: List.generate(8, (groupIndex) {
              final String groupName = String.fromCharCode(65 + groupIndex);
              return Container(
                width: 260,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: _SumoColors.cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: _SumoColors.border)),
                child: Column(
                  children: [
                    Container(padding: const EdgeInsets.symmetric(vertical: 6), child: Text('GRUPO $groupName', style: const TextStyle(color: _SumoColors.gold, fontWeight: FontWeight.bold, letterSpacing: 1.5))),
                    ..._getGroupSortedIndices(groupIndex).map((localIdx) {
                      final globalIdx = groupIndex * 4 + localIdx;
                      final teamName = _teamNames[globalIdx];
                      final pts = _equipePontos[globalIdx];
                      return _buildGroupTeamRow(teamName, pts, () => _showPontuacaoDialog(globalIdx, teamName));
                    }),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupTeamRow(String name, int? pontos, VoidCallback onTap) {
    final bool jogoAtual = pontos != null;
    Color borderColor = pontos == 3 ? _SumoColors.gold : pontos == 2 ? _SumoColors.green : pontos == 1 ? _SumoColors.techBlue : _SumoColors.border;
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: jogoAtual ? borderColor.withValues(alpha: 0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: jogoAtual ? borderColor.withValues(alpha: 0.3) : Colors.transparent),
        ),
        child: Row(
          children: [
            Expanded(child: Text(name, style: TextStyle(color: jogoAtual ? _SumoColors.textDark : _SumoColors.textMuted, fontSize: 13))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: jogoAtual ? borderColor : _SumoColors.border, borderRadius: BorderRadius.circular(4)),
              child: Text(
                jogoAtual ? '$pontos pts' : '--',
                style: TextStyle(color: jogoAtual ? Colors.white : _SumoColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBracket() {
    return Row(
      children: [
        _buildBracketSide(isLeft: true, matchW: 190, matchH: 74, gapV: 8, colGap: 50),
        const SizedBox(width: 40),
        _buildFinalColumn(190),
        const SizedBox(width: 40),
        _buildBracketSide(isLeft: false, matchW: 190, matchH: 74, gapV: 8, colGap: 50),
      ],
    );
  }

  Widget _buildBracketSide({required bool isLeft, required double matchW, required double matchH, required double gapV, required double colGap}) {
    final r16Offset = isLeft ? 0 : 4;
    final qfOffset = isLeft ? 0 : 2;
    final sfOffset = isLeft ? 0 : 1;

    final r16Col = Column(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(4, (i) => Padding(padding: EdgeInsets.symmetric(vertical: gapV), child: _buildMatchCard(width: matchW, teamA: _getR16TeamA(r16Offset + i) ?? '—', teamB: _getR16TeamB(r16Offset + i) ?? '—', selectedTeam: _r16Results[r16Offset + i], onSelectA: _getR16TeamA(r16Offset + i) != null ? () => _selectR16Winner(r16Offset + i, 0) : null, onSelectB: _getR16TeamB(r16Offset + i) != null ? () => _selectR16Winner(r16Offset + i, 1) : null, phase: 'Oitavas'))));
    final qfCol = Column(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(2, (i) => Padding(padding: EdgeInsets.symmetric(vertical: gapV + (matchH + gapV * 2) / 2), child: _buildMatchCard(width: matchW, teamA: _getQfTeamA(qfOffset + i) ?? '—', teamB: _getQfTeamB(qfOffset + i) ?? '—', selectedTeam: _qfResults[qfOffset + i], onSelectA: _getQfTeamA(qfOffset + i) != null ? () => _selectQfWinner(qfOffset + i, 0) : null, onSelectB: _getQfTeamB(qfOffset + i) != null ? () => _selectQfWinner(qfOffset + i, 1) : null, phase: 'Quartas'))));
    final sfCol = Column(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(1, (i) => Padding(padding: EdgeInsets.symmetric(vertical: gapV + (matchH + gapV * 2) * 1.5 + (matchH + gapV * 2) / 2), child: _buildMatchCard(width: matchW, teamA: _getSfTeamA(sfOffset + i) ?? '—', teamB: _getSfTeamB(sfOffset + i) ?? '—', selectedTeam: _sfResults[sfOffset + i], onSelectA: _getSfTeamA(sfOffset + i) != null ? () => _selectSfWinner(sfOffset + i, 0) : null, onSelectB: _getSfTeamB(sfOffset + i) != null ? () => _selectSfWinner(sfOffset + i, 1) : null, phase: 'Semifinal'))));

    final columns = [r16Col, SizedBox(width: colGap), qfCol, SizedBox(width: colGap), sfCol];
    return Row(children: isLeft ? columns : columns.reversed.toList());
  }

  Widget _buildFinalColumn(double matchW) {
    final finalTeamA = _getFinalTeamA();
    final finalTeamB = _getFinalTeamB();
    final terceiroTeamA = _getTerceiroTeamA();
    final terceiroTeamB = _getTerceiroTeamB();
    String? campeao = _finalResult != null ? (_finalResult == 0 ? finalTeamA : finalTeamB) : null;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (campeao != null) Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)]), borderRadius: BorderRadius.circular(12)), child: Column(children: [const Icon(Icons.emoji_events, color: Colors.white, size: 36), Text(campeao, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))])),
        const SizedBox(height: 24),
        _buildMatchCard(width: matchW + 20, teamA: finalTeamA ?? '—', teamB: finalTeamB ?? '—', selectedTeam: _finalResult, onSelectA: finalTeamA != null ? () => _selectFinalWinner(0) : null, onSelectB: finalTeamB != null ? () => _selectFinalWinner(1) : null, phase: 'Final', isFinal: true),
        const SizedBox(height: 40),
        _buildMatchCard(width: matchW + 20, teamA: terceiroTeamA ?? '—', teamB: terceiroTeamB ?? '—', selectedTeam: _terceiroResult, onSelectA: terceiroTeamA != null ? () => _selectTerceiroWinner(0) : null, onSelectB: terceiroTeamB != null ? () => _selectTerceiroWinner(1) : null, phase: '3º Lugar'),
      ],
    );
  }

  Widget _buildMatchCard({
    required double width,
    required String teamA,
    required String teamB,
    required int? selectedTeam,
    required VoidCallback? onSelectA,
    required VoidCallback? onSelectB,
    required String phase,
    bool isFinal = false,
  }) {
    final isTeamASelected = selectedTeam == 0;
    final isTeamBSelected = selectedTeam == 1;
    final isTeamAEmpty = teamA == '—';
    final isTeamBEmpty = teamB == '—';

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: _SumoColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFinal ? _SumoColors.gold.withValues(alpha: 0.5) : _SumoColors.border,
          width: isFinal ? 2 : 1,
        ),
        boxShadow: isFinal
            ? [
                BoxShadow(
                  color: _SumoColors.gold.withValues(alpha: 0.1),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ]
            : [],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: isFinal
                  ? _SumoColors.gold.withValues(alpha: 0.15)
                  : _SumoColors.border.withValues(alpha: 0.3),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            ),
            alignment: Alignment.center,
            child: Text(
              phase.toUpperCase(),
              style: TextStyle(
                color: isFinal ? _SumoColors.gold : _SumoColors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
          ),
          _buildTeamRow(
            name: teamA,
            isSelected: isTeamASelected,
            isEmpty: isTeamAEmpty,
            onTap: onSelectA,
            isTop: true,
            isFinal: isFinal,
          ),
          Container(
            height: 1,
            color: _SumoColors.border,
          ),
          _buildTeamRow(
            name: teamB,
            isSelected: isTeamBSelected,
            isEmpty: isTeamBEmpty,
            onTap: onSelectB,
            isTop: false,
            isFinal: isFinal,
          ),
        ],
      ),
    );
  }

  Widget _buildTeamRow({
    required String name,
    required bool isSelected,
    required bool isEmpty,
    required VoidCallback? onTap,
    required bool isTop,
    required bool isFinal,
  }) {
    Color bgColor;
    Color textColor;

    if (isSelected) {
      bgColor = isFinal
          ? _SumoColors.techBlue.withValues(alpha: 0.2)
          : _SumoColors.green.withValues(alpha: 0.15);
      textColor = isFinal ? _SumoColors.techBlue : _SumoColors.green;
    } else if (isEmpty) {
      bgColor = Colors.transparent;
      textColor = _SumoColors.textMuted.withValues(alpha: 0.4);
    } else {
      bgColor = Colors.transparent;
      textColor = _SumoColors.textDark;
    }

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.vertical(
        top: isTop ? const Radius.circular(12) : Radius.zero,
        bottom: isTop ? Radius.zero : const Radius.circular(12),
      ),
      child: InkWell(
        onTap: isEmpty ? null : onTap,
        borderRadius: BorderRadius.vertical(
          top: isTop ? const Radius.circular(12) : Radius.zero,
          bottom: isTop ? Radius.zero : const Radius.circular(12),
        ),
        splashColor: _SumoColors.techBlue.withValues(alpha: 0.1),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              if (isSelected)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Icon(
                    Icons.check_circle_rounded,
                    size: 18,
                    color:
                        isFinal ? _SumoColors.techBlue : _SumoColors.green,
                  ),
                ),
              Expanded(
                child: Text(
                  name,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight:
                        isSelected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
