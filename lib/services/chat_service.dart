import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/chat_message.dart';
import '../utils/app_config.dart';
import 'auth_manager.dart';

class ChatService {
  final AppConfig _appConfig = AppConfig();
  final AuthManager _authManager = AuthManager();

  String get baseUrl => '${_appConfig.apiBaseUrl}/api';

  // Lấy lịch sử tin nhắn của một phòng chat
  Future<List<ChatMessage>> fetchMessages(String roomId) async {
    try {
      final token = await _authManager.getToken();
      if (token == null) {
        throw Exception('Token không có sẵn');
      }

      print('📱 Đang tải lịch sử chat cho room: $roomId');

      final response = await http.get(
        Uri.parse("$baseUrl/chat/$roomId"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      print('📡 Chat API response: ${response.statusCode}');
      print('📡 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final messages =
              (data['data'] as List)
                  .map((e) => ChatMessage.fromJson(e))
                  .toList();

          print('✅ Đã tải ${messages.length} tin nhắn');
          return messages;
        } else {
          throw Exception(data['message'] ?? 'Không thể tải tin nhắn');
        }
      } else if (response.statusCode == 403) {
        throw Exception('Không có quyền truy cập phòng chat này');
      } else if (response.statusCode == 401) {
        throw Exception('Phiên đăng nhập đã hết hạn');
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(
          errorData['message'] ??
              "Không thể tải lịch sử chat: ${response.statusCode}",
        );
      }
    } catch (e) {
      print('❌ Lỗi khi tải lịch sử chat: $e');
      rethrow;
    }
  }

  // Lấy danh sách phòng chat
  Future<List<ChatRoom>> fetchChatRooms() async {
    try {
      final token = await _authManager.getToken();
      if (token == null) {
        throw Exception('Token không có sẵn');
      }

      print('📱 Đang tải danh sách phòng chat');

      final response = await http.get(
        Uri.parse("$baseUrl/chat/rooms"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      print('📡 Chat rooms API response: ${response.statusCode}');
      print('📡 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final rooms =
              (data['data'] as List).map((e) => ChatRoom.fromJson(e)).toList();

          print('✅ Đã tải ${rooms.length} phòng chat');
          return rooms;
        } else {
          throw Exception(
            data['message'] ?? 'Không thể tải danh sách phòng chat',
          );
        }
      } else if (response.statusCode == 401) {
        throw Exception('Phiên đăng nhập đã hết hạn');
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(
          errorData['message'] ??
              "Không thể tải danh sách phòng chat: ${response.statusCode}",
        );
      }
    } catch (e) {
      print('❌ Lỗi khi tải danh sách phòng chat: $e');
      rethrow;
    }
  }

  // Lấy ID phòng chat với người dùng khác
  Future<String> getChatRoomId(String otherUserEmail) async {
    try {
      final token = await _authManager.getToken();
      if (token == null) {
        throw Exception('Token không có sẵn');
      }

      print('📱 Đang lấy room ID với: $otherUserEmail');

      final response = await http.get(
        Uri.parse("$baseUrl/chat/room/$otherUserEmail"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      print('📡 Get room ID API response: ${response.statusCode}');
      print('📡 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final roomId = data['data'] as String;
          print('✅ Đã lấy room ID: $roomId');
          return roomId;
        } else {
          throw Exception(data['message'] ?? 'Không thể lấy room ID');
        }
      } else if (response.statusCode == 404) {
        throw Exception('Người dùng không tồn tại');
      } else if (response.statusCode == 401) {
        throw Exception('Phiên đăng nhập đã hết hạn');
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(
          errorData['message'] ??
              "Không thể lấy room ID: ${response.statusCode}",
        );
      }
    } catch (e) {
      print('❌ Lỗi khi lấy room ID: $e');
      rethrow;
    }
  }

  // Đánh dấu tin nhắn đã đọc
  Future<void> markMessagesAsRead(String roomId) async {
    try {
      final token = await _authManager.getToken();
      if (token == null) {
        throw Exception('Token không có sẵn');
      }

      print('📱 Đang đánh dấu tin nhắn đã đọc cho room: $roomId');

      final response = await http.put(
        Uri.parse("$baseUrl/chat/$roomId/mark-read"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      print('📡 Mark read API response: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('✅ Đã đánh dấu tin nhắn đã đọc');
      } else if (response.statusCode == 401) {
        throw Exception('Phiên đăng nhập đã hết hạn');
      } else {
        print('⚠️ Không thể đánh dấu tin nhắn đã đọc: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Lỗi khi đánh dấu tin nhắn đã đọc: $e');
      // Không rethrow vì đây không phải lỗi nghiêm trọng
    }
  }

  // Gửi tin nhắn qua HTTP (test)
  Future<ChatMessage> sendMessageViaHttp(String roomId, String content) async {
    try {
      final token = await _authManager.getToken();
      if (token == null) {
        throw Exception('Token không có sẵn');
      }

      print('📱 Đang gửi tin nhắn qua HTTP: $content');

      final response = await http.post(
        Uri.parse("$baseUrl/chat/test/$roomId"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "content": content,
          "receiverEmail": "", // Sẽ được server xác định
        }),
      );

      print('📡 Send message API response: ${response.statusCode}');
      print('📡 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final message = ChatMessage.fromJson(data['data']);
          print('✅ Đã gửi tin nhắn thành công');
          return message;
        } else {
          throw Exception(data['message'] ?? 'Không thể gửi tin nhắn');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Người dùng không tồn tại');
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(
          errorData['message'] ??
              "Không thể gửi tin nhắn: ${response.statusCode}",
        );
      }
    } catch (e) {
      print('❌ Lỗi khi gửi tin nhắn: $e');
      rethrow;
    }
  }
}
