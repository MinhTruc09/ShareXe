import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/chat_message_model.dart';
import '../models/chat_room_model.dart';
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
  final ApiClient _apiClient = ApiClient();
  final AppConfig _appConfig = AppConfig();

  // Initialize WebSocket connection
  Future<void> initializeWebSocket() async {
    try {
      final token = await _authManager.getToken();
      final email = await _authManager.getUserEmail();
      
      if (token != null && email != null) {
        _webSocketService.initialize(
          _appConfig.apiBaseUrl,
          token,
          email,
        );
        
        _webSocketService.onChatMessageReceived = (message) {
          // Handle incoming message
          if (onMessageReceived != null) {
            onMessageReceived!(message);
          }
        };
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing WebSocket: $e');
      }
    }
  }
  
  // Callback for new messages
  Function(ChatMessage)? onMessageReceived;
  
  // Get all chat rooms for the current user
  Future<List<ChatRoom>> getChatRooms() async {
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
      return [];
    } catch (e) {
      if (kDebugMode) {
        print('❌ Lỗi khi lấy lịch sử chat: $e');
        print('❌ Stack trace: ${StackTrace.current}');
      }
      return [];
    }
  }

  // Get chat history for a specific room
  Future<List<ChatMessage>> getChatHistory(String roomId) async {
    try {
      final response = await _apiClient.get(
        '/chat/messages/$roomId',
        requireAuth: true,
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          List<dynamic> messagesJson = jsonResponse['data'];
          return messagesJson.map((json) => ChatMessage.fromJson(json)).toList();
        }
      }
      return [];
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
      return [];
    }
  }

  // Send a message
  Future<bool> sendMessage(String receiverId, String message, String rideId) async {
    try {
      if (kDebugMode) {
        print('📤 Sending message via REST API to room: $roomId');
        print('📤 API Endpoint: ${_appConfig.fullApiUrl}/chat/send');
      }
      
      final response = await _apiClient.post(
        '/chat/send',
        body: {
          'receiverId': receiverId,
          'message': message,
          'rideId': rideId,
          'messageType': 'text'
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

  // Mark messages as read
  Future<bool> markAsRead(String roomId) async {
    try {
      final response = await _apiClient.put(
        '/chat/read/$roomId',
        requireAuth: true,
      );

      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) {
        print('Error marking messages as read: $e');
      }
      return false;
    }
  }

  // Get unread message count
  Future<int> getUnreadCount() async {
    try {
      final response = await _apiClient.get(
        '/chat/unread-count',
        requireAuth: true,
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true) {
          return jsonResponse['data'] ?? 0;
        }
      }
      return 0;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting unread count: $e');
      }
      return 0;
    }
  }

  // Initialize chat room with driver after booking
  Future<String?> initChatWithDriver(String driverId, String rideId) async {
    try {
      final response = await _apiClient.post(
        '/chat/init',
        body: {
          'driverId': driverId,
          'rideId': rideId,
        },
        requireAuth: true,
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          return jsonResponse['data']['roomId'];
        }
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing chat: $e');
      }
      return null;
    }
  }

  // Get mock data for testing
  List<ChatRoom> getMockChatRooms() {
    return [
      ChatRoom(
        id: '1',
        userId: 'driver1',
        userName: 'Nguyễn Văn A',
        userAvatar: 'https://randomuser.me/api/portraits/men/1.jpg',
        lastMessage: 'Tôi sẽ đón bạn lúc 8h sáng nhé',
        lastMessageTime: DateTime.now().subtract(const Duration(minutes: 5)),
        unreadCount: 2,
        rideId: '101',
      ),
      ChatRoom(
        id: '2',
        userId: 'driver2',
        userName: 'Trần Thị B',
        userAvatar: 'https://randomuser.me/api/portraits/women/2.jpg',
        lastMessage: 'Bạn đang ở đâu vậy?',
        lastMessageTime: DateTime.now().subtract(const Duration(hours: 2)),
        unreadCount: 0,
        rideId: '102',
      ),
      ChatRoom(
        id: '3',
        userId: 'driver3',
        userName: 'Lê Văn C',
        userAvatar: 'https://randomuser.me/api/portraits/men/3.jpg',
        lastMessage: 'Cảm ơn bạn đã sử dụng dịch vụ',
        lastMessageTime: DateTime.now().subtract(const Duration(days: 2)),
        unreadCount: 0,
        rideId: '103',
      ),
    ];
  }

  // Get mock chat history for testing
  List<ChatMessage> getMockChatHistory(String roomId) {
    final String currentUserId = 'currentuser'; // This would normally come from auth
    final String otherUserId = roomId == '1' ? 'driver1' : (roomId == '2' ? 'driver2' : 'driver3');
    
    if (roomId == '1') {
      return [
        ChatMessage(
          id: 1,
          senderId: otherUserId,
          receiverId: currentUserId,
          message: 'Xin chào, tôi là tài xế của bạn',
          messageType: 'text',
          timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 30)),
          isRead: true,
        ),
        ChatMessage(
          id: 2,
          senderId: currentUserId,
          receiverId: otherUserId,
          message: 'Xin chào, bạn sẽ đón tôi ở đâu?',
          messageType: 'text',
          timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 25)),
          isRead: true,
        ),
        ChatMessage(
          id: 3,
          senderId: otherUserId,
          receiverId: currentUserId,
          message: 'Tôi sẽ đón bạn ở đầu đường Lê Lợi nhé',
          messageType: 'text',
          timestamp: DateTime.now().subtract(const Duration(hours: 1)),
          isRead: true,
        ),
        ChatMessage(
          id: 4,
          senderId: currentUserId,
          receiverId: otherUserId,
          message: 'Vâng, tôi sẽ có mặt đúng giờ',
          messageType: 'text',
          timestamp: DateTime.now().subtract(const Duration(minutes: 55)),
          isRead: true,
        ),
        ChatMessage(
          id: 5,
          senderId: otherUserId,
          receiverId: currentUserId,
          message: 'Tôi sẽ đón bạn lúc 8h sáng nhé',
          messageType: 'text',
          timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
          isRead: false,
        ),
      ];
    } else if (roomId == '2') {
      return [
        ChatMessage(
          id: 1,
          senderId: currentUserId,
          receiverId: otherUserId,
          message: 'Chào bạn, tôi đã đặt xe của bạn',
          messageType: 'text',
          timestamp: DateTime.now().subtract(const Duration(hours: 3)),
          isRead: true,
        ),
        ChatMessage(
          id: 2,
          senderId: otherUserId,
          receiverId: currentUserId,
          message: 'Vâng, tôi sẽ đón bạn lúc 15h chiều nhé',
          messageType: 'text',
          timestamp: DateTime.now().subtract(const Duration(hours: 2, minutes: 50)),
          isRead: true,
        ),
        ChatMessage(
          id: 3,
          senderId: otherUserId,
          receiverId: currentUserId,
          message: 'Bạn đang ở đâu vậy?',
          messageType: 'text',
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          isRead: true,
        ),
      ];
    } else {
      return [
        ChatMessage(
          id: 1,
          senderId: otherUserId,
          receiverId: currentUserId,
          message: 'Chào bạn, tôi là tài xế của bạn hôm nay',
          messageType: 'text',
          timestamp: DateTime.now().subtract(const Duration(days: 3)),
          isRead: true,
        ),
        ChatMessage(
          id: 2,
          senderId: currentUserId,
          receiverId: otherUserId,
          message: 'Vâng, tôi sẽ đợi ở đầu ngõ',
          messageType: 'text',
          timestamp: DateTime.now().subtract(const Duration(days: 3)).add(const Duration(minutes: 5)),
          isRead: true,
        ),
        ChatMessage(
          id: 3,
          senderId: otherUserId,
          receiverId: currentUserId,
          message: 'Chuyến đi của chúng ta đã hoàn thành',
          messageType: 'text',
          timestamp: DateTime.now().subtract(const Duration(days: 2, hours: 1)),
          isRead: true,
        ),
        ChatMessage(
          id: 4,
          senderId: otherUserId,
          receiverId: currentUserId,
          message: 'Cảm ơn bạn đã sử dụng dịch vụ',
          timestamp: DateTime.now().subtract(const Duration(days: 2)),
          messageType: 'text',
          isRead: true,
        ),
      ];
    }
  }
}
