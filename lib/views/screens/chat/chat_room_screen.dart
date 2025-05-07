import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../../models/chat_message_model.dart';
import '../../../services/chat_service.dart';
import '../../../services/websocket_service.dart';

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
    _loadChatHistory();
    _setupWebSocketListener();
    
    // Mark all messages as read when entering the room
    _chatService.markMessagesAsRead(widget.roomId);
  }
  
  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _chatSubscription?.cancel();
    super.dispose();
  }
  
  void _setupWebSocketListener() {
    _webSocketService.onChatMessageReceived = (message) {
      if (message.roomId == widget.roomId) {
        setState(() {
          _messages.insert(0, message);
        });
        
        // Mark message as read immediately if we're in the room
        _chatService.markMessagesAsRead(widget.roomId);
      }
    };
  }
  
  Future<void> _loadChatHistory() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final messages = await _chatService.getChatHistory(widget.roomId);
      setState(() {
        _messages = messages;
        _isLoading = false;
      });
      
      // Scroll to bottom after messages load
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể tải tin nhắn: $e')),
        );
      }
    }
  }
  
  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;
    
    setState(() {
      _isSending = true;
    });
    
    _messageController.clear();
    
    try {
      final success = await _chatService.sendMessage(
        widget.roomId,
        widget.partnerEmail,
        message,
      );
      
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể gửi tin nhắn')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
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
            child: _isLoading
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
                    decoration: const InputDecoration(
                      hintText: 'Nhắn tin...',
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
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: isMyMessage
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
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
                color: isMyMessage 
                    ? const Color(0xFF0078FF)
                    : const Color(0xFFE4E6EB),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(
                      color: isMyMessage ? Colors.white : Colors.black,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    messageTime,
                    style: TextStyle(
                      color: isMyMessage 
                          ? Colors.white.withOpacity(0.7) 
                          : Colors.black.withOpacity(0.6),
                      fontSize: 12,
                    ),
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