import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/classificacao_model.dart';
import 'classificacao_view.dart'; 

class ModoJuizView extends StatefulWidget {
  // O Walkie-Talkie: Uma função que vem da tela pai para recarregar tudo
  final VoidCallback onAtualizarTabelas;
  
  const ModoJuizView({super.key, required this.onAtualizarTabelas});

  @override
  State<ModoJuizView> createState() => _ModoJuizViewState();
}

class _ModoJuizViewState extends State<ModoJuizView> {
// ... restante do seu código continua normal ...
  final ApiService _apiService = ApiService();

  // ==========================================
  // ESTADO DINÂMICO (PUXADO DO BANCO)
  // ==========================================
  List<ClassificacaoModel> _equipesBanco = [];
  int? _equipeSelecionadaId;
  String _nomeEquipeSelecionada = "Carregando...";
  bool _carregandoEquipes = true;

  int _roundSelecionado = 1;
  double _tempoTotal = 0.0;

  int? _pontuacaoInicial;
  int? _checkPoint1;
  int? _checkPoint2;
  int? _checkPoint3;
  int? _chegada;
  int? _bonusTempo;

  @override
  void initState() {
    super.initState();
    // Assim que a tela nasce, buscamos as equipes reais do servidor
    _carregarEquipes();
  }

  /// Conecta no Java, pega os dados e popula o Dropdown
  Future<void> _carregarEquipes() async {
    try {
      final lista = await _apiService.obterClassificacaoGeral();
      setState(() {
        _equipesBanco = lista;
        if (_equipesBanco.isNotEmpty) {
          _equipeSelecionadaId = _equipesBanco.first.id;
          _nomeEquipeSelecionada = _equipesBanco.first.nomeDaEquipe;
        }
        _carregandoEquipes = false;
      });
    } catch (e) {
      setState(() => _carregandoEquipes = false);
    }
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
    setState(() {
      _pontuacaoInicial = null;
      _checkPoint1 = null;
      _checkPoint2 = null;
      _checkPoint3 = null;
      _chegada = null;
      _bonusTempo = null;
      _tempoTotal = 0.0;
    });
  }

  Future<void> _salvarPontuacao() async {
    if (_equipeSelecionadaId == null || _equipeSelecionadaId == 0) return;

    try {
      await _apiService.lancarNota(
        _equipeSelecionadaId!,
        _roundSelecionado,
        _pontuacaoCalculada,
        _tempoTotal,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Pontuação salva! Atualizando painel...'), backgroundColor: Colors.green),
        );
        widget.onAtualizarTabelas();
      }
      _resetarFormulario();

      // O COMANDO DE ELITE (Auto-Refresh):
      // Obriga a tela a bater na API de novo imediatamente para puxar a nota atualizada
      await _carregarEquipes(); 

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// Nova Função: Confirma com o juiz antes de zerar e aciona a API
  Future<void> _confirmarEZerarPontuacao() async {
    if (_equipeSelecionadaId == null) return;

    // Diálogo de confirmação para evitar toques acidentais
    bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Zerar Pontuação?', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: Text('Isso vai apagar TODO o histórico de notas da $_nomeEquipeSelecionada. Deseja continuar?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCELAR')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('SIM, ZERAR EQUIPE'),
          ),
        ],
      ),
    );

    // Se o juiz clicou em SIM, dispara o Delete
    if (confirmar == true) {
      try {
        // ApiService may not declare zerarPontuacao in its interface depending on implementation.
        // Use a dynamic invocation to avoid static type errors while still attempting the call.
        await (_apiService as dynamic).zerarPontuacao(_equipeSelecionadaId!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('🗑️ Pontuação zerada com sucesso!'), backgroundColor: Colors.orange),
          );
           widget.onAtualizarTabelas();
        }
        // Auto-Refresh para o painel azul voltar a mostrar 0
        await _carregarEquipes();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Erro ao zerar: $e'), backgroundColor: Colors.red));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _construirPainelSuperior(),
          const SizedBox(height: 30),

          _construirSecaoTitulo('Selecione o Round'),
          Row(
            children: [
              Expanded(child: _construirBotaoRound(1, 'ROUND 1')),
              const SizedBox(width: 16),
              Expanded(child: _construirBotaoRound(2, 'ROUND 2')),
              const SizedBox(width: 16),
              Expanded(child: _construirBotaoRound(3, 'ROUND 3')),
            ],
          ),
          const Divider(height: 60, thickness: 1),

          _construirSecaoTitulo('Pontuação Inicial - Round $_roundSelecionado'),
          Row(
            children: [
              Expanded(child: _construirBotaoEscolha(valor: 10, grupoAtual: _pontuacaoInicial, titulo: 'SAÍDA VÁLIDA (+10)', isFalha: false, onSelect: (v) => setState(() => _pontuacaoInicial = v))),
              const SizedBox(width: 16),
              Expanded(child: _construirBotaoEscolha(valor: 0, grupoAtual: _pontuacaoInicial, titulo: 'SAÍDA INVÁLIDA (0)', isFalha: true, onSelect: (v) => setState(() => _pontuacaoInicial = v))),
            ],
          ),
          const Divider(height: 60),

          _construirSecaoTitulo('Check-Point 1'),
          Row(
            children: [
              Expanded(child: _construirBotaoEscolha(valor: 30, grupoAtual: _checkPoint1, titulo: '1ª TENTATIVA\n+30 PONTOS', isFalha: false, onSelect: (v) => setState(() => _checkPoint1 = v))),
              const SizedBox(width: 16),
              Expanded(child: _construirBotaoEscolha(valor: 20, grupoAtual: _checkPoint1, titulo: '2ª TENTATIVA\n+20 PONTOS', isFalha: false, onSelect: (v) => setState(() => _checkPoint1 = v))),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _construirBotaoEscolha(valor: 10, grupoAtual: _checkPoint1, titulo: '3ª TENTATIVA\n+10 PONTOS', isFalha: false, onSelect: (v) => setState(() => _checkPoint1 = v))),
              const SizedBox(width: 16),
              Expanded(child: _construirBotaoEscolha(valor: 0, grupoAtual: _checkPoint1, titulo: 'NÃO CONCLUIU\n0 PONTOS', isFalha: true, onSelect: (v) => setState(() => _checkPoint1 = v))),
            ],
          ),
          const Divider(height: 60),

          _construirSecaoTitulo('Check-Point 2'),
          Row(
            children: [
              Expanded(child: _construirBotaoEscolha(valor: 40, grupoAtual: _checkPoint2, titulo: '1ª TENTATIVA\n+40 PONTOS', isFalha: false, onSelect: (v) => setState(() => _checkPoint2 = v))),
              const SizedBox(width: 16),
              Expanded(child: _construirBotaoEscolha(valor: 30, grupoAtual: _checkPoint2, titulo: '2ª TENTATIVA\n+30 PONTOS', isFalha: false, onSelect: (v) => setState(() => _checkPoint2 = v))),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _construirBotaoEscolha(valor: 20, grupoAtual: _checkPoint2, titulo: '3ª TENTATIVA\n+20 PONTOS', isFalha: false, onSelect: (v) => setState(() => _checkPoint2 = v))),
              const SizedBox(width: 16),
              Expanded(child: _construirBotaoEscolha(valor: 0, grupoAtual: _checkPoint2, titulo: 'NÃO CONCLUIU\n0 PONTOS', isFalha: true, onSelect: (v) => setState(() => _checkPoint2 = v))),
            ],
          ),
          const Divider(height: 60),

          _construirSecaoTitulo('Chegada'),
          Row(
            children: [
              Expanded(child: _construirBotaoEscolha(valor: 50, grupoAtual: _chegada, titulo: 'PAROU 5 SEGUNDOS (+50)', isFalha: false, onSelect: (v) => setState(() => _chegada = v))),
              const SizedBox(width: 16),
              Expanded(child: _construirBotaoEscolha(valor: 0, grupoAtual: _chegada, titulo: 'NÃO CONCLUIU (0)', isFalha: true, onSelect: (v) => setState(() => _chegada = v))),
            ],
          ),
          const Divider(height: 60),

          _construirSecaoTitulo('Bônus de Tempo'),
          TextField(
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Tempo Total (segundos)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onChanged: (value) {
              _tempoTotal = double.tryParse(value) ?? 0.0;
            },
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _construirBotaoEscolha(valor: 50, grupoAtual: _bonusTempo, titulo: 'ABAIXO DE 1 MIN\n+50 PONTOS', isFalha: false, onSelect: (v) => setState(() => _bonusTempo = v))),
              const SizedBox(width: 16),
              Expanded(child: _construirBotaoEscolha(valor: 30, grupoAtual: _bonusTempo, titulo: 'ABAIXO DE 2 MIN\n+30 PONTOS', isFalha: false, onSelect: (v) => setState(() => _bonusTempo = v))),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _construirBotaoEscolha(valor: 10, grupoAtual: _bonusTempo, titulo: 'ABAIXO DE 3 MIN\n+10 PONTOS', isFalha: false, onSelect: (v) => setState(() => _bonusTempo = v))),
              const SizedBox(width: 16),
              Expanded(child: _construirBotaoEscolha(valor: 0, grupoAtual: _bonusTempo, titulo: 'SEM BÔNUS\n0 PONTOS', isFalha: true, onSelect: (v) => setState(() => _bonusTempo = v))),
            ],
          ),
          const Divider(height: 60),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _resetarFormulario,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    side: const BorderSide(color: AppColors.techBlue),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('VOLTAR / LIMPAR', style: TextStyle(color: AppColors.techBlue, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _salvarPontuacao,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.techBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('SALVAR E VER CLASSIFICAÇÃO', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _confirmarEZerarPontuacao,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('ZERAR PONTUAÇÃO DA EQUIPE', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // COMPONENTES VISUAIS (HELPERS) DA TELA DO JUIZ
  // ============================================================================

  Widget _construirSecaoTitulo(String titulo) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(titulo, style: const TextStyle(fontSize: 22, color: AppColors.textDark, fontWeight: FontWeight.w600)),
    );
  }

  Widget _construirPainelSuperior() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Selecione a Equipe', style: TextStyle(fontSize: 18, color: AppColors.textDark, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(8)),
          child: _carregandoEquipes 
            ? const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Carregando banco de dados...', style: TextStyle(color: Colors.grey)),
              )
            : DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  isExpanded: true,
                  value: _equipeSelecionadaId,
                  // Agora usamos os dados mapeados reais e não números inventados!
                  items: _equipesBanco.map((eq) {
                    return DropdownMenuItem<int>(
                      value: eq.id,
                      child: Text(eq.nomeDaEquipe, style: const TextStyle(fontSize: 16)),
                    );
                  }).toList(),
                  onChanged: (novoId) {
                    setState(() {
                      _equipeSelecionadaId = novoId;
                      // Busca o nome correspondente ao ID para atualizar o painel azul
                      _nomeEquipeSelecionada = _equipesBanco.firstWhere((e) => e.id == novoId).nomeDaEquipe;
                    });
                  },
                ),
              ),
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 30),
          decoration: BoxDecoration(color: const Color(0xFF42A5F5), borderRadius: BorderRadius.circular(8)),
          child: Column(
            children: [
              Text(_nomeEquipeSelecionada, style: const TextStyle(fontSize: 28, color: AppColors.textDark, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('$_pontuacaoCalculada pontos (total)', style: const TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.w800)),
            ],
          ),
        )
      ],
    );
  }

  Widget _construirBotaoRound(int round, String texto) {
    bool selecionado = _roundSelecionado == round;
    return ElevatedButton(
      onPressed: () => setState(() => _roundSelecionado = round),
      style: ElevatedButton.styleFrom(
        backgroundColor: selecionado ? AppColors.techBlue : Colors.white,
        foregroundColor: selecionado ? Colors.white : AppColors.techBlue,
        elevation: 0,
        side: BorderSide(color: selecionado ? AppColors.techBlue : Colors.grey.shade300),
        padding: const EdgeInsets.symmetric(vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(texto, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }

  Widget _construirBotaoEscolha({
    required int valor, 
    required int? grupoAtual, 
    required String titulo, 
    required bool isFalha, 
    required Function(int) onSelect
  }) {
    bool selecionado = grupoAtual == valor;
    Color corAtiva = isFalha ? const Color(0xFFDC2626) : AppColors.techBlue;

    return ElevatedButton(
      onPressed: () => onSelect(valor),
      style: ElevatedButton.styleFrom(
        backgroundColor: selecionado ? corAtiva : Colors.white,
        foregroundColor: selecionado ? Colors.white : corAtiva,
        elevation: 0,
        side: BorderSide(color: selecionado ? corAtiva : Colors.grey.shade300),
        padding: const EdgeInsets.symmetric(vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(titulo, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
    );
  }
}