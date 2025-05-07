import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/chat_service.dart';
import 'chat_room_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ChatService _chatService = ChatService();
  List<Map<String, dynamic>> _chatRooms = [];
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
      final chatRooms = await _chatService.getChatRooms();
      setState(() {
        _chatRooms = chatRooms;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể tải danh sách chat: $e')),
        );
      }
    }
  }
  
  void _navigateToChatRoom(String roomId, String partnerName, String partnerEmail) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatRoomScreen(
          roomId: roomId,
          partnerName: partnerName,
          partnerEmail: partnerEmail,
        ),
      ),
    ).then((_) {
      // Reload chat list when returning from chat room
      _loadChatRooms();
    });
  }
  
  String _formatDateTime(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
      
      if (messageDate == today) {
        return DateFormat('HH:mm').format(dateTime);
      } else if (today.difference(messageDate).inDays <= 7) {
        return DateFormat('E').format(dateTime); // Day of week
      } else {
        return DateFormat('dd/MM/yyyy').format(dateTime);
      }
    } catch (e) {
      return '';
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trò chuyện'),
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
                          const Icon(
                            Icons.chat_bubble_outline,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Bạn chưa có cuộc trò chuyện nào',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 32),
                          ElevatedButton(
                            onPressed: _loadChatRooms,
                            child: const Text('Làm mới'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _chatRooms.length,
                      itemBuilder: (context, index) {
                        final room = _chatRooms[index];
                        final partnerName = room['partnerName'] ?? 'Người dùng';
                        final lastMessage = room['lastMessage'] ?? '';
                        final lastMessageTime = room['lastMessageTime'] ?? '';
                        final unreadCount = room['unreadCount'] ?? 0;
                        final roomId = room['roomId'] ?? '';
                        final partnerEmail = room['partnerEmail'] ?? '';
                        final partnerAvatar = room['partnerAvatar'];
                        
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 4.0,
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFF002D72),
                              backgroundImage: partnerAvatar != null
                                  ? NetworkImage(partnerAvatar)
                                  : null,
                              child: partnerAvatar == null
                                  ? Text(
                                      partnerName.isNotEmpty
                                          ? partnerName[0].toUpperCase()
                                          : '?',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : null,
                            ),
                            title: Text(
                              partnerName,
                              style: TextStyle(
                                fontWeight: unreadCount > 0
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            subtitle: Text(
                              lastMessage,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  _formatDateTime(lastMessageTime),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                if (unreadCount > 0)
                                  Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.blue,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      unreadCount.toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            onTap: () => _navigateToChatRoom(
                              roomId,
                              partnerName,
                              partnerEmail,
                            ),
                          ),
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Implement new chat functionality
          // This would typically open a contact list
        },
        backgroundColor: const Color(0xFF002D72),
        child: const Icon(Icons.chat),
      ),
    );
  }
} 