import 'dart:convert';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_frame.dart';
import '../models/chat_message.dart';
import '../utils/app_config.dart';
import 'auth_manager.dart';

class WebSocketService {
  final AppConfig _appConfig = AppConfig();
  final AuthManager _authManager = AuthManager();

  StompClient? _stompClient;
  bool _isConnected = false;
  final Map<String, Function(ChatMessage)> _messageCallbacks = {};

  bool get isConnected => _isConnected;

  // Kết nối WebSocket cho chat
  Future<void> connectForChat(
    String roomId,
    Function(ChatMessage) onMessage,
  ) async {
    try {
      final token = await _authManager.getToken();
      if (token == null) {
        throw Exception('Token không có sẵn');
      }

      print('🔌 Đang kết nối WebSocket cho chat room: $roomId');

      // Lưu callback cho room này
      _messageCallbacks[roomId] = onMessage;

    _stompClient = StompClient(
        config: StompConfig.SockJS(
          url: '${_appConfig.apiBaseUrl}/ws', // WebSocket endpoint
          onConnect: (StompFrame frame) {
            print("✅ Đã kết nối WebSocket cho chat");
            _isConnected = true;

            // Subscribe room chat
            _stompClient?.subscribe(
              destination: "/topic/chat/$roomId",
      callback: (frame) {
        if (frame.body != null) {
          try {
                    final msg = ChatMessage.fromJson(jsonDecode(frame.body!));
                    onMessage(msg); // Callback -> update UI
                    print('📨 Nhận tin nhắn mới: ${msg.content}');
          } catch (e) {
                    print('❌ Lỗi parse tin nhắn: $e');
          }
        }
      },
    );
          },
          beforeConnect: () async {
            print('⏳ Đang kết nối WebSocket...');
          },
          onWebSocketError: (dynamic error) {
            print("❌ WebSocket Error: $error");
            _isConnected = false;
          },
          onStompError: (StompFrame frame) {
            print("❌ STOMP Error: ${frame.body}");
            _isConnected = false;
          },
          onDisconnect: (StompFrame frame) {
            print("🔌 Đã ngắt kết nối WebSocket");
            _isConnected = false;
          },
          stompConnectHeaders: {
            "Authorization": "Bearer $token", // gửi token vào header
          },
        ),
      );

      _stompClient?.activate();
          } catch (e) {
      print('❌ Lỗi khi kết nối WebSocket: $e');
      rethrow;
    }
  }

  // Gửi tin nhắn qua WebSocket
  Future<void> sendMessage(String roomId, ChatMessage message) async {
    if (!_isConnected || _stompClient == null) {
      throw Exception('WebSocket chưa được kết nối');
    }

    try {
      print('📤 Đang gửi tin nhắn: ${message.content}');

      final messageData = message.toJson();
      // Thêm token vào payload như API yêu cầu
      messageData['token'] = await _authManager.getToken();

      _stompClient!.send(
        destination: "/app/chat/$roomId",
        body: jsonEncode(messageData),
      );

      print('✅ Đã gửi tin nhắn thành công');
    } catch (e) {
      print('❌ Lỗi khi gửi tin nhắn: $e');
      rethrow;
    }
  }

  // Ngắt kết nối WebSocket
  void disconnect() {
    if (_stompClient != null) {
      print('🔌 Đang ngắt kết nối WebSocket...');
      _stompClient!.deactivate();
      _stompClient = null;
      _isConnected = false;
      _messageCallbacks.clear();
    }
  }

  // Kiểm tra kết nối và reconnect nếu cần
  Future<void> ensureConnection() async {
    if (!_isConnected) {
      print('🔄 Đang thử kết nối lại WebSocket...');
      // Có thể implement logic reconnect ở đây
    }
  }
}
