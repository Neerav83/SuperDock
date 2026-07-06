import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  const AppSettings({
    required this.backendUrl,
    this.flutterProjectPath,
  });

  final String backendUrl;
  final String? flutterProjectPath;

  AppSettings copyWith({
    String? backendUrl,
    String? flutterProjectPath,
    bool clearFlutterProjectPath = false,
  }) {
    return AppSettings(
      backendUrl: backendUrl ?? this.backendUrl,
      flutterProjectPath: clearFlutterProjectPath
          ? null
          : (flutterProjectPath ?? this.flutterProjectPath),
    );
  }
}

class SettingsService {
  static const _backendUrlKey = 'backend_url';
  static const _flutterProjectPathKey = 'flutter_project_path';
  static const defaultBackendUrl = 'http://127.0.0.1:4545';

  Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return AppSettings(
      backendUrl: prefs.getString(_backendUrlKey) ?? defaultBackendUrl,
      flutterProjectPath: prefs.getString(_flutterProjectPathKey),
    );
  }

  Future<AppSettings> save(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_backendUrlKey, settings.backendUrl);

    final projectPath = settings.flutterProjectPath?.trim();
    if (projectPath == null || projectPath.isEmpty) {
      await prefs.remove(_flutterProjectPathKey);
    } else {
      await prefs.setString(_flutterProjectPathKey, projectPath);
    }

    return settings.copyWith(
      flutterProjectPath:
          projectPath == null || projectPath.isEmpty ? null : projectPath,
      clearFlutterProjectPath: projectPath == null || projectPath.isEmpty,
    );
  }
}
