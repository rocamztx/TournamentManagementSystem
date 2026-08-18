import 'package:dio/dio.dart';
import '../config/network_config.dart';
import '../models/classificacao_model.dart';

class ApiService {
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
    ),
  );

  String get _baseUrl => '${NetworkConfig.baseUrl}/api/classificacao';
  String get _equipesUrl => '${NetworkConfig.baseUrl}/api/equipes';

  // Trata erros do Dio com mensagens em português amigáveis
  String _traduzirErro(Object e) {
    if (e is DioException) {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'Tempo esgotado. Verifique se o servidor está ligado e acessível.';
        case DioExceptionType.connectionError:
          return 'Conexão recusada. Verifique o IP (${NetworkConfig.serverIp}:${NetworkConfig.port}) e se o servidor Java está rodando.';
        case DioExceptionType.badResponse:
          return 'Resposta inválida do servidor (código ${e.response?.statusCode}).';
        default:
          return 'Erro de rede: ${e.message ?? "desconhecido"}';
      }
    }
    return e.toString();
  }

  // ==========================================================
  // 1. GET: Classificação geral (com filtro opcional por modalidade)
  // ==========================================================
  Future<List<ClassificacaoModel>> obterClassificacaoGeral({String? modalidade}) async {
    try {
      final params = <String, dynamic>{};
      if (modalidade != null) params['modalidade'] = modalidade;

      final response = await _dio.get(_baseUrl, queryParameters: params.isNotEmpty ? params : null);

      if (response.statusCode == 200) {
        List<dynamic> dados = response.data;
        return dados.map((json) => ClassificacaoModel.fromJson(json)).toList();
      } else {
        throw Exception('Erro ao carregar classificação do servidor.');
      }
    } catch (e) {
      throw Exception(_traduzirErro(e));
    }
  }

  // ==========================================================
  // 2. GET: Lista de equipes (com filtro opcional por modalidade)
  // ==========================================================
  Future<List<ClassificacaoModel>> obterEquipesParaSelecao({String? modalidade}) async {
    try {
      final params = <String, dynamic>{};
      if (modalidade != null) params['modalidade'] = modalidade;

      final response = await _dio.get(
        _equipesUrl,
        queryParameters: params.isNotEmpty ? params : null,
      );

      if (response.statusCode == 200) {
        final List<dynamic> dados = response.data;
        return dados.map((json) => ClassificacaoModel.fromJson(json)).toList();
      }

      throw Exception('Erro ao carregar equipes do servidor.');
    } catch (e) {
      // Fallback: tenta classificação geral com modalidade
      try {
        return await obterClassificacaoGeral(modalidade: modalidade);
      } catch (_) {
        throw Exception(_traduzirErro(e));
      }
    }
  }

  // ==========================================================
  // 3. POST: Lança nota no Modo Juiz
  // ==========================================================
  Future<void> lancarNota(
    int equipeId,
    int round,
    int pontos,
    double tempo,
  ) async {
    try {
      final String urlPost = '$_baseUrl/lancar-nota';

      final Map<String, dynamic> cabecalhos = {
        'X-API-KEY': 'OBR2026_ROBOTICA_ELITE',
        'Content-Type': 'application/json',
      };

      final Map<String, dynamic> corpoJson = {
        'equipeId': equipeId,
        'round': round,
        'pontos': pontos,
        'tempo': tempo,
      };

      final response = await _dio.post(
        urlPost,
        data: corpoJson,
        options: Options(headers: cabecalhos),
      );

      if (response.statusCode != 200) {
        throw Exception('Erro no servidor: ${response.data}');
      }
    } catch (e) {
      throw Exception(_traduzirErro(e));
    }
  }

  // ==========================================================
  // 4. DELETE: Zera pontuação de uma equipe
  // ==========================================================
  Future<void> zerarPontuacao(int equipeId) async {
    try {
      final String urlDelete = '$_baseUrl/zerar/$equipeId';

      final Map<String, dynamic> cabecalhos = {
        'X-API-KEY': 'OBR2026_ROBOTICA_ELITE',
      };

      final response = await _dio.delete(
        urlDelete,
        options: Options(headers: cabecalhos),
      );

      if (response.statusCode != 200) {
        throw Exception('Erro ao tentar zerar a equipe.');
      }
    } catch (e) {
      throw Exception(_traduzirErro(e));
    }
  }

  // ==========================================================
  // 5. PUT: Atualiza nome da equipe
  // ==========================================================
  Future<void> atualizarNomeEquipe(int equipeId, String novoNome) async {
    try {
      final String urlPut = '$_baseUrl/editar-equipe/$equipeId';
      final cabecalhos = {
        'X-API-KEY': 'OBR2026_ROBOTICA_ELITE',
        'Content-Type': 'application/json',
      };

      final corpoJson = {'nome': novoNome};

      final response = await _dio.put(
        urlPut,
        data: corpoJson,
        options: Options(headers: cabecalhos),
      );

      if (response.statusCode != 200) {
        throw Exception('Erro ao atualizar nome.');
      }
    } catch (e) {
      throw Exception(_traduzirErro(e));
    }
  }

  // ==========================================================
  // 6. GET: Teste de conexão rápido (ping ao status endpoint)
  // ==========================================================
  Future<bool> testarConexao() async {
    try {
      final response = await _dio.get(
        '${NetworkConfig.baseUrl}/api/classificacao/status',
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
