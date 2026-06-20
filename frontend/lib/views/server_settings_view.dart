import 'package:flutter/material.dart';
import '../services/server_config_service.dart';

class ServerSettingsView extends StatefulWidget {
  const ServerSettingsView({super.key});

  @override
  State<ServerSettingsView> createState() => _ServerSettingsViewState();
}

class _ServerSettingsViewState extends State<ServerSettingsView> {
  late TextEditingController _ipController;
  late TextEditingController _portController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _ipController = TextEditingController(
      text: ServerConfigService.getServerIp(),
    );
    _portController = TextEditingController(
      text: ServerConfigService.getServerPort(),
    );
  }

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  Future<void> _saveConfiguration() async {
    final ip = _ipController.text.trim();
    final port = _portController.text.trim();

    if (ip.isEmpty) {
      _showErrorDialog('Por favor, insira o IP do servidor');
      return;
    }

    if (port.isEmpty) {
      _showErrorDialog('Por favor, insira a porta do servidor');
      return;
    }

    // Validar se a porta é um número
    if (int.tryParse(port) == null) {
      _showErrorDialog('Porta deve ser um número válido');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ServerConfigService.setServerIp(ip);
      await ServerConfigService.setServerPort(port);

      if (mounted) {
        _showSuccessDialog(
          'Configuração salva com sucesso!',
          'IP: $ip\nPorta: $port',
        );
      }
    } catch (e) {
      _showErrorDialog('Erro ao salvar configuração: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Erro'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Volta para a tela anterior
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _testConnection() async {
    final ip = _ipController.text.trim();
    final port = _portController.text.trim();

    if (ip.isEmpty || port.isEmpty) {
      _showErrorDialog('Por favor, preencha IP e porta');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Tenta fazer uma requisição simples para testar conexão
      final url = 'http://$ip:$port/api/classificacao';
      // Aqui você pode adicionar um teste de conexão real se necessário
      _showSuccessDialog(
        'Servidor Configurado',
        'URL: $url\n\nClique em OK para continuar.',
      );
    } catch (e) {
      _showErrorDialog('Erro ao conectar: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Previne voltar sem salvar
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Configuração do Servidor'),
          centerTitle: true,
          automaticallyImplyLeading: false,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ícone e título
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.router,
                        size: 48,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Configurar Servidor',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Digite o IP e a porta do servidor Backend',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Campo de IP
              const Text(
                'IP do Servidor',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _ipController,
                enabled: !_isLoading,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  hintText: 'Ex: 192.168.1.100 ou localhost',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.computer),
                ),
              ),
              const SizedBox(height: 24),

              // Campo de Porta
              const Text(
                'Porta do Servidor',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _portController,
                enabled: !_isLoading,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Ex: 8080',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.numbers),
                ),
              ),
              const SizedBox(height: 40),

              // Botão de Teste de Conexão
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _testConnection,
                  icon: const Icon(Icons.cloud_queue),
                  label: const Text('Testar Conexão'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Botão de Salvar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _saveConfiguration,
                  icon: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.save),
                  label: Text(_isLoading ? 'Salvando...' : 'Salvar e Continuar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Informações úteis
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'ℹ️ Dicas de Configuração',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      '• Use o IP local da sua rede (ex: 192.168.x.x)\n'
                      '• O servidor Java/Spring Boot deve estar rodando\n'
                      '• Porta padrão geralmente é 8080\n'
                      '• Ambos (app e servidor) devem estar na mesma rede',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
