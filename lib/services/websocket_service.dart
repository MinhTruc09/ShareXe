import 'dart:convert';
import 'dart:async';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import '../models/notification_model.dart';
import '../models/chat_message_model.dart';
import 'package:flutter/foundation.dart';
import '../utils/app_config.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  StompClient? _stompClient;
  Function(NotificationModel)? onNotificationReceived;
  Function(ChatMessageModel)? onChatMessageReceived;
  String? _userEmail;
  String? _token;
  String? _serverUrl;
  final AppConfig _appConfig = AppConfig();
  
  int _reconnectAttempts = 0;
  Timer? _reconnectTimer;
  final int _maxReconnectAttempts = 5;
  bool _isInitializing = false;
  bool _inFallbackMode = false;

  void initialize(String serverUrl, String token, String userEmail) {
    if (_isInitializing) {
      if (kDebugMode) {
        print('🔄 WebSocket initialization already in progress, skipping');
      }
      return;
    }
    
    if (_inFallbackMode) {
      if (kDebugMode) {
        print('⚠️ WebSocket in fallback mode due to persistent connection issues');
        print('⚠️ Application will use REST API fallback for messaging');
      }
      return;
    }
    
    _isInitializing = true;
    _userEmail = userEmail;
    _token = token;
    _serverUrl = serverUrl;
    _reconnectAttempts = 0;

    if (serverUrl.isNotEmpty) {
      _appConfig.updateBaseUrl(serverUrl);
    }

    if (_stompClient != null && _stompClient!.connected) {
      disconnect();
    }

    if (kDebugMode) {
      print('🔄 Initializing WebSocket connection');
      print('🔄 WebSocket URL: ${_appConfig.webSocketUrl}');
      print('🔄 User email: $_userEmail');
    }

    _stompClient = StompClient(
      config: StompConfig(
        url: _appConfig.webSocketUrl,
        onConnect: _onConnect,
        onStompError: (frame) {
          if (kDebugMode) {
            print('❌ STOMP protocol error: ${frame.headers} - ${frame.body}');
          }
          _scheduleReconnect();
        },
        onDisconnect: (frame) {
          if (kDebugMode) {
            print('❌ WebSocket disconnected: ${frame?.body}');
          }
          
          _scheduleReconnect();
        },
        onWebSocketError: (error) {
          if (kDebugMode) {
            print('❌ WebSocket error: $error');
            print('❌ WebSocket URL: ${_appConfig.webSocketUrl}');
            
            if (error.toString().contains('404')) {
              print('❌ Error 404: WebSocket endpoint not found. Check server configuration.');
            } else if (error.toString().contains('Connection refused')) {
              print('❌ Connection refused: Server may be down or incorrect URL');
            } else if (error.toString().contains('not upgraded to websocket')) {
              print('❌ Connection not upgraded: Server may not support WebSockets or endpoint is incorrect');
            }
          }
          
          _scheduleReconnect();
        },
        stompConnectHeaders: {'Authorization': 'Bearer $token'},
        webSocketConnectHeaders: {'Authorization': 'Bearer $token'},
        reconnectDelay: const Duration(milliseconds: 5000),
        connectionTimeout: const Duration(seconds: 10),
      ),
    );

    try {
      _stompClient!.activate();
      if (kDebugMode) {
        print('✅ WebSocket activation initiated');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error activating WebSocket: $e');
      }
      _scheduleReconnect();
    } finally {
      _isInitializing = false;
    }
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    
    if (_reconnectAttempts < _maxReconnectAttempts && _token != null && _userEmail != null) {
      _reconnectAttempts++;
      final delay = _calculateReconnectDelay();
      
      if (kDebugMode) {
        print('🔄 Scheduling WebSocket reconnect attempt $_reconnectAttempts in ${delay.inSeconds} seconds');
      }
      
      _reconnectTimer = Timer(delay, () {
        if (kDebugMode) {
          print('🔄 Attempting to reconnect WebSocket (attempt $_reconnectAttempts)');
        }
        initialize(_serverUrl ?? '', _token!, _userEmail!);
      });
    } else if (_reconnectAttempts >= _maxReconnectAttempts) {
      if (kDebugMode) {
        print('⚠️ Maximum WebSocket reconnect attempts reached');
        print('⚠️ Switching to fallback mode - using REST API for messaging');
      }
      _inFallbackMode = true;
      
      Timer(const Duration(minutes: 5), () {
        if (kDebugMode) {
          print('🔄 Attempting to reconnect WebSocket after cooldown period');
        }
        _inFallbackMode = false;
        _reconnectAttempts = 0;
        
        if (_token != null && _userEmail != null) {
          initialize(_serverUrl ?? '', _token!, _userEmail!);
        }
      });
    }
  }
  
  Duration _calculateReconnectDelay() {
    final seconds = (1 << (_reconnectAttempts - 1)).clamp(1, 30);
    return Duration(seconds: seconds);
  }

  void _onConnect(StompFrame frame) {
    if (kDebugMode) {
      print('✅ WebSocket connected successfully');
    }
    
    _reconnectAttempts = 0;

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
              print('❌ Error parsing notification: $e');
              print('Body: ${frame.body}');
            }
          }
        }
      },
    );

    _stompClient!.subscribe(
      destination: '/topic/chat/$_userEmail',
      callback: (frame) {
        if (frame.body != null) {
          try {
            if (kDebugMode) {
              print('✉️ Received chat message via WebSocket: ${frame.body}');
            }
            
            final chatMessage = ChatMessageModel.fromJson(
              json.decode(frame.body!),
            );
            
            if (kDebugMode) {
              print('✉️ Parsed message details:');
              print('   - Room ID: ${chatMessage.roomId}');
              print('   - Sender: ${chatMessage.senderEmail}');
              print('   - Receiver: ${chatMessage.receiverEmail}');
              print('   - Content: ${chatMessage.content.length > 30 ? '${chatMessage.content.substring(0, 30)}...' : chatMessage.content}');
              print('   - Timestamp: ${chatMessage.timestamp}');
            }
            
            if (onChatMessageReceived != null) {
              onChatMessageReceived!(chatMessage);
            } else if (kDebugMode) {
              print('⚠️ No chat message handler registered');
            }
          } catch (e) {
            if (kDebugMode) {
              print('❌ Error parsing chat message: $e');
              print('Body: ${frame.body}');
              print('Stack trace: ${StackTrace.current}');
            }
          }
        } else if (kDebugMode) {
          print('⚠️ Received empty chat message frame');
        }
      },
    );
    
    _stompClient!.subscribe(
      destination: '/topic/chat/global',
      callback: (frame) {
        if (frame.body != null && frame.body!.isNotEmpty) {
          try {
            final data = json.decode(frame.body!);
            if (kDebugMode) {
              print('📢 Global chat message: ${frame.body}');
            }
            
            if (data['receiverEmail'] == _userEmail || data['senderEmail'] == _userEmail) {
              final chatMessage = ChatMessageModel.fromJson(data);
              if (onChatMessageReceived != null) {
                onChatMessageReceived!(chatMessage);
              }
            }
          } catch (e) {
            if (kDebugMode) {
              print('❌ Error processing global chat message: $e');
            }
          }
        }
      },
    );
  }

  bool isConnected() {
    if (_inFallbackMode) {
      return false;
    }
    
    final connected = _stompClient?.connected ?? false;
    if (kDebugMode) {
      print('🔍 WebSocket connection status: ${connected ? 'connected' : 'disconnected'}');
    }
    return connected;
  }

  void sendChatMessage(String roomId, String receiverEmail, String content) {
    if (_stompClient?.connected != true) {
      if (kDebugMode) {
        print('❌ WebSocket not connected. Cannot send message.');
      }
      return;
    }

    final message = {
      'senderEmail': _userEmail,
      'receiverEmail': receiverEmail,
      'content': content,
      'roomId': roomId,
      'timestamp': DateTime.now().toIso8601String(),
      'token':
          _stompClient!.config.stompConnectHeaders?['Authorization']
              ?.replaceAll('Bearer ', '') ??
          '',
    };

    if (kDebugMode) {
      print('✉️ Sending message via WebSocket to /app/chat/$roomId');
      print('Message: ${json.encode(message)}');
    }

    try {
      _stompClient!.send(
        destination: '/app/chat/$roomId',
        body: json.encode(message),
      );
      if (kDebugMode) {
        print('✅ Message sent successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error sending message: $e');
      }
    }
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    if (_stompClient?.connected == true) {
      if (kDebugMode) {
        print('🔄 Disconnecting WebSocket');
      }
      _stompClient?.deactivate();
    }
  }
}
