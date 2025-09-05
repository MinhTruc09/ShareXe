import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../../services/chat_service.dart';
import '../../../services/auth_manager.dart';
import 'chat_room_screen.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({Key? key}) : super(key: key);

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  final ChatService _chatService = ChatService();
  final AuthManager _authManager = AuthManager();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _chatRooms = [];
  bool _isLoading = true;
  String? _userEmail;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _initialize();

    // Cập nhật danh sách chat mỗi 30 giây
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _loadChatRooms();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _initialize() async {
    _userEmail = await _authManager.getUserEmail();
    await _loadChatRooms();
  }

  Future<void> _loadChatRooms() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _chatService.getChatRooms();

      if (response.success) {
        if (mounted) {
          setState(() {
            _chatRooms = response.data;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Không thể tải danh sách chat: ${response.message}',
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể tải danh sách chat: $e')),
        );
      }
    }
  }

  void _searchChats(String query) {
    // TODO: Thêm chức năng tìm kiếm chat sau này
  }

  String _formatLastMessageTime(String? timestamp) {
    if (timestamp == null) return '';

    try {
      final DateTime messageTime = DateTime.parse(timestamp);
      final DateTime now = DateTime.now();
      final Duration difference = now.difference(messageTime);

      if (difference.inDays == 0) {
        return DateFormat('HH:mm').format(messageTime);
      } else if (difference.inDays == 1) {
        return 'Hôm qua';
      } else if (difference.inDays < 7) {
        return DateFormat('EEEE', 'vi_VN').format(messageTime);
      } else {
        return DateFormat('dd/MM/yyyy').format(messageTime);
      }
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tin nhắn',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF002D72),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _chatRooms.isEmpty
                    ? _buildEmptyState()
                    : _buildChatList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Tìm kiếm cuộc trò chuyện...',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          filled: true,
          fillColor: Colors.grey.shade100,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: _searchChats,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          const Text(
            'Bạn chưa có cuộc trò chuyện nào',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          const Text(
            'Khi bạn đặt chuyến đi, bạn có thể nhắn tin với tài xế',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildChatList() {
    return RefreshIndicator(
      onRefresh: _loadChatRooms,
      child: ListView.separated(
        itemCount: _chatRooms.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final chatRoom = _chatRooms[index];
          final bool hasUnreadMessages = chatRoom['unreadCount'] > 0;

          return ListTile(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => ChatRoomScreen(
                        roomId: chatRoom['roomId'],
                        partnerName: chatRoom['partnerName'],
                        partnerEmail: chatRoom['partnerEmail'],
                      ),
                ),
              ).then((_) => _loadChatRooms());
            },
            leading: CircleAvatar(
              radius: 28,
              backgroundColor: const Color(0xFF00AEEF).withOpacity(0.2),
              child: Icon(
                Icons.person,
                color: const Color(0xFF002D72),
                size: 30,
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    chatRoom['partnerName'] ?? 'Người dùng',
                    style: TextStyle(
                      fontWeight:
                          hasUnreadMessages
                              ? FontWeight.bold
                              : FontWeight.normal,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  _formatLastMessageTime(chatRoom['lastMessageTime']),
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        hasUnreadMessages
                            ? const Color(0xFF00AEEF)
                            : Colors.grey,
                  ),
                ),
              ],
            ),
            subtitle: Row(
              children: [
                Expanded(
                  child: Text(
                    chatRoom['lastMessage'] ?? 'Chưa có tin nhắn',
                    style: TextStyle(
                      color: hasUnreadMessages ? Colors.black87 : Colors.grey,
                      fontWeight:
                          hasUnreadMessages
                              ? FontWeight.w500
                              : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (hasUnreadMessages)
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Color(0xFF00AEEF),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      chatRoom['unreadCount'].toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
              ],
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
          );
        },
      ),
    );
  }
}
