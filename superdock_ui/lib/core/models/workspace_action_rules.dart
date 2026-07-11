class WorkspaceActionRules {
  static bool isFlutterRun(Map<String, dynamic> action) {
    if (action['type'] != 'shell') return false;
    return isFlutterRunCommand(action['cmd'] as String? ?? '');
  }

  static bool isFlutterRunCommand(String cmd) {
    return cmd.trim().startsWith('flutter run');
  }

  static bool isGitAdd(Map<String, dynamic> action) {
    if (action['type'] != 'shell') return false;
    return isGitAddCommand(action['cmd'] as String? ?? '');
  }

  static bool isGitAddCommand(String cmd) {
    final normalized = cmd.trim();
    return normalized == 'git add' || normalized == 'git add .';
  }

  static bool isGitCommit(Map<String, dynamic> action) {
    if (action['type'] != 'shell') return false;
    return isGitCommitCommand(action['cmd'] as String? ?? '');
  }

  static bool isGitCommitCommand(String cmd) {
    final normalized = cmd.trim();
    if (normalized == 'git commit') return true;
    if (normalized == 'git commit -m') return true;
    return RegExp(r'^git commit -m\s*$').hasMatch(normalized);
  }

  static bool isGitPull(Map<String, dynamic> action) {
    if (action['type'] != 'shell') return false;
    final cmd = (action['cmd'] as String? ?? '').trim();
    return cmd == 'git pull';
  }

  static bool isPreservedShell(Map<String, dynamic> action) {
    if (action['type'] != 'shell') return false;
    return !isFlutterRun(action) && !isGitPull(action);
  }

  static bool usesGitProject(Map<String, dynamic> action) {
    return action['usesGitProject'] == true || action['useGitProject'] == true;
  }

  static bool usesFlutterProject(Map<String, dynamic> action) {
    return action['usesFlutterProject'] == true ||
        action['useFlutterProject'] == true;
  }
}
