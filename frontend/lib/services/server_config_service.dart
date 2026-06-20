import 'package:shared_preferences/shared_preferences.dart';

class ServerConfigService {
  static const String _keyServerIp = 'server_ip';
  static const String _keyServerPort = 'server_port';
  static const String _defaultIp = 'localhost';
  static const String _defaultPort = '8080';

  static late SharedPreferences _prefs;

  // Inicializa o serviço
  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Obtém o IP do servidor
  static String getServerIp() {
    return _prefs.getString(_keyServerIp) ?? _defaultIp;
  }

  // Obtém a porta do servidor
  static String getServerPort() {
    return _prefs.getString(_keyServerPort) ?? _defaultPort;
  }

  // Obtém a URL base completa
  static String getBaseUrl() {
    final ip = getServerIp();
    final port = getServerPort();
    return 'http://$ip:$port';
  }

  // Salva o IP do servidor
  static Future<bool> setServerIp(String ip) async {
    return await _prefs.setString(_keyServerIp, ip.trim());
  }

  // Salva a porta do servidor
  static Future<bool> setServerPort(String port) async {
    return await _prefs.setString(_keyServerPort, port.trim());
  }

  // Verifica se o servidor está configurado
  static bool isServerConfigured() {
    final ip = _prefs.getString(_keyServerIp);
    return ip != null && ip.isNotEmpty && ip != _defaultIp;
  }

  // Reseta as configurações para o padrão
  static Future<bool> resetConfiguration() async {
    await _prefs.remove(_keyServerIp);
    await _prefs.remove(_keyServerPort);
    return true;
  }
}
