// ARQUIVO: lib/config/network_config.dart
class NetworkConfig {
  // Troque pelo IP IPv4 do PC que vai rodar o Java (o Servidor)
  static const String serverIp = '192.168.10.50'; 
  static const String port = '8080';
  static const String baseUrl = 'http://$serverIp:$port';
}