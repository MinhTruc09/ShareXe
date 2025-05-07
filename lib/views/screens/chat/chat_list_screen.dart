import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/chat_room_model.dart';
import '../../../services/chat_service.dart';
import 'chat_detail_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ChatService _chatService = ChatService();
  List<ChatRoom> _chatRooms = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadChatRooms();
  }
  
  Future<void> _loadChatRooms() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // In a real app, this would call the API
      // final chatRooms = await _chatService.getChatRooms();
      
      // For demo purposes, use mock data
      final chatRooms = _chatService.getMockChatRooms();
      
      setState(() {
        _chatRooms = chatRooms;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading chat rooms: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return DateFormat('dd/MM/yyyy').format(dateTime);
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tin nhắn'),
        backgroundColor: const Color(0xFF002D72),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadChatRooms,
              child: _chatRooms.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.message_outlined, 
                            size: 80, 
                            color: Colors.grey.shade400
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Chưa có cuộc trò chuyện nào',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tin nhắn từ tài xế sẽ xuất hiện ở đây',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _chatRooms.length,
                      itemBuilder: (context, index) {
                        final room = _chatRooms[index];
                        return _buildChatRoomItem(room);
                      },
                    ),
            ),
    );
  }
  
  Widget _buildChatRoomItem(ChatRoom room) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatDetailScreen(chatRoomId: room.id),
            ),
          ).then((_) => _loadChatRooms()); // Reload after returning
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: room.userAvatar.isNotEmpty
                    ? NetworkImage(room.userAvatar)
                    : null,
                child: room.userAvatar.isEmpty
                    ? const Icon(Icons.person, size: 28, color: Colors.grey)
                    : null,
              ),
              const SizedBox(width: 12),
              
              // Chat info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            room.userName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          _formatTime(room.lastMessageTime),
                          style: TextStyle(
                            fontSize: 12,
                            color: room.unreadCount > 0
                                ? const Color(0xFF002D72)
                                : Colors.grey,
                            fontWeight: room.unreadCount > 0
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            room.lastMessage,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: room.unreadCount > 0
                                  ? Colors.black
                                  : Colors.grey.shade600,
                              fontWeight: room.unreadCount > 0
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (room.unreadCount > 0)
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Color(0xFF002D72),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              room.unreadCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 