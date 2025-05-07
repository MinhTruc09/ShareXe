import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/chat_message_model.dart';
import 'auth_manager.dart';
import 'websocket_service.dart';

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();
  
  final WebSocketService _webSocketService = WebSocketService();
  final AuthManager _authManager = AuthManager();
  String _baseUrl = 'https://yourapi.com'; // Thay thế bằng URL thực tế
  
  Future<void> initialize(String baseUrl) async {
    _baseUrl = baseUrl;
  }
  
  // Lấy danh sách các cuộc trò chuyện
  Future<List<Map<String, dynamic>>> getChatRooms() async {
    try {
      final token = await _authManager.getToken();
      if (token == null) {
        throw Exception('Không tìm thấy token xác thực');
      }
      
      final response = await http.get(
        Uri.parse('$_baseUrl/api/chat/rooms'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          return List<Map<String, dynamic>>.from(jsonResponse['data']);
        } else {
          return [];
        }
      } else {
        throw Exception('Lỗi khi tải danh sách phòng chat: ${response.statusCode}');
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
      final token = await _authManager.getToken();
      if (token == null) {
        throw Exception('Không tìm thấy token xác thực');
      }
      
      final response = await http.get(
        Uri.parse('$_baseUrl/api/chat/history/$roomId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          final List<dynamic> data = jsonResponse['data'];
          return data.map((item) => ChatMessageModel.fromJson(item)).toList();
        } else {
          return [];
        }
      } else {
        throw Exception('Lỗi khi tải lịch sử chat: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Lỗi khi lấy lịch sử chat: $e');
      }
      return [];
    }
  }
  
  // Tạo phòng chat mới hoặc lấy phòng chat hiện tại với một người dùng
  Future<String?> createOrGetChatRoom(String receiverEmail) async {
    try {
      final token = await _authManager.getToken();
      if (token == null) {
        throw Exception('Không tìm thấy token xác thực');
      }
      
      final response = await http.post(
        Uri.parse('$_baseUrl/api/chat/room'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'receiverEmail': receiverEmail}),
      );
      
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          return jsonResponse['data']['roomId'];
        } else {
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
  Future<bool> sendMessage(String roomId, String receiverEmail, String content) async {
    if (!_webSocketService.isConnected()) {
      if (kDebugMode) {
        print('WebSocket không được kết nối. Thử gửi qua REST API.');
      }
      return _sendMessageViaRest(roomId, receiverEmail, content);
    }
    
    try {
      _webSocketService.sendChatMessage(roomId, receiverEmail, content);
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Lỗi khi gửi tin nhắn qua WebSocket: $e');
      }
      // Fallback to REST API if WebSocket fails
      return _sendMessageViaRest(roomId, receiverEmail, content);
    }
  }
  
  // Gửi tin nhắn qua REST API (fallback khi WebSocket không hoạt động)
  Future<bool> _sendMessageViaRest(String roomId, String receiverEmail, String content) async {
    try {
      final token = await _authManager.getToken();
      if (token == null) {
        throw Exception('Không tìm thấy token xác thực');
      }
      
      final response = await http.post(
        Uri.parse('$_baseUrl/api/chat/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'roomId': roomId,
          'receiverEmail': receiverEmail,
          'content': content,
        }),
      );
      
      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) {
        print('Lỗi khi gửi tin nhắn: $e');
      }
      return false;
    }
  }
  
  // Đánh dấu tin nhắn đã đọc
  Future<bool> markMessagesAsRead(String roomId) async {
    try {
      final token = await _authManager.getToken();
      if (token == null) {
        throw Exception('Không tìm thấy token xác thực');
      }
      
      final response = await http.put(
        Uri.parse('$_baseUrl/api/chat/read/$roomId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
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
      final token = await _authManager.getToken();
      if (token == null) {
        throw Exception('Không tìm thấy token xác thực');
      }
      
      final response = await http.get(
        Uri.parse('$_baseUrl/api/chat/unread-count'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true) {
          return jsonResponse['data'] ?? 0;
        } else {
          return 0;
        }
      } else {
        throw Exception('Lỗi khi tải số tin nhắn chưa đọc: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Lỗi khi lấy số tin nhắn chưa đọc: $e');
      }
      return 0;
    }
  }
} 