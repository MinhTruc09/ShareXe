import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../../models/chat_message.dart';
import '../../../services/chat_service.dart';
import '../../../services/websocket_service.dart';
import '../../../services/auth_manager.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ChatRoomScreenV2 extends StatefulWidget {
  final String roomId;
  final String partnerName;
  final String partnerEmail;

  const ChatRoomScreenV2({
    Key? key,
    required this.roomId,
    required this.partnerName,
    required this.partnerEmail,
  }) : super(key: key);

  @override
  State<ChatRoomScreenV2> createState() => _ChatRoomScreenV2State();
}

class _ChatRoomScreenV2State extends State<ChatRoomScreenV2> {
  final ChatService _chatService = ChatService();
  final WebSocketService _webSocketService = WebSocketService();
  final AuthManager _authManager = AuthManager();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();

  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  String? _userEmail;
  String? _userName;
  bool _showEmojiPicker = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _webSocketService.disconnect();
    super.dispose();
  }

  Future<void> _initialize() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Lấy thông tin user
      _userEmail = await _authManager.getUserEmail();
      _userName = await _authManager.getUserName();

      // Load lịch sử tin nhắn
      await _loadMessages();

      // Kết nối WebSocket
      await _connectWebSocket();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Lỗi khi khởi tạo chat: $e');
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể kết nối chat: $e'),
            action: SnackBarAction(label: 'Thử lại', onPressed: _initialize),
          ),
        );
      }
    }
  }

  Future<void> _loadMessages() async {
    try {
      print('📱 Đang tải lịch sử chat...');
      final messages = await _chatService.fetchMessages(widget.roomId);

      if (mounted) {
        setState(() {
          _messages = messages;
        });
        _scrollToBottom();
      }
    } catch (e) {
      print('❌ Lỗi khi tải tin nhắn: $e');
    }
  }

  Future<void> _connectWebSocket() async {
    try {
      print('🔌 Đang kết nối WebSocket...');
      await _webSocketService.connectForChat(widget.roomId, _handleNewMessage);
    } catch (e) {
      print('❌ Lỗi khi kết nối WebSocket: $e');
    }
  }

  void _handleNewMessage(ChatMessage message) {
    if (mounted) {
      setState(() {
        _messages.add(message);
      });
      _scrollToBottom();
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _isSending) return;

    final content = _messageController.text.trim();
    _messageController.clear();

    setState(() {
      _isSending = true;
    });

    try {
      final message = ChatMessage(
        roomId: widget.roomId,
        senderEmail: _userEmail!,
        senderName: _userName ?? 'Unknown',
        receiverEmail: widget.partnerEmail,
        content: content,
        timestamp: DateTime.now(),
        read: false,
      );

      // Gửi qua WebSocket
      await _webSocketService.sendMessage(widget.roomId, message);

      // Thêm vào UI ngay lập tức
      setState(() {
        _messages.add(message);
      });
      _scrollToBottom();
    } catch (e) {
      print('❌ Lỗi khi gửi tin nhắn: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Không thể gửi tin nhắn: $e')));
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _toggleEmojiPicker() {
    setState(() {
      _showEmojiPicker = !_showEmojiPicker;
    });
  }

  void _selectEmoji(String emoji) {
    _messageController.text += emoji;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.partnerName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              widget.partnerEmail,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF002D72),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // TODO: Implement more options
            },
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  // Messages list
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        final isMe = message.senderEmail == _userEmail;

                        return _buildMessageBubble(message, isMe);
                      },
                    ),
                  ),

                  // Emoji picker
                  if (_showEmojiPicker) _buildEmojiPicker(),

                  // Message input
                  _buildMessageInput(),
                ],
              ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF00AEEF) : Colors.grey[300],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMe) ...[
              Text(
                message.senderName,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 4),
            ],
            Text(
              message.content,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black87,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('HH:mm').format(message.timestamp),
              style: TextStyle(
                color: isMe ? Colors.white70 : Colors.black54,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmojiPicker() {
    return Container(
      height: 200,
      color: Colors.grey[100],
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 8,
          childAspectRatio: 1,
        ),
        itemCount: 80, // Số lượng emoji
        itemBuilder: (context, index) {
          final emoji = String.fromCharCode(0x1F600 + index);
          return GestureDetector(
            onTap: () => _selectEmoji(emoji),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 24)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.emoji_emotions),
            onPressed: _toggleEmojiPicker,
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: 'Nhập tin nhắn...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              maxLines: null,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon:
                _isSending
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Icon(Icons.send),
            onPressed: _isSending ? null : _sendMessage,
          ),
        ],
      ),
    );
  }
}
