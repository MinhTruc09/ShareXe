import 'dart:convert';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import '../models/notification_model.dart';
import '../models/chat_message_model.dart';
import 'package:flutter/foundation.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();
  
  StompClient? _stompClient;
  Function(NotificationModel)? onNotificationReceived;
  Function(ChatMessageModel)? onChatMessageReceived;
  String? _userEmail;
  
  void initialize(String serverUrl, String token, String userEmail) {
    _userEmail = userEmail;
    
    if (_stompClient != null && _stompClient!.connected) {
      disconnect();
    }
    
    _stompClient = StompClient(
      config: StompConfig(
        url: 'ws://$serverUrl/ws',
        onConnect: _onConnect,
        onDisconnect: (_) {
          if (kDebugMode) {
            print('WebSocket disconnected');
          }
        },
        onWebSocketError: (error) {
          if (kDebugMode) {
            print('WebSocket error: $error');
          }
        },
        stompConnectHeaders: {'Authorization': 'Bearer $token'},
        webSocketConnectHeaders: {'Authorization': 'Bearer $token'},
      ),
    );
    
    _stompClient!.activate();
  }
  
  void _onConnect(StompFrame frame) {
    if (kDebugMode) {
      print('WebSocket connected');
    }
    
    // 1. Đăng ký nhận thông báo
    _stompClient!.subscribe(
      destination: '/topic/notifications/$_userEmail',
      callback: (frame) {
        if (frame.body != null) {
          try {
            final notification = NotificationModel.fromJson(
              json.decode(frame.body!),
            );
            if (onNotificationReceived != null) {
              onNotificationReceived!(notification);
            }
          } catch (e) {
            if (kDebugMode) {
              print('Error parsing notification: $e');
            }
          }
        }
      },
    );
    
    // 2. Đăng ký nhận tin nhắn chat
    _stompClient!.subscribe(
      destination: '/topic/chat/$_userEmail',
      callback: (frame) {
        if (frame.body != null) {
          try {
            final chatMessage = ChatMessageModel.fromJson(
              json.decode(frame.body!),
            );
            if (onChatMessageReceived != null) {
              onChatMessageReceived!(chatMessage);
            }
          } catch (e) {
            if (kDebugMode) {
              print('Error parsing chat message: $e');
            }
          }
        }
      },
    );
  }
  
  bool isConnected() {
    return _stompClient?.connected ?? false;
  }
  
  void sendChatMessage(String roomId, String receiverEmail, String content) {
    if (_stompClient?.connected != true) {
      if (kDebugMode) {
        print('WebSocket not connected. Cannot send message.');
      }
      return;
    }
    
    final message = {
      'senderEmail': _userEmail,
      'receiverEmail': receiverEmail,
      'content': content,
      'roomId': roomId,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    _stompClient!.send(
      destination: '/app/chat/$roomId',
      body: json.encode(message),
    );
  }
  
  void disconnect() {
    _stompClient?.deactivate();
  }
} 