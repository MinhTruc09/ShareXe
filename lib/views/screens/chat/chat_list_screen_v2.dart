import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/chat_message.dart';
import '../../../services/chat_service.dart';
import '../../../services/auth_manager.dart';
import 'chat_room_screen_v2.dart';

class ChatListScreenV2 extends StatefulWidget {
  const ChatListScreenV2({Key? key}) : super(key: key);

  @override
  State<ChatListScreenV2> createState() => _ChatListScreenV2State();
}

class _ChatListScreenV2State extends State<ChatListScreenV2> {
  final ChatService _chatService = ChatService();
  final AuthManager _authManager = AuthManager();

  List<ChatRoom> _chatRooms = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _loadChatRooms();
    } catch (e) {
      print('❌ Lỗi khi khởi tạo chat list: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadChatRooms() async {
    try {
      print('📱 Đang tải danh sách phòng chat...');
      final rooms = await _chatService.fetchChatRooms();

      if (mounted) {
        setState(() {
          _chatRooms = rooms;
        });
      }
    } catch (e) {
      print('❌ Lỗi khi tải danh sách phòng chat: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể tải danh sách chat: $e'),
            action: SnackBarAction(label: 'Thử lại', onPressed: _loadChatRooms),
          ),
        );
      }
    }
  }

  Future<void> _startChatWithUser(String otherUserEmail) async {
    try {
      print('📱 Đang tạo phòng chat với: $otherUserEmail');

      // Lấy room ID
      final roomId = await _chatService.getChatRoomId(otherUserEmail);

      // Navigate to chat room
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => ChatRoomScreenV2(
                  roomId: roomId,
                  partnerName: otherUserEmail, // Có thể lấy tên từ API
                  partnerEmail: otherUserEmail,
                ),
          ),
        );
      }
    } catch (e) {
      print('❌ Lỗi khi tạo phòng chat: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Không thể tạo phòng chat: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tin nhắn'),
        backgroundColor: const Color(0xFF002D72),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadChatRooms,
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _chatRooms.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                onRefresh: _loadChatRooms,
                child: ListView.builder(
                  itemCount: _chatRooms.length,
                  itemBuilder: (context, index) {
                    final room = _chatRooms[index];
                    return _buildChatRoomItem(room);
                  },
                ),
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showNewChatDialog,
        backgroundColor: const Color(0xFF00AEEF),
        child: const Icon(Icons.chat, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Chưa có cuộc trò chuyện nào',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Nhấn nút + để bắt đầu trò chuyện',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildChatRoomItem(ChatRoom room) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: const Color(0xFF00AEEF),
        child: Text(
          room.partnerName.isNotEmpty ? room.partnerName[0].toUpperCase() : '?',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        room.partnerName,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        room.lastMessage ?? 'Chưa có tin nhắn',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (room.lastMessageTime != null)
            Text(
              DateFormat('HH:mm').format(room.lastMessageTime!),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          if (room.unreadCount > 0)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: const BoxDecoration(
                color: Color(0xFF00AEEF),
                borderRadius: BorderRadius.all(Radius.circular(10)),
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
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => ChatRoomScreenV2(
                  roomId: room.roomId,
                  partnerName: room.partnerName,
                  partnerEmail: room.partnerEmail,
                ),
          ),
        );
      },
    );
  }

  void _showNewChatDialog() {
    final TextEditingController emailController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Bắt đầu trò chuyện mới'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Nhập email của người bạn muốn trò chuyện:'),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'example@gmail.com',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: () {
                  final email = emailController.text.trim();
                  if (email.isNotEmpty) {
                    Navigator.pop(context);
                    _startChatWithUser(email);
                  }
                },
                child: const Text('Bắt đầu'),
              ),
            ],
          ),
    );
  }
}
