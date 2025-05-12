import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../../models/chat_message_model.dart';
import '../../../services/chat_service.dart';
import '../../../services/websocket_service.dart';
import '../../../services/auth_manager.dart';
import '../../../utils/app_config.dart';
import '../../../utils/chat_local_storage.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:image_picker/image_picker.dart';
import 'dart:io';

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
  final ImagePicker _imagePicker = ImagePicker();

  List<ChatMessageModel> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  String? _userEmail;
  StreamSubscription? _chatSubscription;
  bool _showEmojiPicker = false;
  Timer? _refreshTimer;
  File? _selectedImage;
  bool _isTyping = false;

  final List<String> _commonEmojis = [
    '😀',
    '😃',
    '😄',
    '😁',
    '😆',
    '😅',
    '😂',
    '🤣',
    '😊',
    '😇',
    '🙂',
    '🙃',
    '😉',
    '😌',
    '😍',
    '🥰',
    '😘',
    '😗',
    '😙',
    '😚',
    '😋',
    '😛',
    '😝',
    '😜',
    '🤪',
    '🤨',
    '🧐',
    '🤓',
    '😎',
    '🤩',
    '😏',
    '😒',
    '😞',
    '😔',
    '😟',
    '😕',
    '🙁',
    '☹️',
    '😣',
    '😖',
    '😫',
    '😩',
    '🥺',
    '😢',
    '😭',
    '😤',
    '😠',
    '😡',
    '🤬',
    '🤯',
    '😳',
    '🥵',
    '🥶',
    '😱',
    '😨',
    '😰',
    '😥',
    '😓',
    '🤗',
    '🤔',
    '👍',
    '👎',
    '👏',
    '🙌',
    '👐',
    '🤲',
    '🤝',
    '🙏',
    '✌️',
    '🤞',
    '❤️',
    '💔',
    '💯',
    '✨',
    '🔥',
    '🎉',
    '🎊',
    '👋',
    '🤚',
    '🖐️',
  ];

  @override
  void initState() {
    super.initState();
    _initialize();

    // Đặt timer để làm mới tin nhắn
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _loadMessages();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _chatSubscription?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _initialize() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Lấy email người dùng để phân biệt tin nhắn của mình
      _userEmail = await _authManager.getUserEmail();

      if (_userEmail == null) {
        if (foundation.kDebugMode) {
          print('Không thể lấy email người dùng');
        }
        throw Exception('Không thể lấy email người dùng');
      }

      // Kết nối WebSocket
      String? token = await _authManager.getToken();
      if (token == null) {
        if (foundation.kDebugMode) {
          print('Không tìm thấy token xác thực');
        }
        throw Exception('Không tìm thấy token xác thực');
      }

      if (foundation.kDebugMode) {
        print('Khởi tạo WebSocket với email: $_userEmail');
        print('WebSocket URL: ${_appConfig.webSocketUrl}');
      }

      _webSocketService.initialize(_appConfig.apiBaseUrl, token, _userEmail!);

      // Kiểm tra kết nối WebSocket
      await Future.delayed(
        const Duration(seconds: 2),
      ); // Cho WebSocket có thời gian kết nối
      if (!_webSocketService.isConnected()) {
        if (foundation.kDebugMode) {
          print('⚠️ WebSocket không thể kết nối sau khi khởi tạo');
        }
        // Vẫn tiếp tục mà không throw exception, vì chúng ta sẽ fallback sang REST API
      } else {
        if (foundation.kDebugMode) {
          print('✅ WebSocket đã kết nối thành công');
        }
      }

      // Thiết lập lắng nghe tin nhắn
      _setupWebSocketListener();

      // Tải lịch sử chat
      await _loadChatHistory();

      // Đánh dấu tin nhắn đã đọc
      await _chatService.markMessagesAsRead(widget.roomId);
    } catch (e) {
      if (foundation.kDebugMode) {
        print('Lỗi khởi tạo chat: $e');
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Không thể kết nối: $e')));
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
    _webSocketService.onChatMessageReceived = (message) async {
      if (foundation.kDebugMode) {
        print('Nhận tin nhắn qua WebSocket: ${message.content}');
        print(
          'Phòng chat hiện tại: ${widget.roomId}, Phòng của tin nhắn: ${message.roomId}',
        );
      }

      // Chỉ hiển thị tin nhắn thuộc phòng chat hiện tại
      if (message.roomId == widget.roomId) {
        // Cải thiện logic phát hiện tin nhắn trùng lặp
        bool isDuplicate = _isDuplicateMessage(message);

        if (!isDuplicate) {
          // Lưu tin nhắn vào bộ nhớ cục bộ
          await _chatLocalStorage.addMessage(widget.roomId, message);

          if (mounted) {
            setState(() {
              // Thêm tin nhắn vào cuối danh sách
              _messages.add(message);
              // Sắp xếp lại theo thời gian để đảm bảo hiển thị đúng thứ tự
              _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
            });

            // Cuộn xuống cuối danh sách tin nhắn
            _scrollToBottom();
          }
        } else {
          // Nếu trùng lặp, kiểm tra và cập nhật trạng thái tin nhắn nếu cần
          _updateMessageStatusIfNeeded(message);
        }

        // Đánh dấu tin nhắn đã đọc
        _chatService.markMessagesAsRead(widget.roomId);
      }
    };
  }

  // Phương thức mới để kiểm tra tin nhắn trùng lặp
  bool _isDuplicateMessage(ChatMessageModel newMessage) {
    // Kiểm tra nếu tin nhắn có id và id đã tồn tại trong danh sách
    if (newMessage.id != null && newMessage.id! > 0) {
      for (var msg in _messages) {
        if (msg.id != null && msg.id == newMessage.id) {
          return true;
        }
      }
    }

    // Kiểm tra dựa trên nội dung, người gửi và thời gian
    for (var existingMessage in _messages) {
      if (existingMessage.content == newMessage.content &&
          existingMessage.senderEmail == newMessage.senderEmail) {
        // Nếu thời gian tạo gần nhau (trong 5 giây)
        if (existingMessage.timestamp
                .difference(newMessage.timestamp)
                .inSeconds
                .abs() <
            5) {
          return true;
        }
      }
    }

    return false;
  }

  // Phương thức mới để cập nhật trạng thái tin nhắn nếu cần
  void _updateMessageStatusIfNeeded(ChatMessageModel newMessage) {
    if (newMessage.senderEmail == _userEmail) {
      // Tìm tin nhắn trong danh sách hiện tại
      for (int i = 0; i < _messages.length; i++) {
        var existingMessage = _messages[i];

        if (existingMessage.content == newMessage.content &&
            existingMessage.senderEmail == newMessage.senderEmail &&
            (existingMessage.timestamp
                    .difference(newMessage.timestamp)
                    .inSeconds
                    .abs() <
                5)) {
          // Chỉ cập nhật khi trạng thái mới tốt hơn trạng thái cũ
          String currentStatus = existingMessage.status ?? '';
          String newStatus = newMessage.status ?? '';
          bool shouldUpdate = false;

          // Thứ tự ưu tiên: failed < sending < sent < read
          if (currentStatus == 'failed') {
            shouldUpdate = true;
          } else if (currentStatus == 'sending' && newStatus != 'failed') {
            shouldUpdate = true;
          } else if (currentStatus == 'sent' && newStatus == 'read') {
            shouldUpdate = true;
          }

          if (shouldUpdate && mounted) {
            setState(() {
              _messages[i] = existingMessage.copyWith(
                status: newMessage.status,
                read: newMessage.read,
                id: newMessage.id ?? existingMessage.id,
              );
            });
            // Cập nhật tin nhắn trong bộ nhớ cục bộ
            _chatLocalStorage.updateMessageStatus(
              widget.roomId,
              existingMessage,
              newMessage.status ?? '',
            );
          }

          break;
        }
      }
    }
  }

  Future<void> _loadChatHistory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (foundation.kDebugMode) {
        print('🔍 Tải lịch sử chat cho phòng: ${widget.roomId}');
        print('🔍 Tài khoản người dùng: $_userEmail');
      }

      // Kiểm tra roomId có hợp lệ không
      if (widget.roomId.isEmpty) {
        if (foundation.kDebugMode) {
          print('⚠️ RoomId trống, không thể tải lịch sử');
        }
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Đầu tiên, thử tải tin nhắn từ bộ nhớ cục bộ
      final localMessages = await _chatLocalStorage.getMessages(widget.roomId);

      if (localMessages.isNotEmpty) {
        if (foundation.kDebugMode) {
          print('📱 Tải ${localMessages.length} tin nhắn từ bộ nhớ cục bộ');
        }

        if (mounted) {
          setState(() {
            // Đảm bảo tin nhắn được sắp xếp theo thời gian tăng dần (cũ lên trên, mới xuống dưới)
            _messages =
                localMessages
                  ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
            _isLoading = false;
          });
        }
      }

      // Sau đó tải tin nhắn từ server để cập nhật
      if (foundation.kDebugMode) {
        print('🌐 Đang tải tin nhắn từ server...');
      }
      
      final serverMessages = await _chatService.getChatHistory(widget.roomId);

      if (foundation.kDebugMode) {
        print('🌐 Đã nhận ${serverMessages.length} tin nhắn từ server');
      }

      if (serverMessages.isNotEmpty) {
        // Lưu tin nhắn từ server vào bộ nhớ cục bộ
        await _chatLocalStorage.saveMessages(widget.roomId, serverMessages);

        if (mounted) {
          // Cập nhật giao diện nếu danh sách tin nhắn từ server khác với local
          if (localMessages.isEmpty ||
              !_areMessagesEqual(localMessages, serverMessages)) {
            setState(() {
              // Đảm bảo tin nhắn được sắp xếp theo thời gian tăng dần
              _messages =
                  serverMessages
                    ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
              _isLoading = false;
            });

            if (foundation.kDebugMode) {
              print('✅ Đã cập nhật danh sách tin nhắn với dữ liệu từ server');
            }
          }
        }
      } else if (foundation.kDebugMode) {
        print('ℹ️ Không có tin nhắn mới từ server');
      }

      // Cuộn xuống để hiển thị tin nhắn mới nhất sau khi tải xong
      // Sử dụng một delay ngắn để đảm bảo giao diện đã được vẽ hoàn toàn
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 100), () {
          _scrollToBottom();
        });
      });

      // Đánh dấu tin nhắn đã đọc
      try {
        await _chatService.markMessagesAsRead(widget.roomId);
        if (foundation.kDebugMode) {
          print('✅ Đã đánh dấu tin nhắn là đã đọc');
        }
      } catch (e) {
        if (foundation.kDebugMode) {
          print('⚠️ Lỗi khi đánh dấu tin nhắn đã đọc: $e');
        }
      }
    } catch (e) {
      if (foundation.kDebugMode) {
        print('❌ Lỗi khi tải lịch sử chat: $e');
        print('Stack trace: ${StackTrace.current}');
      }
      
      // Nếu đã có tin nhắn từ local, không hiển thị thông báo lỗi
      if (_messages.isEmpty && mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể tải tin nhắn: $e'),
            action: SnackBarAction(
              label: 'Thử lại',
              onPressed: _loadChatHistory,
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
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

  Future<void> _loadMessages() async {
    if (!mounted) return;

    try {
      final messages = await _chatService.getChatHistory(widget.roomId);
      if (mounted && messages.isNotEmpty) {
        // Chỉ cập nhật nếu có tin nhắn mới
        if (_messages.isEmpty ||
            messages.length > _messages.length ||
            !_areMessagesEqual(_messages, messages)) {
          setState(() {
            // Đảm bảo tin nhắn được sắp xếp theo thời gian tăng dần
            _messages =
                messages..sort((a, b) => a.timestamp.compareTo(b.timestamp));
            _isLoading = false;
          });

          // Cuộn xuống tin nhắn cuối cùng
          _scrollToBottom();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        // Chỉ hiển thị thông báo lỗi nếu chưa có tin nhắn nào
        if (_messages.isEmpty) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Không thể tải tin nhắn: $e')));
        }
      }
    }
  }

  Future<void> _sendMessage() async {
    final String content = _messageController.text.trim();
    if (content.isEmpty && _selectedImage == null) return;

    setState(() {
      _isSending = true;
    });

    try {
      // TODO: Xử lý gửi ảnh ở phiên bản tiếp theo
      if (_selectedImage != null) {
        // Thêm code xử lý upload ảnh và gửi URL ở đây
        setState(() {
          _selectedImage = null;
        });
      }

      // Tạo tin nhắn mới với ID tạm thời
      final now = DateTime.now();
      final String tempId = now.millisecondsSinceEpoch.toString();
      final newMessage = ChatMessageModel(
        id: 0, // ID sẽ được server cấp
        senderEmail: _userEmail,
        receiverEmail: widget.partnerEmail,
        content: content,
        roomId: widget.roomId,
        timestamp: now,
        read: false,
        status: 'sending', // Đánh dấu là đang gửi
      );

      // Thêm tin nhắn vào giao diện ngay lập tức với trạng thái đang gửi
      setState(() {
        _messages.add(newMessage);
        // Sắp xếp lại danh sách để đảm bảo thứ tự hiển thị đúng
        _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      });

      // Lưu tin nhắn vào bộ nhớ cục bộ tạm thời với trạng thái 'sending'
      await _chatLocalStorage.addMessage(widget.roomId, newMessage);

      // Xóa nội dung tin nhắn trong khung nhập
      _messageController.clear();

      // Cuộn xuống dưới để hiển thị tin nhắn mới
      _scrollToBottom();

      // Gọi API để gửi tin nhắn
      bool success = await _chatService.sendMessage(
        widget.roomId,
        widget.partnerEmail,
        content,
      );

      if (success && mounted) {
        // Tìm tin nhắn trong danh sách và cập nhật trạng thái thành 'sent'
        setState(() {
          for (int i = 0; i < _messages.length; i++) {
            if (_messages[i].content == content &&
                _messages[i].senderEmail == _userEmail &&
                (_messages[i].timestamp.difference(now).inSeconds.abs() < 5) &&
                _messages[i].status == 'sending') {
              _messages[i] = _messages[i].copyWith(status: 'sent');
              // Cập nhật tin nhắn trong bộ nhớ cục bộ
              _chatLocalStorage.updateMessageStatus(
                widget.roomId,
                _messages[i],
                'sent',
              );
              break;
            }
          }
          _isSending = false;
        });
      } else if (mounted) {
        // Cập nhật trạng thái tin nhắn thành 'failed' nếu gửi thất bại
        setState(() {
          for (int i = 0; i < _messages.length; i++) {
            if (_messages[i].content == content &&
                _messages[i].senderEmail == _userEmail &&
                (_messages[i].timestamp.difference(now).inSeconds.abs() < 5) &&
                _messages[i].status == 'sending') {
              _messages[i] = _messages[i].copyWith(status: 'failed');
              // Cập nhật tin nhắn trong bộ nhớ cục bộ
              _chatLocalStorage.updateMessageStatus(
                widget.roomId,
                _messages[i],
                'failed',
              );
              break;
            }
          }
          _isSending = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không thể gửi tin nhắn. Vui lòng thử lại sau.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        // Cập nhật tin nhắn thành trạng thái lỗi
        setState(() {
          // Tìm tin nhắn theo nội dung và thời gian
          DateTime now = DateTime.now();
          for (int i = 0; i < _messages.length; i++) {
            if (_messages[i].content == content &&
                _messages[i].senderEmail == _userEmail &&
                _messages[i].status == 'sending') {
              _messages[i] = _messages[i].copyWith(status: 'failed');
              // Cập nhật tin nhắn trong bộ nhớ cục bộ
              _chatLocalStorage.updateMessageStatus(
                widget.roomId,
                _messages[i],
                'failed',
              );
              break;
            }
          }
          _isSending = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi gửi tin nhắn: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      try {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } catch (e) {
        if (foundation.kDebugMode) {
          print('Lỗi khi cuộn xuống cuối: $e');
        }
      }
    } else {
      // Nếu ScrollController chưa sẵn sàng, thử lại sau một khoảng thời gian ngắn
      Future.delayed(const Duration(milliseconds: 50), () {
        _scrollToBottom();
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Không thể chọn ảnh: $e')));
    }
  }

  void _onEmojiSelected(String emoji) {
    _messageController.text = _messageController.text + emoji;
  }

  void _toggleEmojiPicker() {
    setState(() {
      _showEmojiPicker = !_showEmojiPicker;
    });
  }

  String _formatTime(DateTime timestamp) {
    return DateFormat('HH:mm').format(timestamp);
  }

  String _formatDate(DateTime timestamp) {
    final DateTime now = DateTime.now();

    if (timestamp.year == now.year &&
        timestamp.month == now.month &&
        timestamp.day == now.day) {
      return 'Hôm nay';
    } else if (timestamp.year == now.year &&
        timestamp.month == now.month &&
        timestamp.day == now.day - 1) {
      return 'Hôm qua';
    } else {
      return DateFormat('dd/MM/yyyy').format(timestamp);
    }
  }

  String _formatFullDateTime(DateTime timestamp) {
    final DateTime now = DateTime.now();
    final bool isSameDay =
        timestamp.year == now.year &&
        timestamp.month == now.month &&
        timestamp.day == now.day;

    if (isSameDay) {
      return 'Hôm nay, ${DateFormat('HH:mm').format(timestamp)}';
    } else {
      return DateFormat('dd/MM/yyyy, HH:mm').format(timestamp);
    }
  }

  bool _shouldShowDate(int index) {
    if (index == 0) return true;

    try {
      final DateTime current = _messages[index].timestamp;
      final DateTime previous = _messages[index - 1].timestamp;

      return current.day != previous.day ||
          current.month != previous.month ||
          current.year != previous.year;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF002D72),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFF00AEEF).withOpacity(0.2),
              child: const Icon(Icons.person, color: Color(0xFF002D72)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.partnerName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Text(
                    'Online', // Có thể thay đổi thành trạng thái thực tế
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: () {
              // TODO: Hiển thị thông tin về người dùng hoặc chuyến đi
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Phần tin nhắn
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _messages.isEmpty
                    ? _buildEmptyChat()
                    : GestureDetector(
                      onTap: () {
                        // Ẩn bàn phím và emoji picker khi tap vào màn hình
                        FocusScope.of(context).unfocus();
                        if (_showEmojiPicker) {
                          setState(() {
                            _showEmojiPicker = false;
                          });
                        }
                      },
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          final bool isMe = message.senderEmail == _userEmail;

                          return Column(
                            children: [
                              if (_shouldShowDate(index))
                                _buildDateSeparator(message.timestamp),
                              _buildMessageBubble(message, isMe),
                            ],
                          );
                        },
                      ),
                    ),
          ),

          // Hiển thị preview ảnh đã chọn
          if (_selectedImage != null)
            Container(
              height: 100,
              padding: const EdgeInsets.all(8),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(_selectedImage!, height: 100),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedImage = null;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(4),
                        child: const Icon(
                          Icons.close,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Phần nhập tin nhắn
          _buildMessageInput(),

          // Emoji picker
          if (_showEmojiPicker)
            Container(
              height: 250,
              color: const Color(0xFFF2F2F2),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 4.0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Emoji',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF333333),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: Color(0xFF666666),
                          ),
                          onPressed: _toggleEmojiPicker,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 8,
                            childAspectRatio: 1.0,
                          ),
                      itemCount: _commonEmojis.length,
                      itemBuilder: (context, index) {
                        return InkWell(
                          onTap: () => _onEmojiSelected(_commonEmojis[index]),
                          child: Center(
                            child: Text(
                              _commonEmojis[index],
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyChat() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có tin nhắn với ${widget.partnerName}',
            style: const TextStyle(fontSize: 16, color: Color(0xFF666666)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Hãy bắt đầu cuộc trò chuyện ngay!',
            style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSeparator(DateTime timestamp) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              _formatDate(timestamp),
              style: TextStyle(
                fontSize: 12,
                color: const Color(0xFF666666),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessageModel message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () {
                // Hiển thị thời gian đầy đủ khi nhấn vào tin nhắn
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(_formatFullDateTime(message.timestamp)),
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: Colors.black87,
                  ),
                );
              },
              onLongPress:
                  isMe
                      ? () {
                        // Hiển thị menu cho tin nhắn của mình (xóa, gửi lại nếu lỗi)
                        _showMessageOptions(message);
                      }
                      : null,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isMe ? const Color(0xFF002D72) : Colors.grey.shade200,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft:
                        isMe
                            ? const Radius.circular(16)
                            : const Radius.circular(4),
                    bottomRight:
                        isMe
                            ? const Radius.circular(4)
                            : const Radius.circular(16),
                  ),
                ),
                child: Text(
                  message.content,
                  style: TextStyle(
                    color: isMe ? Colors.white : Colors.black87,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      fontSize: 11,
                      color: const Color(0xFF666666),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (isMe) ...[
                    const SizedBox(width: 4),
                    if (message.status == 'sending')
                      GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Đang gửi tin nhắn...'),
                              backgroundColor: Colors.grey,
                              duration: Duration(seconds: 1),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        child: Icon(
                          Icons.access_time,
                          size: 12,
                          color: const Color(0xFF666666),
                        ),
                      )
                    else if (message.status == 'failed')
                      GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Gửi tin nhắn thất bại. Nhấn giữ để thử lại.',
                              ),
                              backgroundColor: Colors.red,
                              duration: Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        child: Icon(
                          Icons.error_outline,
                          size: 14,
                          color: Colors.red.shade400,
                        ),
                      )
                    else if (message.read)
                      GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Đã xem'),
                              backgroundColor: Color(0xFF00AEEF),
                              duration: Duration(seconds: 1),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        child: const Icon(
                          Icons.done_all,
                          size: 14,
                          color: Color(0xFF00AEEF),
                        ),
                      )
                    else
                      GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Đã gửi, chưa xem'),
                              backgroundColor: Colors.grey,
                              duration: Duration(seconds: 1),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        child: Icon(
                          Icons.done,
                          size: 14,
                          color: const Color(0xFF666666),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Hiển thị menu tùy chọn khi nhấn giữ tin nhắn
  void _showMessageOptions(ChatMessageModel message) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (context) => SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.copy),
                  title: const Text('Sao chép tin nhắn'),
                  onTap: () {
                    // Sao chép nội dung tin nhắn vào clipboard
                    // Bạn có thể thêm code để sao chép vào clipboard ở đây
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã sao chép tin nhắn')),
                    );
                  },
                ),
                if (message.status == 'failed')
                  ListTile(
                    leading: const Icon(Icons.refresh),
                    title: const Text('Gửi lại'),
                    onTap: () {
                      Navigator.pop(context);
                      _resendMessage(message);
                    },
                  ),
                // Thêm các tùy chọn khác nếu cần
              ],
            ),
          ),
    );
  }

  // Gửi lại tin nhắn bị lỗi
  Future<void> _resendMessage(ChatMessageModel message) async {
    setState(() {
      // Tìm tin nhắn trong danh sách và cập nhật trạng thái thành 'sending'
      for (int i = 0; i < _messages.length; i++) {
        if (_messages[i].content == message.content &&
            _messages[i].timestamp.isAtSameMomentAs(message.timestamp)) {
          _messages[i] = _messages[i].copyWith(status: 'sending');
          break;
        }
      }
      _isSending = true;
    });

    try {
      // Gọi API để gửi lại tin nhắn
      bool success = await _chatService.sendMessage(
        widget.roomId,
        widget.partnerEmail,
        message.content,
      );

      if (success && mounted) {
        setState(() {
          // Tìm tin nhắn và cập nhật trạng thái
          for (int i = 0; i < _messages.length; i++) {
            if (_messages[i].content == message.content &&
                _messages[i].timestamp.isAtSameMomentAs(message.timestamp)) {
              _messages[i] = _messages[i].copyWith(status: 'sent');
              // Cập nhật tin nhắn trong bộ nhớ cục bộ
              _chatLocalStorage.updateMessageStatus(
                widget.roomId,
                _messages[i],
                'sent',
              );
              break;
            }
          }
          _isSending = false;
        });
      } else if (mounted) {
        setState(() {
          // Tìm tin nhắn và đánh dấu là thất bại
          for (int i = 0; i < _messages.length; i++) {
            if (_messages[i].content == message.content &&
                _messages[i].timestamp.isAtSameMomentAs(message.timestamp)) {
              _messages[i] = _messages[i].copyWith(status: 'failed');
              break;
            }
          }
          _isSending = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Không thể gửi lại tin nhắn. Vui lòng thử lại sau.',
              ),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSending = false;
          // Tìm tin nhắn và đánh dấu là thất bại
          for (int i = 0; i < _messages.length; i++) {
            if (_messages[i].content == message.content &&
                _messages[i].timestamp.isAtSameMomentAs(message.timestamp)) {
              _messages[i] = _messages[i].copyWith(status: 'failed');
              break;
            }
          }
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi khi gửi lại tin nhắn: $e')));
      }
    }
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: Icon(
                _showEmojiPicker
                    ? Icons.keyboard
                    : Icons.emoji_emotions_outlined,
                color: const Color(0xFF00AEEF),
              ),
              onPressed: _toggleEmojiPicker,
            ),
            IconButton(
              icon: const Icon(Icons.image, color: Color(0xFF00AEEF)),
              onPressed: _pickImage,
            ),
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Nhập tin nhắn...',
                  hintStyle: TextStyle(color: Colors.grey.shade600),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                ),
                style: const TextStyle(color: Color(0xFF333333)),
                textCapitalization: TextCapitalization.sentences,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                onChanged: (value) {
                  // TODO: Thêm tính năng đang nhập tin nhắn
                  setState(() {
                    _isTyping = value.isNotEmpty;
                  });
                },
              ),
            ),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 48,
              height: 48,
              child: FloatingActionButton(
                onPressed: _isSending ? null : _sendMessage,
                backgroundColor:
                    _isSending ? Colors.grey : const Color(0xFF00AEEF),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                child:
                    _isSending
                        ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                        : const Icon(Icons.send, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
