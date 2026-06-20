import 'package:dio/dio.dart';
import '../config/network_config.dart';
import '../models/classificacao_model.dart';

class ApiService {
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
    ),
  );

  // URL base do seu servidor Spring Boot
  final String _baseUrl = '${NetworkConfig.baseUrl}/api/classificacao';

  // ==========================================================
  // 1. MÉTODO GET: Busca a lista de classificação para a tabela
  // ==========================================================
  Future<List<ClassificacaoModel>> obterClassificacaoGeral() async {
    try {
      final response = await _dio.get(_baseUrl);

      if (response.statusCode == 200) {
        List<dynamic> dados = response.data;
        return dados.map((json) => ClassificacaoModel.fromJson(json)).toList();
      } else {
        throw Exception('Erro ao carregar classificação do servidor.');
      }
    } catch (e) {
      throw Exception('Falha na conexão com a API Java: $e');
    }
  }

  // ==========================================================
  // 2. MÉTODO POST: Envia a nota do Modo Juiz para o Java
  // ==========================================================
  Future<void> lancarNota(
    int equipeId,
    int round,
    int pontos,
    double tempo,
  ) async {
    try {
      // Endpoint exato onde o Java está escutando o POST
      final String urlPost = '$_baseUrl/lancar-nota';

      // Segurança: Injeta a API Key que configuramos no Back-end
      final Map<String, dynamic> cabecalhos = {
        'X-API-KEY': 'OBR2026_ROBOTICA_ELITE',
        'Content-Type': 'application/json',
      };

      // Empacota as variáveis do Flutter no formato JSON exigido pelo DTO do Java
      final Map<String, dynamic> corpoJson = {
        'equipeId': equipeId,
        'round': round,
        'pontos': pontos,
        'tempo': tempo,
      };

      // Dispara a requisição assíncrona
      final response = await _dio.post(
        urlPost,
        data: corpoJson,
        options: Options(headers: cabecalhos),
      );

      // Se o Java não retornar 200 (OK), lança um erro para a tela vermelha capturar
      if (response.statusCode != 200) {
        throw Exception('Erro no servidor: ${response.data}');
      }
    } catch (e) {
      throw Exception('Falha ao enviar pontuação: $e');
    }
  }

  // ==========================================================
  // 3. MÉTODO DELETE: Zera o histórico de uma equipe no banco
  // ==========================================================
  Future<void> zerarPontuacao(int equipeId) async {
    try {
      final String urlDelete = '$_baseUrl/zerar/$equipeId';

      final Map<String, dynamic> cabecalhos = {
        'X-API-KEY': 'OBR2026_ROBOTICA_ELITE',
      };

      // Dispara o comando HTTP DELETE
      final response = await _dio.delete(
        urlDelete,
        options: Options(headers: cabecalhos),
      );

      if (response.statusCode != 200) {
        throw Exception('Erro ao tentar zerar a equipe.');
      }
    } catch (e) {
      throw Exception('Falha na comunicação: $e');
    }
  }

  // ==========================================================
  // 4. MÉTODO PUT: Atualiza o nome da equipe no banco
  // ==========================================================
  Future<void> atualizarNomeEquipe(int equipeId, String novoNome) async {
    try {
      final String urlPut = '$_baseUrl/editar-equipe/$equipeId';
      final cabecalhos = {'X-API-KEY': 'OBR2026_ROBOTICA_ELITE'};

      final corpoJson = {'nome': novoNome};

      final response = await _dio.put(
        urlPut,
        data: corpoJson,
        options: Options(headers: cabecalhos),
      );

      if (response.statusCode != 200)
        throw Exception('Erro ao atualizar nome.');
    } catch (e) {
      throw Exception('Falha na comunicação: $e');
    }
  }
}
