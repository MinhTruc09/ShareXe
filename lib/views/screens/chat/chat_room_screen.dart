import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../../models/chat_message_model.dart';
import '../../../services/chat_service.dart';
import '../../../services/websocket_service.dart';
import '../../../services/auth_manager.dart';
import '../../../utils/app_config.dart';
import '../../../utils/chat_local_storage.dart';
import 'package:flutter/foundation.dart';

class ChatRoomScreen extends StatefulWidget {
  final String roomId;
  final String partnerName;
  final String partnerEmail;

  const ChatRoomScreen({
    Key? key,
    required this.roomId,
    required this.partnerName,
    required this.partnerEmail,
  }) : super(key: key);

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final ChatService _chatService = ChatService();
  final WebSocketService _webSocketService = WebSocketService();
  final AuthManager _authManager = AuthManager();
  final AppConfig _appConfig = AppConfig();
  final ChatLocalStorage _chatLocalStorage = ChatLocalStorage();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<ChatMessageModel> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  String? _userEmail;
  StreamSubscription? _chatSubscription;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _chatSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeChat() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Lấy email người dùng để phân biệt tin nhắn của mình
      _userEmail = await _authManager.getUserEmail();

      if (_userEmail == null) {
        if (kDebugMode) {
          print('Không thể lấy email người dùng');
        }
        throw Exception('Không thể lấy email người dùng');
      }

      // Kết nối WebSocket
      String? token = await _authManager.getToken();
      if (token == null) {
        if (kDebugMode) {
          print('Không tìm thấy token xác thực');
        }
        throw Exception('Không tìm thấy token xác thực');
      }

      if (kDebugMode) {
        print('Khởi tạo WebSocket với email: $_userEmail');
        print('WebSocket URL: ${_appConfig.webSocketUrl}');
      }

      _webSocketService.initialize(_appConfig.apiBaseUrl, token, _userEmail!);

      // Kiểm tra kết nối WebSocket
      await Future.delayed(
        const Duration(seconds: 2),
      ); // Cho WebSocket có thời gian kết nối
      if (!_webSocketService.isConnected()) {
        if (kDebugMode) {
          print('⚠️ WebSocket không thể kết nối sau khi khởi tạo');
        }
        // Vẫn tiếp tục mà không throw exception, vì chúng ta sẽ fallback sang REST API
      } else {
        if (kDebugMode) {
          print('✅ WebSocket đã kết nối thành công');
        }
      }

      // Thiết lập lắng nghe tin nhắn
      _setupWebSocketListener();

      // Tải lịch sử chat
      await _loadChatHistory();

      // Đánh dấu tin nhắn đã đọc
      await _chatService.markMessagesAsRead(widget.roomId);
    } catch (e) {
      if (kDebugMode) {
        print('Lỗi khởi tạo chat: $e');
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Không thể kết nối: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _setupWebSocketListener() {
    _webSocketService.onChatMessageReceived = (message) async {
      if (kDebugMode) {
        print('Nhận tin nhắn qua WebSocket: ${message.content}');
        print(
          'Phòng chat hiện tại: ${widget.roomId}, Phòng của tin nhắn: ${message.roomId}',
        );
      }

      // Chỉ hiển thị tin nhắn thuộc phòng chat hiện tại
      if (message.roomId == widget.roomId) {
        // Lưu tin nhắn vào bộ nhớ cục bộ
        await _chatLocalStorage.addMessage(widget.roomId, message);

        if (mounted) {
          setState(() {
            // Thêm tin nhắn vào đầu danh sách vì ListView hiển thị ngược
            _messages.insert(0, message);
          });

          // Cuộn xuống cuối danh sách tin nhắn
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          });

          // Đánh dấu tin nhắn đã đọc
          _chatService.markMessagesAsRead(widget.roomId);
        }
      }
    };
  }

  Future<void> _loadChatHistory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Đầu tiên, thử tải tin nhắn từ bộ nhớ cục bộ
      final localMessages = await _chatLocalStorage.getMessages(widget.roomId);

      if (localMessages.isNotEmpty) {
        if (kDebugMode) {
          print('Tải ${localMessages.length} tin nhắn từ bộ nhớ cục bộ');
        }

        setState(() {
          _messages = localMessages;
          _isLoading = false;
        });
      }

      // Sau đó tải tin nhắn từ server để cập nhật
      final serverMessages = await _chatService.getChatHistory(widget.roomId);

      if (serverMessages.isNotEmpty) {
        if (kDebugMode) {
          print('Tải ${serverMessages.length} tin nhắn từ server');
        }

        // Lưu tin nhắn từ server vào bộ nhớ cục bộ
        await _chatLocalStorage.saveMessages(widget.roomId, serverMessages);

        // Cập nhật giao diện nếu danh sách tin nhắn từ server khác với local
        if (localMessages.isEmpty ||
            !_areMessagesEqual(localMessages, serverMessages)) {
          setState(() {
            _messages = serverMessages;
          });
        }
      }

      // Cuộn xuống để hiển thị tin nhắn mới nhất
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });

      // Đánh dấu tin nhắn đã đọc
      await _chatService.markMessagesAsRead(widget.roomId);
    } catch (e) {
      // Nếu đã có tin nhắn từ local, không hiển thị thông báo lỗi
      if (_messages.isEmpty) {
        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Không thể tải tin nhắn: $e')));
        }
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Hàm so sánh hai danh sách tin nhắn
  bool _areMessagesEqual(
    List<ChatMessageModel> list1,
    List<ChatMessageModel> list2,
  ) {
    if (list1.length != list2.length) {
      return false;
    }

    for (int i = 0; i < list1.length; i++) {
      if (list1[i].content != list2[i].content ||
          !list1[i].timestamp.isAtSameMomentAs(list2[i].timestamp) ||
          list1[i].senderEmail != list2[i].senderEmail) {
        return false;
      }
    }

    return true;
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    setState(() {
      _isSending = true;
    });

    _messageController.clear();

    // Tạo tin nhắn tạm thời để hiển thị ngay lập tức
    final localMessage = ChatMessageModel(
      id: 0, // ID tạm thời
      senderEmail: _userEmail ?? '',
      receiverEmail: widget.partnerEmail,
      senderName: await _authManager.getUsername() ?? 'Tôi',
      content: message,
      roomId: widget.roomId,
      timestamp: DateTime.now(),
      read: false,
      status: 'sending', // Trạng thái đang gửi
    );

    // Thêm tin nhắn vào UI ngay lập tức
    setState(() {
      _messages.insert(0, localMessage);
    });

    // Lưu tin nhắn vào bộ nhớ cục bộ
    await _chatLocalStorage.addMessage(widget.roomId, localMessage);

    // Cuộn xuống để hiển thị tin nhắn mới
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    try {
      final success = await _chatService.sendMessage(
        widget.roomId,
        widget.partnerEmail,
        message,
      );

      // Cập nhật trạng thái tin nhắn
      final updatedStatus = success ? 'sent' : 'failed';

      setState(() {
        final index = _messages.indexWhere(
          (msg) =>
              msg.content == localMessage.content &&
              msg.timestamp.isAtSameMomentAs(localMessage.timestamp),
        );

        if (index >= 0) {
          final updatedMessage = _messages[index].copyWith(
            status: updatedStatus,
          );
          _messages[index] = updatedMessage;
        }
      });

      // Cập nhật trạng thái tin nhắn trong bộ nhớ cục bộ
      await _chatLocalStorage.updateMessageStatus(
        widget.roomId,
        localMessage,
        updatedStatus,
      );

      if (!success && mounted) {
        // Nếu gửi thất bại, hiển thị thông báo
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Không thể gửi tin nhắn')));
      }
    } catch (e) {
      if (mounted) {
        // Cập nhật trạng thái tin nhắn thất bại
        setState(() {
          final index = _messages.indexWhere(
            (msg) =>
                msg.content == localMessage.content &&
                msg.timestamp.isAtSameMomentAs(localMessage.timestamp),
          );

          if (index >= 0) {
            final updatedMessage = _messages[index].copyWith(status: 'failed');
            _messages[index] = updatedMessage;
          }
        });

        // Cập nhật trạng thái tin nhắn trong bộ nhớ cục bộ
        await _chatLocalStorage.updateMessageStatus(
          widget.roomId,
          localMessage,
          'failed',
        );

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  String _formatMessageTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) {
      return DateFormat('HH:mm').format(dateTime);
    } else if (today.difference(messageDate).inDays == 1) {
      return 'Hôm qua, ${DateFormat('HH:mm').format(dateTime)}';
    } else {
      return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white,
              radius: 16,
              child: Text(
                widget.partnerName.isNotEmpty
                    ? widget.partnerName[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.partnerName,
                style: const TextStyle(fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF002D72),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              // Show partner info or chat settings
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _messages.isEmpty
                    ? const Center(
                      child: Text(
                        'Chưa có tin nhắn nào. Hãy bắt đầu cuộc trò chuyện!',
                        style: TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    )
                    : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: ListView.builder(
                        controller: _scrollController,
                        reverse: true, // Display latest messages at the bottom
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          final isMyMessage = message.senderEmail == _userEmail;

                          return _buildMessageBubble(message, isMyMessage);
                        },
                      ),
                    ),
          ),

          // Message input area
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.photo_outlined),
                  onPressed: () {
                    // Handle image selection
                  },
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(color: Colors.black87, fontSize: 16),
                    decoration: const InputDecoration(
                      hintText: 'Nhắn tin...',
                      hintStyle: TextStyle(color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(24.0)),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Color(0xFFF0F2F5),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                _isSending
                    ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.0),
                    )
                    : IconButton(
                      icon: const Icon(Icons.send),
                      color: Theme.of(context).primaryColor,
                      onPressed: _sendMessage,
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessageModel message, bool isMyMessage) {
    final messageTime = _formatMessageTime(message.timestamp);

    // Icon trạng thái tin nhắn
    Widget? statusIcon;
    if (isMyMessage && message.status != null) {
      switch (message.status) {
        case 'sending':
          statusIcon = const SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 2.0,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
            ),
          );
          break;
        case 'sent':
          statusIcon = const Icon(
            Icons.check,
            size: 14.0,
            color: Colors.white70,
          );
          break;
        case 'delivered':
          statusIcon = const Icon(
            Icons.done_all,
            size: 14.0,
            color: Colors.white70,
          );
          break;
        case 'read':
          statusIcon = const Icon(
            Icons.done_all,
            size: 14.0,
            color: Colors.lightBlueAccent,
          );
          break;
        case 'failed':
          statusIcon = const Icon(
            Icons.error_outline,
            size: 14.0,
            color: Colors.redAccent,
          );
          break;
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment:
            isMyMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMyMessage) ...[
            const CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFF002D72),
              child: Icon(Icons.person, size: 16, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 10.0,
              ),
              decoration: BoxDecoration(
                color:
                    isMyMessage
                        ? const Color(0xFF0078FF)
                        : const Color(0xFFE4E6EB),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(
                      color: isMyMessage ? Colors.white : Colors.black87,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        messageTime,
                        style: TextStyle(
                          color:
                              isMyMessage
                                  ? Colors.white.withOpacity(0.8)
                                  : Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                      if (isMyMessage && statusIcon != null) ...[
                        const SizedBox(width: 4),
                        statusIcon,
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isMyMessage) const SizedBox(width: 8),
        ],
      ),
    );
  }
}
