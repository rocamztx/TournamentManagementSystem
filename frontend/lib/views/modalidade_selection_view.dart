import 'package:flutter/material.dart';
import 'modo_juiz_view.dart';
import 'cabo_guerra_view.dart';
import 'sumo_view.dart';
import 'server_settings_view.dart';
import 'telao_view.dart';
import 'cabo_guerra_telao_view.dart';
import 'sumo_telao_view.dart';

class ModalidadeSelectionView extends StatefulWidget {
  const ModalidadeSelectionView({super.key});

  @override
  State<ModalidadeSelectionView> createState() =>
      _ModalidadeSelectionViewState();
}

class _ModalidadeSelectionViewState extends State<ModalidadeSelectionView>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnim;
  late Animation<double> _pulseAnim;
  int? _hoveredIndex;

  static const _bgDark = Color(0xFF040D1A);
  static const _navy = Color(0xFF1A365D);
  static const _blue = Color(0xFF2563EB);
  static const _textPrimary = Color(0xFFE2E8F0);
  static const _textMuted = Color(0xFF64748B);
  static const _divider = Color(0xFF1E3A5F);

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulseAnim =
        Tween<double>(begin: 0.3, end: 0.8).animate(_pulseController);

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDark,
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
            _buildBgPattern(),
            FadeTransition(
              opacity: _fadeAnim,
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(child: _buildCards()),
                  _buildFooter(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: _divider, width: 1),
        ),
        gradient: LinearGradient(
          colors: [
            _navy.withValues(alpha: 0.6),
            _bgDark.withValues(alpha: 0.0),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        children: [
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
                  color: _blue.withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.emoji_events, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'SISTEMA DE TORNEIO',
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'SELECIONE A MODALIDADE',
                style: TextStyle(
                  color: _blue.withValues(alpha: 0.8),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 3.0,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Botão de configurar servidor
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const ServerSettingsView(),
                transitionDuration: const Duration(milliseconds: 300),
                transitionsBuilder:
                    (context, anim, secondaryAnimation, child) =>
                        FadeTransition(
                  opacity:
                      CurvedAnimation(parent: anim, curve: Curves.easeOut),
                  child: child,
                ),
              ),
            ),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                  Icon(Icons.settings_rounded,
                      color: _textMuted, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'SERVIDOR',
                    style: TextStyle(
                      color: _textMuted,
                      fontSize: 12,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w600,
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

  Widget _buildCards() {
    final modalities = [
      _ModalityData(
        title: 'CABO DE GUERRA',
        subtitle: 'Mata-mata com classificatórias',
        description: '32 equipes em bracket estilo Copa do Mundo\nOitavas → Quartas → Semi → Final',
        icon: Icons.link,
        gradient: const [Color(0xFFDC2626), Color(0xFFB91C1C)],
        glowColor: const Color(0xFFDC2626),
        index: 0,
      ),
      _ModalityData(
        title: 'SEGUIDOR DE LINHA',
        subtitle: 'Pontuação e classificação',
        description: 'Sistema de pontuação por rounds\nCheckpoints, tempo e ranking geral',
        icon: Icons.route,
        gradient: const [Color(0xFF2563EB), Color(0xFF1D4ED8)],
        glowColor: const Color(0xFF2563EB),
        index: 1,
      ),
      _ModalityData(
        title: 'SUMÔ',
        subtitle: 'Fase de Grupos',
        description: '8 Grupos com 4 equipes (Classificam 2)\nMata-Mata (Oitavas → Final)',
        icon: Icons.sports_martial_arts,
        gradient: const [Color(0xFFF59E0B), Color(0xFFD97706)],
        glowColor: const Color(0xFFF59E0B),
        index: 2,
      ),
    ];

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
          child: Row(
            children: modalities.map((m) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: _buildModalityCard(m),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildModalityCard(_ModalityData data) {
    final isHovered = _hoveredIndex == data.index;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredIndex = data.index),
      onExit: (_) => setState(() => _hoveredIndex = null),
      child: GestureDetector(
        onTap: () => _navigateToModality(data.index, false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          transform: Matrix4.identity()
            ..setTranslationRaw(0.0, isHovered ? -8.0 : 0.0, 0.0),
          decoration: BoxDecoration(
            color: const Color(0xFF0A1628),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isHovered
                  ? data.glowColor.withValues(alpha: 0.6)
                  : _divider,
              width: isHovered ? 2 : 1,
            ),
            boxShadow: isHovered
                ? [
                    BoxShadow(
                      color: data.glowColor.withValues(alpha: 0.25),
                      blurRadius: 30,
                      spreadRadius: 2,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 12,
                    ),
                  ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon container
              AnimatedBuilder(
                animation: _pulseAnim,
                builder: (context, child) => Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: data.gradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: data.glowColor.withValues(
                          alpha: isHovered ? 0.5 : _pulseAnim.value * 0.2,
                        ),
                        blurRadius: isHovered ? 30 : 20,
                        spreadRadius: isHovered ? 4 : 0,
                      ),
                    ],
                  ),
                  child: Icon(data.icon, color: Colors.white, size: 48),
                ),
              ),
              const SizedBox(height: 28),

              // Title
              Text(
                data.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isHovered ? data.glowColor : _textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 8),

              // Subtitle
              Text(
                data.subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _blue.withValues(alpha: 0.7),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 16),

              // Description
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _divider.withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  data.description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _textMuted,
                    fontSize: 13,
                    height: 1.6,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // CTA Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () => _navigateToModality(data.index, false),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: isHovered
                            ? LinearGradient(colors: data.gradient)
                            : null,
                        color: isHovered ? null : Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: isHovered ? Colors.transparent : _divider,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit_document,
                              color: isHovered ? Colors.white : _textMuted, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'MODO JUIZ',
                            style: TextStyle(
                              color: isHovered ? Colors.white : _textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => _navigateToModality(data.index, true),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: _divider),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.monitor, color: _textMuted, size: 16),
                          const SizedBox(width: 8),
                          const Text(
                            'TELÃO',
                            style: TextStyle(
                              color: _textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToModality(int index, bool isTelao) {
    Widget destination;
    switch (index) {
      case 0:
        destination = isTelao ? const CaboGuerraTelaoView() : const CaboGuerraView();
        break;
      case 1:
        // Seguidor de Linha: se for tela, abre ClassificacaoView (o antigo telão que tem Tabela e Modo Juiz)
        // Opa, TelaoView já existe para Seguidor de Linha. 
        destination = isTelao ? const TelaoView() : ModoJuizView(onAtualizarTabelas: () {});
        break;
      case 2:
        destination = isTelao ? const SumoTelaoView() : const SumoView();
        break;
      default:
        return;
    }

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => destination,
        transitionDuration: const Duration(milliseconds: 400),
        transitionsBuilder: (context, anim, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
            child: child,
          );
        },
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: _divider),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'SISTEMA DE TORNEIO FRC/OBR',
            style: TextStyle(
              color: _textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              color: _textMuted,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'v2.0',
            style: TextStyle(
              color: _textMuted.withValues(alpha: 0.6),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModalityData {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final List<Color> gradient;
  final Color glowColor;
  final int index;

  const _ModalityData({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.gradient,
    required this.glowColor,
    required this.index,
  });
}
