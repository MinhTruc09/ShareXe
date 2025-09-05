import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/chat_model.dart';
import '../utils/app_config.dart';
import 'auth_manager.dart';

class ChatService {
  final AuthManager _authManager = AuthManager();
  final AppConfig _appConfig = AppConfig();

  /// Get messages for a specific chat room
  Future<ApiResponseListChatMessageDTO> getMessages(String roomId) async {
    try {
      final token = await _authManager.getToken();
      if (token == null) {
        return ApiResponseListChatMessageDTO(
          message: 'Chưa đăng nhập',
          statusCode: 401,
          data: [],
          success: false,
        );
      }

      final endpoint = '${_appConfig.fullApiUrl}/chat/$roomId';
      print('Getting messages from: $endpoint');

      final response = await http
          .get(
            Uri.parse(endpoint),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Kết nối máy chủ quá hạn. Vui lòng thử lại sau.');
            },
          );

      print('Chat messages response status: ${response.statusCode}');
      print('Chat messages response body: ${response.body}');

      if (response.statusCode == 401 || response.statusCode == 403) {
        return ApiResponseListChatMessageDTO(
          message: 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
          statusCode: response.statusCode,
          data: [],
          success: false,
        );
      }

      if (response.statusCode == 200) {
        try {
          final responseData = json.decode(response.body);
          return ApiResponseListChatMessageDTO.fromJson(responseData);
        } catch (parseError) {
          print('Error parsing chat messages response: $parseError');
          return ApiResponseListChatMessageDTO(
            message: 'Lấy tin nhắn thành công',
            statusCode: 200,
            data: [],
            success: true,
          );
        }
      } else {
        try {
          final responseData = json.decode(response.body);
          return ApiResponseListChatMessageDTO(
            message: responseData['message'] ?? 'Lỗi không xác định',
            statusCode: response.statusCode,
            data: [],
            success: false,
          );
        } catch (parseError) {
          return ApiResponseListChatMessageDTO(
            message: 'Lỗi khi lấy tin nhắn: ${response.statusCode}',
            statusCode: response.statusCode,
            data: [],
            success: false,
          );
        }
      }
    } on SocketException catch (_) {
      return ApiResponseListChatMessageDTO(
        message:
            'Không thể kết nối đến máy chủ. Vui lòng kiểm tra kết nối mạng.',
        statusCode: 0,
        data: [],
        success: false,
      );
    } catch (e) {
      return ApiResponseListChatMessageDTO(
        message: 'Lỗi: ${e.toString()}',
        statusCode: 0,
        data: [],
        success: false,
      );
    }
  }

  /// Get chat rooms for current user
  Future<ApiResponseListChatRoom> getChatRooms() async {
    try {
      final token = await _authManager.getToken();
      if (token == null) {
        return ApiResponseListChatRoom(
          message: 'Chưa đăng nhập',
          statusCode: 401,
          data: [],
          success: false,
        );
      }

      final endpoint = '${_appConfig.fullApiUrl}/chat/rooms';
      print('Getting chat rooms from: $endpoint');

      final response = await http
          .get(
            Uri.parse(endpoint),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Kết nối máy chủ quá hạn. Vui lòng thử lại sau.');
            },
          );

      print('Chat rooms response status: ${response.statusCode}');
      print('Chat rooms response body: ${response.body}');

      if (response.statusCode == 401 || response.statusCode == 403) {
        return ApiResponseListChatRoom(
          message: 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
          statusCode: response.statusCode,
          data: [],
          success: false,
        );
      }

      if (response.statusCode == 200) {
        try {
          final responseData = json.decode(response.body);
          return ApiResponseListChatRoom.fromJson(responseData);
        } catch (parseError) {
          print('Error parsing chat rooms response: $parseError');
          return ApiResponseListChatRoom(
            message: 'Lấy danh sách phòng chat thành công',
            statusCode: 200,
            data: [],
            success: true,
          );
        }
      } else {
        try {
          final responseData = json.decode(response.body);
          return ApiResponseListChatRoom(
            message: responseData['message'] ?? 'Lỗi không xác định',
            statusCode: response.statusCode,
            data: [],
            success: false,
          );
        } catch (parseError) {
          return ApiResponseListChatRoom(
            message: 'Lỗi khi lấy danh sách phòng chat: ${response.statusCode}',
            statusCode: response.statusCode,
            data: [],
            success: false,
          );
        }
      }
    } on SocketException catch (_) {
      return ApiResponseListChatRoom(
        message:
            'Không thể kết nối đến máy chủ. Vui lòng kiểm tra kết nối mạng.',
        statusCode: 0,
        data: [],
        success: false,
      );
    } catch (e) {
      return ApiResponseListChatRoom(
        message: 'Lỗi: ${e.toString()}',
        statusCode: 0,
        data: [],
        success: false,
      );
    }
  }

  /// Get chat room ID for conversation with another user
  Future<ApiResponseChatRoomId> getChatRoomId(String otherUserEmail) async {
    try {
      final token = await _authManager.getToken();
      if (token == null) {
        return ApiResponseChatRoomId(
          message: 'Chưa đăng nhập',
          statusCode: 401,
          data: null,
          success: false,
        );
      }

      final endpoint = '${_appConfig.fullApiUrl}/chat/room/$otherUserEmail';
      print('Getting chat room ID from: $endpoint');

      final response = await http
          .get(
            Uri.parse(endpoint),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Kết nối máy chủ quá hạn. Vui lòng thử lại sau.');
            },
          );

      print('Chat room ID response status: ${response.statusCode}');
      print('Chat room ID response body: ${response.body}');

      if (response.statusCode == 401 || response.statusCode == 403) {
        return ApiResponseChatRoomId(
          message: 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
          statusCode: response.statusCode,
          data: null,
          success: false,
        );
      }

      if (response.statusCode == 200) {
        try {
          final responseData = json.decode(response.body);
          return ApiResponseChatRoomId.fromJson(responseData);
        } catch (parseError) {
          print('Error parsing chat room ID response: $parseError');
          return ApiResponseChatRoomId(
            message: 'Lấy ID phòng chat thành công',
            statusCode: 200,
            data: null,
            success: true,
          );
        }
      } else {
        try {
          final responseData = json.decode(response.body);
          return ApiResponseChatRoomId(
            message: responseData['message'] ?? 'Lỗi không xác định',
            statusCode: response.statusCode,
            data: null,
            success: false,
          );
        } catch (parseError) {
          return ApiResponseChatRoomId(
            message: 'Lỗi khi lấy ID phòng chat: ${response.statusCode}',
            statusCode: response.statusCode,
            data: null,
            success: false,
          );
        }
      }
    } on SocketException catch (_) {
      return ApiResponseChatRoomId(
        message:
            'Không thể kết nối đến máy chủ. Vui lòng kiểm tra kết nối mạng.',
        statusCode: 0,
        data: null,
        success: false,
      );
    } catch (e) {
      return ApiResponseChatRoomId(
        message: 'Lỗi: ${e.toString()}',
        statusCode: 0,
        data: null,
        success: false,
      );
    }
  }

  /// Send message via HTTP (for testing)
  Future<ApiResponseChatMessageDTO> sendMessage({
    required String roomId,
    required String content,
    required String receiverEmail,
    String? senderName,
  }) async {
    try {
      final token = await _authManager.getToken();
      final userEmail = await _authManager.getUserEmail();

      if (token == null || userEmail == null) {
        return ApiResponseChatMessageDTO(
          message: 'Chưa đăng nhập',
          statusCode: 401,
          data: null,
          success: false,
        );
      }

      final endpoint = '${_appConfig.fullApiUrl}/chat/test/$roomId';
      print('Sending message to: $endpoint');

      final messageData = ChatMessageDTO(
        token: token,
        senderEmail: userEmail,
        receiverEmail: receiverEmail,
        senderName: senderName,
        content: content,
        roomId: roomId,
        timestamp: DateTime.now(),
        read: false,
      );

      final response = await http
          .post(
            Uri.parse(endpoint),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: json.encode(messageData.toJson()),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Kết nối máy chủ quá hạn. Vui lòng thử lại sau.');
            },
          );

      print('Send message response status: ${response.statusCode}');
      print('Send message response body: ${response.body}');

      if (response.statusCode == 401 || response.statusCode == 403) {
        return ApiResponseChatMessageDTO(
          message: 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
          statusCode: response.statusCode,
          data: null,
          success: false,
        );
      }

      if (response.statusCode == 200) {
        try {
          final responseData = json.decode(response.body);
          return ApiResponseChatMessageDTO.fromJson(responseData);
        } catch (parseError) {
          print('Error parsing send message response: $parseError');
          return ApiResponseChatMessageDTO(
            message: 'Gửi tin nhắn thành công',
            statusCode: 200,
            data: messageData,
            success: true,
          );
        }
      } else {
        try {
          final responseData = json.decode(response.body);
          return ApiResponseChatMessageDTO(
            message: responseData['message'] ?? 'Lỗi không xác định',
            statusCode: response.statusCode,
            data: null,
            success: false,
          );
        } catch (parseError) {
          return ApiResponseChatMessageDTO(
            message: 'Lỗi khi gửi tin nhắn: ${response.statusCode}',
            statusCode: response.statusCode,
            data: null,
            success: false,
          );
        }
      }
    } on SocketException catch (_) {
      return ApiResponseChatMessageDTO(
        message:
            'Không thể kết nối đến máy chủ. Vui lòng kiểm tra kết nối mạng.',
        statusCode: 0,
        data: null,
        success: false,
      );
    } catch (e) {
      return ApiResponseChatMessageDTO(
        message: 'Lỗi: ${e.toString()}',
        statusCode: 0,
        data: null,
        success: false,
      );
    }
  }

  /// Mark messages as read in a chat room
  Future<bool> markMessagesAsRead(String roomId) async {
    try {
      final token = await _authManager.getToken();
      if (token == null) {
        print('No token available for marking messages as read');
        return false;
      }

      final endpoint = '${_appConfig.fullApiUrl}/chat/$roomId/mark-read';
      print('Marking messages as read at: $endpoint');

      final response = await http
          .put(
            Uri.parse(endpoint),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Kết nối máy chủ quá hạn. Vui lòng thử lại sau.');
            },
          );

      print('Mark as read response status: ${response.statusCode}');
      print('Mark as read response body: ${response.body}');

      if (response.statusCode == 200) {
        return true;
      } else {
        print('Failed to mark messages as read: ${response.statusCode}');
        return false;
      }
    } on SocketException catch (_) {
      print('Network error when marking messages as read');
      return false;
    } catch (e) {
      print('Error marking messages as read: $e');
      return false;
    }
  }

  /// Ensure chat room is created (alias for getChatRoomId)
  Future<String?> ensureChatRoomIsCreated(String otherUserEmail) async {
    final result = await getChatRoomId(otherUserEmail);
    return result.success ? result.data : null;
  }

  /// Get chat history (alias for getMessages)
  Future<List<ChatMessageDTO>> getChatHistory(String roomId) async {
    final result = await getMessages(roomId);
    return result.success ? result.data : [];
  }

  /// Trigger chat room sync
  Future<void> triggerChatRoomSync(String roomId, String partnerEmail) async {
    // Sync chat room by fetching latest messages
    try {
      final messages = await getChatHistory(roomId);
      if (messages.isNotEmpty) {
        print('Chat room sync completed for room: $roomId');
      } else {
        print('No messages found during sync for room: $roomId');
      }
    } catch (e) {
      print('Error during chat room sync: $e');
    }
  }

  /// Create or get chat room (alias for getChatRoomId)
  Future<String?> createOrGetChatRoom(String otherUserEmail) async {
    final result = await getChatRoomId(otherUserEmail);
    return result.success ? result.data : null;
  }

  /// Send message with simplified signature for compatibility
  Future<bool> sendMessageSimple(
    String roomId,
    String content,
    String receiverEmail,
  ) async {
    final result = await sendMessage(
      roomId: roomId,
      content: content,
      receiverEmail: receiverEmail,
    );
    return result.success;
  }
}
