class NetworkConfig {
  static const String serverIp = String.fromEnvironment(
    'SERVER_IP',
    defaultValue: '192.168.10.50',
  );
  static const String port = String.fromEnvironment(
    'SERVER_PORT',
    defaultValue: '8080',
  );
  static const String baseUrl = 'http://$serverIp:$port';
}
