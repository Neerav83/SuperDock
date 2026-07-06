class ConnectionStatus {
  const ConnectionStatus({
    required this.connected,
    required this.hostname,
    required this.platform,
  });

  factory ConnectionStatus.fromJson(Map<String, dynamic> json) {
    return ConnectionStatus(
      connected: json['connected'] as bool? ?? false,
      hostname: json['hostname'] as String? ?? 'Unknown',
      platform: json['platform'] as String? ?? '',
    );
  }

  final bool connected;
  final String hostname;
  final String platform;
}
