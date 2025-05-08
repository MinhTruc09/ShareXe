import 'package:flutter/material.dart';
import '../../../services/profile_service.dart';
import '../../../services/chat_service.dart';
import '../../../services/auth_manager.dart';
import 'chat_room_screen.dart';
import 'package:flutter/foundation.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({Key? key}) : super(key: key);

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  final ChatService _chatService = ChatService();
  final AuthManager _authManager = AuthManager();

  bool _isLoading = true;
  List<Map<String, dynamic>> _users = [];
  String? _currentUserEmail;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Lấy email của người dùng hiện tại
      _currentUserEmail = await _authManager.getUserEmail();

      // Lấy danh sách người dùng từ API
      final response = await _fetchUsers();

      setState(() {
        _users = response;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể tải danh sách người dùng: $e')),
        );
      }
    }
  }

  // Gọi API để lấy danh sách người dùng có thể chat
  Future<List<Map<String, dynamic>>> _fetchUsers() async {
    try {
      // Lấy vai trò người dùng hiện tại
      final currentUserRole = await _authManager.getUserRole();

      if (currentUserRole == null) {
        throw Exception('Không thể xác định vai trò người dùng');
      }

      // Xác định danh sách cần lấy (tài xế cần danh sách hành khách và ngược lại)
      final targetRole = currentUserRole == 'DRIVER' ? 'PASSENGER' : 'DRIVER';

      // Đối với demo, sử dụng dữ liệu giả
      final bool useRealApi = false; // Đặt thành true khi có API thực

      if (useRealApi) {
        // TODO: Gọi API thực khi có endpoint
        // final response = await http.get(Uri.parse('${AppConfig().fullApiUrl}/users?role=$targetRole'));
        // if (response.statusCode == 200) {
        //   final data = jsonDecode(response.body);
        //   return List<Map<String, dynamic>>.from(data['data']);
        // }
        throw Exception('API chưa được triển khai');
      } else {
        // Dữ liệu mẫu cho demo
        // Khi vai trò là tài xế, hiển thị các hành khách và ngược lại
        if (targetRole == 'PASSENGER') {
          return [
            {
              'email': 'khachvip1@gmail.com',
              'fullName': 'Khách VIP 1',
              'role': 'PASSENGER',
              'avatarUrl': null,
            },
            {
              'email': 'khachvip2@gmail.com',
              'fullName': 'Khách VIP 2',
              'role': 'PASSENGER',
              'avatarUrl': null,
            },
          ];
        } else {
          return [
            {
              'email': 'xeom1@gmail.com',
              'fullName': 'Tài Xế Honda',
              'role': 'DRIVER',
              'avatarUrl': null,
            },
            {
              'email': 'xeom2@gmail.com',
              'fullName': 'Tài Xế Yamaha',
              'role': 'DRIVER',
              'avatarUrl': null,
            },
          ];
        }
      }
    } catch (e) {
      print('Lỗi khi lấy danh sách người dùng: $e');
      return [];
    }
  }

  Future<void> _createChatWithUser(
    String receiverEmail,
    String receiverName,
  ) async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (kDebugMode) {
        print('Bắt đầu tạo phòng chat với: $receiverEmail');
      }

      // Tạo phòng chat hoặc lấy phòng chat hiện có
      final roomId = await _chatService.createOrGetChatRoom(receiverEmail);

      if (roomId != null) {
        if (kDebugMode) {
          print('Tạo phòng chat thành công với ID: $roomId');
        }

        if (mounted) {
          setState(() {
            _isLoading = false;
          });

          // Chuyển đến màn hình chat
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => ChatRoomScreen(
                    roomId: roomId,
                    partnerName: receiverName,
                    partnerEmail: receiverEmail,
                  ),
            ),
          );
        }
      } else {
        if (kDebugMode) {
          print('Không thể tạo phòng chat: roomId là null');
        }
        throw Exception('Không thể tạo phòng chat');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Lỗi khi tạo phòng chat: $e');
      }

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Không thể tạo cuộc trò chuyện: ${e.toString().contains('403') ? 'Không có quyền truy cập' : e}',
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Người dùng'),
        backgroundColor: const Color(0xFF002D72),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _loadUsers,
                child:
                    _users.isEmpty
                        ? const Center(
                          child: Text('Không tìm thấy người dùng nào'),
                        )
                        : ListView.builder(
                          itemCount: _users.length,
                          itemBuilder: (context, index) {
                            final user = _users[index];
                            final email = user['email'] ?? '';
                            final fullName = user['fullName'] ?? 'Người dùng';
                            final role = user['role'] ?? '';
                            final avatarUrl = user['avatarUrl'];

                            // Bỏ qua người dùng hiện tại
                            if (email == _currentUserEmail) {
                              return const SizedBox.shrink();
                            }

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                                vertical: 4.0,
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor:
                                      role == 'DRIVER'
                                          ? const Color(0xFF002D72)
                                          : const Color(0xFF00AEEF),
                                  backgroundImage:
                                      avatarUrl != null
                                          ? NetworkImage(avatarUrl)
                                          : null,
                                  child:
                                      avatarUrl == null
                                          ? Text(
                                            fullName.isNotEmpty
                                                ? fullName[0].toUpperCase()
                                                : '?',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          )
                                          : null,
                                ),
                                title: Text(
                                  fullName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  role == 'DRIVER' ? 'Tài xế' : 'Hành khách',
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.chat_bubble_outline),
                                  onPressed:
                                      () =>
                                          _createChatWithUser(email, fullName),
                                ),
                                onTap:
                                    () => _createChatWithUser(email, fullName),
                              ),
                            );
                          },
                        ),
              ),
    );
  }
}
