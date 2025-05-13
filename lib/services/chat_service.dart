import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/chat_message_model.dart';
import 'auth_manager.dart';
import 'websocket_service.dart';
import '../utils/app_config.dart';
import '../utils/http_client.dart';

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  final WebSocketService _webSocketService = WebSocketService();
  final AuthManager _authManager = AuthManager();
  final AppConfig _appConfig = AppConfig();
  final ApiClient _apiClient = ApiClient();

  Future<void> initialize(String baseUrl) async {
    if (baseUrl.isNotEmpty) {
      _appConfig.updateBaseUrl(baseUrl);
    }
  }

  // Lấy danh sách các cuộc trò chuyện
  Future<List<Map<String, dynamic>>> getChatRooms() async {
    try {
      final response = await _apiClient.get('/chat/rooms', requireAuth: true);

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          return List<Map<String, dynamic>>.from(jsonResponse['data']);
        } else {
          return [];
        }
      } else {
        throw Exception(
          'Lỗi khi tải danh sách phòng chat: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Lỗi khi lấy danh sách phòng chat: $e');
      }
      return [];
    }
  }

  // Lấy lịch sử tin nhắn của một phòng chat
  Future<List<ChatMessageModel>> getChatHistory(String roomId) async {
    try {
      if (kDebugMode) {
        print('🔄 Đang tải lịch sử chat cho phòng: $roomId');
        print('🔄 API Endpoint: ${_appConfig.fullApiUrl}/chat/history/$roomId');
      }
      
      // Kiểm tra xem roomId có hợp lệ không
      if (roomId.isEmpty || roomId == 'null' || roomId == 'undefined') {
        if (kDebugMode) {
          print('❌ RoomId không hợp lệ: $roomId');
        }
        return [];
      }
      
      final response = await _apiClient.get(
        '/chat/history/$roomId',
        requireAuth: true,
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (kDebugMode) {
          print('✅ Nhận phản hồi từ API: ${response.statusCode}');
          print('✅ Dữ liệu: ${jsonResponse['success']}, có ${jsonResponse['data']?.length ?? 0} tin nhắn');
        }
        
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          final List<dynamic> data = jsonResponse['data'];
          final messages = data.map((item) => ChatMessageModel.fromJson(item)).toList();
          
          if (kDebugMode) {
            print('✅ Đã chuyển đổi ${messages.length} tin nhắn từ JSON');
          }
          
          return messages;
        } else {
          if (kDebugMode) {
            print('⚠️ API trả về success=false hoặc data=null: ${jsonResponse['message']}');
          }
          return [];
        }
      } else {
        if (kDebugMode) {
          print('❌ Lỗi HTTP ${response.statusCode}: ${response.body}');
        }
        throw Exception('Lỗi khi tải lịch sử chat: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Lỗi khi lấy lịch sử chat: $e');
        print('❌ Stack trace: ${StackTrace.current}');
      }
      return [];
    }
  }

  // Tạo phòng chat mới hoặc lấy phòng chat hiện tại với một người dùng
  Future<String?> createOrGetChatRoom(String receiverEmail) async {
    try {
      final response = await _apiClient.get(
        '/chat/room/${Uri.encodeComponent(receiverEmail)}',
        requireAuth: true,
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          return jsonResponse['data'];
        } else {
          if (kDebugMode) {
            print('Không thể lấy roomId: ${jsonResponse['message']}');
          }
          return null;
        }
      } else {
        throw Exception('Lỗi khi tạo phòng chat: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Lỗi khi tạo phòng chat: $e');
      }
      return null;
    }
  }

  // Gửi tin nhắn chat
  Future<bool> sendMessage(
    String roomId,
    String receiverEmail,
    String content,
  ) async {
    // Ensure we have valid parameters
    if (roomId.isEmpty || receiverEmail.isEmpty || content.isEmpty) {
      if (kDebugMode) {
        print('❌ Invalid parameters for sending message');
        print('roomId: $roomId, receiverEmail: $receiverEmail, content length: ${content.length}');
      }
      return false;
    }
    
    // First check if WebSocket is connected
    final bool wsConnected = _webSocketService.isConnected();
    
    if (!wsConnected) {
      if (kDebugMode) {
        print('ℹ️ WebSocket not connected, using REST API fallback');
      }
      return _sendMessageViaRest(roomId, receiverEmail, content);
    }

    try {
      if (kDebugMode) {
        print('📤 Sending message via WebSocket to room: $roomId');
      }
      
      _webSocketService.sendChatMessage(roomId, receiverEmail, content);
      
      // Still send via REST API as a backup to ensure delivery
      // This helps in case the WebSocket message gets lost
      bool restSent = await _sendMessageViaRest(roomId, receiverEmail, content);
      
      if (kDebugMode && !restSent) {
        print('⚠️ WebSocket message sent but REST API backup failed');
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error sending message via WebSocket: $e');
        print('⚠️ Falling back to REST API');
      }
      // Fallback to REST API if WebSocket fails
      return _sendMessageViaRest(roomId, receiverEmail, content);
    }
  }

  // Gửi tin nhắn qua REST API (fallback khi WebSocket không hoạt động)
  Future<bool> _sendMessageViaRest(
    String roomId,
    String receiverEmail,
    String content,
  ) async {
    try {
      if (kDebugMode) {
        print('📤 Sending message via REST API to room: $roomId');
        print('📤 API Endpoint: ${_appConfig.fullApiUrl}/chat/send');
      }
      
      final response = await _apiClient.post(
        '/chat/send',
        body: {
          'roomId': roomId,
          'receiverEmail': receiverEmail,
          'content': content,
        },
        requireAuth: true,
      );

      final bool success = response.statusCode == 200;
      
      if (kDebugMode) {
        if (success) {
          print('✅ Message sent successfully via REST API');
        } else {
          print('❌ REST API message failed with status: ${response.statusCode}');
          print('❌ Response: ${response.body}');
        }
      }
      
      return success;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error sending message via REST API: $e');
        print('❌ Stack trace: ${StackTrace.current}');
      }
      return false;
    }
  }

  // Đánh dấu tin nhắn đã đọc
  Future<bool> markMessagesAsRead(String roomId) async {
    try {
      final response = await _apiClient.put(
        '/chat/read/$roomId',
        requireAuth: true,
      );

      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) {
        print('Lỗi khi đánh dấu tin nhắn đã đọc: $e');
      }
      return false;
    }
  }

  // Lấy số lượng tin nhắn chưa đọc
  Future<int> getUnreadMessageCount() async {
    try {
      final response = await _apiClient.get(
        '/chat/unread-count',
        requireAuth: true,
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true) {
          return jsonResponse['data'] ?? 0;
        } else {
          return 0;
        }
      } else {
        throw Exception(
          'Lỗi khi tải số tin nhắn chưa đọc: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Lỗi khi lấy số tin nhắn chưa đọc: $e');
      }
      return 0;
    }
  }
}
