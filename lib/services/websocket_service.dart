import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import '../models/chat_message_model.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  WebSocketChannel? _channel;
  bool _isConnected = false;
  String? _userEmail;

  // Callback for new messages
  Function(ChatMessage)? onChatMessageReceived;

  // Initialize WebSocket connection
  void initialize(String baseUrl, String token, String userEmail) {
    if (_isConnected) {
      // Already connected
      return;
    }

    _userEmail = userEmail;

    try {
      // Convert http to ws protocol
      final uri = baseUrl.replaceFirst('http', 'ws');
      final wsUrl = '$uri/ws/chat?token=$token';

      if (kDebugMode) {
        print('🔌 Connecting to WebSocket: $wsUrl');
      }

      _channel = IOWebSocketChannel.connect(wsUrl);
      _isConnected = true;

      _channel!.stream.listen(
        (dynamic message) {
          _handleMessage(message);
        },
        onDone: _onConnectionClosed,
        onError: _onError,
      );

      if (kDebugMode) {
        print('✅ WebSocket connected successfully');
      }
    } catch (e) {
      _isConnected = false;
      if (kDebugMode) {
        print('❌ WebSocket connection error: $e');
      }
    }
  }

  // Handle incoming WebSocket messages
  void _handleMessage(dynamic message) {
    try {
      if (message is String) {
        final data = jsonDecode(message);
        
        if (data['type'] == 'chat_message') {
          final chatMessage = ChatMessage.fromJson(data['data']);
          
          if (onChatMessageReceived != null) {
            onChatMessageReceived!(chatMessage);
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error parsing WebSocket message: $e');
      }
    }
  }

  // Handle WebSocket connection closed
  void _onConnectionClosed() {
    _isConnected = false;
    if (kDebugMode) {
      print('🔌 WebSocket connection closed');
    }
    // You could implement reconnection logic here
  }

  // Handle WebSocket errors
  void _onError(error) {
    _isConnected = false;
    if (kDebugMode) {
      print('❌ WebSocket error: $error');
    }
    // Handle error as needed
  }

  // Check if connected
  bool isConnected() {
    return _isConnected;
  }

  // Close WebSocket connection
  void close() {
    if (_channel != null) {
      _channel!.sink.close();
      _isConnected = false;
    }
  }

  // Send a message through WebSocket
  void sendChatMessage(String roomId, String receiverId, String message) {
    if (!_isConnected || _channel == null) {
      throw Exception('WebSocket is not connected');
    }

    final messageData = {
      'type': 'chat_message',
      'data': {
        'roomId': roomId,
        'receiverId': receiverId,
        'message': message,
        'messageType': 'text',
      },
    };

    _channel!.sink.add(jsonEncode(messageData));
  }
}
