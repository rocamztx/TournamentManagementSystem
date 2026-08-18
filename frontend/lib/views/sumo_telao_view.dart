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

class SumoTelaoView extends StatefulWidget {
  const SumoTelaoView({super.key});

  @override
  State<SumoTelaoView> createState() => _SumoTelaoViewState();
}

class _SumoTelaoViewState extends State<SumoTelaoView> {
  late List<String> _teamNames;
  late List<int> _equipePontos;
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
    _equipePontos = List.filled(32, 0);
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
                  _equipePontos = List<int>.from(json['pontos'] ?? List.filled(32, 0));
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



  String? _getGroupWinner(int groupIndex) {
    int maxPts = 0;
    int? winnerIdx;
    for (int i = 0; i < 4; i++) {
      int idx = groupIndex * 4 + i;
      if (_equipePontos[idx] > maxPts) {
        maxPts = _equipePontos[idx];
        winnerIdx = idx;
      }
    }
    return winnerIdx != null ? _teamNames[winnerIdx] : null;
  }

  String? _getQfTeamA(int matchIndex) {
    switch(matchIndex) {
      case 0: return _getGroupWinner(0); // A
      case 1: return _getGroupWinner(2); // C
      case 2: return _getGroupWinner(4); // E
      case 3: return _getGroupWinner(6); // G
      default: return null;
    }
  }

  String? _getQfTeamB(int matchIndex) {
    switch(matchIndex) {
      case 0: return _getGroupWinner(1); // B
      case 1: return _getGroupWinner(3); // D
      case 2: return _getGroupWinner(5); // F
      case 3: return _getGroupWinner(7); // H
      default: return null;
    }
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



  List<int> _getGroupSortedIndices(int groupIndex) {
    List<int> indices = [0, 1, 2, 3];
    indices.sort((a, b) {
      int idxA = groupIndex * 4 + a;
      int idxB = groupIndex * 4 + b;
      return _equipePontos[idxB].compareTo(_equipePontos[idxA]);
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
              Text('TELÃO DE ACOMPANHAMENTO', style: TextStyle(color: _SumoColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 2.0)),
            ],
          ),
          const Spacer(),
          const SizedBox(),
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
                      return _buildGroupTeamRow(teamName, pts, null);
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

  Widget _buildGroupTeamRow(String name, int pontos, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(color: Colors.transparent, borderRadius: BorderRadius.circular(6)),
        child: Row(
          children: [
            Expanded(child: Text(name, style: const TextStyle(color: _SumoColors.textDark, fontSize: 13))),
            Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: _SumoColors.border, borderRadius: BorderRadius.circular(4)), child: Text('${pontos} pts', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
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
    final qfOffset = isLeft ? 0 : 2;
    final sfOffset = isLeft ? 0 : 1;

    final qfCol = Column(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(2, (i) => Padding(padding: EdgeInsets.symmetric(vertical: gapV), child: _buildMatchCard(width: matchW, teamA: _getQfTeamA(qfOffset + i) ?? '—', teamB: _getQfTeamB(qfOffset + i) ?? '—', selectedTeam: _qfResults[qfOffset + i], onSelectA: null, onSelectB: null, phase: 'Quartas'))));
    final sfCol = Column(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(1, (i) => Padding(padding: EdgeInsets.symmetric(vertical: gapV + (matchH + gapV * 2) / 2), child: _buildMatchCard(width: matchW, teamA: _getSfTeamA(sfOffset + i) ?? '—', teamB: _getSfTeamB(sfOffset + i) ?? '—', selectedTeam: _sfResults[sfOffset + i], onSelectA: null, onSelectB: null, phase: 'Semifinal'))));

    final columns = [qfCol, SizedBox(width: colGap), sfCol];
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
        _buildMatchCard(width: matchW + 20, teamA: finalTeamA ?? '—', teamB: finalTeamB ?? '—', selectedTeam: _finalResult, onSelectA: null, onSelectB: null, phase: 'Final', isFinal: true),
        const SizedBox(height: 40),
        _buildMatchCard(width: matchW + 20, teamA: terceiroTeamA ?? '—', teamB: terceiroTeamB ?? '—', selectedTeam: _terceiroResult, onSelectA: null, onSelectB: null, phase: '3º Lugar'),
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
