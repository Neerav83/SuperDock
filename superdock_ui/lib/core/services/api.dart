import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/action_history.dart';
import '../models/connection_status.dart';
import '../models/process_info.dart';
import '../models/system_stats.dart';
import '../models/terminal_output.dart';

class SuperDockApi {
  SuperDockApi({this.baseUrl = 'http://localhost:4545'});

  final String baseUrl;

  Future<Map<String, dynamic>> _get(String path) async {
    final response = await http.get(Uri.parse('$baseUrl$path'));
    if (response.statusCode != 200) {
      throw Exception('GET $path failed: ${response.statusCode}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<List<dynamic>> _getList(String path) async {
    final response = await http.get(Uri.parse('$baseUrl$path'));
    if (response.statusCode != 200) {
      throw Exception('GET $path failed: ${response.statusCode}');
    }
    return jsonDecode(response.body) as List<dynamic>;
  }

  Future<void> runAction(String action, Map<String, dynamic> payload) async {
    final response = await http.post(
      Uri.parse('$baseUrl/run'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'action': action, 'payload': payload}),
    );
    if (response.statusCode != 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>?;
      throw Exception(body?['error'] ?? 'Action failed');
    }
  }

  Future<void> openApp(String name) => runAction('open_app', {'name': name});

  Future<void> runShell(String cmd, {String? cwd}) {
    final payload = <String, dynamic>{'cmd': cmd};
    if (cwd != null) payload['cwd'] = cwd;
    return runAction('shell', payload);
  }

  Future<void> launchWorkspace(String id) =>
      runAction('launch_workspace', {'id': id});

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
}
