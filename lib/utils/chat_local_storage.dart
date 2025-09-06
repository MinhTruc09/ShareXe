import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_message.dart';

/// Lớp quản lý lưu trữ cục bộ cho tin nhắn chat
class ChatLocalStorage {
  static final ChatLocalStorage _instance = ChatLocalStorage._internal();
  factory ChatLocalStorage() => _instance;
  ChatLocalStorage._internal();

  static const String _chatMessagesPrefix = 'chat_messages_';

  /// Lưu trữ tin nhắn vào local storage
  Future<bool> saveMessages(String roomId, List<ChatMessage> messages) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final messagesList = messages.map((msg) => msg.toJson()).toList();
      final messagesJson = json.encode(messagesList);

      return await prefs.setString('$_chatMessagesPrefix$roomId', messagesJson);
    } catch (e) {
      if (kDebugMode) {
        print('Lỗi khi lưu tin nhắn vào local storage: $e');
      }
      return false;
    }
  }

  /// Lấy tin nhắn từ local storage
  Future<List<ChatMessage>> getMessages(String roomId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final messagesJson = prefs.getString('$_chatMessagesPrefix$roomId');

      if (messagesJson == null || messagesJson.isEmpty) {
        return [];
      }

      final List<dynamic> decoded = json.decode(messagesJson);
      return decoded.map((item) => ChatMessage.fromJson(item)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Lỗi khi đọc tin nhắn từ local storage: $e');
      }
      return [];
    }
  }

  /// Thêm một tin nhắn mới vào local storage
  Future<bool> addMessage(String roomId, ChatMessage message) async {
    try {
      final messages = await getMessages(roomId);
      messages.insert(0, message); // Thêm tin nhắn mới vào đầu danh sách

      // Chỉ giữ 100 tin nhắn gần nhất để tránh lưu trữ quá nhiều
      if (messages.length > 100) {
        messages.removeRange(100, messages.length);
      }

      return await saveMessages(roomId, messages);
    } catch (e) {
      if (kDebugMode) {
        print('Lỗi khi thêm tin nhắn vào local storage: $e');
      }
      return false;
    }
  }

  /// Cập nhật trạng thái của một tin nhắn trong local storage
  Future<bool> updateMessageStatus(
    String roomId,
    ChatMessage message,
    String newStatus,
  ) async {
    try {
      final messages = await getMessages(roomId);
      final index = messages.indexWhere(
        (msg) =>
            msg.content == message.content &&
            msg.timestamp?.isAtSameMomentAs(
                  message.timestamp ?? DateTime.now(),
                ) ==
                true,
      );

      if (index >= 0) {
        final updatedMessage = ChatMessage(
          token: messages[index].token,
          senderEmail: messages[index].senderEmail,
          receiverEmail: messages[index].receiverEmail,
          senderName: messages[index].senderName,
          content: messages[index].content,
          roomId: messages[index].roomId,
          timestamp: messages[index].timestamp,
          read: messages[index].read,
          id: messages[index].id,
          status: newStatus,
        );
        messages[index] = updatedMessage;
        return await saveMessages(roomId, messages);
      }

      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Lỗi khi cập nhật trạng thái tin nhắn trong local storage: $e');
      }
      return false;
    }
  }

  /// Xóa tất cả tin nhắn của một phòng chat
  Future<bool> clearMessages(String roomId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove('$_chatMessagesPrefix$roomId');
    } catch (e) {
      if (kDebugMode) {
        print('Lỗi khi xóa tin nhắn từ local storage: $e');
      }
      return false;
    }
  }

  /// Kiểm tra xem có tin nhắn được lưu trữ cục bộ cho phòng chat hay không
  Future<bool> hasLocalMessages(String roomId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final messagesJson = prefs.getString('$_chatMessagesPrefix$roomId');
      return messagesJson != null && messagesJson.isNotEmpty;
    } catch (e) {
      if (kDebugMode) {
        print('Lỗi khi kiểm tra tin nhắn trong local storage: $e');
      }
      return false;
    }
  }
}
