import 'dart:io';

import 'package:superdock_ui/core/services/api.dart';

class BackendLauncher {
  static const defaultCorePath = '../superdock-core';

  static Future<bool> ensureRunning({
    required String baseUrl,
    String? corePath,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final api = SuperDockApi(baseUrl: baseUrl);
    if (await api.isReachable()) return true;
    if (corePath == null || corePath.isEmpty || !Platform.isMacOS) {
      return false;
    }

    final directory = Directory(corePath);
    final resolvedPath = directory.isAbsolute
        ? directory.path
        : Directory('${Directory.current.path}/$corePath').absolute.path;
    if (!Directory(resolvedPath).existsSync()) return false;

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
      if (await api.isReachable()) return true;
    }

    return false;
  }
}
