import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import '../config/network_config.dart';
import '../models/classificacao_model.dart';
import '../services/api_service.dart';

// ─────────────────────────────────────────────
//  Paleta de cores do Telão
// ─────────────────────────────────────────────
class _TelaoColors {
  static const Color bg = Color(0xFF040D1A);
  static const Color bgCard = Color(0xFF0A1628);
  static const Color navy = Color(0xFF1A365D);
  static const Color blue = Color(0xFF2563EB);

  static const Color gold = Color(0xFFF59E0B);
  static const Color silver = Color(0xFF94A3B8);
  static const Color bronze = Color(0xFFB45309);
  static const Color goldBg = Color(0xFF1A1500);
  static const Color silverBg = Color(0xFF0D1117);
  static const Color bronzeBg = Color(0xFF1A0E00);
  static const Color textPrimary = Color(0xFFE2E8F0);
  static const Color textMuted = Color(0xFF64748B);
  static const Color green = Color(0xFF22C55E);

  static const Color divider = Color(0xFF1E3A5F);
}

const int _equipePorPagina = 16;
const int _intervaloPaginaSegundos = 15;

class TelaoView extends StatefulWidget {
  const TelaoView({super.key});

  @override
  State<TelaoView> createState() => _TelaoViewState();
}

class _TelaoViewState extends State<TelaoView> with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  StompClient? _client;
  List<ClassificacaoModel> _dados = [];
  bool _conectado = false;
  bool _novosDados = false;

  int _paginaAtual = 0;
  Timer? _timerPagina;
  Timer? _timerNovosDados;
  Timer? _timerPolling;
  double _progressoPagina = 0.0;
  Timer? _timerProgresso;
  bool _pausado = false;

  // Animação de transição de página
  late AnimationController _paginaCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // Animação do ponto de status (pulsante)
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  // Animação do flash de novos dados
  late AnimationController _flashCtrl;
  late Animation<double> _flashAnim;

  @override
  void initState() {
    super.initState();

    // Animação de troca de página (fade + slide de baixo para cima)
    _paginaCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _paginaCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _paginaCtrl, curve: Curves.easeOut));

    // Animação pulsante do indicador de status
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.4, end: 1.0).animate(_pulseCtrl);

    // Animação de flash ao receber novos dados
    _flashCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _flashAnim = CurvedAnimation(parent: _flashCtrl, curve: Curves.easeOut);

    _carregarDadosRest();
    _conectar();
    _iniciarTimerPagina();

    // Polling REST a cada 10s como garantia/fallback
    _timerPolling = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) _carregarDadosRest();
    });
  }

  String? _erroCarregamento;

  Future<void> _carregarDadosRest() async {
    try {
      final lista = await _apiService.obterClassificacaoGeral(modalidade: 'seguidor_linha');
      if (!mounted) return;
      setState(() {
        _dados = lista;
        _erroCarregamento = null;
      });
      final totalPaginas = _totalPaginas;
      if (totalPaginas > 0 && _paginaAtual >= totalPaginas) {
        setState(() => _paginaAtual = 0);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erroCarregamento = e.toString();
      });
      debugPrint('Erro ao carregar classificacao via REST: $e');
    }
  }

  @override
  void dispose() {
    _client?.deactivate();
    _timerPagina?.cancel();
    _timerProgresso?.cancel();
    _timerNovosDados?.cancel();
    _timerPolling?.cancel();
    _paginaCtrl.dispose();
    _pulseCtrl.dispose();
    _flashCtrl.dispose();
    super.dispose();
  }

  // ─── WebSocket ───────────────────────────────
  void _conectar() {
    _client = StompClient(
      config: StompConfig(
        url: '${NetworkConfig.baseUrl}/ws-torneio',
        useSockJS: true,
        reconnectDelay: const Duration(seconds: 5),
        onConnect: (frame) {
          if (!mounted) return;
          setState(() => _conectado = true);

          _client?.subscribe(
            destination: '/topic/classificacao/seguidor_linha',
            callback: (frame) {
              if (!mounted || frame.body == null) return;
              final List<dynamic> json = jsonDecode(frame.body!);
              final lista =
                  json.map((j) => ClassificacaoModel.fromJson(j)).toList();
              setState(() {
                _dados = lista;
                _novosDados = true;
              });
              _flashCtrl.forward(from: 0);
              _timerNovosDados?.cancel();
              _timerNovosDados = Timer(const Duration(seconds: 4), () {
                if (mounted) setState(() => _novosDados = false);
              });
              // Garante que a página atual é válida após atualizar dados
              final totalPaginas = _totalPaginas;
              if (totalPaginas > 0 && _paginaAtual >= totalPaginas) {
                setState(() => _paginaAtual = 0);
              }
            },
          );

          _client?.send(destination: '/app/solicitar-classificacao/seguidor_linha', body: '');
        },
        onWebSocketError: (_) {
          if (mounted) setState(() => _conectado = false);
        },
        onDisconnect: (_) {
          if (mounted) setState(() => _conectado = false);
        },
      ),
    );
    _client?.activate();
  }

  // ─── Timer de paginação ───────────────────────
  void _iniciarTimerPagina() {
    _progressoPagina = 0.0;

    _timerProgresso?.cancel();
    _timerProgresso = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted || _pausado) return;
      setState(() {
        _progressoPagina +=
            0.1 / _intervaloPaginaSegundos; // incrementa a cada 100ms
        if (_progressoPagina >= 1.0) _progressoPagina = 1.0;
      });
    });

    _timerPagina?.cancel();
    _timerPagina = Timer.periodic(
      const Duration(seconds: _intervaloPaginaSegundos),
      (_) {
        if (!mounted || _pausado) return;
        _avancarPagina();
      },
    );
  }

  void _avancarPagina() {
    final total = _totalPaginas;
    if (total <= 1) return;
    _paginaCtrl.reset();
    setState(() {
      _paginaAtual = (_paginaAtual + 1) % total;
      _progressoPagina = 0.0;
    });
    _paginaCtrl.forward();
  }

  void _voltarPagina() {
    final total = _totalPaginas;
    if (total <= 1) return;
    _paginaCtrl.reset();
    setState(() {
      _paginaAtual = (_paginaAtual - 1 + total) % total;
      _progressoPagina = 0.0;
    });
    _paginaCtrl.forward();
  }

  void _togglePausa() {
    setState(() => _pausado = !_pausado);
  }

  int get _totalPaginas =>
      _dados.isEmpty ? 0 : (_dados.length / _equipePorPagina).ceil();

  List<ClassificacaoModel> get _equipesdaPaginaAtual {
    if (_dados.isEmpty) return [];
    final inicio = _paginaAtual * _equipePorPagina;
    final fim = (inicio + _equipePorPagina).clamp(0, _dados.length);
    return _dados.sublist(inicio, fim);
  }

  // ─── Build ────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      autofocus: true,
      onKeyEvent: (event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.escape) {
            Navigator.pop(context);
          } else if (event.logicalKey == LogicalKeyboardKey.arrowRight ||
              event.logicalKey == LogicalKeyboardKey.space) {
            _avancarPagina();
          } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            _voltarPagina();
          } else if (event.logicalKey == LogicalKeyboardKey.keyP) {
            _togglePausa();
          }
        }
      },
      child: Scaffold(
        backgroundColor: _TelaoColors.bg,
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF040D1A), Color(0xFF071527), Color(0xFF040D1A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              // Grade de pontos decorativa no fundo
              _buildBgPattern(),

              Column(
                children: [
                  _buildHeader(),
                  Expanded(child: _buildCorpo()),
                  _buildFooter(),
                ],
              ),

              // Botão fechar (canto superior direito)
              Positioned(
                top: 16,
                right: 20,
                child: _buildBotaoFechar(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Fundo decorativo ─────────────────────────
  Widget _buildBgPattern() {
    return Opacity(
      opacity: 0.03,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 40,
          childAspectRatio: 1,
        ),
        itemCount: 40 * 25,
        itemBuilder: (context, idx) => Container(
          margin: const EdgeInsets.all(2),
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  // ─── Header ───────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: _TelaoColors.divider,
            width: 1,
          ),
        ),
        gradient: LinearGradient(
          colors: [
            _TelaoColors.navy.withValues(alpha: 0.6),
            _TelaoColors.bg.withValues(alpha: 0.0),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        children: [
          // Logo / Ícone
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: _TelaoColors.blue.withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.emoji_events, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 20),

          // Título
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'TORNEIO ROBÔ SEGUIDOR DE LINHA',
                style: TextStyle(
                  color: _TelaoColors.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'CLASSIFICAÇÃO GERAL — TEMPO REAL',
                style: TextStyle(
                  color: _TelaoColors.blue.withValues(alpha: 0.8),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 3.0,
                ),
              ),
            ],
          ),

          const Spacer(),

          // Badge: novos dados
          AnimatedOpacity(
            opacity: _novosDados ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 400),
            child: FadeTransition(
              opacity: _flashAnim,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: _TelaoColors.green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: _TelaoColors.green.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: _TelaoColors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'ATUALIZADO',
                      style: TextStyle(
                        color: _TelaoColors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Indicador de conexão
          _buildStatusConexao(),
        ],
      ),
    );
  }

  Widget _buildStatusConexao() {
    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (context, child) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: (_conectado ? _TelaoColors.green : Colors.red)
              .withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: (_conectado ? _TelaoColors.green : Colors.red)
                .withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: (_conectado ? _TelaoColors.green : Colors.red)
                    .withValues(alpha: _conectado ? _pulseAnim.value : 1.0),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (_conectado ? _TelaoColors.green : Colors.red)
                        .withValues(alpha: 0.5),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _conectado ? 'AO VIVO' : 'RECONECTANDO...',
              style: TextStyle(
                color: _conectado ? _TelaoColors.green : Colors.red,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Corpo (tabela) ───────────────────────────
  Widget _buildCorpo() {
    if (_dados.isEmpty) {
      return _buildAguardando();
    }

    final equipes = _equipesdaPaginaAtual;
    final half = (equipes.length / 2).ceil();
    final leftCol = equipes.sublist(0, half);
    final rightCol = equipes.length > half ? equipes.sublist(half) : <ClassificacaoModel>[];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
      child: Column(
        children: [
          // Cabeçalhos lado a lado
          Row(
            children: [
              Expanded(child: _buildCabecalhoTabela()),
              if (rightCol.isNotEmpty) ...[
                const SizedBox(width: 40),
                Expanded(child: _buildCabecalhoTabela()),
              ],
            ],
          ),
          const SizedBox(height: 8),

          // Duas colunas de dados
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ListView.separated(
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: leftCol.length,
                        separatorBuilder: (_, x) => const SizedBox(height: 6),
                        itemBuilder: (_, i) {
                          final posicaoGlobal = _paginaAtual * _equipePorPagina + i;
                          return _buildLinhaEquipe(leftCol[i], posicaoGlobal, i);
                        },
                      ),
                    ),
                    if (rightCol.isNotEmpty) ...[
                      const SizedBox(width: 40),
                      Expanded(
                        child: ListView.separated(
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: rightCol.length,
                          separatorBuilder: (_, x) => const SizedBox(height: 6),
                          itemBuilder: (_, i) {
                            final posicaoGlobal = _paginaAtual * _equipePorPagina + half + i;
                            return _buildLinhaEquipe(rightCol[i], posicaoGlobal, i);
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAguardando() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_erroCarregamento != null) ...[
              const Icon(
                Icons.error_outline,
                color: Colors.amber,
                size: 70,
              ),
              const SizedBox(height: 20),
              const Text(
                'FALHA AO CONECTAR COM O SERVIDOR',
                style: TextStyle(
                  color: Colors.amber,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Container(
                  padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                ),
                child: Text(
                  _erroCarregamento!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _TelaoColors.textPrimary,
                    fontSize: 14,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
              Text(
                'URL do Servidor: ${NetworkConfig.baseUrl}',
                style: const TextStyle(
                  color: _TelaoColors.textMuted,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _TelaoColors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                ),
                onPressed: () {
                  setState(() => _erroCarregamento = null);
                  _carregarDadosRest();
                  _conectar();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('TENTAR NOVAMENTE'),
              ),
            ] else ...[
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: _TelaoColors.blue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: _TelaoColors.blue.withValues(alpha: 0.3), width: 2),
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: _TelaoColors.blue,
                    strokeWidth: 3,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'AGUARDANDO DADOS DO SERVIDOR...',
                style: TextStyle(
                  color: _TelaoColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Servidor: ${NetworkConfig.baseUrl}',
                style: const TextStyle(
                  color: _TelaoColors.textMuted,
                  fontSize: 14,
                  letterSpacing: 1,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCabecalhoTabela() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _TelaoColors.navy,
            _TelaoColors.navy.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _TelaoColors.divider),
      ),
      child: Row(
        children: [
          _cellCabecalho('#', 70, TextAlign.center),
          _cellCabecalho('EQUIPE', null, TextAlign.left, flex: true),
          _cellCabecalho('ROUND 1', 110, TextAlign.center),
          _cellCabecalho('ROUND 2', 110, TextAlign.center),
          _cellCabecalho('ROUND 3', 110, TextAlign.center),
          _cellCabecalho('TOTAL', 130, TextAlign.center),
        ],
      ),
    );
  }

  Widget _cellCabecalho(
    String texto,
    double? width,
    TextAlign align, {
    bool flex = false,
  }) {
    final child = Text(
      texto,
      textAlign: align,
      style: const TextStyle(
        color: _TelaoColors.silver,
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 2.0,
      ),
    );
    if (flex) {
      return Expanded(child: child);
    }
    return SizedBox(width: width, child: child);
  }

  Widget _buildLinhaEquipe(
    ClassificacaoModel equipe,
    int posicaoGlobal,
    int indexLocal,
  ) {
    final rank = posicaoGlobal + 1;

    Color bgColor;
    Color rankColor;
    Color? glowColor;

    if (rank == 1) {
      bgColor = _TelaoColors.goldBg;
      rankColor = _TelaoColors.gold;
      glowColor = _TelaoColors.gold;
    } else if (rank == 2) {
      bgColor = _TelaoColors.silverBg;
      rankColor = _TelaoColors.silver;
      glowColor = _TelaoColors.silver;
    } else if (rank == 3) {
      bgColor = _TelaoColors.bronzeBg;
      rankColor = _TelaoColors.bronze;
      glowColor = _TelaoColors.bronze;
    } else {
      bgColor = _TelaoColors.bgCard;
      rankColor = _TelaoColors.textMuted;
      glowColor = null;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      height: 72,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: glowColor?.withValues(alpha: 0.25) ?? _TelaoColors.divider,
          width: rank <= 3 ? 1.5 : 1,
        ),
        boxShadow: glowColor != null
            ? [
                BoxShadow(
                  color: glowColor.withValues(alpha: 0.08),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // Posição + medalha
          SizedBox(
            width: 70,
            child: Center(child: _buildInsigniaRank(rank, rankColor)),
          ),

          // Nome da equipe
          Expanded(
            child: Row(
              children: [
                if (rank <= 3) ...[
                  Icon(
                    Icons.military_tech,
                    color: rankColor,
                    size: 28,
                  ),
                  const SizedBox(width: 10),
                ],
                Flexible(
                  child: Text(
                    equipe.nomeDaEquipe,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: rank <= 3
                          ? Colors.white
                          : _TelaoColors.textPrimary,
                      fontSize: rank <= 3 ? 22 : 20,
                      fontWeight: rank <= 3
                          ? FontWeight.w800
                          : FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Round 1
          SizedBox(
            width: 110,
            child: Center(child: _buildPilulaRound(equipe.notaRound1)),
          ),
          // Round 2
          SizedBox(
            width: 110,
            child: Center(child: _buildPilulaRound(equipe.notaRound2)),
          ),
          // Round 3
          SizedBox(
            width: 110,
            child: Center(child: _buildPilulaRound(equipe.notaRound3)),
          ),
          // Total
          SizedBox(
            width: 130,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: _TelaoColors.blue.withValues(alpha: 0.35),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Text(
                  '${equipe.notaTotal}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsigniaRank(int rank, Color cor) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.12),
        shape: BoxShape.circle,
        border: Border.all(color: cor.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Center(
        child: Text(
          '$rank',
          style: TextStyle(
            color: cor,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget _buildPilulaRound(int nota) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _TelaoColors.divider),
      ),
      child: Text(
        '$nota',
        style: const TextStyle(
          color: _TelaoColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // ─── Footer ───────────────────────────────────
  Widget _buildFooter() {
    final total = _totalPaginas;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: _TelaoColors.divider),
        ),
      ),
      child: Row(
        children: [
          // Botão voltar página
          _buildBotaoNavegacao(Icons.chevron_left, _voltarPagina),
          const SizedBox(width: 16),

          // Indicadores de página (bolinhas)
          if (total > 0)
            Row(
              children: List.generate(total, (i) {
                final ativo = i == _paginaAtual;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: ativo ? 28 : 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: ativo
                        ? _TelaoColors.blue
                        : _TelaoColors.divider,
                    borderRadius: BorderRadius.circular(5),
                  ),
                );
              }),
            ),
          const SizedBox(width: 16),

          // Botão avançar página
          _buildBotaoNavegacao(Icons.chevron_right, _avancarPagina),

          const Spacer(),

          // Texto de paginação
          Text(
            total > 0
                ? 'Página ${_paginaAtual + 1} de $total  •  ${_dados.length} equipes'
                : '—',
            style: const TextStyle(
              color: _TelaoColors.textMuted,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 24),

          // Barra de progresso + pausa
          GestureDetector(
            onTap: _togglePausa,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    Icon(
                      _pausado ? Icons.play_arrow : Icons.pause,
                      color: _TelaoColors.textMuted,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _pausado
                          ? 'PAUSADO'
                          : '${_intervaloPaginaSegundos}s AUTO',
                      style: const TextStyle(
                        color: _TelaoColors.textMuted,
                        fontSize: 12,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: 160,
                  height: 4,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: _pausado ? _progressoPagina : _progressoPagina,
                      backgroundColor: _TelaoColors.divider,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _pausado
                            ? _TelaoColors.textMuted
                            : _TelaoColors.blue,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBotaoNavegacao(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: _TelaoColors.navy.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _TelaoColors.divider),
        ),
        child: Icon(icon, color: _TelaoColors.textMuted, size: 22),
      ),
    );
  }

  Widget _buildBotaoFechar() {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.close, color: _TelaoColors.textMuted, size: 18),
            const SizedBox(width: 6),
            Text(
              'FECHAR  [ESC]',
              style: TextStyle(
                color: _TelaoColors.textMuted,
                fontSize: 12,
                letterSpacing: 1,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
