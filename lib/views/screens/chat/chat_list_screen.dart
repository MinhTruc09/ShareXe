import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/chat_service.dart';
import 'chat_room_screen.dart';
import 'user_list_screen.dart';
import 'package:flutter/foundation.dart';

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
    _loadChatList();

    // Kiểm tra kết nối API khi mở màn hình
    _checkApiConnection();
  }

  Future<void> _loadChatList() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (kDebugMode) {
        print('Đang tải danh sách phòng chat...');
      }

      // Tải danh sách phòng chat từ server
      final chatRooms = await _chatService.getChatRooms();

      if (kDebugMode) {
        print('Đã tải ${chatRooms.length} phòng chat');
        if (chatRooms.isNotEmpty) {
          print(
            'Phòng chat đầu tiên: ${chatRooms.first['partnerName'] ?? 'Unknown'}',
          );
        }
      }

      setState(() {
        _chatRooms = chatRooms;
        _isLoading = false;
      });

      // Hiển thị thông báo nếu không có phòng chat nào
      if (chatRooms.isEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Bạn chưa có cuộc trò chuyện nào. Hãy bắt đầu cuộc trò chuyện với tài xế hoặc hành khách!',
            ),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Lỗi khi tải danh sách phòng chat: $e');
      }

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Không thể tải danh sách chat: ${e.toString().contains('403') ? 'Không có quyền truy cập' : e}',
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Kiểm tra kết nối API
  Future<void> _checkApiConnection() async {
    try {
      final isConnected = await _chatService.checkApiConnection();
      if (mounted) {
        // Hiển thị thông báo dựa trên trạng thái kết nối
        if (isConnected) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Đã kết nối tới máy chủ. Đang sử dụng chế độ trực tuyến.',
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Không thể kết nối tới máy chủ. Đang sử dụng chế độ ngoại tuyến.',
              ),
              backgroundColor: Colors.orange.shade800,
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'Thử lại',
                textColor: Colors.white,
                onPressed: _checkApiConnection,
              ),
            ),
          );
        }
      }
    } catch (e) {
      print('Lỗi khi kiểm tra kết nối API: $e');
    }
  }

  void _navigateToChatRoom(
    String roomId,
    String partnerName,
    String partnerEmail,
  ) {
    if (kDebugMode) {
      print(
        'Điều hướng đến phòng chat $roomId với $partnerName ($partnerEmail)',
      );
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ChatRoomScreen(
              roomId: roomId,
              partnerName: partnerName,
              partnerEmail: partnerEmail,
            ),
      ),
    ).then((_) {
      // Reload chat list when returning from chat room
      _loadChatList();
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
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _loadChatList,
                child:
                    _chatRooms.isEmpty
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
                                onPressed: _loadChatList,
                                child: const Text('Làm mới'),
                              ),
                            ],
                          ),
                        )
                        : ListView.builder(
                          itemCount: _chatRooms.length,
                          itemBuilder: (context, index) {
                            final room = _chatRooms[index];
                            final partnerName =
                                room['partnerName'] ?? 'Người dùng';
                            final lastMessage = room['lastMessage'] ?? '';
                            final lastMessageTime =
                                room['lastMessageTime'] ?? '';
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
                                  backgroundImage:
                                      partnerAvatar != null
                                          ? NetworkImage(partnerAvatar)
                                          : null,
                                  child:
                                      partnerAvatar == null
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
                                    fontWeight:
                                        unreadCount > 0
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
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
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
                                onTap:
                                    () => _navigateToChatRoom(
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
          // Mở màn hình danh sách người dùng để bắt đầu chat mới
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const UserListScreen()),
          ).then((_) {
            // Làm mới danh sách chat khi quay lại
            _loadChatList();
          });
        },
        backgroundColor: const Color(0xFF002D72),
        child: const Icon(Icons.chat),
      ),
    );
  }
}
