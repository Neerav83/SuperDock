class TerminalOutput {
  const TerminalOutput({
    required this.live,
    required this.lines,
  });

  factory TerminalOutput.fromJson(Map<String, dynamic> json) {
    final lines = json['lines'];
    return TerminalOutput(
      live: json['live'] as bool? ?? false,
      lines: lines is List ? lines.map((e) => e.toString()).toList() : [],
    );
  }

  final bool live;
  final List<String> lines;
}
