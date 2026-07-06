import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/terminal_output.dart';
import 'api.dart';

class TerminalStreamService {
  TerminalStreamService(this._api);

  final SuperDockApi _api;
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  final _controller = StreamController<TerminalOutput>.broadcast();

  Stream<TerminalOutput> get stream => _controller.stream;

  Future<void> connect() async {
    await disconnect();
    try {
      _channel = _api.connectTerminalStream();
      _subscription = _channel!.stream.listen(
        (event) {
          final decoded = jsonDecode(event as String);
          if (decoded is Map<String, dynamic>) {
            _controller.add(TerminalOutput.fromJson(decoded));
          }
        },
        onError: (error) => _controller.addError(error),
        cancelOnError: false,
      );
    } catch (_) {
      // Fallback to polling in dashboard.
    }
  }

  Future<void> disconnect() async {
    await _subscription?.cancel();
    _subscription = null;
    await _channel?.sink.close();
    _channel = null;
  }

  void dispose() {
    disconnect();
    _controller.close();
  }
}
