class GitChangeFile {
  const GitChangeFile({
    required this.path,
    required this.status,
  });

  final String path;
  final String status;

  factory GitChangeFile.fromJson(Map<String, dynamic> json) {
    return GitChangeFile(
      path: json['path'] as String,
      status: json['status'] as String? ?? 'changed',
    );
  }

  String get statusLabel {
    switch (status) {
      case 'untracked':
        return 'Ny';
      case 'modified':
        return 'Ändrad';
      case 'deleted':
        return 'Borttagen';
      case 'added':
        return 'Tillagd';
      default:
        return 'Ändrad';
    }
  }
}

class GitChangesResponse {
  const GitChangesResponse({
    required this.files,
    required this.projectPath,
  });

  final List<GitChangeFile> files;
  final String projectPath;

  factory GitChangesResponse.fromJson(Map<String, dynamic> json) {
    final files = json['files'];
    return GitChangesResponse(
      projectPath: json['projectPath'] as String? ?? '',
      files: files is List
          ? files
              .map(
                (file) => GitChangeFile.fromJson(
                  Map<String, dynamic>.from(file as Map),
                ),
              )
              .toList()
          : const [],
    );
  }
}
