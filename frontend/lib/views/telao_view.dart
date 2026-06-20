import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import '../config/network_config.dart';
import '../models/classificacao_model.dart';

class TelaoView extends StatefulWidget {
  const TelaoView({super.key});

  @override
  State<TelaoView> createState() => _TelaoViewState();
}

class _TelaoViewState extends State<TelaoView> {
  StompClient? _client;
  List<ClassificacaoModel> _dados = [];

  @override
  void initState() {
    super.initState();
    _conectar();
  }

  void _conectar() {
    _client = StompClient(
      config: StompConfig(
        url: '${NetworkConfig.baseUrl}/ws-torneio',
        useSockJS: true,
        onConnect: (frame) {
          print('✅ Conexão WebSocket Ativa');
          
          // 1. Inscreve-se para receber atualizações futuras
          _client?.subscribe(
            destination: '/topic/classificacao',
            callback: (frame) {
              if (frame.body != null) {
                final List<dynamic> json = jsonDecode(frame.body!);
                setState(() {
                  _dados = json.map((j) => ClassificacaoModel.fromJson(j)).toList();
                });
                print('⚡ Dados atualizados em tempo real.');
              }
            },
          );

          // 2. SOLICITAÇÃO INICIAL: Pede os dados atuais imediatamente após conectar
          _client?.send(
            destination: '/app/solicitar-classificacao',
            body: '', 
          );
        },
        onWebSocketError: (e) => print('🚨 Erro WS: $e'),
      ),
    );
    _client?.activate();
  }

  @override
  void dispose() {
    _client?.deactivate();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _dados.isEmpty 
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.blueAccent),
                  SizedBox(height: 20),
                  Text("AGUARDANDO DADOS DO SERVIDOR...", style: TextStyle(color: Colors.white, fontSize: 18)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _dados.length,
              itemBuilder: (_, i) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_dados[i].nomeDaEquipe, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                    Text('${_dados[i].notaTotal} PTS', style: const TextStyle(color: Color(0xFF22C55E), fontSize: 32, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
    );
  }
}
