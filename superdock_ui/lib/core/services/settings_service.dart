import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  const AppSettings({
    required this.backendUrl,
    this.flutterProjectPath,
    this.gitProjectPath,
    this.backendCorePath,
    this.autoStartBackend = true,
    this.activeWorkspaceId,
  });

  final String backendUrl;
  final String? flutterProjectPath;
  final String? gitProjectPath;
  final String? backendCorePath;
  final bool autoStartBackend;
  final String? activeWorkspaceId;

  AppSettings copyWith({
    String? backendUrl,
    String? flutterProjectPath,
    String? gitProjectPath,
    String? backendCorePath,
    bool? autoStartBackend,
    String? activeWorkspaceId,
    bool clearFlutterProjectPath = false,
    bool clearGitProjectPath = false,
    bool clearBackendCorePath = false,
    bool clearActiveWorkspaceId = false,
  }) {
    return AppSettings(
      backendUrl: backendUrl ?? this.backendUrl,
      flutterProjectPath: clearFlutterProjectPath
          ? null
          : (flutterProjectPath ?? this.flutterProjectPath),
      gitProjectPath: clearGitProjectPath
          ? null
          : (gitProjectPath ?? this.gitProjectPath),
      backendCorePath: clearBackendCorePath
          ? null
          : (backendCorePath ?? this.backendCorePath),
      autoStartBackend: autoStartBackend ?? this.autoStartBackend,
      activeWorkspaceId: clearActiveWorkspaceId
          ? null
          : (activeWorkspaceId ?? this.activeWorkspaceId),
    );
  }
}

class SettingsService {
  static const _backendUrlKey = 'backend_url';
  static const _flutterProjectPathKey = 'flutter_project_path';
  static const _gitProjectPathKey = 'git_project_path';
  static const _backendCorePathKey = 'backend_core_path';
  static const _autoStartBackendKey = 'auto_start_backend';
  static const _activeWorkspaceIdKey = 'active_workspace_id';
  static const defaultBackendUrl = 'http://127.0.0.1:4545';
  static const defaultBackendCorePath = '../superdock-core';

  Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return AppSettings(
      backendUrl: prefs.getString(_backendUrlKey) ?? defaultBackendUrl,
      flutterProjectPath: prefs.getString(_flutterProjectPathKey),
      gitProjectPath: prefs.getString(_gitProjectPathKey),
      backendCorePath:
          prefs.getString(_backendCorePathKey) ?? defaultBackendCorePath,
      autoStartBackend: prefs.getBool(_autoStartBackendKey) ?? true,
      activeWorkspaceId: prefs.getString(_activeWorkspaceIdKey),
    );
  }

  Future<AppSettings> save(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_backendUrlKey, settings.backendUrl);
    await prefs.setBool(_autoStartBackendKey, settings.autoStartBackend);

    await _saveOptionalPath(
      prefs,
      _flutterProjectPathKey,
      settings.flutterProjectPath,
    );
    await _saveOptionalPath(prefs, _gitProjectPathKey, settings.gitProjectPath);
    await _saveOptionalPath(
      prefs,
      _backendCorePathKey,
      settings.backendCorePath,
      fallback: defaultBackendCorePath,
    );
    await _saveOptionalString(
      prefs,
      _activeWorkspaceIdKey,
      settings.activeWorkspaceId,
    );

    return settings.copyWith(
      flutterProjectPath: _normalize(settings.flutterProjectPath),
      gitProjectPath: _normalize(settings.gitProjectPath),
      backendCorePath:
          _normalize(settings.backendCorePath) ?? defaultBackendCorePath,
      activeWorkspaceId: _normalize(settings.activeWorkspaceId),
      clearFlutterProjectPath: _normalize(settings.flutterProjectPath) == null,
      clearGitProjectPath: _normalize(settings.gitProjectPath) == null,
      clearActiveWorkspaceId: _normalize(settings.activeWorkspaceId) == null,
    );
  }

  Future<void> _saveOptionalString(
    SharedPreferences prefs,
    String key,
    String? value,
  ) async {
    final normalized = _normalize(value);
    if (normalized == null) {
      await prefs.remove(key);
    } else {
      await prefs.setString(key, normalized);
    }
  }

  Future<void> _saveOptionalPath(
    SharedPreferences prefs,
    String key,
    String? value, {
    String? fallback,
  }) async {
    final normalized = _normalize(value) ?? fallback;
    if (normalized == null || normalized.isEmpty) {
      await prefs.remove(key);
    } else {
      await prefs.setString(key, normalized);
    }
  }

  String? _normalize(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }
}
