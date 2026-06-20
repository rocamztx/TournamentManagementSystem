import '../services/server_config_service.dart';

class NetworkConfig {
  /// Obtém o IP do servidor (pode ser configurado dinamicamente)
  static String get serverIp {
    return ServerConfigService.getServerIp();
  }

  /// Obtém a porta do servidor (pode ser configurada dinamicamente)
  static String get port {
    return ServerConfigService.getServerPort();
  }

  /// Obtém a URL base completa
  static String get baseUrl {
    return ServerConfigService.getBaseUrl();
  }

  /// URL completa para a API de classificação
  static String get classificacaoUrl {
    return '$baseUrl/api/classificacao';
  }

  /// Retorna informações da configuração atual (útil para debug)
  static String getConfigInfo() {
    return 'Servidor: ${serverIp}:${port}\nURL: $baseUrl';
  }
}
