import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/chat_message_model.dart';
import 'auth_manager.dart';
import 'websocket_service.dart';
import '../utils/app_config.dart';
import '../utils/http_client.dart';
import '../utils/chat_local_storage.dart';
import 'package:firebase_database/firebase_database.dart';

// Thiết lập chế độ ngoại tuyến, mặc định là false để ứng dụng luôn cố gắng kết nối với API trước
bool USE_MOCK_MODE = false;

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  final WebSocketService _webSocketService = WebSocketService();
  final AuthManager _authManager = AuthManager();
  final AppConfig _appConfig = AppConfig();
  final ApiClient _apiClient = ApiClient();
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final Map<String, StreamSubscription<DatabaseEvent>> _mockChatSubscriptions =
      {};

  Future<void> initialize(String baseUrl) async {
    if (baseUrl.isNotEmpty) {
      _appConfig.updateBaseUrl(baseUrl);
    }
  }

  // Lấy danh sách các cuộc trò chuyện
  Future<List<Map<String, dynamic>>> getChatRooms() async {
    try {
      if (kDebugMode) {
        print('Đang lấy danh sách phòng chat...');
      }

      // Kiểm tra và lấy thông tin người dùng
      final userEmail = await _authManager.getUserEmail();

      if (userEmail == null) {
        if (kDebugMode) {
          print('Không thể lấy email người dùng hiện tại');
        }
        throw Exception('Không thể xác thực người dùng');
      }

      if (kDebugMode) {
        print('Lấy phòng chat cho người dùng: $userEmail');
      }

      // Kiểm tra kết nối API trước khi tải phòng chat
      final isConnected = await checkApiConnection();

      // Nếu đang ở chế độ ngoại tuyến hoặc không thể kết nối, sử dụng mock data
      if (USE_MOCK_MODE || !isConnected) {
        if (kDebugMode) {
          print(
            'Đang sử dụng chế độ ngoại tuyến hoặc không kết nối được với API.',
          );
          print('Trả về danh sách phòng chat mô phỏng.');
        }
        return await _getMockChatRooms(userEmail);
      }

      try {
        // Thử gọi endpoint /chat/rooms nếu nó tồn tại
        final response = await http
            .get(
              Uri.parse('${_appConfig.apiBaseUrl}/api/chat/rooms'),
              headers: {
                'Accept': 'application/json',
                'Authorization': 'Bearer ${await _authManager.getToken()}',
              },
            )
            .timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          final jsonResponse = json.decode(response.body);
          if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
            final List<Map<String, dynamic>> rooms =
                List<Map<String, dynamic>>.from(jsonResponse['data']);

            if (kDebugMode) {
              print('Đã tải ${rooms.length} phòng chat');
              if (rooms.isNotEmpty) {
                print(
                  'Phòng chat đầu tiên: ${rooms.first['partnerName']} (${rooms.first['partnerEmail']})',
                );
              }
            }

            return rooms;
          }
        }

        // Nếu endpoint không tồn tại hoặc lỗi, chuyển sang chế độ mock
        if (kDebugMode) {
          print(
            'Endpoint /api/chat/rooms không tồn tại hoặc trả về lỗi: ${response.statusCode}',
          );
          print('Chuyển sang chế độ mô phỏng cho phòng chat.');
        }

        USE_MOCK_MODE = true;
        return await _getMockChatRooms(userEmail);
      } catch (innerError) {
        if (kDebugMode) {
          print('Lỗi khi gọi endpoint /api/chat/rooms: $innerError');
          print('Chuyển sang chế độ mô phỏng cho phòng chat.');
        }

        USE_MOCK_MODE = true;
        return await _getMockChatRooms(userEmail);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Lỗi khi lấy danh sách phòng chat: $e');
      }
      // Thử lấy dữ liệu từ local storage nếu có lỗi kết nối
      return await _getMockChatRooms(await _authManager.getUserEmail() ?? '');
    }
  }

  // Tạo danh sách phòng chat mô phỏng
  Future<List<Map<String, dynamic>>> _getMockChatRooms(String userEmail) async {
    if (kDebugMode) {
      print('Tạo danh sách phòng chat mô phỏng cho $userEmail');
    }

    final userRole = await _authManager.getUserRole();
    final DateTime now = DateTime.now();

    // Tạo danh sách phòng chat mô phỏng khác nhau cho tài xế và hành khách
    if (userRole == 'DRIVER') {
      return [
        {
          'roomId': 'mock_${userEmail}_khachvip1@gmail.com',
          'partnerName': 'Khách VIP 1',
          'partnerEmail': 'khachvip1@gmail.com',
          'lastMessage': 'Tôi đang đợi ở địa điểm đã hẹn.',
          'lastMessageTime':
              now.subtract(const Duration(minutes: 3)).toIso8601String(),
          'unreadCount': 0,
          'partnerAvatar': null,
        },
        {
          'roomId': 'mock_${userEmail}_khachvip2@gmail.com',
          'partnerName': 'Khách VIP 2',
          'partnerEmail': 'khachvip2@gmail.com',
          'lastMessage': 'Xin chào, tôi muốn đặt chuyến xe.',
          'lastMessageTime':
              now.subtract(const Duration(hours: 2)).toIso8601String(),
          'unreadCount': 1,
          'partnerAvatar': null,
        },
      ];
    } else {
      return [
        {
          'roomId': 'mock_${userEmail}_xeom1@gmail.com',
          'partnerName': 'Tài Xế Honda',
          'partnerEmail': 'xeom1@gmail.com',
          'lastMessage': 'Chào bạn, tôi đã nhận được thông tin đặt xe.',
          'lastMessageTime':
              now.subtract(const Duration(minutes: 4)).toIso8601String(),
          'unreadCount': 0,
          'partnerAvatar': null,
        },
      ];
    }
  }

  // Helper to get min value (dùng cho substring khi log)
  int min(int a, int b) => a < b ? a : b;

  // Tạo phòng chat mới hoặc lấy phòng chat hiện tại với một người dùng
  Future<String?> createOrGetChatRoom(String receiverEmail) async {
    try {
      if (kDebugMode) {
        print('Bắt đầu tạo phòng chat với: $receiverEmail');
      }

      final token = await _authManager.getToken();
      final senderEmail = await _authManager.getUserEmail();

      if (token == null || senderEmail == null) {
        if (kDebugMode) {
          print('Không thể lấy token hoặc email người gửi');
        }
        throw Exception('Không thể xác thực người dùng');
      }

      if (kDebugMode) {
        print('Người gửi: $senderEmail, Người nhận: $receiverEmail');
      }

      // Kiểm tra kết nối API trước khi tạo phòng chat
      final isConnected = await checkApiConnection();

      // Nếu đang ở chế độ ngoại tuyến hoặc không thể kết nối tới API, tạo phòng chat mô phỏng
      if (USE_MOCK_MODE || !isConnected) {
        if (kDebugMode) {
          print('Đang sử dụng chế độ ngoại tuyến. Tạo phòng chat mô phỏng.');
        }

        // Tạo phòng chat mô phỏng với _createMockChatRoom
        return _createMockChatRoom(senderEmail, receiverEmail);
      }

      // Bắt đầu từ đây làm việc với API nếu kết nối thành công
      final url = Uri.parse(
        '${_appConfig.apiBaseUrl}/api/chat/room/$receiverEmail',
      );
      if (kDebugMode) {
        print('Gửi yêu cầu tạo phòng chat tới: $url');
      }

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final response = await http.get(url, headers: headers);

      if (kDebugMode) {
        print('Phản hồi từ API: ${response.statusCode}');
        if (response.body.isNotEmpty) {
          print(
            'Nội dung: ${response.body.substring(0, min(response.body.length, 100))}',
          );
        }
      }

      if (response.statusCode == 200) {
        // Phân tích phản hồi
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['success'] == true && responseData['data'] != null) {
          final String roomId = responseData['data'];
          if (kDebugMode) {
            print('Tạo phòng chat thành công với ID: $roomId');
          }

          return roomId;
        } else {
          if (kDebugMode) {
            print('Không thể lấy roomId: ${responseData['message']}');
          }
          return null;
        }
      } else if (response.statusCode == 403) {
        // Xử lý khi không có quyền truy cập (403 Forbidden)
        if (kDebugMode) {
          print('Lỗi quyền truy cập (403). Tạo phòng chat mô phỏng.');

          // Phân tích body của response để lấy thông báo lỗi nếu có
          try {
            final jsonResponse = json.decode(response.body);
            if (jsonResponse['message'] != null) {
              print('Thông báo từ server: ${jsonResponse['message']}');
            }
          } catch (e) {
            print('Không thể phân tích thông báo lỗi từ server');
          }
        }

        // Tạo phòng chat mô phỏng
        return _createMockChatRoom(senderEmail, receiverEmail);
      } else {
        throw Exception('Lỗi khi tạo phòng chat: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Lỗi khi tạo phòng chat: $e');
      }

      // Lấy email người dùng hiện tại nếu có
      final senderEmail = await _authManager.getUserEmail();
      if (senderEmail != null) {
        // Sử dụng phòng chat mô phỏng nếu không thể tạo phòng chat thật
        USE_MOCK_MODE = true; // Đặt chế độ mock để tránh tiếp tục thử API
        return _createMockChatRoom(senderEmail, receiverEmail);
      }

      return null;
    }
  }

  // Tạo ID phòng chat mô phỏng dựa trên email của cả hai người dùng
  String _createMockChatRoom(String senderEmail, String receiverEmail) {
    if (kDebugMode) {
      print('Tạo phòng chat mô phỏng giữa $senderEmail và $receiverEmail');
    }

    // Tạo ID phòng chat dựa trên email của hai người (sắp xếp để đảm bảo cùng ID cho cả hai phía)
    List<String> emails = [senderEmail, receiverEmail];
    emails.sort(); // Sắp xếp để đảm bảo thứ tự không đổi

    // Tạo roomId mô phỏng dạng "mock_[email1]_[email2]"
    String roomId = 'mock_${emails[0]}_${emails[1]}';

    if (kDebugMode) {
      print('Đã tạo phòng chat mô phỏng với ID: $roomId');
    }

    // Tạo tin nhắn mô phỏng ban đầu
    _initializeMockChat(roomId, senderEmail, receiverEmail);

    // Thiết lập lắng nghe thay đổi từ Firebase
    _setupMockChatListener(roomId);

    return roomId;
  }

  // Khởi tạo tin nhắn mô phỏng cho phòng chat mới
  Future<void> _initializeMockChat(
    String roomId,
    String senderEmail,
    String receiverEmail,
  ) async {
    if (kDebugMode) {
      print('Khởi tạo tin nhắn mô phỏng cho phòng $roomId');
    }

    try {
      // Kiểm tra xem phòng chat đã có tin nhắn chưa
      final ChatLocalStorage chatLocalStorage = ChatLocalStorage();
      final existingMessages = await chatLocalStorage.getMessages(roomId);

      if (existingMessages.isNotEmpty) {
        if (kDebugMode) {
          print(
            'Phòng chat đã có ${existingMessages.length} tin nhắn, không khởi tạo lại',
          );
        }
        return;
      }

      // Tạo tin nhắn mô phỏng
      final now = DateTime.now();
      final userRole = await _authManager.getUserRole();

      // Lấy tên người dùng thực tế nếu có thể
      String senderName =
          await _getSenderNameFromRole(userRole) ??
          (userRole == 'DRIVER' ? 'Tài Xế' : 'Hành Khách');

      // Lấy tên đối tác từ thông tin phòng chat hoặc mặc định theo vai trò
      String receiverName = userRole == 'DRIVER' ? 'Hành Khách' : 'Tài Xế';

      // Xác định thông tin tên người nhận nếu có thể từ email
      if (receiverEmail.contains('@')) {
        String localPart = receiverEmail.split('@')[0];
        if (localPart.isNotEmpty) {
          // Chuyển đổi localPart thành dạng tên người dùng
          localPart = localPart
              .replaceAll('.', ' ')
              .split(' ')
              .map(
                (word) =>
                    word.isNotEmpty
                        ? word[0].toUpperCase() + word.substring(1)
                        : '',
              )
              .join(' ');
          receiverName = localPart;
        }
      }

      List<ChatMessageModel> messages = [];

      // Thêm tin nhắn chào mừng từ hệ thống
      messages.add(
        ChatMessageModel(
          id: 1,
          senderEmail: 'system@sharexe.vn',
          receiverEmail: senderEmail,
          senderName: 'ShareXe System',
          content:
              'Chào mừng đến với hệ thống chat của ShareXe. Tin nhắn giữa bạn và $receiverName sẽ được lưu tại đây.',
          roomId: roomId,
          timestamp: now.subtract(const Duration(minutes: 10)),
          read: true,
          status: 'sent',
        ),
      );

      // Thêm thông báo về chế độ ngoại tuyến
      messages.add(
        ChatMessageModel(
          id: 2,
          senderEmail: 'system@sharexe.vn',
          receiverEmail: senderEmail,
          senderName: 'ShareXe System',
          content:
              'Hiện tại bạn đang ở chế độ ngoại tuyến hoặc không thể kết nối tới máy chủ. Tin nhắn sẽ được lưu cục bộ và đồng bộ khi kết nối được thiết lập.',
          roomId: roomId,
          timestamp: now.subtract(const Duration(minutes: 8)),
          read: true,
          status: 'sent',
        ),
      );

      // Tạo tin nhắn mô phỏng dựa trên vai trò
      if (userRole == 'DRIVER') {
        // Tin nhắn mô phỏng cho tài xế
        messages.add(
          ChatMessageModel(
            id: 3,
            senderEmail: receiverEmail,
            receiverEmail: senderEmail,
            senderName: receiverName,
            content: 'Xin chào tài xế, tôi đã đặt chuyến xe của bạn.',
            roomId: roomId,
            timestamp: now.subtract(const Duration(minutes: 5)),
            read: true,
            status: 'sent',
          ),
        );

        messages.add(
          ChatMessageModel(
            id: 4,
            senderEmail: senderEmail,
            receiverEmail: receiverEmail,
            senderName: senderName,
            content:
                'Chào bạn, tôi đã nhận được thông tin đặt xe. Bạn có thể nhắn tin cho tôi khi cần.',
            roomId: roomId,
            timestamp: now.subtract(const Duration(minutes: 4)),
            read: true,
            status: 'sent',
          ),
        );

        // Thêm tin nhắn về thời gian đón khách
        messages.add(
          ChatMessageModel(
            id: 5,
            senderEmail: receiverEmail,
            receiverEmail: senderEmail,
            senderName: receiverName,
            content: 'Tài xế ơi, mấy giờ anh sẽ đến đón tôi?',
            roomId: roomId,
            timestamp: now.subtract(const Duration(minutes: 3)),
            read: true,
            status: 'sent',
          ),
        );
      } else {
        // Tin nhắn mô phỏng cho hành khách
        messages.add(
          ChatMessageModel(
            id: 3,
            senderEmail: senderEmail,
            receiverEmail: receiverEmail,
            senderName: senderName,
            content: 'Xin chào tài xế, tôi đã đặt chuyến xe của bạn.',
            roomId: roomId,
            timestamp: now.subtract(const Duration(minutes: 5)),
            read: true,
            status: 'sent',
          ),
        );

        messages.add(
          ChatMessageModel(
            id: 4,
            senderEmail: receiverEmail,
            receiverEmail: senderEmail,
            senderName: receiverName,
            content:
                'Chào bạn, tôi đã nhận được thông tin đặt xe. Bạn có thể nhắn tin cho tôi khi cần.',
            roomId: roomId,
            timestamp: now.subtract(const Duration(minutes: 4)),
            read: true,
            status: 'sent',
          ),
        );

        // Thêm tin nhắn về thời gian đón khách
        messages.add(
          ChatMessageModel(
            id: 5,
            senderEmail: receiverEmail,
            receiverEmail: senderEmail,
            senderName: receiverName,
            content:
                'Tôi sẽ đến đón bạn trong khoảng 15 phút nữa. Bạn vui lòng chuẩn bị nhé!',
            roomId: roomId,
            timestamp: now.subtract(const Duration(minutes: 2)),
            read: false, // Chưa đọc để tạo hiệu ứng tin nhắn mới
            status: 'sent',
          ),
        );
      }

      // Lưu tin nhắn vào bộ nhớ cục bộ
      await chatLocalStorage.saveMessages(roomId, messages);

      if (kDebugMode) {
        print(
          'Đã khởi tạo ${messages.length} tin nhắn mô phỏng thành công cho phòng chat',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Lỗi khi khởi tạo tin nhắn mô phỏng: $e');
      }
    }
  }

  // Lấy tên người gửi từ vai trò
  Future<String?> _getSenderNameFromRole(String? role) async {
    try {
      // Thử lấy tên từ thông tin người dùng trong bộ nhớ
      final username = await _authManager.getUsername();
      if (username != null && username.isNotEmpty) {
        return username;
      }

      // Nếu không có tên trong bộ nhớ, trả về tên mặc định theo vai trò
      if (role == 'DRIVER') {
        return 'Tài Xế';
      } else if (role == 'PASSENGER') {
        return 'Hành Khách';
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  // Lấy lịch sử tin nhắn của một phòng chat
  Future<List<ChatMessageModel>> getChatHistory(String roomId) async {
    try {
      if (kDebugMode) {
        print('Đang lấy lịch sử chat cho phòng: $roomId');
      }

      // Nếu là phòng chat mô phỏng (bắt đầu bằng 'mock_'), lấy từ local storage
      if (roomId.startsWith('mock_') || USE_MOCK_MODE) {
        if (kDebugMode) {
          print('Đây là phòng chat mô phỏng, lấy từ bộ nhớ cục bộ');
        }

        final ChatLocalStorage chatLocalStorage = ChatLocalStorage();
        final localMessages = await chatLocalStorage.getMessages(roomId);

        if (localMessages.isNotEmpty) {
          if (kDebugMode) {
            print('Đã tìm thấy ${localMessages.length} tin nhắn mô phỏng');
          }
          return localMessages;
        } else {
          // Nếu không có tin nhắn mô phỏng trong bộ nhớ, tạo tin nhắn mới
          if (kDebugMode) {
            print('Không tìm thấy tin nhắn mô phỏng, tạo tin nhắn mới');
          }
          return await _getMockChatHistory(roomId);
        }
      }

      // Lấy token để gọi API
      final token = await _authManager.getToken();
      if (token == null) {
        if (kDebugMode) {
          print('Không thể lấy tin nhắn: Không có token');
        }
        throw Exception('Không có token xác thực');
      }

      // Gọi API endpoint chính xác từ backend
      final url = Uri.parse('${_appConfig.apiBaseUrl}/api/chat/$roomId');
      if (kDebugMode) {
        print('Gửi yêu cầu lấy lịch sử chat tới: $url');
      }

      final headers = {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final response = await http.get(url, headers: headers);

      if (kDebugMode) {
        print('Phản hồi từ API: ${response.statusCode}');
        if (response.body.isNotEmpty) {
          print(
            'Nội dung: ${response.body.substring(0, min(response.body.length, 100))}',
          );
        }
      }

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          final List<dynamic> data = jsonResponse['data'];
          if (kDebugMode) {
            print('Nhận được ${data.length} tin nhắn từ server');
          }
          return data.map((item) => ChatMessageModel.fromJson(item)).toList();
        } else {
          if (kDebugMode) {
            print('Không có tin nhắn hoặc lỗi: ${jsonResponse['message']}');
          }
          return [];
        }
      } else if (response.statusCode == 403) {
        if (kDebugMode) {
          print('Lỗi quyền truy cập (403): Không có quyền xem lịch sử chat');
          try {
            final jsonResponse = json.decode(response.body);
            if (jsonResponse['message'] != null) {
              print('Thông báo từ server: ${jsonResponse['message']}');
            }
          } catch (e) {
            print('Không thể phân tích thông báo lỗi từ server');
          }
        }

        // Khi gặp lỗi 403, tự động chuyển sang chế độ ngoại tuyến
        USE_MOCK_MODE = true;

        // Tạo tin nhắn demo cho tài xế và hành khách
        return await _getMockChatHistory(roomId);
      } else {
        if (kDebugMode) {
          print('Lỗi khi tải lịch sử chat HTTP: ${response.statusCode}');
        }
        throw Exception('Lỗi khi tải lịch sử chat: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Lỗi khi lấy lịch sử chat: $e');
        print('Đang tạo dữ liệu mẫu để hiển thị');
      }

      // Trước khi tạo tin nhắn mẫu, thử lấy từ bộ nhớ cục bộ
      final ChatLocalStorage chatLocalStorage = ChatLocalStorage();
      final localMessages = await chatLocalStorage.getMessages(roomId);

      if (localMessages.isNotEmpty) {
        if (kDebugMode) {
          print(
            'Đã tìm thấy ${localMessages.length} tin nhắn từ bộ nhớ cục bộ',
          );
        }
        return localMessages;
      }

      // Trả về tin nhắn mẫu khi có lỗi kết nối
      return await _getMockChatHistory(roomId);
    }
  }

  // Tạo tin nhắn mẫu để demo khi không thể kết nối server
  Future<List<ChatMessageModel>> _getMockChatHistory(String roomId) async {
    try {
      final userRole = await _authManager.getUserRole();
      final userEmail = await _authManager.getUserEmail();

      if (userEmail == null) return [];

      final now = DateTime.now();

      // Tạo dữ liệu mẫu khác nhau cho tài xế và hành khách
      if (userRole == 'DRIVER') {
        return [
          ChatMessageModel(
            id: 1,
            senderEmail: userEmail,
            receiverEmail: 'khachvip1@gmail.com',
            senderName: 'Tài Xế Demo',
            content: 'Xin chào, tôi đã nhận được yêu cầu của bạn',
            roomId: roomId,
            timestamp: now.subtract(const Duration(minutes: 30)),
            read: true,
            status: 'sent',
          ),
          ChatMessageModel(
            id: 2,
            senderEmail: 'khachvip1@gmail.com',
            receiverEmail: userEmail,
            senderName: 'Khách VIP 1',
            content: 'Tôi sẽ đứng ở cổng chính, mặc áo xanh',
            roomId: roomId,
            timestamp: now.subtract(const Duration(minutes: 25)),
            read: true,
            status: 'sent',
          ),
          ChatMessageModel(
            id: 3,
            senderEmail: userEmail,
            receiverEmail: 'khachvip1@gmail.com',
            senderName: 'Tài Xế Demo',
            content: 'Tôi sẽ đến trong vòng 10 phút nữa',
            roomId: roomId,
            timestamp: now.subtract(const Duration(minutes: 20)),
            read: true,
            status: 'sent',
          ),
        ];
      } else {
        return [
          ChatMessageModel(
            id: 1,
            senderEmail: 'xeom1@gmail.com',
            receiverEmail: userEmail,
            senderName: 'Tài Xế Honda',
            content: 'Tôi đã nhận chuyến của bạn',
            roomId: roomId,
            timestamp: now.subtract(const Duration(minutes: 10)),
            read: true,
            status: 'sent',
          ),
          ChatMessageModel(
            id: 2,
            senderEmail: userEmail,
            receiverEmail: 'xeom1@gmail.com',
            senderName: 'Khách VIP Demo',
            content: 'Cảm ơn tài xế, tôi đang đợi ở cổng',
            roomId: roomId,
            timestamp: now.subtract(const Duration(minutes: 5)),
            read: true,
            status: 'sent',
          ),
        ];
      }
    } catch (e) {
      if (kDebugMode) {
        print('Lỗi khi tạo tin nhắn mẫu: $e');
      }
      return [];
    }
  }

  // Gửi tin nhắn mới
  Future<bool> sendMessage(
    String roomId,
    String receiverEmail,
    String content,
  ) async {
    try {
      if (kDebugMode) {
        print('📤 Đang gửi tin nhắn tới: $receiverEmail');
        print('📤 Nội dung: $content');
        print('📤 Phòng chat: $roomId');
      }

      final senderEmail = await _authManager.getUserEmail();
      final senderName = await _authManager.getUsername() ?? 'Tôi';

      if (senderEmail == null) {
        throw Exception('Không thể xác thực người dùng');
      }

      // Tạo message với trạng thái đang gửi
      final message = ChatMessageModel(
        senderEmail: senderEmail,
        receiverEmail: receiverEmail,
        senderName: senderName,
        content: content,
        roomId: roomId,
        timestamp: DateTime.now(),
        read: false,
        status: 'sending',
      );

      // Lưu tin nhắn vào bộ nhớ cục bộ ngay lập tức để hiển thị trên UI
      await ChatLocalStorage().addMessage(roomId, message);

      // Kiểm tra nếu đây là phòng chat mô phỏng
      final bool isMockRoom = roomId.startsWith('mock_');

      // Nếu là phòng chat mô phỏng, đồng bộ với Firebase
      if (isMockRoom || USE_MOCK_MODE) {
        try {
          await _syncMockMessageToFirebase(roomId, message);
          await ChatLocalStorage().updateMessageStatus(roomId, message, 'sent');
          return true;
        } catch (e) {
          if (kDebugMode) {
            print('❌ Lỗi khi đồng bộ tin nhắn mô phỏng: $e');
          }
          await ChatLocalStorage().updateMessageStatus(
            roomId,
            message,
            'failed',
          );
          return false;
        }
      }

      // Chiến lược gửi tin nhắn ưu tiên API REST
      // 1. Thử gửi qua API REST (ưu tiên vì ổn định hơn)
      // 2. Nếu API thất bại, thử gửi qua WebSocket
      // 3. Nếu cả hai đều thất bại, chuyển sang chế độ mô phỏng

      // Thử gửi qua API REST
      bool apiSuccess = false;
      try {
        apiSuccess = await _sendMessageViaAPI(
          roomId,
          receiverEmail,
          content,
          message,
        );
        if (apiSuccess) {
          if (kDebugMode) {
            print('✅ Tin nhắn được gửi thành công qua API REST');
          }
          return true;
        }
      } catch (apiError) {
        if (kDebugMode) {
          print('❌ Lỗi khi gửi tin nhắn qua API: $apiError');
          print('🔄 Chuyển sang thử WebSocket...');
        }
      }

      // Nếu API thất bại, thử WebSocket
      if (!apiSuccess) {
        bool wsSuccess = false;
        try {
          wsSuccess = await _tryWebSocketSend(roomId, receiverEmail, content);
          if (wsSuccess) {
            await ChatLocalStorage().updateMessageStatus(
              roomId,
              message,
              'sent',
            );
            return true;
          }
          if (kDebugMode) {
            print('❌ Gửi tin nhắn qua WebSocket thất bại');
          }
        } catch (wsError) {
          if (kDebugMode) {
            print('❌ Lỗi khi gửi tin nhắn qua WebSocket: $wsError');
          }
        }

        // Nếu cả API và WebSocket đều thất bại, thử Firebase
        if (!wsSuccess) {
          if (kDebugMode) {
            print(
              '🔄 Cả API và WebSocket đều thất bại, chuyển sang chế độ mô phỏng...',
            );
          }

          try {
            USE_MOCK_MODE = true;
            await _syncMockMessageToFirebase(roomId, message);
            await ChatLocalStorage().updateMessageStatus(
              roomId,
              message,
              'sent',
            );
            return true;
          } catch (fbError) {
            if (kDebugMode) {
              print('❌ Lỗi khi gửi tin nhắn qua Firebase: $fbError');
            }
            await ChatLocalStorage().updateMessageStatus(
              roomId,
              message,
              'failed',
            );
            return false;
          }
        }
      }

      // Cập nhật trạng thái tin nhắn thành thất bại nếu tất cả phương thức đều thất bại
      await ChatLocalStorage().updateMessageStatus(roomId, message, 'failed');
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Lỗi tổng thể khi gửi tin nhắn: $e');
      }

      try {
        // Lấy thông tin người gửi trước
        final senderEmail = await _authManager.getUserEmail() ?? '';
        final senderName = await _authManager.getUsername() ?? 'Tôi';

        // Lấy lại thông tin message đang gửi từ local storage
        final messages = await ChatLocalStorage().getMessages(roomId);
        final pendingMessage = messages.firstWhere(
          (msg) => msg.status == 'sending' && msg.content == content,
          orElse:
              () => ChatMessageModel(
                senderEmail: senderEmail,
                receiverEmail: receiverEmail,
                senderName: senderName,
                content: content,
                roomId: roomId,
                timestamp: DateTime.now(),
                read: false,
                status: 'failed',
              ),
        );

        // Cập nhật trạng thái thất bại
        await ChatLocalStorage().updateMessageStatus(
          roomId,
          pendingMessage,
          'failed',
        );
      } catch (updateError) {
        if (kDebugMode) {
          print('❌ Lỗi khi cập nhật trạng thái tin nhắn: $updateError');
        }
      }
      return false;
    }
  }

  // Gửi tin nhắn qua API REST
  Future<bool> _sendMessageViaAPI(
    String roomId,
    String receiverEmail,
    String content,
    ChatMessageModel message,
  ) async {
    final token = await _authManager.getToken();
    if (token == null) {
      throw Exception('Không có token xác thực');
    }

    final url = Uri.parse('${_appConfig.apiBaseUrl}/api/chat/test/$roomId');
    if (kDebugMode) {
      print('📤 Gửi tin nhắn tới API: $url');
    }

    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final body = json.encode({
      'receiverEmail': receiverEmail,
      'content': content,
    });

    // Thêm retry logic cho API
    int retryCount = 0;
    const maxRetries = 2;
    const retryDelay = Duration(seconds: 1);

    while (retryCount <= maxRetries) {
      try {
        final response = await http
            .post(url, headers: headers, body: body)
            .timeout(const Duration(seconds: 10));

        if (kDebugMode) {
          print('📡 Phản hồi từ API sendMessage: ${response.statusCode}');
          if (response.body.isNotEmpty) {
            print(
              '📡 Body: ${response.body.substring(0, min(100, response.body.length))}...',
            );
          }
        }

        if (response.statusCode == 200 || response.statusCode == 201) {
          // Cập nhật trạng thái tin nhắn thành 'sent'
          await ChatLocalStorage().updateMessageStatus(roomId, message, 'sent');

          if (kDebugMode) {
            print('✅ Tin nhắn đã được gửi thành công qua API');
          }

          return true;
        } else if (response.statusCode == 403) {
          if (kDebugMode) {
            print('❌ Lỗi quyền truy cập (403). Chuyển sang chế độ mô phỏng.');
          }

          // Tự động chuyển sang chế độ mô phỏng khi gặp lỗi 403
          USE_MOCK_MODE = true;
          return false;
        } else if (retryCount < maxRetries &&
            (response.statusCode >= 500 || response.statusCode == 429)) {
          // Retry cho lỗi server hoặc rate limiting
          retryCount++;
          if (kDebugMode) {
            print(
              '🔄 Thử lại gửi API lần $retryCount sau lỗi ${response.statusCode}',
            );
          }
          await Future.delayed(retryDelay * retryCount);
          continue;
        } else {
          throw Exception('Lỗi khi gửi tin nhắn: ${response.statusCode}');
        }
      } catch (e) {
        if (retryCount < maxRetries) {
          retryCount++;
          if (kDebugMode) {
            print('🔄 Thử lại gửi API lần $retryCount sau lỗi: $e');
          }
          await Future.delayed(retryDelay * retryCount);
        } else {
          if (kDebugMode) {
            print('❌ Đã hết số lần thử lại API, chuyển sang WebSocket');
          }
          throw e; // Ném lỗi để chuyển sang WebSocket
        }
      }
    }

    return false;
  }

  // Phương thức trợ giúp để thử gửi qua WebSocket
  Future<bool> _tryWebSocketSend(
    String roomId,
    String receiverEmail,
    String content,
  ) async {
    try {
      if (kDebugMode) {
        print('📱 Thử gửi tin nhắn qua WebSocket');
      }

      // Kiểm tra trạng thái kết nối WebSocket
      final bool isConnected = _webSocketService.isConnected();
      if (!isConnected) {
        if (kDebugMode) {
          print('⚠️ WebSocket không kết nối, chuyển sang gửi qua API REST');
        }
        return false;
      }

      // Thử gửi tin nhắn qua WebSocket
      final result = await _webSocketService.sendChatMessage(
        roomId,
        receiverEmail,
        content,
      );

      if (kDebugMode) {
        print(
          result
              ? '✅ Đã gửi thành công qua WebSocket'
              : '❌ Không thể gửi tin nhắn qua WebSocket',
        );
      }

      return result;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Lỗi khi gửi tin nhắn qua WebSocket: $e');
      }
      return false;
    }
  }

  // Đánh dấu tin nhắn đã đọc
  Future<bool> markMessagesAsRead(String roomId) async {
    try {
      // Nếu là phòng chat mô phỏng, chỉ cập nhật local
      if (roomId.startsWith('mock_') || USE_MOCK_MODE) {
        if (kDebugMode) {
          print('Đánh dấu tin nhắn đã đọc trong phòng mô phỏng: $roomId');
        }

        // Đánh dấu tất cả tin nhắn đã đọc trong bộ nhớ cục bộ
        final chatLocalStorage = ChatLocalStorage();
        final messages = await chatLocalStorage.getMessages(roomId);

        for (var message in messages) {
          if (!message.read) {
            final updatedMessage = message.copyWith(read: true);
            await chatLocalStorage.updateMessageStatus(roomId, message, 'read');
          }
        }

        return true;
      }

      // Nếu không phải phòng mô phỏng, gọi API
      final token = await _authManager.getToken();
      if (token == null) {
        if (kDebugMode) {
          print('Không thể đánh dấu tin nhắn đã đọc: Không có token');
        }
        return false;
      }

      final url = Uri.parse(
        '${_appConfig.apiBaseUrl}/api/chat/$roomId/mark-read',
      );
      if (kDebugMode) {
        print('Gửi yêu cầu đánh dấu tin nhắn đã đọc tới: $url');
      }

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final response = await http.put(url, headers: headers);

      if (kDebugMode) {
        print('Phản hồi từ API markMessagesAsRead: ${response.statusCode}');
      }

      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) {
        print('Lỗi khi đánh dấu tin nhắn đã đọc: $e');
      }
      return false;
    }
  }

  // Lấy số lượng tin nhắn chưa đọc
  Future<int> getUnreadMessageCount() async {
    try {
      final response = await _apiClient.get(
        '/chat/unread-count',
        requireAuth: true,
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true) {
          return jsonResponse['data'] ?? 0;
        } else {
          return 0;
        }
      } else {
        throw Exception(
          'Lỗi khi tải số tin nhắn chưa đọc: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Lỗi khi lấy số tin nhắn chưa đọc: $e');
      }
      return 0;
    }
  }

  // Đồng bộ tin nhắn mô phỏng lên Firebase
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

      // Tạo ID duy nhất cho tin nhắn
      final String messageId =
          '${DateTime.now().millisecondsSinceEpoch}_${message.senderEmail?.hashCode}';

      // Lưu tin nhắn lên Firebase
      await roomRef.child(messageId).set(message.toJson());

      if (kDebugMode) {
        print('Đã đồng bộ tin nhắn lên Firebase thành công');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Lỗi khi đồng bộ tin nhắn lên Firebase: $e');
      }
    }
  }

  // Thiết lập lắng nghe thay đổi từ Firebase cho phòng chat mô phỏng
  void _setupMockChatListener(String roomId) {
    // Hủy lắng nghe cũ nếu có
    _mockChatSubscriptions[roomId]?.cancel();

    try {
      // Chuyển đổi roomId thành định dạng an toàn cho Firebase
      final String safeRoomId = roomId
          .replaceAll('@', '_at_')
          .replaceAll('.', '_dot_');

      // Tham chiếu đến đường dẫn trong Firebase
      final DatabaseReference roomRef = _database.ref(
        'mock_chats/$safeRoomId/messages',
      );

      if (kDebugMode) {
        print(
          'Thiết lập lắng nghe tin nhắn mô phỏng từ Firebase cho phòng $roomId',
        );
      }

      // Lắng nghe thay đổi
      _mockChatSubscriptions[roomId] = roomRef.onChildAdded.listen((
        event,
      ) async {
        try {
          if (event.snapshot.value != null) {
            final data = Map<String, dynamic>.from(event.snapshot.value as Map);
            final ChatMessageModel message = ChatMessageModel.fromJson(data);

            // Lấy email người dùng hiện tại
            final userEmail = await _authManager.getUserEmail();

            if (userEmail != null && message.senderEmail != userEmail) {
              if (kDebugMode) {
                print('Nhận tin nhắn mới từ Firebase: ${message.content}');
              }

              // Lưu tin nhắn vào bộ nhớ cục bộ
              final ChatLocalStorage chatLocalStorage = ChatLocalStorage();

              // Kiểm tra tin nhắn đã tồn tại chưa
              final messages = await chatLocalStorage.getMessages(roomId);
              final isDuplicate = messages.any(
                (msg) =>
                    msg.content == message.content &&
                    msg.senderEmail == message.senderEmail &&
                    msg.timestamp.isAtSameMomentAs(message.timestamp),
              );

              if (!isDuplicate) {
                await chatLocalStorage.addMessage(roomId, message);

                if (kDebugMode) {
                  print('Đã lưu tin nhắn mới từ Firebase vào bộ nhớ cục bộ');
                }
              }
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('Lỗi khi xử lý tin nhắn từ Firebase: $e');
          }
        }
      });

      if (kDebugMode) {
        print('Đã thiết lập lắng nghe tin nhắn từ Firebase thành công');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Lỗi khi thiết lập lắng nghe tin nhắn từ Firebase: $e');
      }
    }
  }

  // Hủy tất cả các lắng nghe khi không cần thiết
  void dispose() {
    for (final subscription in _mockChatSubscriptions.values) {
      subscription.cancel();
    }
    _mockChatSubscriptions.clear();
  }

  // Xóa tất cả tin nhắn của một phòng chat mô phỏng
  Future<bool> clearMockChat(String roomId) async {
    try {
      if (kDebugMode) {
        print('Xóa tất cả tin nhắn của phòng chat mô phỏng: $roomId');
      }

      // Xóa tin nhắn từ bộ nhớ cục bộ
      final ChatLocalStorage chatLocalStorage = ChatLocalStorage();
      final success = await chatLocalStorage.clearMessages(roomId);

      // Xóa tin nhắn từ Firebase nếu đang sử dụng phòng mô phỏng
      if (roomId.startsWith('mock_')) {
        try {
          // Chuyển đổi roomId thành định dạng an toàn cho Firebase
          final String safeRoomId = roomId
              .replaceAll('@', '_at_')
              .replaceAll('.', '_dot_');

          // Tham chiếu đến đường dẫn trong Firebase
          final DatabaseReference roomRef = _database.ref(
            'mock_chats/$safeRoomId/messages',
          );

          // Xóa tất cả tin nhắn
          await roomRef.remove();

          if (kDebugMode) {
            print('Đã xóa tin nhắn từ Firebase cho phòng $roomId');
          }
        } catch (e) {
          if (kDebugMode) {
            print('Lỗi khi xóa tin nhắn từ Firebase: $e');
          }
        }
      }

      return success;
    } catch (e) {
      if (kDebugMode) {
        print('Lỗi khi xóa tin nhắn: $e');
      }
      return false;
    }
  }

  // Chuyển đổi chế độ mock
  bool toggleMockMode() {
    USE_MOCK_MODE = !USE_MOCK_MODE;
    if (kDebugMode) {
      print('Chế độ mock: ${USE_MOCK_MODE ? 'Bật' : 'Tắt'}');
    }
    return USE_MOCK_MODE;
  }

  // Lấy trạng thái mock hiện tại
  bool getMockModeStatus() {
    return USE_MOCK_MODE;
  }

  // Kiểm tra kết nối API và tự động chuyển đổi chế độ nếu cần
  Future<bool> checkApiConnection() async {
    try {
      if (kDebugMode) {
        print('🔍 Đang kiểm tra kết nối API...');
      }

      // Lấy email người dùng hiện tại
      final userEmail = await _authManager.getUserEmail();
      if (userEmail == null) {
        if (kDebugMode) {
          print('❌ Không thể lấy email người dùng');
        }
        USE_MOCK_MODE = true;
        return false;
      }

      // Lấy token
      final token = await _authManager.getToken();
      if (token == null) {
        if (kDebugMode) {
          print('❌ Không tìm thấy token - có thể chưa đăng nhập');
        }
        USE_MOCK_MODE = true;
        return false;
      }

      if (kDebugMode) {
        print('🔒 Token: ${token.substring(0, min(20, token.length))}...');
        print('👤 Email: $userEmail');
        print('🌐 API URL: ${_appConfig.apiBaseUrl}');
        print('🔄 WebSocket URL: ${_appConfig.webSocketUrl}');
      }

      // Kiểm tra kết nối thông qua endpoint lấy phòng chat
      final url = Uri.parse(
        '${_appConfig.apiBaseUrl}/api/chat/room/${userEmail}',
      );
      if (kDebugMode) {
        print('🔍 Kiểm tra kết nối tới: $url');
      }

      final headers = {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

      try {
        final response = await http
            .get(url, headers: headers)
            .timeout(const Duration(seconds: 5));

        if (kDebugMode) {
          print('📡 Kết quả kiểm tra API: ${response.statusCode}');
          print('📡 Headers: ${response.headers}');
          if (response.body.isNotEmpty) {
            print(
              '📡 Body: ${response.body.substring(0, min(100, response.body.length))}...',
            );
          }
        }

        // Nếu mã trạng thái là 403 (Forbidden), server vẫn đang chạy nhưng không cho phép truy cập
        // hoặc 200 OK, server đang chạy và cho phép truy cập
        // Bất kỳ phản hồi nào từ server đều cho thấy kết nối thành công
        final isSuccessResponse =
            response.statusCode >= 200 && response.statusCode < 500;

        if (isSuccessResponse) {
          if (kDebugMode) {
            print(
              '✅ Kết nối API thành công với status code: ${response.statusCode}',
            );
          }

          // Thử khởi tạo WebSocket nếu chưa kết nối
          if (!_webSocketService.isConnected()) {
            if (kDebugMode) {
              print('🔄 WebSocket chưa kết nối, thử khởi tạo kết nối...');
            }

            try {
              _webSocketService.initialize(
                _appConfig.apiBaseUrl,
                token,
                userEmail,
              );

              // Đợi một chút để WebSocket kết nối
              await Future.delayed(const Duration(seconds: 2));

              final wsConnected = _webSocketService.isConnected();
              if (kDebugMode) {
                print(
                  '🔄 Trạng thái kết nối WebSocket sau khởi tạo: ${wsConnected ? "✅ Đã kết nối" : "❌ Chưa kết nối"}',
                );
              }
            } catch (wsError) {
              if (kDebugMode) {
                print('❌ Lỗi khởi tạo WebSocket: $wsError');
              }
            }
          } else if (kDebugMode) {
            print('✅ WebSocket đã kết nối sẵn');
          }

          // Nếu kết nối thành công và đang ở chế độ mock, tự động chuyển sang chế độ online
          if (USE_MOCK_MODE) {
            USE_MOCK_MODE = false;
            if (kDebugMode) {
              print('🔄 Đã tự động chuyển sang chế độ trực tuyến');
            }
          }

          return true;
        } else {
          if (kDebugMode) {
            print('❌ Lỗi kết nối API: ${response.statusCode}');
          }

          // Nếu không kết nối được và chưa ở chế độ mock, tự động chuyển sang chế độ offline
          if (!USE_MOCK_MODE) {
            USE_MOCK_MODE = true;
            if (kDebugMode) {
              print(
                '🔄 Đã tự động chuyển sang chế độ ngoại tuyến do không kết nối được API',
              );
            }
          }

          return false;
        }
      } catch (httpError) {
        if (kDebugMode) {
          print('❌ Lỗi HTTP khi kiểm tra kết nối API: $httpError');
        }

        // Nếu có lỗi kết nối và chưa ở chế độ mock, tự động chuyển sang chế độ offline
        if (!USE_MOCK_MODE) {
          USE_MOCK_MODE = true;
          if (kDebugMode) {
            print(
              '🔄 Đã tự động chuyển sang chế độ ngoại tuyến do lỗi kết nối HTTP',
            );
          }
        }

        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Lỗi khi kiểm tra kết nối API: $e');
      }

      // Nếu có lỗi kết nối và chưa ở chế độ mock, tự động chuyển sang chế độ offline
      if (!USE_MOCK_MODE) {
        USE_MOCK_MODE = true;
        if (kDebugMode) {
          print('🔄 Đã tự động chuyển sang chế độ ngoại tuyến do lỗi kết nối');
        }
      }

      return false;
    }
  }
}
