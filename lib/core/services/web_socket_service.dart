import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import '../constants/app_constants.dart';
import '../api/api_client.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  Timer? _heartbeatTimer;
  
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

  Future<void> connect({String? tokenOverride}) async {
    if (_isConnected || _isConnecting) return;
    
    _isConnecting = true;
    _shouldReconnect = true;
    
    final token = tokenOverride ?? await ApiClient().getAccessToken();
    
    if (token == null) {
      _isConnecting = false;
      debugPrint('WS: Cannot connect, no token found');
      return;
    }

    final wsUrl = Uri.parse(AppConstants.wsUserUrl).replace(
      queryParameters: {'token': token},
    );

    debugPrint('WS: Connecting to: $wsUrl');
    debugPrint('WS: Attempting connection (Attempt ${_reconnectAttempts + 1})...');
    
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
            _startHeartbeat();
          }
          
          try {
            final data = jsonDecode(message);
            if (data is Map<String, dynamic>) {
              // Heartbeat check: server sends {type: "ping"}
              if (data['type'] == 'ping') {
                debugPrint('WS: Received heartbeat (ping) from server');
                return;
              }
              if (data['type'] == 'pong') {
                debugPrint('WS: Received heartbeat response (pong) from server');
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
          final code = _channel?.closeCode;
          debugPrint('WS: Connection closed (Code: $code)');
          
          if (code == 1008) {
            debugPrint('WS: Auth failure (1008). Proactive refresh needed.');
            // Trigger a reconnection which will inherently try to get a new token
            // In a more advanced setup, we could call ApiClient()._refreshToken() here
          }
          
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

  void _startHeartbeat() {
    _stopHeartbeat();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 25), (_) {
      if (_isConnected && _channel != null) {
        debugPrint('WS: Sending heartbeat (ping)');
        _channel!.sink.add('ping');
      }
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  void _handleDisconnect() {
    _isConnected = false;
    _isConnecting = false;
    _channel = null;
    _connectionController.add(false);
    _stopHeartbeat();
    
    if (!_shouldReconnect) return;

    // Auto-reconnect with exponential backoff
    _reconnectTimer?.cancel();
    final delay = _reconnectDelays[(_reconnectAttempts).clamp(0, _reconnectDelays.length - 1)];
    
    _reconnectTimer = Timer(Duration(seconds: delay), () async {
      debugPrint('WS: Attempting to reconnect in $delay seconds...');
      _reconnectAttempts++;
      await connect();
    });
  }

  void updateToken(String newToken) {
    debugPrint('WS: Token updated, reconnecting...');
    disconnect();
    connect(tokenOverride: newToken);
  }

  void disconnect() {
    _shouldReconnect = false;
    _reconnectTimer?.cancel();
    _isConnected = false;
    _isConnecting = false;
    _stopHeartbeat();
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
