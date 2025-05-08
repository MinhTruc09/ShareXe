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
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

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
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  List<ChatMessageModel> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  String? _userEmail;
  StreamSubscription? _chatSubscription;
  Timer? _refreshTimer;
  bool _isMockRoom = false;

  @override
  void initState() {
    super.initState();
    _isMockRoom = widget.roomId.startsWith('mock_');
    _initializeChat();

    // Nếu là phòng chat mô phỏng, thiết lập timer để tự động làm mới
    if (_isMockRoom) {
      _setupRefreshTimer();
      _setupFirebaseListener();
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _chatSubscription?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }

  // Thiết lập timer định kỳ làm mới tin nhắn cho phòng chat mô phỏng
  void _setupRefreshTimer() {
    // Hủy timer cũ nếu có
    _refreshTimer?.cancel();

    // Thiết lập timer mới - làm mới mỗi 3 giây
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted && _isMockRoom) {
        _refreshMessages();
      }
    });
  }

  // Làm mới tin nhắn mà không cần hiển thị loading
  Future<void> _refreshMessages() async {
    try {
      if (!mounted || !_isMockRoom) return;

      if (kDebugMode) {
        print('Đang làm mới tin nhắn cho phòng ${widget.roomId}');
      }

      final localMessages = await _chatLocalStorage.getMessages(widget.roomId);

      if (localMessages.isNotEmpty && mounted) {
        setState(() {
          _messages = localMessages;
        });

        if (kDebugMode) {
          print('Đã làm mới ${localMessages.length} tin nhắn');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Lỗi khi làm mới tin nhắn: $e');
      }
    }
  }

  Future<void> _initializeChat() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Kiểm tra kết nối API trước khi khởi tạo chat
      await _chatService.checkApiConnection();

      // Lấy email người dùng để phân biệt tin nhắn của mình
      _userEmail = await _authManager.getUserEmail();

      if (_userEmail == null) {
        if (kDebugMode) {
          print('Không thể lấy email người dùng');
        }
        throw Exception('Không thể lấy email người dùng');
      }

      if (kDebugMode) {
        print('Bắt đầu khởi tạo chat phòng ${widget.roomId}');
        print('Email người dùng: $_userEmail');
        print('Partner email: ${widget.partnerEmail}');
      }

      // Kiểm tra nếu đây là phòng chat mô phỏng
      final bool isMockRoom = widget.roomId.startsWith('mock_');
      _isMockRoom = isMockRoom || _chatService.getMockModeStatus();

      if (_isMockRoom) {
        if (kDebugMode) {
          print('Đây là phòng chat mô phỏng: ${widget.roomId}');
        }

        // Hiển thị thông báo nếu đang sử dụng phòng chat mô phỏng
        if (mounted) {
          Future.delayed(const Duration(milliseconds: 500), () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'Đang sử dụng chế độ chat ngoại tuyến. Tin nhắn sẽ được lưu cục bộ.',
                ),
                backgroundColor: Colors.orange.shade800,
                duration: const Duration(seconds: 4),
                action: SnackBarAction(
                  label: 'Chuyển chế độ',
                  onPressed: () {
                    // Chuyển đổi chế độ chat
                    final isStillMocked = _chatService.toggleMockMode();
                    setState(() {
                      _isMockRoom =
                          isStillMocked || widget.roomId.startsWith('mock_');
                    });

                    // Kiểm tra kết nối API
                    _chatService.checkApiConnection();

                    // Làm mới tin nhắn
                    _refreshMessages();

                    // Hiển thị thông báo
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          _isMockRoom
                              ? 'Vẫn đang ở chế độ ngoại tuyến do ID phòng là giả lập.'
                              : 'Đã chuyển sang chế độ trực tuyến.',
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ),
            );
          });
        }
      }

      // Nếu không phải phòng mô phỏng, thử kết nối WebSocket
      if (!_isMockRoom) {
        try {
          // Kết nối WebSocket nếu không phải phòng chat mô phỏng
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

          _webSocketService.initialize(
            _appConfig.apiBaseUrl,
            token,
            _userEmail!,
          );
        } catch (wsError) {
          if (kDebugMode) {
            print('Không thể kết nối WebSocket: $wsError');
          }
          // Tiếp tục với các bước tiếp theo ngay cả khi WebSocket không kết nối được
        }
      }

      // Tải lịch sử chat
      await _loadChatHistory();

      // Thiết lập lắng nghe tin nhắn - Đặt sau khi tải lịch sử để tránh duplicate messages
      // Chỉ thiết lập nếu không phải phòng chat mô phỏng
      if (!_isMockRoom) {
        _setupWebSocketListener();
      } else {
        // Thiết lập Firebase listener cho phòng chat mô phỏng
        _setupFirebaseListener();
      }

      // Đánh dấu tin nhắn đã đọc nếu không phải phòng chat mô phỏng
      if (!_isMockRoom) {
        try {
          await _chatService.markMessagesAsRead(widget.roomId);
        } catch (e) {
          if (kDebugMode) {
            print('Lỗi khi đánh dấu tin nhắn đã đọc: $e');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Lỗi khởi tạo chat: $e');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Không thể kết nối tới máy chủ. Đang sử dụng dữ liệu ngoại tuyến.',
            ),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }

      // Trong trường hợp lỗi, vẫn cố gắng tải tin nhắn cục bộ nếu có
      final localMessages = await _chatLocalStorage.getMessages(widget.roomId);
      if (localMessages.isNotEmpty && mounted) {
        setState(() {
          _messages = localMessages;
        });
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
    if (kDebugMode) {
      print('Thiết lập người nghe WebSocket cho phòng ${widget.roomId}');
    }

    _webSocketService.onChatMessageReceived = (message) async {
      if (kDebugMode) {
        print('Nhận tin nhắn qua WebSocket: ${message.content}');
        print(
          'Phòng chat hiện tại: ${widget.roomId}, Phòng của tin nhắn: ${message.roomId}',
        );
      }

      // Chỉ hiển thị tin nhắn thuộc phòng chat hiện tại hoặc
      // tin nhắn từ/đến người dùng hiện tại và đối tác
      final isCurrentRoom = message.roomId == widget.roomId;
      final isFromCurrentUser = message.senderEmail == _userEmail;
      final isFromPartner = message.senderEmail == widget.partnerEmail;
      final isToCurrentUser = message.receiverEmail == _userEmail;
      final isToPartner = message.receiverEmail == widget.partnerEmail;

      final shouldDisplay =
          isCurrentRoom ||
          ((isFromCurrentUser || isToCurrentUser) &&
              (isFromPartner || isToPartner));

      if (shouldDisplay) {
        // Lưu tin nhắn vào bộ nhớ cục bộ
        await _chatLocalStorage.addMessage(widget.roomId, message);

        if (mounted) {
          setState(() {
            // Kiểm tra xem tin nhắn đã tồn tại chưa (tránh hiển thị trùng lặp)
            final isDuplicate = _messages.any(
              (msg) =>
                  msg.content == message.content &&
                  msg.senderEmail == message.senderEmail &&
                  msg.timestamp.isAtSameMomentAs(message.timestamp),
            );

            if (!isDuplicate) {
              // Thêm tin nhắn vào đầu danh sách vì ListView hiển thị ngược
              _messages.insert(0, message);
            }
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
      if (kDebugMode) {
        print('Đang tải lịch sử chat phòng ${widget.roomId}');
      }

      // Kiểm tra nếu đây là phòng chat mô phỏng
      final bool isMockRoom = widget.roomId.startsWith('mock_');

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

        // Nếu là phòng chat mô phỏng, không cần gọi API
        if (isMockRoom) {
          return;
        }
      }

      // Nếu không phải phòng chat mô phỏng, tải tin nhắn từ server để cập nhật
      if (!isMockRoom) {
        try {
          final serverMessages = await _chatService.getChatHistory(
            widget.roomId,
          );

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
          } else {
            if (kDebugMode) {
              print('Không có tin nhắn nào từ server');
            }
          }
        } catch (serverError) {
          // Nếu không thể tải từ server nhưng đã có tin nhắn cục bộ, tiếp tục sử dụng tin nhắn cục bộ
          if (kDebugMode) {
            print('Lỗi khi tải tin nhắn từ server: $serverError');
            print('Tiếp tục sử dụng ${localMessages.length} tin nhắn cục bộ');
          }

          // Nếu gặp lỗi 403 và không có tin nhắn cục bộ, tạo phòng chat mô phỏng
          if (serverError.toString().contains('403') && localMessages.isEmpty) {
            if (kDebugMode) {
              print('Lỗi quyền truy cập (403). Tạo phòng chat mô phỏng.');
            }

            // Hãy tạo tin nhắn mô phỏng
            await _createMockChatMessages();
          }
        }
      } else if (localMessages.isEmpty) {
        // Nếu là phòng chat mô phỏng nhưng không có tin nhắn cục bộ, tạo tin nhắn mô phỏng
        await _createMockChatMessages();
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

      // Đánh dấu tin nhắn đã đọc nếu không phải phòng mô phỏng
      if (!isMockRoom) {
        try {
          await _chatService.markMessagesAsRead(widget.roomId);
        } catch (e) {
          if (kDebugMode) {
            print('Lỗi khi đánh dấu tin nhắn đã đọc: $e');
          }
        }
      }
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

        // Tạo tin nhắn mô phỏng khi có lỗi và không có tin nhắn
        await _createMockChatMessages();
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Tạo tin nhắn mô phỏng cho phòng chat
  Future<void> _createMockChatMessages() async {
    try {
      if (kDebugMode) {
        print('Tạo tin nhắn mô phỏng cho phòng chat ${widget.roomId}');
      }

      final now = DateTime.now();
      final List<ChatMessageModel> mockMessages = [];

      // Thêm tin nhắn chào mừng từ hệ thống
      mockMessages.add(
        ChatMessageModel(
          id: 1,
          senderEmail: 'system@sharexe.vn',
          receiverEmail: _userEmail,
          senderName: 'ShareXe System',
          content:
              'Chào mừng đến với hệ thống chat của ShareXe. Tin nhắn giữa bạn và ${widget.partnerName} sẽ được lưu tại đây.',
          roomId: widget.roomId,
          timestamp: now.subtract(const Duration(minutes: 10)),
          read: true,
          status: 'sent',
        ),
      );

      // Thêm thông báo về chế độ ngoại tuyến
      mockMessages.add(
        ChatMessageModel(
          id: 2,
          senderEmail: 'system@sharexe.vn',
          receiverEmail: _userEmail,
          senderName: 'ShareXe System',
          content:
              'Hiện tại bạn đang ở chế độ ngoại tuyến hoặc không thể kết nối tới máy chủ. Tin nhắn sẽ được lưu cục bộ và đồng bộ khi kết nối được thiết lập.',
          roomId: widget.roomId,
          timestamp: now.subtract(const Duration(minutes: 8)),
          read: true,
          status: 'sent',
        ),
      );

      // Thêm một tin nhắn giả từ đối tác
      mockMessages.add(
        ChatMessageModel(
          id: 3,
          senderEmail: widget.partnerEmail,
          receiverEmail: _userEmail,
          senderName: widget.partnerName,
          content:
              'Xin chào, tôi là ${widget.partnerName}. Bạn cần hỗ trợ gì không?',
          roomId: widget.roomId,
          timestamp: now.subtract(const Duration(minutes: 5)),
          read: true,
          status: 'sent',
        ),
      );

      // Lưu tin nhắn vào bộ nhớ cục bộ
      await _chatLocalStorage.saveMessages(widget.roomId, mockMessages);

      if (mounted) {
        setState(() {
          _messages = mockMessages;
        });
      }

      if (kDebugMode) {
        print('Đã tạo ${mockMessages.length} tin nhắn mô phỏng');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Lỗi khi tạo tin nhắn mô phỏng: $e');
      }
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

    try {
      if (kDebugMode) {
        print('📤 Đang gửi tin nhắn: $message');
      }

      final username = await _authManager.getUsername() ?? 'Tôi';

      // Create message locally first for immediate display
      final chatMessage = ChatMessageModel(
        senderEmail: _userEmail,
        receiverEmail: widget.partnerEmail,
        senderName: username,
        content: message,
        roomId: widget.roomId,
        timestamp: DateTime.now(),
        read: false,
        status: 'sending',
      );

      // Immediately add to local storage and display
      await _chatLocalStorage.addMessage(widget.roomId, chatMessage);

      // Refresh to show message immediately
      setState(() {
        _refreshMessages();
      });

      // Debug Firebase connection
      await _testFirebaseConnection();

      // Sync directly to Firebase for mock chat room
      if (_isMockRoom) {
        try {
          if (kDebugMode) {
            print("📱 Đang sync tin nhắn tới Firebase: $message");
          }
          await _syncMockMessageToFirebase(widget.roomId, chatMessage);
          if (kDebugMode) {
            print("✅ Đã sync tin nhắn tới Firebase thành công");
          }
        } catch (e) {
          if (kDebugMode) {
            print("❌ Lỗi khi sync tin nhắn tới Firebase: $e");
          }
        }
      }

      // Also send through ChatService
      final success = await _chatService.sendMessage(
        widget.roomId,
        widget.partnerEmail,
        message,
      );

      if (success) {
        if (kDebugMode) {
          print("✅ Gửi tin nhắn thành công: $message");
        }

        // Cập nhật trạng thái tin nhắn là đã gửi thành công
        final messages = await _chatLocalStorage.getMessages(widget.roomId);
        for (final msg in messages) {
          if (msg.content == message &&
              msg.senderEmail == _userEmail &&
              msg.status == 'sending') {
            await _chatLocalStorage.updateMessageStatus(
              widget.roomId,
              msg,
              'sent',
            );
            break;
          }
        }
      } else {
        if (kDebugMode) {
          print("❌ Không thể gửi tin nhắn qua server: $message");
        }

        // Cập nhật trạng thái tin nhắn là thất bại
        final messages = await _chatLocalStorage.getMessages(widget.roomId);
        for (final msg in messages) {
          if (msg.content == message &&
              msg.senderEmail == _userEmail &&
              msg.status == 'sending') {
            await _chatLocalStorage.updateMessageStatus(
              widget.roomId,
              msg,
              'failed',
            );
            break;
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Không thể gửi tin nhắn'),
              action: SnackBarAction(
                label: 'Thử lại',
                onPressed: () => _retrySendMessage(message),
              ),
            ),
          );
        }
      }

      // Làm mới danh sách tin nhắn để cập nhật trạng thái
      _refreshMessages();
    } catch (e) {
      if (kDebugMode) {
        print("❌ Lỗi khi gửi tin nhắn: $e");
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Lỗi khi gửi tin nhắn: ${e.toString().substring(0, min(50, e.toString().length))}',
            ),
            action: SnackBarAction(
              label: 'Thử lại',
              onPressed: () => _retrySendMessage(message),
            ),
          ),
        );
      }
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  // Thử gửi lại tin nhắn đã thất bại
  Future<void> _retrySendMessage(String message) async {
    if (kDebugMode) {
      print('🔄 Đang thử gửi lại tin nhắn: $message');
    }

    setState(() {
      _isSending = true;
    });

    try {
      final success = await _chatService.sendMessage(
        widget.roomId,
        widget.partnerEmail,
        message,
      );

      if (success) {
        if (kDebugMode) {
          print('✅ Gửi lại tin nhắn thành công');
        }

        // Cập nhật trạng thái tin nhắn là đã gửi thành công
        final messages = await _chatLocalStorage.getMessages(widget.roomId);
        for (final msg in messages) {
          if (msg.content == message &&
              msg.senderEmail == _userEmail &&
              msg.status == 'failed') {
            await _chatLocalStorage.updateMessageStatus(
              widget.roomId,
              msg,
              'sent',
            );
            break;
          }
        }

        // Làm mới danh sách tin nhắn
        _refreshMessages();
      } else {
        if (kDebugMode) {
          print('❌ Gửi lại tin nhắn thất bại');
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không thể gửi lại tin nhắn')),
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Lỗi khi gửi lại tin nhắn: $e');
      }

      if (mounted) {
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
          if (_isMockRoom)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refreshMessages,
              tooltip: 'Làm mới tin nhắn',
            ),
          if (_isMockRoom)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _clearMockChat,
              tooltip: 'Xóa tất cả tin nhắn',
            ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              // Hiển thị thông tin về phòng chat
              _showChatInfo();
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
    final timeText = _formatMessageTime(message.timestamp);
    final bubbleColor =
        isMyMessage ? const Color(0xFF0084FF) : const Color(0xFFE4E6EB);
    final textColor = isMyMessage ? Colors.white : Colors.black87;

    // Hiển thị trạng thái tin nhắn
    Widget? statusIcon;
    if (isMyMessage) {
      if (message.status == 'sending') {
        statusIcon = const SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
          ),
        );
      } else if (message.status == 'sent') {
        statusIcon = const Icon(Icons.check, size: 12, color: Colors.white70);
      } else if (message.status == 'failed') {
        statusIcon = Icon(
          Icons.error_outline,
          size: 14,
          color: Colors.red.shade300,
        );
      } else if (message.read) {
        statusIcon = const Icon(
          Icons.done_all,
          size: 12,
          color: Colors.white70,
        );
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment:
            isMyMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMyMessage && !_isMockRoom)
            CircleAvatar(
              radius: 14,
              backgroundColor: Colors.grey.shade300,
              child: Text(
                message.senderName?.isNotEmpty == true
                    ? message.senderName![0].toUpperCase()
                    : '?',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          if (!isMyMessage) const SizedBox(width: 6),
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              child: Column(
                crossAxisAlignment:
                    isMyMessage
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                children: [
                  if (!isMyMessage && message.senderName != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 12.0, bottom: 2.0),
                      child: Text(
                        message.senderName!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  Stack(
                    children: [
                      Material(
                        borderRadius: BorderRadius.circular(18.0),
                        color: bubbleColor,
                        elevation: 0,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18.0),
                          onLongPress: () {
                            _showMessageOptions(message);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 10.0,
                            ),
                            child: Text(
                              message.content,
                              style: TextStyle(color: textColor, fontSize: 15),
                            ),
                          ),
                        ),
                      ),
                      // Tin nhắn thất bại hiển thị nút thử lại
                      if (isMyMessage && message.status == 'failed')
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () => _retrySendMessage(message.content),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.red.shade200,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.refresh,
                                    size: 12,
                                    color: Colors.red.shade700,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Thử lại',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.red.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 2.0,
                      left: 12.0,
                      right: 12.0,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          timeText,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        if (statusIcon != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 3.0),
                            child: statusIcon,
                          ),
                      ],
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

  // Hiển thị tùy chọn cho tin nhắn
  void _showMessageOptions(ChatMessageModel message) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text('Sao chép'),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: message.content));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã sao chép tin nhắn')),
                  );
                },
              ),
              if (message.senderEmail == _userEmail &&
                  message.status == 'failed')
                ListTile(
                  leading: const Icon(Icons.refresh),
                  title: const Text('Gửi lại'),
                  onTap: () {
                    Navigator.pop(context);
                    _retrySendMessage(message.content);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  // Hiển thị thông tin về phòng chat
  void _showChatInfo() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Thông tin phòng chat'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Phòng chat: ${widget.roomId}'),
                Text('Đối tác: ${widget.partnerName}'),
                Text('Email đối tác: ${widget.partnerEmail}'),
                Text('Chế độ ngoại tuyến: ${_isMockRoom ? 'Có' : 'Không'}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Đóng'),
              ),
            ],
          ),
    );
  }

  // Xóa tất cả tin nhắn trong phòng chat mô phỏng
  Future<void> _clearMockChat() async {
    try {
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Xác nhận'),
              content: const Text(
                'Bạn có chắc muốn xóa tất cả tin nhắn trong phòng chat này không?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Hủy'),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.of(context).pop();

                    // Hiển thị loading
                    setState(() {
                      _isLoading = true;
                    });

                    // Xóa tin nhắn
                    await _chatService.clearMockChat(widget.roomId);

                    // Làm mới danh sách tin nhắn
                    await _refreshMessages();

                    setState(() {
                      _isLoading = false;
                    });

                    // Hiển thị thông báo
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Đã xóa tất cả tin nhắn'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                  child: const Text('Xóa', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Lỗi khi xóa tin nhắn: $e');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi xóa tin nhắn: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _testFirebaseConnection() async {
    try {
      // Thực hiện ghi test vào Firebase
      await _database.ref('test_connection').set({
        'timestamp': DateTime.now().toIso8601String(),
        'message': 'Test connection',
      });
      print('Kết nối Firebase thành công');
    } catch (e) {
      print('Lỗi kết nối Firebase: $e');
    }
  }

  void _showRoomIdDebugInfo() {
    print('Phòng chat hiện tại: ${widget.roomId}');
    print('Partner email: ${widget.partnerEmail}');
    print('User email: $_userEmail');
  }

  Future<void> _syncMockMessageToFirebase(
    String roomId,
    ChatMessageModel message,
  ) async {
    try {
      if (kDebugMode) {
        print('Đồng bộ tin nhắn lên Firebase: ${message.content}');
      }

      // Chuyển đổi roomId thành định dạng an toàn cho Firebase (thay thế @ và dấu chấm)
      final String safeRoomId = roomId
          .replaceAll('@', '_at_')
          .replaceAll('.', '_dot_');

      // Tham chiếu đến đường dẫn trong Firebase
      final DatabaseReference roomRef = _database.ref(
        'mock_chats/$safeRoomId/messages',
      );

      // Tạo ID duy nhất cho tin nhắn với timestamp chính xác hơn
      final String messageId =
          '${DateTime.now().millisecondsSinceEpoch}_${message.senderEmail?.hashCode ?? 0}';

      // Đảm bảo tin nhắn có timestamp cập nhật
      final updatedMessage = message.copyWith(
        timestamp: DateTime.now(),
        status: 'sent',
      );

      // Lưu tin nhắn lên Firebase
      await roomRef.child(messageId).set(updatedMessage.toJson());

      if (kDebugMode) {
        print('Đã đồng bộ tin nhắn lên Firebase thành công');
        print('Path: mock_chats/$safeRoomId/messages/$messageId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Lỗi khi đồng bộ tin nhắn lên Firebase: $e');
      }
    }
  }

  void _setupFirebaseListener() {
    try {
      print("👉 Thiết lập lắng nghe Firebase cho phòng: ${widget.roomId}");

      // Chuyển đổi roomId thành định dạng an toàn cho Firebase
      final String safeRoomId = widget.roomId
          .replaceAll('@', '_at_')
          .replaceAll('.', '_dot_');

      // Tham chiếu đến đường dẫn trong Firebase
      final DatabaseReference roomRef = _database.ref(
        'mock_chats/$safeRoomId/messages',
      );

      print("👉 Đường dẫn Firebase: mock_chats/$safeRoomId/messages");

      // Test kết nối
      _testFirebaseConnection();

      // Lắng nghe thay đổi
      _chatSubscription = roomRef.onChildAdded.listen((event) async {
        try {
          print("👉 Nhận sự kiện từ Firebase: ${event.snapshot.key}");

          if (event.snapshot.value != null) {
            final data = Map<String, dynamic>.from(event.snapshot.value as Map);
            final message = ChatMessageModel.fromJson(data);

            print("👉 Nội dung tin nhắn: ${message.content}");
            print("👉 Người gửi: ${message.senderEmail}");
            print("👉 Người dùng hiện tại: $_userEmail");

            // Kiểm tra có phải tin nhắn từ người khác không
            if (message.senderEmail != _userEmail) {
              print("👉 Tin nhắn từ người khác, thêm vào danh sách");

              // Thêm tin nhắn vào storage
              await _chatLocalStorage.addMessage(widget.roomId, message);

              // Cập nhật giao diện
              if (mounted) {
                setState(() {
                  _refreshMessages();
                });
              }
            } else {
              print("👉 Đây là tin nhắn từ chính mình, bỏ qua");
            }
          }
        } catch (e) {
          print("❌ Lỗi xử lý tin nhắn Firebase: $e");
        }
      });

      print("👉 Đã thiết lập lắng nghe Firebase thành công");
    } catch (e) {
      print("❌ Lỗi thiết lập lắng nghe Firebase: $e");
    }
  }

  // Helper to get min value
  int min(int a, int b) => a < b ? a : b;
}
