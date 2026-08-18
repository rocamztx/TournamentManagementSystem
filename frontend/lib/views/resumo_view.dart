import 'package:flutter/material.dart';

class _ResumoColors {
  static const Color background = Color(0xFF040D1A);
  static const Color cardBg = Color(0xFF0A1628);
  static const Color divider = Color(0xFF1E3A5F);
  static const Color textDark = Color(0xFFE2E8F0);
  static const Color textMuted = Color(0xFF64748B);
  static const Color techBlue = Color(0xFF2563EB);
  static const Color green = Color(0xFF22C55E);
}

class ResumoScreen extends StatelessWidget {
  final String nomeEquipe;
  final int equipeId;
  final double tempoFinal;
  final int pontuacaoTotal;
  final Function(int, double) onConfirm;

  const ResumoScreen({
    super.key,
    required this.nomeEquipe,
    required this.equipeId,
    required this.tempoFinal,
    required this.pontuacaoTotal,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _ResumoColors.background,
      appBar: AppBar(
        title: const Text('Confirmar Pontuação'),
        centerTitle: true,
        backgroundColor: _ResumoColors.cardBg,
        foregroundColor: _ResumoColors.textDark,
        elevation: 0,
        shape: const Border(bottom: BorderSide(color: _ResumoColors.divider)),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Card(
              elevation: 0,
              color: _ResumoColors.cardBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: _ResumoColors.divider),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      size: 64,
                      color: _ResumoColors.techBlue,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      nomeEquipe,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: _ResumoColors.textDark,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    _buildRow('Tempo Registrado', '${tempoFinal.toStringAsFixed(1)} s'),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Divider(color: _ResumoColors.divider),
                    ),
                    _buildRow('Pontuação Total', '$pontuacaoTotal pts', isHighlight: true),
                    const SizedBox(height: 48),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: const BorderSide(color: _ResumoColors.divider),
                              foregroundColor: _ResumoColors.textMuted,
                            ),
                            child: const Text('VOLTAR', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => onConfirm(equipeId, tempoFinal),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _ResumoColors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('CONFIRMAR', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
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

  Widget _buildRow(String label, String value, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            color: _ResumoColors.textMuted,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isHighlight ? 24 : 20,
            fontWeight: FontWeight.bold,
            color: isHighlight ? _ResumoColors.green : _ResumoColors.textDark,
          ),
        ),
      ],
    );
  }
}