import 'package:flutter/material.dart';
import '../services/server_config_service.dart';
import '../services/api_service.dart';

// ─── Cores (igual ao resto do app) ───────────────────────────────────────
class _Cores {
  static const Color bg = Color(0xFF040D1A);
  static const Color bgCard = Color(0xFF0A1628);
  static const Color navy = Color(0xFF1A365D);
  static const Color blue = Color(0xFF2563EB);
  static const Color green = Color(0xFF22C55E);
  static const Color red = Color(0xFFDC2626);
  static const Color textPrimary = Color(0xFFE2E8F0);
  static const Color textMuted = Color(0xFF64748B);
  static const Color divider = Color(0xFF1E3A5F);
}

class ServerSettingsView extends StatefulWidget {
  final void Function(BuildContext)? onConfigurationFinished;

  const ServerSettingsView({super.key, this.onConfigurationFinished});

  @override
  State<ServerSettingsView> createState() => _ServerSettingsViewState();
}

class _ServerSettingsViewState extends State<ServerSettingsView>
    with SingleTickerProviderStateMixin {
  late TextEditingController _ipController;
  late TextEditingController _portController;
  bool _isLoading = false;
  bool _isTestando = false;
  String? _statusMsg;
  bool _statusOk = false;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _ipController = TextEditingController(
      text: ServerConfigService.getServerIp() == 'localhost'
          ? ''
          : ServerConfigService.getServerIp(),
    );
    _portController = TextEditingController(
      text: ServerConfigService.getServerPort(),
    );

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.4, end: 1.0).animate(_pulseCtrl);
  }

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _testarEConfigurar() async {
    final ip = _ipController.text.trim();
    final port = _portController.text.trim();

    if (ip.isEmpty) {
      _setStatus('Digite o IP do servidor.', false);
      return;
    }
    if (int.tryParse(port) == null) {
      _setStatus('Porta inválida. Use apenas números.', false);
      return;
    }

    setState(() {
      _isTestando = true;
      _statusMsg = 'Testando conexão com $ip:$port...';
      _statusOk = false;
    });

    // Salva provisoriamente para o ApiService usar
    await ServerConfigService.setServerIp(ip);
    await ServerConfigService.setServerPort(port);

    final api = ApiService();
    final ok = await api.testarConexao();

    if (!mounted) return;

    if (ok) {
      _setStatus('✅ Conexão bem-sucedida! Servidor online.', true);
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      _finalizarConfiguracao();
    } else {
      _setStatus(
        '❌ Não foi possível conectar em $ip:$port\n'
        '• Verifique se o servidor Java está rodando\n'
        '• Verifique se o celular e o PC estão na mesma rede Wi-Fi\n'
        '• Confirme o IP do servidor com o arquivo ver-ip-do-servidor.bat',
        false,
      );
      setState(() => _isTestando = false);
    }
  }

  Future<void> _salvarSemTestar() async {
    final ip = _ipController.text.trim();
    final port = _portController.text.trim();

    if (ip.isEmpty) {
      _setStatus('Digite o IP do servidor.', false);
      return;
    }
    if (int.tryParse(port) == null) {
      _setStatus('Porta inválida.', false);
      return;
    }

    setState(() => _isLoading = true);
    await ServerConfigService.setServerIp(ip);
    await ServerConfigService.setServerPort(port);
    if (!mounted) return;
    _finalizarConfiguracao();
  }

  void _finalizarConfiguracao() {
    final cb = widget.onConfigurationFinished;
    if (cb != null) {
      cb(context);
    } else if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop(true);
    }
  }

  void _setStatus(String msg, bool ok) {
    if (!mounted) return;
    setState(() {
      _statusMsg = msg;
      _statusOk = ok;
      _isTestando = false;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Cores.bg,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF040D1A), Color(0xFF071527), Color(0xFF040D1A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ── Ícone pulsante ──────────────────────────────────
                    AnimatedBuilder(
                      animation: _pulseAnim,
                      builder: (_, __) => Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _Cores.blue.withValues(alpha: _pulseAnim.value * 0.5),
                              blurRadius: 28,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.router, color: Colors.white, size: 44),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── Título ──────────────────────────────────────────
                    const Text(
                      'CONFIGURAR SERVIDOR',
                      style: TextStyle(
                        color: _Cores.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Digite o IP do PC onde o servidor Java está rodando',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _Cores.textMuted,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 36),

                    // ── Card de formulário ──────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: _Cores.bgCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _Cores.divider),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('IP do Servidor', Icons.computer_rounded),
                          const SizedBox(height: 8),
                          _buildTextField(
                            controller: _ipController,
                            hint: 'Ex: 192.168.1.100',
                            keyboard: TextInputType.text,
                          ),
                          const SizedBox(height: 20),
                          _buildLabel('Porta', Icons.numbers_rounded),
                          const SizedBox(height: 8),
                          _buildTextField(
                            controller: _portController,
                            hint: '8080',
                            keyboard: TextInputType.number,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Status ──────────────────────────────────────────
                    if (_statusMsg != null) ...[
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: (_statusOk ? _Cores.green : _Cores.red)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: (_statusOk ? _Cores.green : _Cores.red)
                                .withValues(alpha: 0.35),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              _statusOk
                                  ? Icons.check_circle_outline
                                  : Icons.error_outline,
                              color: _statusOk ? _Cores.green : _Cores.red,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _statusMsg!,
                                style: TextStyle(
                                  color: _statusOk ? _Cores.green : const Color(0xFFFF8080),
                                  fontSize: 13,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // ── Botão principal: Testar e Entrar ────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: (_isLoading || _isTestando)
                            ? null
                            : _testarEConfigurar,
                        icon: _isTestando
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.wifi_find_rounded),
                        label: Text(
                          _isTestando ? 'Testando...' : 'TESTAR E ENTRAR',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            letterSpacing: 1.0,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _Cores.blue,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: _Cores.blue.withValues(alpha: 0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ── Botão secundário: Salvar sem testar ─────────────
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton(
                        onPressed: (_isLoading || _isTestando)
                            ? null
                            : _salvarSemTestar,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _Cores.textMuted,
                          side: BorderSide(color: _Cores.divider),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'SALVAR SEM TESTAR',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.0,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // ── Dicas ────────────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _Cores.navy.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _Cores.divider),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.info_outline,
                                  color: _Cores.textMuted, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                'DICAS',
                                style: TextStyle(
                                  color: _Cores.textMuted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildDica(
                              '• Use o IP local do PC servidor (ex: 192.168.1.100)'),
                          _buildDica(
                              '• Celular e PC devem estar na mesma rede Wi-Fi'),
                          _buildDica(
                              '• Execute ver-ip-do-servidor.bat para descobrir o IP'),
                          _buildDica('• Porta padrão: 8080'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String texto, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: _Cores.textMuted, size: 16),
        const SizedBox(width: 8),
        Text(
          texto,
          style: const TextStyle(
            color: _Cores.textMuted,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required TextInputType keyboard,
  }) {
    return TextField(
      controller: controller,
      enabled: !_isLoading && !_isTestando,
      keyboardType: keyboard,
      style: const TextStyle(
        color: _Cores.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: _Cores.textMuted.withValues(alpha: 0.6)),
        filled: true,
        fillColor: const Color(0xFF040D1A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _Cores.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _Cores.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _Cores.blue, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildDica(String texto) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        texto,
        style: TextStyle(
          color: _Cores.textMuted.withValues(alpha: 0.8),
          fontSize: 12,
          height: 1.5,
        ),
      ),
    );
  }
}
