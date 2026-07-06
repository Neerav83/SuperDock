class ProcessInfo {
  const ProcessInfo({
    required this.name,
    required this.detail,
    required this.active,
  });

  factory ProcessInfo.fromJson(Map<String, dynamic> json) {
    return ProcessInfo(
      name: json['name'] as String? ?? '',
      detail: json['detail'] as String? ?? '',
      active: json['active'] as bool? ?? false,
    );
  }

  final String name;
  final String detail;
  final bool active;
}
