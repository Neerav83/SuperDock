import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:superdock_ui/core/services/api.dart';

class BackendLauncher {
  static const defaultCorePath = '../superdock-core';
  static const _currentApiVersion = 6;

  static Future<bool> ensureRunning({
    required String baseUrl,
    String? corePath,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final api = SuperDockApi(baseUrl: baseUrl);
    if (await api.isReachable()) {
      if (await _supportsCurrentApi(baseUrl)) return true;
      await killListenersOnPort(Uri.parse(baseUrl));
    }

    return _startBackend(
      baseUrl: baseUrl,
      corePath: corePath,
      timeout: timeout,
    );
  }

  static Future<bool> restart({
    required String baseUrl,
    String? corePath,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    await killListenersOnPort(Uri.parse(baseUrl));
    return _startBackend(
      baseUrl: baseUrl,
      corePath: corePath,
      timeout: timeout,
    );
  }

  static Future<bool> _startBackend({
    required String baseUrl,
    String? corePath,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    if (corePath == null || corePath.isEmpty || !Platform.isMacOS) {
      return false;
    }

    final directory = Directory(corePath);
    final resolvedPath = directory.isAbsolute
        ? directory.path
        : Directory('${Directory.current.path}/$corePath').absolute.path;
    if (!Directory(resolvedPath).existsSync()) return false;

    final api = SuperDockApi(baseUrl: baseUrl);

    try {
      await Process.start(
        'node',
        ['index.js'],
        workingDirectory: resolvedPath,
        mode: ProcessStartMode.detached,
      );
    } catch (_) {
      return false;
    }

    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (await api.isReachable() && await _supportsCurrentApi(baseUrl)) {
        return true;
      }
    }

    return false;
  }

  static Future<bool> _supportsCurrentApi(String baseUrl) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/meta'))
          .timeout(const Duration(seconds: 2));
      if (response.statusCode != 200) return false;

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return json['apiVersion'] == _currentApiVersion &&
          json['flutterDevices'] == true &&
          json['workspaceProjectPath'] == true &&
          json['workspaceImageUrl'] == true &&
          json['gitInteractive'] == true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> killListenersOnPort(Uri uri) async {
    if (!Platform.isMacOS) return;

    final port = uri.port;
    if (port <= 0) return;

    try {
      final result = await Process.run('lsof', [
        '-ti',
        'tcp:$port',
        '-sTCP:LISTEN',
      ]);
      final stdout = result.stdout.toString().trim();
      if (stdout.isEmpty) return;

      for (final pid in stdout.split('\n')) {
        final trimmed = pid.trim();
        if (trimmed.isEmpty) continue;
        await Process.run('kill', [trimmed]);
      }

      await Future<void>.delayed(const Duration(milliseconds: 400));
    } catch (_) {
      // Best effort only.
    }
  }
}
