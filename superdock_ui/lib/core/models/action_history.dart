class ActionHistoryEntry {
  const ActionHistoryEntry({
    required this.label,
    required this.relative,
    required this.success,
  });

  factory ActionHistoryEntry.fromJson(Map<String, dynamic> json) {
    return ActionHistoryEntry(
      label: json['label'] as String? ?? '',
      relative: json['relative'] as String? ?? '',
      success: json['success'] as bool? ?? true,
    );
  }

  final String label;
  final String relative;
  final bool success;
}
