import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/action_history.dart';
import '../models/connection_status.dart';
import '../models/dock_action.dart';
import '../models/process_info.dart';
import '../models/system_stats.dart';
import '../models/terminal_output.dart';
import '../models/workspace.dart';

class SuperDockApi {
  SuperDockApi({this.baseUrl = 'http://127.0.0.1:4545'});

  final String baseUrl;
  static const _timeout = Duration(seconds: 5);

  Uri get _uri => Uri.parse(baseUrl);

  String get terminalWsUrl {
    final wsScheme = _uri.scheme == 'https' ? 'wss' : 'ws';
    return '$wsScheme://${_uri.host}:${_uri.port}/terminal/ws';
  }

  Future<bool> isReachable() async {
    try {
      await getStatus();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> _get(String path) async {
    final response =
        await http.get(Uri.parse('$baseUrl$path')).timeout(_timeout);
    if (response.statusCode != 200) {
      throw Exception('GET $path failed: ${response.statusCode}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<List<dynamic>> _getList(String path) async {
    final response =
        await http.get(Uri.parse('$baseUrl$path')).timeout(_timeout);
    if (response.statusCode != 200) {
      throw Exception('GET $path failed: ${response.statusCode}');
    }
    return jsonDecode(response.body) as List<dynamic>;
  }

  Future<void> runAction(String action, Map<String, dynamic> payload) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/run'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'action': action, 'payload': payload}),
        )
        .timeout(_timeout);

    if (response.statusCode != 200) {
      throw Exception(_readErrorMessage(response.body));
    }
  }

  String _readErrorMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['error'] != null) {
        return decoded['error'].toString();
      }
    } catch (_) {}
    return 'Action failed';
  }

  Future<void> openApp(String name) => runAction('open_app', {'name': name});

  Future<void> runShell(String cmd, {String? cwd}) {
    final payload = <String, dynamic>{'cmd': cmd};
    if (cwd != null) payload['cwd'] = cwd;
    return runAction('shell', payload);
  }

  Future<void> launchWorkspace(String id) =>
      runAction('launch_workspace', {'id': id});

  Future<void> runDockAction(String id) =>
      runAction('run_dock_action', {'id': id});

  Future<ConnectionStatus> getStatus() async {
    final json = await _get('/status');
    return ConnectionStatus.fromJson(json);
  }

  Future<SystemStats> getSystemStats() async {
    final json = await _get('/system');
    return SystemStats.fromJson(json);
  }

  Future<List<ProcessInfo>> getProcesses() async {
    final list = await _getList('/processes');
    return list
        .map((e) => ProcessInfo.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ProcessInfo>> getAllProcesses() async {
    final list = await _getList('/processes/all');
    return list
        .map((e) => ProcessInfo.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ActionHistoryEntry>> getHistory({int limit = 10}) async {
    final list = await _getList('/history?limit=$limit');
    return list
        .map((e) => ActionHistoryEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<TerminalOutput> getTerminal() async {
    final json = await _get('/terminal');
    return TerminalOutput.fromJson(json);
  }

  Future<List<DockAction>> getActions() async {
    final list = await _getList('/actions');
    return list
        .map((e) => DockAction.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<DockAction> createAction(Map<String, dynamic> payload) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/actions'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        )
        .timeout(_timeout);

    if (response.statusCode != 201) {
      throw Exception(_readErrorMessage(response.body));
    }

    return DockAction.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<DockAction> updateAction(
    String id,
    Map<String, dynamic> payload,
  ) async {
    final response = await http
        .put(
          Uri.parse('$baseUrl/actions/$id'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        )
        .timeout(_timeout);

    if (response.statusCode != 200) {
      throw Exception(_readErrorMessage(response.body));
    }

    return DockAction.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<void> deleteAction(String id) async {
    final response = await http
        .delete(Uri.parse('$baseUrl/actions/$id'))
        .timeout(_timeout);

    if (response.statusCode != 200) {
      throw Exception(_readErrorMessage(response.body));
    }
  }

  Future<List<Workspace>> getWorkspaces() async {
    final list = await _getList('/workspaces');
    return list
        .map((e) => Workspace.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Workspace> createWorkspace(Map<String, dynamic> payload) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/workspaces'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        )
        .timeout(_timeout);

    if (response.statusCode != 201) {
      throw Exception(_readErrorMessage(response.body));
    }

    return Workspace.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<Workspace> updateWorkspace(
    String id,
    Map<String, dynamic> payload,
  ) async {
    final response = await http
        .put(
          Uri.parse('$baseUrl/workspaces/$id'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        )
        .timeout(_timeout);

    if (response.statusCode != 200) {
      throw Exception(_readErrorMessage(response.body));
    }

    return Workspace.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<void> deleteWorkspace(String id) async {
    final response = await http
        .delete(Uri.parse('$baseUrl/workspaces/$id'))
        .timeout(_timeout);

    if (response.statusCode != 200) {
      throw Exception(_readErrorMessage(response.body));
    }
  }

  Future<Map<String, dynamic>> getConfig() async => _get('/config');

  Future<Map<String, dynamic>> updateConfig(Map<String, dynamic> config) async {
    final response = await http
        .put(
          Uri.parse('$baseUrl/config'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(config),
        )
        .timeout(_timeout);

    if (response.statusCode != 200) {
      throw Exception(_readErrorMessage(response.body));
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  WebSocketChannel connectTerminalStream() {
    return WebSocketChannel.connect(Uri.parse(terminalWsUrl));
  }
}
