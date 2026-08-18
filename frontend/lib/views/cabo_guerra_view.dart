import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import '../config/network_config.dart';
import '../services/api_service.dart';
import '../models/classificacao_model.dart';

// ─────────────────────────────────────────────
//  Cabo de Guerra - Bracket Mata-Mata (32 equipes)
//  Estilo Copa do Mundo
// ─────────────────────────────────────────────

class _BracketColors {
  static const Color bg = Color(0xFF040D1A);
  static const Color bgCard = Color(0xFF0A1628);
  static const Color navy = Color(0xFF1A365D);
  static const Color blue = Color(0xFF2563EB);
  static const Color red = Color(0xFFDC2626);
  static const Color gold = Color(0xFFF59E0B);
  static const Color green = Color(0xFF22C55E);
  static const Color textPrimary = Color(0xFFE2E8F0);
  static const Color textMuted = Color(0xFF64748B);
  static const Color divider = Color(0xFF1E3A5F);
}

class CaboGuerraView extends StatefulWidget {
  const CaboGuerraView({super.key});

  @override
  State<CaboGuerraView> createState() => _CaboGuerraViewState();
}

class _CaboGuerraViewState extends State<CaboGuerraView> {
  // Nomes das equipes (editáveis)
  late List<String> _teamNames;

  // Resultados por fase: índice do vencedor de cada jogo
  late List<int?> _r32Results;
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
    _r32Results = List.filled(16, null);
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
            destination: '/topic/bracket/cabo_guerra',
            callback: (frame) {
              if (!mounted || frame.body == null) return;
              try {
                final Map<String, dynamic> json = jsonDecode(frame.body!);
                if (json.isEmpty) return;
                setState(() {
                  _r32Results = List<int?>.from(json['r32'] ?? List.filled(16, null));
                  _r16Results = List<int?>.from(json['r16'] ?? List.filled(8, null));
                  _qfResults = List<int?>.from(json['qf'] ?? List.filled(4, null));
                  _sfResults = List<int?>.from(json['sf'] ?? List.filled(2, null));
                  _finalResult = json['final'];
                  _terceiroResult = json['terceiro'];
                });
              } catch (_) {}
            },
          );
          _client?.send(destination: '/app/solicitar-bracket/cabo_guerra', body: '');
        },
      ),
    );
    _client?.activate();
  }

  void _publishBracketState() {
    if (_client == null || !_client!.connected) return;
    final state = {
      'r32': _r32Results,
      'r16': _r16Results,
      'qf': _qfResults,
      'sf': _sfResults,
      'final': _finalResult,
      'terceiro': _terceiroResult,
    };
    _client!.send(
      destination: '/app/update-bracket/cabo_guerra',
      body: jsonEncode(state),
    );
  }

  Future<void> _carregarEquipes() async {
    try {
      final api = ApiService();
      final equipes = await api.obterEquipesParaSelecao(modalidade: 'cabo_guerra');
      
      setState(() {
        _isLoading = false;
        // Pega os nomes ou preenche com "Equipe X" se faltar
        for (int i = 0; i < 32; i++) {
          if (i < equipes.length) {
            _teamNames[i] = equipes[i].nomeDaEquipe;
          } else {
            _teamNames[i] = 'Equipe ${i + 1}';
          }
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMsg = e.toString();
        // Em caso de erro, usa nomes genéricos
        _teamNames = List.generate(32, (i) => 'Equipe ${i + 1}');
      });
    }
  }


  // Helpers para obter equipes em cada fase
  String? _getR32TeamA(int matchIndex) {
    final idx = matchIndex * 2;
    return idx < _teamNames.length ? _teamNames[idx] : null;
  }

  String? _getR32TeamB(int matchIndex) {
    final idx = matchIndex * 2 + 1;
    return idx < _teamNames.length ? _teamNames[idx] : null;
  }

  String? _getR16TeamA(int matchIndex) {
    final r32A = matchIndex * 2;
    if (_r32Results[r32A] == null) return null;
    return _r32Results[r32A] == 0 ? _getR32TeamA(r32A) : _getR32TeamB(r32A);
  }

  String? _getR16TeamB(int matchIndex) {
    final r32B = matchIndex * 2 + 1;
    if (_r32Results[r32B] == null) return null;
    return _r32Results[r32B] == 0 ? _getR32TeamA(r32B) : _getR32TeamB(r32B);
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

  void _selectR32Winner(int matchIndex, int team) {
    setState(() {
      _r32Results[matchIndex] = team;
      final nextIndex = matchIndex ~/ 2;
      _r16Results[nextIndex] = null;
      _qfResults[nextIndex ~/ 2] = null;
      _sfResults[nextIndex ~/ 4] = null;
      _finalResult = null;
      _terceiroResult = null;
    });
    _publishBracketState();
  }

  void _selectR16Winner(int matchIndex, int team) {
    setState(() {
      _r16Results[matchIndex] = team;
      final nextIndex = matchIndex ~/ 2;
      _qfResults[nextIndex] = null;
      _sfResults[nextIndex ~/ 2] = null;
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
        title: const Text(
          'Resetar Bracket',
          style: TextStyle(color: _BracketColors.textPrimary),
        ),
        content: const Text(
          'Tem certeza que deseja resetar todos os resultados?',
          style: TextStyle(color: _BracketColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCELAR',
                style: TextStyle(color: _BracketColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _BracketColors.red,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _r32Results = List.filled(16, null);
                _r16Results = List.filled(8, null);
                _qfResults = List.filled(4, null);
                _sfResults = List.filled(2, null);
                _finalResult = null;
                _terceiroResult = null;
              });
              _publishBracketState();
            },
            child: const Text('RESETAR',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _BracketColors.bg,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF040D1A), Color(0xFF071527), Color(0xFF040D1A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            _buildHeader(),
            if (_isLoading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(color: _BracketColors.red),
                ),
              )
            else
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: _buildBracket(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: _BracketColors.divider),
        ),
        gradient: LinearGradient(
          colors: [
            _BracketColors.navy.withValues(alpha: 0.6),
            _BracketColors.bg.withValues(alpha: 0.0),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded,
                color: _BracketColors.textPrimary),
            tooltip: 'Voltar',
          ),
          const SizedBox(width: 12),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFDC2626), Color(0xFFB91C1C)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: _BracketColors.red.withValues(alpha: 0.4),
                  blurRadius: 12,
                ),
              ],
            ),
            child: const Icon(Icons.link, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CABO DE GUERRA',
                style: TextStyle(
                  color: _BracketColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                ),
              ),
              Text(
                'BRACKET MATA-MATA • 32 EQUIPES',
                style: TextStyle(
                  color: _BracketColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2.0,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Reset button
          TextButton.icon(
            onPressed: _resetBracket,
            icon: const Icon(Icons.refresh, color: _BracketColors.textMuted, size: 18),
            label: const Text(
              'RESETAR',
              style: TextStyle(
                color: _BracketColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBracket() {
    // Layout: Left bracket (16 equipes) + Centro (Final/3º) + Right bracket (16 equipes)
    const double matchW = 180;
    const double matchH = 70;
    const double gapV = 8;
    const double colGap = 50;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // ── LADO ESQUERDO (Equipes 1-16) ──
        _buildBracketSide(
          isLeft: true,
          startTeamIndex: 0,
          matchW: matchW,
          matchH: matchH,
          gapV: gapV,
          colGap: colGap,
        ),

        // ── CENTRO: FINAL + 3º LUGAR ──
        const SizedBox(width: 30),
        _buildFinalColumn(matchW, matchH),
        const SizedBox(width: 30),

        // ── LADO DIREITO (Equipes 17-32) ──
        _buildBracketSide(
          isLeft: false,
          startTeamIndex: 16,
          matchW: matchW,
          matchH: matchH,
          gapV: gapV,
          colGap: colGap,
        ),
      ],
    );
  }


  Widget _buildBracketSide({
    required bool isLeft,
    required int startTeamIndex,
    required double matchW,
    required double matchH,
    required double gapV,
    required double colGap,
  }) {
    final r32Offset = isLeft ? 0 : 8;
    final r16Offset = isLeft ? 0 : 4;
    final qfOffset = isLeft ? 0 : 2;
    final sfOffset = isLeft ? 0 : 1;

    // R32 (8 jogos no lado)
    final r32Col = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(8, (i) {
        final mi = r32Offset + i;
        final teamA = _getR32TeamA(mi);
        final teamB = _getR32TeamB(mi);
        return Padding(
          padding: EdgeInsets.symmetric(vertical: gapV),
          child: _buildMatchCard(
            width: matchW,
            teamA: teamA ?? '—',
            teamB: teamB ?? '—',
            selectedTeam: _r32Results[mi],
            onSelectA: teamA != null ? () => _selectR32Winner(mi, 0) : null,
            onSelectB: teamB != null ? () => _selectR32Winner(mi, 1) : null,
            phase: 'Round de 32',
          ),
        );
      }),
    );

    // R16 (4 jogos no lado)
    final r16Col = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (i) {
        final mi = r16Offset + i;
        final teamA = _getR16TeamA(mi);
        final teamB = _getR16TeamB(mi);
        return Padding(
          padding: EdgeInsets.symmetric(
              vertical: gapV + (matchH + gapV * 2) / 2),
          child: _buildMatchCard(
            width: matchW,
            teamA: teamA ?? '—',
            teamB: teamB ?? '—',
            selectedTeam: _r16Results[mi],
            onSelectA: teamA != null ? () => _selectR16Winner(mi, 0) : null,
            onSelectB: teamB != null ? () => _selectR16Winner(mi, 1) : null,
            phase: 'Oitavas',
          ),
        );
      }),
    );

    // QF (2 jogos no lado)
    final qfCol = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(2, (i) {
        final mi = qfOffset + i;
        final teamA = _getQfTeamA(mi);
        final teamB = _getQfTeamB(mi);
        return Padding(
          padding: EdgeInsets.symmetric(
              vertical: gapV + (matchH + gapV * 2) * 1.5 + (matchH + gapV * 2) / 2),
          child: _buildMatchCard(
            width: matchW,
            teamA: teamA ?? '—',
            teamB: teamB ?? '—',
            selectedTeam: _qfResults[mi],
            onSelectA: teamA != null ? () => _selectQfWinner(mi, 0) : null,
            onSelectB: teamB != null ? () => _selectQfWinner(mi, 1) : null,
            phase: 'Quartas',
          ),
        );
      }),
    );

    // SF (1 jogo no lado)
    final sfCol = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(1, (i) {
        final mi = sfOffset + i;
        final teamA = _getSfTeamA(mi);
        final teamB = _getSfTeamB(mi);
        return Padding(
          padding: EdgeInsets.symmetric(
              vertical: gapV + (matchH + gapV * 2) * 3.5 + (matchH + gapV * 2) / 2),
          child: _buildMatchCard(
            width: matchW,
            teamA: teamA ?? '—',
            teamB: teamB ?? '—',
            selectedTeam: _sfResults[mi],
            onSelectA: teamA != null ? () => _selectSfWinner(mi, 0) : null,
            onSelectB: teamB != null ? () => _selectSfWinner(mi, 1) : null,
            phase: 'Semifinal',
          ),
        );
      }),
    );

    final columns = [
      r32Col,
      SizedBox(width: colGap),
      r16Col,
      SizedBox(width: colGap),
      qfCol,
      SizedBox(width: colGap),
      sfCol,
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: isLeft ? columns : columns.reversed.toList(),
    );
  }


  Widget _buildFinalColumn(double matchW, double matchH) {
    final finalTeamA = _getFinalTeamA();
    final finalTeamB = _getFinalTeamB();
    final terceiroTeamA = _getTerceiroTeamA();
    final terceiroTeamB = _getTerceiroTeamB();

    // Campeão
    String? campeao;
    if (_finalResult != null) {
      campeao = _finalResult == 0 ? finalTeamA : finalTeamB;
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Troféu do campeão
        if (campeao != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: _BracketColors.gold.withValues(alpha: 0.4),
                  blurRadius: 20,
                ),
              ],
            ),
            child: Column(
              children: [
                const Icon(Icons.emoji_events, color: Colors.white, size: 36),
                const SizedBox(height: 4),
                const Text(
                  'CAMPEÃO',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  campeao,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Label FINAL
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'FINAL',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 3,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Final match
        _buildMatchCard(
          width: matchW + 20,
          teamA: finalTeamA ?? '—',
          teamB: finalTeamB ?? '—',
          selectedTeam: _finalResult,
          onSelectA:
              finalTeamA != null ? () => _selectFinalWinner(0) : null,
          onSelectB:
              finalTeamB != null ? () => _selectFinalWinner(1) : null,
          phase: 'Final',
          isFinal: true,
        ),
        const SizedBox(height: 40),

        // Label 3º LUGAR
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: _BracketColors.navy,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _BracketColors.divider),
          ),
          child: const Text(
            '3º LUGAR',
            style: TextStyle(
              color: _BracketColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // 3rd place match
        _buildMatchCard(
          width: matchW + 20,
          teamA: terceiroTeamA ?? '—',
          teamB: terceiroTeamB ?? '—',
          selectedTeam: _terceiroResult,
          onSelectA: terceiroTeamA != null
              ? () => _selectTerceiroWinner(0)
              : null,
          onSelectB: terceiroTeamB != null
              ? () => _selectTerceiroWinner(1)
              : null,
          phase: '3º Lugar',
        ),
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
        color: _BracketColors.bgCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isFinal
              ? _BracketColors.gold.withValues(alpha: 0.4)
              : _BracketColors.divider,
          width: isFinal ? 1.5 : 1,
        ),
        boxShadow: isFinal
            ? [
                BoxShadow(
                  color: _BracketColors.gold.withValues(alpha: 0.1),
                  blurRadius: 12,
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Team A
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
            color: _BracketColors.divider.withValues(alpha: 0.5),
          ),
          // Team B
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
          ? _BracketColors.gold.withValues(alpha: 0.2)
          : _BracketColors.green.withValues(alpha: 0.15);
      textColor = isFinal ? _BracketColors.gold : _BracketColors.green;
    } else if (isEmpty) {
      bgColor = Colors.transparent;
      textColor = _BracketColors.textMuted.withValues(alpha: 0.4);
    } else {
      bgColor = Colors.transparent;
      textColor = _BracketColors.textPrimary;
    }

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.vertical(
        top: isTop ? const Radius.circular(10) : Radius.zero,
        bottom: isTop ? Radius.zero : const Radius.circular(10),
      ),
      child: InkWell(
        onTap: isEmpty ? null : onTap,
        borderRadius: BorderRadius.vertical(
          top: isTop ? const Radius.circular(10) : Radius.zero,
          bottom: isTop ? Radius.zero : const Radius.circular(10),
        ),
        splashColor: _BracketColors.blue.withValues(alpha: 0.2),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              if (isSelected)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(
                    Icons.check_circle,
                    size: 16,
                    color: isFinal ? _BracketColors.gold : _BracketColors.green,
                  ),
                ),
              Expanded(
                child: Text(
                  name,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 13,
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
