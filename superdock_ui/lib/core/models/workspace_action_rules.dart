class WorkspaceActionRules {
  static bool isFlutterRun(Map<String, dynamic> action) {
    if (action['type'] != 'shell') return false;
    final cmd = (action['cmd'] as String? ?? '').trim();
    return cmd.startsWith('flutter run');
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
