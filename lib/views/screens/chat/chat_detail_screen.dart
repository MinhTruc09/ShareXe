import 'package:flutter/material.dart';
import '../../../models/chat_message_model.dart';
import '../../../models/chat_room_model.dart';
import '../../../services/chat_service.dart';
import 'package:intl/intl.dart';

class ChatDetailScreen extends StatefulWidget {
  final String chatRoomId;

  const ChatDetailScreen({
    Key? key,
    required this.chatRoomId,
  }) : super(key: key);

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  final ScrollController _scrollController = ScrollController();
  
  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  ChatRoom? _chatRoom;
  bool _isSending = false;
  final String _currentUserId = 'currentuser'; // This would come from auth in a real app
  
  @override
  void initState() {
    super.initState();
    _loadChatDetails();
  }
  
  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  Future<void> _loadChatDetails() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Get chat room details - in a real app this would use the API
      final chatRooms = _chatService.getMockChatRooms();
      final room = chatRooms.firstWhere(
        (room) => room.id == widget.chatRoomId,
        orElse: () => ChatRoom(
          id: widget.chatRoomId,
          userId: 'unknown',
          userName: 'Unknown User',
          userAvatar: '',
          lastMessage: '',
          lastMessageTime: DateTime.now(),
          unreadCount: 0,
          rideId: '',
        ),
      );
      
      // Get chat messages - in a real app this would use the API
      final messages = _chatService.getMockChatHistory(widget.chatRoomId);
      
      setState(() {
        _chatRoom = room;
        _messages = messages;
        _isLoading = false;
      });
      
      // Mark messages as read in a real app
      // await _chatService.markAsRead(widget.chatRoomId);
      
      // Scroll to bottom after loading messages
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } catch (e) {
      print('Error loading chat: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }
  
  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _chatRoom == null) return;
    
    setState(() {
      _isSending = true;
    });
    
    try {
      // In a real app, we would send the message to the API
      // final success = await _chatService.sendMessage(
      //   _chatRoom!.userId,
      //   message,
      //   _chatRoom!.rideId,
      // );
      
      // For demo purposes, just simulate success
      const success = true;
      
      if (success) {
        // Create a temporary message to display immediately
        final newMessage = ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch,
          senderId: _currentUserId,
          receiverId: _chatRoom!.userId,
          message: message,
          messageType: 'text',
          timestamp: DateTime.now(),
          isRead: false,
        );
        
        setState(() {
          _messages.add(newMessage);
          _messageController.clear();
          _isSending = false;
        });
        
        // Scroll to bottom to show the new message
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể gửi tin nhắn')),
        );
        setState(() {
          _isSending = false;
        });
      }
    } catch (e) {
      print('Error sending message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
      setState(() {
        _isSending = false;
      });
    }
  }
  
  String _formatTime(DateTime dateTime) {
    return DateFormat('HH:mm').format(dateTime);
  }
  
  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    
    if (messageDate == today) {
      return 'Hôm nay';
    } else if (messageDate == yesterday) {
      return 'Hôm qua';
    } else {
      return DateFormat('dd/MM/yyyy').format(dateTime);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF002D72),
        title: _isLoading || _chatRoom == null
            ? const Text('Đang tải...')
            : Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: _chatRoom!.userAvatar.isNotEmpty
                        ? NetworkImage(_chatRoom!.userAvatar)
                        : null,
                    child: _chatRoom!.userAvatar.isEmpty
                        ? const Icon(Icons.person, size: 16, color: Colors.grey)
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _chatRoom!.userName,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              // Show ride details
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Messages list
                Expanded(
                  child: _messages.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Chưa có tin nhắn nào',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Hãy bắt đầu cuộc trò chuyện!',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final message = _messages[index];
                            final isCurrentUser = message.senderId == _currentUserId;
                            
                            // Show date headers
                            final showDateHeader = index == 0 ||
                                _formatDate(_messages[index].timestamp) !=
                                    _formatDate(_messages[index - 1].timestamp);
                            
                            return Column(
                              children: [
                                if (showDateHeader)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    child: Center(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade200,
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Text(
                                          _formatDate(message.timestamp),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                _buildMessageBubble(
                                  message,
                                  isCurrentUser,
                                ),
                              ],
                            );
                          },
                        ),
                ),
                
                // Message input
                Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 8,
                        color: Colors.black.withOpacity(0.1),
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        // Input field
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: TextField(
                              controller: _messageController,
                              decoration: const InputDecoration(
                                hintText: 'Nhập tin nhắn...',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                              ),
                              textInputAction: TextInputAction.send,
                              onSubmitted: (_) => _sendMessage(),
                            ),
                          ),
                        ),
                        
                        // Send button
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          child: FloatingActionButton(
                            onPressed: _isSending ? null : _sendMessage,
                            backgroundColor: const Color(0xFF002D72),
                            elevation: 0,
                            mini: true,
                            child: _isSending
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.send),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
  
  Widget _buildMessageBubble(ChatMessage message, bool isCurrentUser) {
    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(
          top: 4,
          bottom: 4,
          left: 8,
          right: 8,
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isCurrentUser 
              ? const Color(0xFF002D72)
              : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomLeft: isCurrentUser ? const Radius.circular(16) : const Radius.circular(0),
            bottomRight: isCurrentUser ? const Radius.circular(0) : const Radius.circular(16),
          ),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Message content
            Text(
              message.message,
              style: TextStyle(
                color: isCurrentUser ? Colors.white : Colors.black87,
                fontSize: 16,
              ),
            ),
            
            // Message time
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _formatTime(message.timestamp),
                style: TextStyle(
                  color: isCurrentUser 
                      ? Colors.white.withOpacity(0.7)
                      : Colors.grey.shade600,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 