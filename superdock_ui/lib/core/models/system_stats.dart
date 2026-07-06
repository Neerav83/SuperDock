class SystemStats {
  const SystemStats({
    required this.cpu,
    required this.memory,
    required this.disk,
    required this.uptime,
    required this.sparklines,
  });

  factory SystemStats.fromJson(Map<String, dynamic> json) {
    final sparklines = json['sparklines'] as Map<String, dynamic>? ?? {};
    return SystemStats(
      cpu: json['cpu'] as int? ?? 0,
      memory: json['memory'] as int? ?? 0,
      disk: json['disk'] as int? ?? 0,
      uptime: json['uptime'] as String? ?? '',
      sparklines: Sparklines.fromJson(sparklines),
    );
  }

  final int cpu;
  final int memory;
  final int disk;
  final String uptime;
  final Sparklines sparklines;
}

class Sparklines {
  const Sparklines({
    required this.cpu,
    required this.memory,
    required this.disk,
  });

  factory Sparklines.fromJson(Map<String, dynamic> json) {
    return Sparklines(
      cpu: _toIntList(json['cpu']),
      memory: _toIntList(json['memory']),
      disk: _toIntList(json['disk']),
    );
  }

  final List<int> cpu;
  final List<int> memory;
  final List<int> disk;

  static List<int> _toIntList(dynamic value) {
    if (value is! List) return [];
    return value.map((e) => (e as num).toInt()).toList();
  }
}
