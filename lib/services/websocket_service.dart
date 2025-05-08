import 'dart:convert';
import 'dart:async';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import '../models/notification_model.dart';
import '../models/chat_message_model.dart';
import 'package:flutter/foundation.dart';
import '../utils/app_config.dart';
import 'dart:math';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  StompClient? _stompClient;
  Function(NotificationModel)? onNotificationReceived;
  Function(ChatMessageModel)? onChatMessageReceived;
  String? _userEmail;
  String? _token;
  final AppConfig _appConfig = AppConfig();
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  bool _isReconnecting = false;
  int _reconnectAttempts = 0;
  static const int MAX_RECONNECT_ATTEMPTS = 10;
  double _reconnectDelay = 1.0;
  static const double MAX_RECONNECT_DELAY = 60.0;
  bool _manualDisconnect = false;
  Function(String, bool)? onUserStatusChanged;

  void initialize(String serverUrl, String token, String userEmail) {
    // Nếu không có thay đổi thông tin và đã kết nối, không tạo kết nối mới
    if (_userEmail == userEmail &&
        _token == token &&
        _stompClient?.connected == true) {
      if (kDebugMode) {
        print(
          '⚠️ Đã có kết nối WebSocket hoạt động với cùng thông tin, bỏ qua việc khởi tạo lại',
        );
      }
      return;
    }

    _userEmail = userEmail;
    _token = token;

    if (serverUrl.isNotEmpty) {
      _appConfig.updateBaseUrl(serverUrl);
    }

    // Cleanup existing connections and timers
    _cleanupExistingConnection();

    final socketUrl = _appConfig.webSocketUrl;
    if (kDebugMode) {
      print('🔄 Khởi tạo WebSocket với URL: $socketUrl');
      print(
        '🔑 Token: ${token.length > 20 ? "${token.substring(0, 20)}..." : token}',
      );
      print('👤 Người dùng: $_userEmail');
    }

    try {
      _stompClient = StompClient(
        config: StompConfig(
          url: socketUrl,
          onConnect: _onConnect,
          onStompError: (frame) {
            if (kDebugMode) {
              print('❌ Lỗi STOMP: ${frame.headers}');
              print('❌ Nội dung lỗi: ${frame.body}');
            }
            _scheduleReconnect();
          },
          onDisconnect: (_) {
            if (kDebugMode) {
              print('❌ WebSocket đã ngắt kết nối');
            }
            _scheduleReconnect();
          },
          onWebSocketError: (error) {
            if (kDebugMode) {
              print('❌ Lỗi WebSocket: $error');
            }
            _scheduleReconnect();
          },
          onWebSocketDone: () {
            if (kDebugMode) {
              print('❌ WebSocket kết nối đã đóng');
            }
            _scheduleReconnect();
          },
          stompConnectHeaders: {'Authorization': 'Bearer $token'},
          webSocketConnectHeaders: {'Authorization': 'Bearer $token'},
          connectionTimeout: const Duration(seconds: 10),
          heartbeatOutgoing: const Duration(seconds: 5),
          heartbeatIncoming: const Duration(seconds: 5),
          reconnectDelay: const Duration(milliseconds: 1000),
        ),
      );

      if (kDebugMode) {
        print('🔄 Đang kích hoạt kết nối WebSocket...');
      }
      _stompClient!.activate();
      _startHeartbeat();

      // Đặt thời gian chờ cho kết nối ban đầu
      Future.delayed(const Duration(seconds: 5), () {
        if (_stompClient != null && !_stompClient!.connected) {
          if (kDebugMode) {
            print('❌ WebSocket không thể kết nối sau 5 giây, thử lại...');
          }
          _scheduleReconnect(immediate: true);
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ Lỗi khởi tạo WebSocket: $e');
      }
      _scheduleReconnect();
    }
  }

  // Dọn dẹp kết nối và bộ đếm thời gian hiện tại
  void _cleanupExistingConnection() {
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();
    _reconnectAttempts = 0;
    _isReconnecting = false;

    if (_stompClient != null) {
      if (_stompClient!.connected) {
        if (kDebugMode) {
          print('🔄 WebSocket đã kết nối, ngắt kết nối trước khi khởi tạo lại');
        }
        disconnect();
      } else {
        if (kDebugMode) {
          print(
            '🔄 WebSocket đang có kết nối không hoạt động, hủy và khởi tạo lại',
          );
        }
        _stompClient!.deactivate();
        _stompClient = null;
      }
    }
  }

  // Bắt đầu gửi heartbeat định kỳ để kiểm tra kết nối
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (_stompClient != null) {
        if (!_stompClient!.connected) {
          if (kDebugMode) {
            print('💓 Phát hiện mất kết nối qua heartbeat, thử kết nối lại...');
          }
          _scheduleReconnect(immediate: true);
        } else {
          if (kDebugMode) {
            print('💓 Heartbeat: WebSocket vẫn đang kết nối.');
          }

          // Gửi một ping để giữ kết nối sống
          try {
            _stompClient!.send(
              destination: '/app/ping',
              body: json.encode({
                'timestamp': DateTime.now().toIso8601String(),
              }),
            );
          } catch (e) {
            if (kDebugMode) {
              print('❌ Lỗi gửi ping: $e - Sẽ thử kết nối lại');
            }
            _scheduleReconnect();
          }
        }
      } else {
        if (kDebugMode) {
          print(
            '💓 Heartbeat: StompClient chưa được khởi tạo, thử kết nối lại',
          );
        }
        _scheduleReconnect(immediate: true);
      }
    });
  }

  // Bắt đầu kết nối lại
  void _scheduleReconnect({bool immediate = false}) {
    // Nếu việc ngắt kết nối là do người dùng chủ ý thực hiện, không tự động kết nối lại
    if (_manualDisconnect) {
      if (kDebugMode) {
        print(
          '⚠️ Không tự động kết nối lại vì người dùng đã chủ động ngắt kết nối',
        );
      }
      return;
    }

    // Nếu đang trong quá trình kết nối lại hoặc đã vượt quá số lần thử lại, không thực hiện thêm
    if (_isReconnecting || _reconnectAttempts >= MAX_RECONNECT_ATTEMPTS) {
      if (_reconnectAttempts >= MAX_RECONNECT_ATTEMPTS) {
        if (kDebugMode) {
          print(
            '❌ Đã đạt giới hạn kết nối lại (${MAX_RECONNECT_ATTEMPTS} lần). Dừng thử lại.',
          );
        }
      }
      return;
    }

    _isReconnecting = true;
    _reconnectAttempts++;

    if (kDebugMode) {
      print(
        '🔄 Lên lịch kết nối lại sau $_reconnectDelay giây (lần thử: $_reconnectAttempts)',
      );
    }

    // Giới hạn tổng số lần kết nối lại
    if (_reconnectAttempts <= MAX_RECONNECT_ATTEMPTS) {
      _reconnectTimer?.cancel();
      _reconnectTimer = Timer(
        Duration(seconds: immediate ? 0 : _reconnectDelay.toInt()),
        () {
          _performReconnect();

          // Tăng thời gian chờ cho lần kết nối tiếp theo (max 60 giây)
          _reconnectDelay =
              (_reconnectDelay * 1.5 < MAX_RECONNECT_DELAY)
                  ? _reconnectDelay * 1.5
                  : MAX_RECONNECT_DELAY;
        },
      );
    } else {
      if (kDebugMode) {
        print('⚠️ Đã vượt quá số lần thử kết nối lại tối đa. Hãy thử lại sau.');
      }
      // Reset để cho phép thử lại nếu người dùng tương tác
      _reconnectAttempts = 0;
      _isReconnecting = false;
    }
  }

  // Thực hiện kết nối lại
  void _performReconnect() {
    if (_token == null || _userEmail == null) {
      if (kDebugMode) {
        print('❌ Không thể kết nối lại: thiếu token hoặc email người dùng');
      }
      _isReconnecting = false;
      return;
    }

    try {
      if (kDebugMode) {
        print('🔄 Đang thực hiện kết nối lại WebSocket...');
      }

      // Đảm bảo đã dọn dẹp kết nối cũ
      if (_stompClient != null) {
        _stompClient!.deactivate();
        _stompClient = null;
      }

      // Tránh vòng lặp vô hạn, đặt cờ để ngăn việc kết nối lại tự động trong quá trình đang cố gắng kết nối lại
      _isReconnecting = true;

      // Khởi tạo lại kết nối mới
      final socketUrl = _appConfig.webSocketUrl;

      if (kDebugMode) {
        print('🔄 Khởi tạo lại WebSocket với URL: $socketUrl');
      }

      _stompClient = StompClient(
        config: StompConfig(
          url: socketUrl,
          onConnect: (frame) {
            _onConnect(frame);
            // Reset khi kết nối thành công
            _reconnectAttempts = 0;
            _reconnectDelay = 1.0;
            _isReconnecting = false;
          },
          onStompError: (frame) {
            if (kDebugMode) {
              print('❌ Lỗi STOMP khi reconnect: ${frame.headers}');
            }
            _isReconnecting = false;
          },
          onDisconnect: (_) {
            if (kDebugMode) {
              print('❌ WebSocket đã ngắt kết nối trong quá trình reconnect');
            }
            _isReconnecting = false;
          },
          onWebSocketError: (error) {
            if (kDebugMode) {
              print('❌ Lỗi WebSocket trong quá trình reconnect: $error');
            }
            _isReconnecting = false;
          },
          onWebSocketDone: () {
            if (kDebugMode) {
              print('❌ WebSocket kết nối đã đóng trong quá trình reconnect');
            }
            _isReconnecting = false;
          },
          stompConnectHeaders: {'Authorization': 'Bearer $_token'},
          webSocketConnectHeaders: {'Authorization': 'Bearer $_token'},
          connectionTimeout: const Duration(seconds: 10),
          heartbeatOutgoing: const Duration(seconds: 5),
          heartbeatIncoming: const Duration(seconds: 5),
          reconnectDelay: const Duration(milliseconds: 1000),
        ),
      );

      _stompClient!.activate();

      // Đặt timeout cho việc kết nối lại
      Future.delayed(const Duration(seconds: 10), () {
        if (_stompClient != null &&
            !_stompClient!.connected &&
            _isReconnecting) {
          if (kDebugMode) {
            print('⌛ Timeout kết nối lại sau 10 giây');
          }
          _isReconnecting = false;
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ Lỗi khi thực hiện kết nối lại: $e');
      }
      _isReconnecting = false;
    }
  }

  // Xử lý khi kết nối WebSocket thành công
  void _onConnect(StompFrame frame) {
    if (kDebugMode) {
      print('\n');
      print('✅ WebSocket đã kết nối thành công!');
      print('🔑 Thiết lập subscriptions...');
    }

    // Reset reconnect state
    _reconnectAttempts = 0;
    _reconnectDelay = 1.0;
    _isReconnecting = false;
    _manualDisconnect = false;

    _setupSubscriptions();
  }

  // Thiết lập các kênh đăng ký nhận thông báo
  void _setupSubscriptions() {
    // Hủy kênh cũ nếu có
    _unsubscribeAll();

    if (_userEmail == null) {
      if (kDebugMode) {
        print('❌ Không thể đăng ký subscriptions vì không có email người dùng');
      }
      return;
    }

    try {
      // 1. Lắng nghe kênh cho người dùng cụ thể (dùng để nhận tin nhắn chat)
      if (kDebugMode) {
        print('🔔 Đăng ký nhận tin nhắn cho người dùng: $_userEmail');
      }

      _stompClient!.subscribe(
        destination: '/topic/chat/$_userEmail',
        callback: (frame) {
          if (kDebugMode) {
            print('\n📨 Nhận tin nhắn cho người dùng $_userEmail:');
            print('📄 Nội dung: ${frame.body}');
          }
          _handleChatMessageReceived(frame);
        },
      );

      // 2. Lắng nghe kênh thông báo chung
      if (kDebugMode) {
        print('🔔 Đăng ký nhận thông báo chung cho người dùng');
      }

      _stompClient!.subscribe(
        destination: '/topic/notifications',
        callback: (frame) {
          if (kDebugMode) {
            print('\n🔔 Nhận thông báo chung:');
            print('📄 Nội dung: ${frame.body}');
          }
          _handleNotificationReceived(frame);
        },
      );

      // Thêm xử lý cho topic /topic/receipt/{email} và /topic/receipt/{roomId}
      _stompClient?.subscribe(
        destination: '/topic/receipt/$_userEmail',
        callback: (frame) {
          try {
            final data = json.decode(frame.body!);
            if (kDebugMode) {
              print('📩 Nhận delivery receipt: $data');
            }

            // Xử lý trạng thái tin nhắn
            if (data['status'] == 'DELIVERED') {
              // Cập nhật trạng thái tin nhắn đã gửi
              // ...
            } else if (data['status'] == 'READ') {
              // Cập nhật trạng thái tin nhắn đã đọc
              // ...
            }
          } catch (e) {
            if (kDebugMode) {
              print('❌ Lỗi khi xử lý receipt: $e');
            }
          }
        },
      );

      if (kDebugMode) {
        print('🔔 Đã đăng ký thành công các kênh thông báo!');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Lỗi khi đăng ký subscriptions: $e');
      }
    }
  }

  // Hủy tất cả các đăng ký hiện tại
  void _unsubscribeAll() {
    if (_stompClient != null && _stompClient!.connected) {
      try {
        // Không có API trực tiếp để unsubscribe tất cả
        // Stomp client tự quản lý việc này
        if (kDebugMode) {
          print('🔔 Đã hủy đăng ký các kênh cũ');
        }
      } catch (e) {
        if (kDebugMode) {
          print('❌ Lỗi khi hủy đăng ký: $e');
        }
      }
    }
  }

  bool isConnected() {
    if (_stompClient == null) {
      if (kDebugMode) {
        print('❌ StompClient chưa được khởi tạo');
      }
      return false;
    }

    final connected = _stompClient!.connected;
    if (kDebugMode) {
      print(
        '🔍 Trạng thái kết nối WebSocket: ${connected ? "✅ Đã kết nối" : "❌ Chưa kết nối"}',
      );
    }
    return connected;
  }

  // Gửi tin nhắn chat
  Future<bool> sendChatMessage(
    String roomId,
    String receiverEmail,
    String content,
  ) async {
    if (kDebugMode) {
      print('📤 Thử gửi tin nhắn chat qua WebSocket');
      print('📤 Room ID: $roomId');
      print('📤 Receiver Email: $receiverEmail');
      print('📤 Content: $content');
    }

    return _trySendChatMessage(roomId, receiverEmail, content);
  }

  // Thử gửi tin nhắn qua WebSocket với cơ chế kiểm tra trạng thái kết nối
  Future<bool> _trySendChatMessage(
    String roomId,
    String receiverEmail,
    String content,
  ) async {
    // Nếu đang có quá nhiều thử lại hoặc WebSocket không được kết nối đúng cách, trả về false ngay lập tức
    if (_stompClient == null || !_stompClient!.connected) {
      if (kDebugMode) {
        print('❌ Không thể gửi tin nhắn: WebSocket chưa được kết nối');
        print('🔍 Trạng thái kết nối: ${_stompClient?.connected}');
      }
      return false;
    }

    try {
      // Đảm bảo đã có thông tin người dùng
      if (_userEmail == null) {
        if (kDebugMode) {
          print('❌ Lỗi: Chưa có thông tin người dùng để gửi tin nhắn');
        }
        return false;
      }

      // Tạo payload cho tin nhắn
      final message = {
        'roomId': roomId,
        'senderEmail': _userEmail,
        'receiverEmail': receiverEmail,
        'content': content,
        'timestamp': DateTime.now().toIso8601String(),
        'token': _token?.replaceAll('Bearer ', ''),
      };

      // QUAN TRỌNG: Đảm bảo gửi đến đúng destination của server
      // Đường dẫn chính xác là /app/chat/{roomId} - đây là nơi server đang lắng nghe
      final destination = '/app/chat/$roomId';

      // Gửi tin nhắn
      if (kDebugMode) {
        print('----------------------------------------------');
        print('📤 SENDING WEBSOCKET MESSAGE:');
        print('📤 Destination: $destination');
        print('📤 Room ID: $roomId');
        print('📤 Sender: $_userEmail');
        print('📤 Receiver: $receiverEmail');
        print('📤 Content: $content');
        if (_token != null) {
          final int maxLength = 20;
          final int tokenLength = _token!.length;
          final int subLength =
              tokenLength < maxLength ? tokenLength : maxLength;
          print('📤 Token: ${_token!.substring(0, subLength)}...');
        } else {
          print('📤 Token: NULL (No authentication token)');
        }
        print('📤 Full Message: ${json.encode(message)}');
        print('----------------------------------------------');
      }

      // Thực hiện gửi tin nhắn
      try {
        _stompClient!.send(
          destination: destination,
          body: json.encode(message),
          headers: {'content-type': 'application/json'},
        );

        if (kDebugMode) {
          print('✅ Đã gửi tin nhắn qua WebSocket, đang chờ phản hồi...');
        }

        // Gửi lại một lần nữa sau 300ms để đảm bảo tin nhắn được gửi đi (phòng trường hợp lỗi truyền tin)
        Future.delayed(const Duration(milliseconds: 300), () {
          try {
            _stompClient!.send(
              destination: destination,
              body: json.encode(message),
              headers: {'content-type': 'application/json'},
            );
            if (kDebugMode) {
              print(
                '✅ Đã gửi tin nhắn lần thứ 2 để đảm bảo tin nhắn được nhận',
              );
            }
          } catch (e) {
            if (kDebugMode) {
              print('❌ Lỗi khi gửi tin nhắn lần thứ 2: $e');
            }
          }
        });

        // Không có cách nào để biết tin nhắn đã được xử lý thành công hay chưa trong STOMP,
        // nên ta mặc định trả về true và xử lý thành công
        return true;
      } catch (sendError) {
        if (kDebugMode) {
          print('❌ Lỗi khi gửi tin nhắn qua STOMP client: $sendError');
        }
        throw sendError; // Ném lỗi để xử lý ở ngoài
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Lỗi khi gửi tin nhắn qua WebSocket: $e');
      }
      return false;
    }
  }

  // Helper function to get min value
  int min(int a, int b) => a < b ? a : b;

  void disconnect() {
    _manualDisconnect = true;

    if (kDebugMode) {
      print('🔌 Ngắt kết nối WebSocket theo yêu cầu');
    }

    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();

    if (_stompClient != null && _stompClient!.connected) {
      _stompClient!.deactivate();
    }

    _stompClient = null;

    // Sau 5 giây, cho phép kết nối lại nếu cần
    Future.delayed(const Duration(seconds: 5), () {
      _manualDisconnect = false;
    });
  }

  // Đăng ký lắng nghe trạng thái đang gõ
  void subscribeToTypingStatus(String roomId) {
    _stompClient?.subscribe(
      destination: '/topic/typing/$roomId',
      callback: (frame) {
        try {
          final data = json.decode(frame.body!);
          // Thông báo có người đang gõ
          // ...
        } catch (e) {
          if (kDebugMode) {
            print('❌ Lỗi khi xử lý trạng thái đang gõ: $e');
          }
        }
      },
    );
  }

  // Gửi trạng thái đang gõ
  void sendTypingStatus(String roomId, bool isTyping) {
    if (_stompClient?.connected ?? false) {
      final payload = {'isTyping': isTyping};

      _stompClient?.send(
        destination: '/app/chat.typing/$roomId',
        body: json.encode(payload),
      );
    }
  }

  // Gửi xác nhận đã đọc tin nhắn
  void markMessagesAsRead(String roomId) {
    if (_stompClient?.connected ?? false) {
      _stompClient?.send(
        destination: '/app/chat.markRead/$roomId',
        body: json.encode({}),
      );
    }
  }

  // Thêm phương thức subscribe vào ChatService hoặc WebSocketService
  void subscribeToUserStatus() {
    _stompClient?.subscribe(
      destination: '/topic/user-status',
      callback: (frame) {
        try {
          final data = json.decode(frame.body!);
          final userEmail = data['userEmail'];
          final isOnline = data['online'];

          if (onUserStatusChanged != null) {
            onUserStatusChanged!(userEmail, isOnline);
          }

          if (kDebugMode) {
            print(
              '👤 Trạng thái người dùng: $userEmail - ${isOnline ? "online" : "offline"}',
            );
          }
        } catch (e) {
          if (kDebugMode) {
            print('❌ Lỗi khi xử lý trạng thái người dùng: $e');
          }
        }
      },
    );
  }

  // Phương thức xử lý tin nhắn chat nhận được
  void _handleChatMessageReceived(StompFrame frame) {
    try {
      if (frame.body == null) {
        if (kDebugMode) {
          print('❌ Nhận được frame rỗng từ WebSocket');
        }
        return;
      }

      final data = json.decode(frame.body!);
      if (kDebugMode) {
        print('📨 Xử lý tin nhắn chat: $data');
      }

      // Tạo model từ dữ liệu nhận được
      final ChatMessageModel message = ChatMessageModel.fromJson(data);

      // Gọi callback nếu có
      if (onChatMessageReceived != null) {
        onChatMessageReceived!(message);
      } else {
        if (kDebugMode) {
          print('⚠️ Không có callback cho tin nhắn chat');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Lỗi khi xử lý tin nhắn chat: $e');
      }
    }
  }

  // Phương thức xử lý thông báo nhận được
  void _handleNotificationReceived(StompFrame frame) {
    try {
      if (frame.body == null) {
        if (kDebugMode) {
          print('❌ Nhận được frame thông báo rỗng từ WebSocket');
        }
        return;
      }

      final data = json.decode(frame.body!);
      if (kDebugMode) {
        print('🔔 Xử lý thông báo: $data');
      }

      // Tạo model từ dữ liệu nhận được
      final NotificationModel notification = NotificationModel.fromJson(data);

      // Gọi callback nếu có
      if (onNotificationReceived != null) {
        onNotificationReceived!(notification);
      } else {
        if (kDebugMode) {
          print('⚠️ Không có callback cho thông báo');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Lỗi khi xử lý thông báo: $e');
      }
    }
  }
}
