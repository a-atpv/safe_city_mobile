import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import '../constants/app_constants.dart';
import '../api/api_client.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  
  final StreamController<Map<String, dynamic>> _messageController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;
  
  final StreamController<bool> _connectionController = StreamController<bool>.broadcast();
  Stream<bool> get connectionStream => _connectionController.stream;
  
  bool _isConnected = false;
  bool _isConnecting = false;
  bool _shouldReconnect = true;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  final List<int> _reconnectDelays = [2, 4, 8, 16, 30];
  
  bool get isConnected => _isConnected;

  Future<void> connect() async {
    if (_isConnected || _isConnecting) return;
    
    _isConnecting = true;
    _shouldReconnect = true;
    
    final token = await ApiClient().getAccessToken();
    
    if (token == null) {
      _isConnecting = false;
      debugPrint('WS: Cannot connect, no token found');
      return;
    }

    final wsUrl = Uri.parse(AppConstants.wsUserUrl).replace(
      queryParameters: {'token': token},
    );

    debugPrint('WS: Connecting to WebSocket...');
    
    try {
      _channel = WebSocketChannel.connect(wsUrl);
      
      _channel!.stream.listen(
        (message) {
          if (!_isConnected) {
            _isConnected = true;
            _isConnecting = false;
            _connectionController.add(true);
            _reconnectAttempts = 0; // Reset on success
            debugPrint('WS: Connected');
          }
          
          try {
            final data = jsonDecode(message);
            if (data is Map<String, dynamic>) {
              // Heartbeat check: server sends {type: "ping"}
              if (data['type'] == 'ping') {
                debugPrint('WS: Received heartbeat (ping)');
                return;
              }
              debugPrint('WS Received business message: ${data['type']}');
              _messageController.add(data);
            }
          } catch (e) {
            debugPrint('WS: Error decoding message: $e');
          }
        },
        onDone: () {
          debugPrint('WS: Connection closed');
          _handleDisconnect();
        },
        onError: (error) {
          debugPrint('WS: Error: $error');
          _handleDisconnect();
        },
      );
    } catch (e) {
      debugPrint('WS: Connection failed: $e');
      _handleDisconnect();
    }
  }

  void _handleDisconnect() {
    _isConnected = false;
    _isConnecting = false;
    _channel = null;
    _connectionController.add(false);
    
    if (!_shouldReconnect) return;

    // Auto-reconnect with exponential backoff
    _reconnectTimer?.cancel();
    final delay = _reconnectDelays[(_reconnectAttempts).clamp(0, _reconnectDelays.length - 1)];
    
    _reconnectTimer = Timer(Duration(seconds: delay), () async {
      debugPrint('WS: Attempting to reconnect (attempt ${_reconnectAttempts + 1}) in $delay seconds...');
      _reconnectAttempts++;
      
      // Before reconnecting, try to refresh token once if we suspect it's expired
      // In a real scenario, we might only do this if we get a specific error or on every few attempts.
      await connect();
    });
  }

  void disconnect() {
    _shouldReconnect = false;
    _reconnectTimer?.cancel();
    _isConnected = false;
    _isConnecting = false;
    _channel?.sink.close(status.goingAway);
    _channel = null;
    _connectionController.add(false);
    debugPrint('WS: Manually disconnected');
  }

  void dispose() {
    disconnect();
    _messageController.close();
    _connectionController.close();
  }
}
}
