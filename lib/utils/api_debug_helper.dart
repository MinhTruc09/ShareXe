import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import '../utils/app_config.dart';
import 'package:http/http.dart' as http;
import '../services/auth_manager.dart';
import 'dart:convert';

class ApiDebugHelper {
  static final ApiDebugHelper _instance = ApiDebugHelper._internal();
  factory ApiDebugHelper() => _instance;
  ApiDebugHelper._internal();

  final AppConfig _appConfig = AppConfig();
  final AuthManager _authManager = AuthManager();

  // Danh sách endpoints muốn theo dõi
  final List<Map<String, dynamic>> debugEndpoints = [
    // Authentication
    {
      'name': 'Passenger Register',
      'endpoint': '/auth/passenger-register',
      'description': 'Đăng ký tài khoản hành khách',
      'requireAuth': false,
    },
    {
      'name': 'Driver Register',
      'endpoint': '/auth/driver-register',
      'description': 'Đăng ký tài khoản tài xế',
      'requireAuth': false,
    },
    {
      'name': 'Login',
      'endpoint': '/auth/login',
      'description': 'Đăng nhập',
      'requireAuth': false,
    },
    // Chat
    {
      'name': 'Chat Rooms',
      'endpoint': '/chat/rooms',
      'description': 'Lấy danh sách phòng chat',
      'requireAuth': true,
    },
    {
      'name': 'Chat Room by Email',
      'endpoint': '/chat/room/test@example.com',
      'description': 'Lấy ID phòng chat theo email',
      'requireAuth': true,
    },
    {
      'name': 'Chat Messages',
      'endpoint': '/chat/1',
      'description': 'Lấy tin nhắn của phòng chat',
      'requireAuth': true,
    },
    {
      'name': 'Send Chat Message',
      'endpoint': '/chat/test/1',
      'description': 'Gửi tin nhắn qua HTTP',
      'requireAuth': true,
    },
    {
      'name': 'Mark Chat Read',
      'endpoint': '/chat/1/mark-read',
      'description': 'Đánh dấu tin nhắn đã đọc',
      'requireAuth': true,
    },
    // Driver
    {
      'name': 'Driver Profile',
      'endpoint': '/driver/profile',
      'description': 'Lấy thông tin cá nhân tài xế',
      'requireAuth': true,
    },
    {
      'name': 'Driver Rides',
      'endpoint': '/driver/my-rides',
      'description': 'Lấy danh sách chuyến đi của tài xế',
      'requireAuth': true,
    },
    {
      'name': 'Driver Bookings',
      'endpoint': '/driver/bookings',
      'description': 'Lấy danh sách đặt chỗ của tài xế',
      'requireAuth': true,
    },
    {
      'name': 'Driver Accept Booking',
      'endpoint': '/driver/accept/1',
      'description': 'Chấp nhận đặt chỗ',
      'requireAuth': true,
    },
    {
      'name': 'Driver Reject Booking',
      'endpoint': '/driver/reject/1',
      'description': 'Từ chối đặt chỗ',
      'requireAuth': true,
    },
    {
      'name': 'Driver Complete Ride',
      'endpoint': '/driver/complete/1',
      'description': 'Xác nhận hoàn thành chuyến đi',
      'requireAuth': true,
    },
    // Notifications
    {
      'name': 'Notifications',
      'endpoint': '/notifications',
      'description': 'Lấy danh sách thông báo',
      'requireAuth': true,
    },
    {
      'name': 'Unread Notification Count',
      'endpoint': '/notifications/unread-count',
      'description': 'Đếm số thông báo chưa đọc',
      'requireAuth': true,
    },
    {
      'name': 'Mark Notification Read',
      'endpoint': '/notifications/1/read',
      'description': 'Đánh dấu thông báo đã đọc',
      'requireAuth': true,
    },
    {
      'name': 'Mark All Notifications Read',
      'endpoint': '/notifications/read-all',
      'description': 'Đánh dấu tất cả thông báo đã đọc',
      'requireAuth': true,
    },
    // Passenger
    {
      'name': 'Passenger Profile',
      'endpoint': '/passenger/profile',
      'description': 'Lấy thông tin cá nhân hành khách',
      'requireAuth': true,
    },
    {
      'name': 'Passenger Bookings',
      'endpoint': '/passenger/bookings',
      'description': 'Lấy danh sách đặt chỗ của hành khách',
      'requireAuth': true,
    },
    {
      'name': 'Passenger Booking Detail',
      'endpoint': '/passenger/booking/1',
      'description': 'Lấy chi tiết đặt chỗ',
      'requireAuth': true,
    },
    {
      'name': 'Create Passenger Booking',
      'endpoint': '/passenger/booking/1',
      'description': 'Đặt chỗ cho chuyến đi',
      'requireAuth': true,
    },
    {
      'name': 'Passenger Confirm Ride',
      'endpoint': '/passenger/passenger-confirm/1',
      'description': 'Xác nhận hoàn thành chuyến đi',
      'requireAuth': true,
    },
    {
      'name': 'Cancel Passenger Booking',
      'endpoint': '/passenger/cancel-bookings/1',
      'description': 'Hủy đặt chỗ',
      'requireAuth': true,
    },
    // Rides
    {
      'name': 'Ride Detail',
      'endpoint': '/ride/1',
      'description': 'Xem chi tiết chuyến đi',
      'requireAuth': true,
    },
    {
      'name': 'Available Rides',
      'endpoint': '/ride/available',
      'description': 'Danh sách chuyến đi đang hoạt động',
      'requireAuth': false,
    },
    {
      'name': 'Search Rides',
      'endpoint': '/ride/search',
      'description': 'Tìm kiếm chuyến đi',
      'requireAuth': false,
    },
    {
      'name': 'All Rides',
      'endpoint': '/ride/all-rides',
      'description': 'Lấy tất cả chuyến đi',
      'requireAuth': true,
    },
    {
      'name': 'Create Ride',
      'endpoint': '/ride',
      'description': 'Tạo chuyến đi',
      'requireAuth': true,
    },
    {
      'name': 'Update Ride',
      'endpoint': '/ride/update/1',
      'description': 'Cập nhật chuyến đi',
      'requireAuth': true,
    },
    {
      'name': 'Cancel Ride',
      'endpoint': '/ride/cancel/1',
      'description': 'Hủy chuyến đi',
      'requireAuth': true,
    },
    // Tracking
    {
      'name': 'Send Tracking Data',
      'endpoint': '/tracking/test/1',
      'description': 'Gửi vị trí driver',
      'requireAuth': true,
    },
    // User
    {
      'name': 'Update User Profile',
      'endpoint': '/user/update-profile',
      'description': 'Cập nhật thông tin cá nhân',
      'requireAuth': true,
    },
    {
      'name': 'Change Password',
      'endpoint': '/user/change-pass',
      'description': 'Thay đổi mật khẩu',
      'requireAuth': true,
    },
    // Health Check
    {
      'name': 'Health Check',
      'endpoint': '/health',
      'description': 'Kiểm tra kết nối API',
      'requireAuth': false,
    },
  ];

  // Kiểm tra kết nối đến API
  Future<bool> testApiConnection() async {
    developer.log(
      'Kiểm tra kết nối đến API: ${_appConfig.fullApiUrl}',
      name: 'api_debug',
    );

    try {
      final response = await http
          .get(Uri.parse('${_appConfig.fullApiUrl}/health'))
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              throw Exception('Kết nối quá hạn');
            },
          );

      developer.log(
        'Kết quả kiểm tra API: ${response.statusCode}',
        name: 'api_debug',
      );

      // Kiểm tra phản hồi
      if (response.statusCode == 200) {
        developer.log('Kết nối thành công!', name: 'api_debug');
        return true;
      }

      // Nếu nhận được bất kỳ phản hồi nào (ngay cả 404) từ server, URL vẫn hoạt động
      if (response.statusCode != 502 && response.statusCode != 504) {
        developer.log(
          'URL hoạt động nhưng endpoint không tìm thấy',
          name: 'api_debug',
        );
        return true;
      }

      developer.log(
        'Kết nối thất bại: Mã lỗi ${response.statusCode}',
        name: 'api_debug',
      );
      return false;
    } catch (e) {
      developer.log(
        'Lỗi khi kiểm tra kết nối: $e',
        name: 'api_debug',
        error: e,
      );
      return false;
    }
  }

  // Kiểm tra một endpoint cụ thể
  Future<Map<String, dynamic>> testEndpoint(
    String endpoint, {
    bool requireAuth = true,
  }) async {
    developer.log(
      'Kiểm tra endpoint: ${_appConfig.fullApiUrl}$endpoint',
      name: 'api_debug',
    );

    try {
      final uri = Uri.parse('${_appConfig.fullApiUrl}$endpoint');
      final headers = <String, String>{'Content-Type': 'application/json'};

      // Thêm token nếu cần xác thực
      if (requireAuth) {
        // Lấy token từ local storage
        final token = await _authManager.getToken();
        if (token != null) {
          headers['Authorization'] = 'Bearer $token';
        } else {
          developer.log(
            'Thiếu token xác thực, endpoint có thể không hoạt động',
            name: 'api_debug',
          );
        }
      }

      final response = await http
          .get(uri, headers: headers)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Kết nối quá hạn');
            },
          );

      developer.log(
        'Kết quả endpoint $endpoint: ${response.statusCode}',
        name: 'api_debug',
      );

      // Phân tích kết quả
      return {
        'success': response.statusCode >= 200 && response.statusCode < 300,
        'statusCode': response.statusCode,
        'body': response.body,
        'contentType': response.headers['content-type'] ?? 'unknown',
        'endpoint': endpoint,
      };
    } catch (e) {
      developer.log(
        'Lỗi khi kiểm tra endpoint $endpoint: $e',
        name: 'api_debug',
        error: e,
      );
      return {
        'success': false,
        'statusCode': 0,
        'body': e.toString(),
        'contentType': 'error',
        'endpoint': endpoint,
      };
    }
  }

  // Kiểm tra xem có sử dụng mock data không
  Future<bool> isUsingMockData(String endpoint) async {
    final result = await testEndpoint(endpoint);
    if (!result['success']) return true;

    try {
      final data = json.decode(result['body']);
      if (data['data'] is List && data['data'].isNotEmpty) {
        // Kiểm tra ID có là mock data không (thường ID >= 1000 cho mock data)
        return data['data'].every(
          (item) => item['id'] >= 1000 && item['id'] < 10000,
        );
      }
    } catch (e) {
      developer.log('Lỗi khi phân tích dữ liệu: $e', name: 'api_debug');
    }

    return true;
  }

  // Hiển thị dialog cập nhật URL API
  void showUpdateApiUrlDialog(BuildContext context, {Function? onUpdated}) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Cập nhật API URL'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('URL hiện tại: ${_appConfig.apiBaseUrl}'),
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Nhập URL mới',
                    hintText: 'https://your-ngrok-url.ngrok-free.app',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (value) {
                    if (value.isNotEmpty) {
                      _appConfig.updateBaseUrl(value);
                      Navigator.pop(context);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Đã cập nhật API URL: $value')),
                      );

                      // Gọi hàm callback nếu có
                      if (onUpdated != null) {
                        onUpdated();
                      }
                    }
                  },
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
                  Navigator.pop(context);
                  _appConfig.updateBaseUrl(
                    'https://carpooling-j5xn.onrender.com',
                  );

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã cập nhật về URL mặc định'),
                    ),
                  );

                  // Gọi hàm callback nếu có
                  if (onUpdated != null) {
                    onUpdated();
                  }
                },
                child: const Text('Khôi phục mặc định'),
              ),
            ],
          ),
    );
  }

  // Hiển thị trang debug API
  void showApiDebugScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ApiDebugScreen()),
    );
  }
}

class ApiDebugScreen extends StatefulWidget {
  const ApiDebugScreen({Key? key}) : super(key: key);

  @override
  _ApiDebugScreenState createState() => _ApiDebugScreenState();
}

class _ApiDebugScreenState extends State<ApiDebugScreen> {
  final ApiDebugHelper _apiDebugHelper = ApiDebugHelper();
  final AppConfig _appConfig = AppConfig();
  final AuthManager _authManager = AuthManager();
  bool _isTestingConnection = false;
  String _connectionStatus = '';
  String? _tokenStatus;
  bool _isLoadingToken = true;
  Map<String, dynamic>? _selectedEndpointResult;
  bool _isTestingEndpoint = false;

  @override
  void initState() {
    super.initState();
    _testApiConnection();
    _checkToken();
  }

  Future<void> _checkToken() async {
    setState(() {
      _isLoadingToken = true;
    });

    try {
      final token = await _authManager.getToken();
      if (token != null) {
        // Chỉ hiển thị 10 ký tự đầu của token
        setState(() {
          _tokenStatus = "Valid token: ${token.substring(0, 10)}...";
          _isLoadingToken = false;
        });
      } else {
        setState(() {
          _tokenStatus = "No token available";
          _isLoadingToken = false;
        });
      }
    } catch (e) {
      setState(() {
        _tokenStatus = "Error checking token: $e";
        _isLoadingToken = false;
      });
    }
  }

  Future<void> _testApiConnection() async {
    setState(() {
      _isTestingConnection = true;
      _connectionStatus = 'Đang kiểm tra kết nối...';
    });

    try {
      final isWorking = await _apiDebugHelper.testApiConnection();

      setState(() {
        _isTestingConnection = false;
        _connectionStatus =
            isWorking
                ? 'Kết nối API thành công ✅'
                : 'Không thể kết nối đến API ❌';
      });
    } catch (e) {
      setState(() {
        _isTestingConnection = false;
        _connectionStatus = 'Lỗi kiểm tra kết nối: $e';
      });
    }
  }

  Future<void> _testEndpoint(Map<String, dynamic> endpoint) async {
    setState(() {
      _isTestingEndpoint = true;
      _selectedEndpointResult = null;
    });

    try {
      final result = await _apiDebugHelper.testEndpoint(
        endpoint['endpoint'],
        requireAuth: endpoint['requireAuth'] ?? true,
      );

      setState(() {
        _selectedEndpointResult = result;
        _isTestingEndpoint = false;
      });
    } catch (e) {
      setState(() {
        _selectedEndpointResult = {'success': false, 'error': e.toString()};
        _isTestingEndpoint = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF002D72),
        title: const Text('Kiểm tra kết nối API'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current API URL section
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'API URL',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _appConfig.apiBaseUrl,
                      style: const TextStyle(
                        fontSize: 14,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Full API URL: ${_appConfig.fullApiUrl}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Connection status
                    Row(
                      children: [
                        const Text('Trạng thái:'),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _connectionStatus,
                            style: TextStyle(
                              color:
                                  _connectionStatus.contains('thành công')
                                      ? Colors.green
                                      : _connectionStatus.contains('kiểm tra')
                                      ? Colors.orange
                                      : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (_isTestingConnection)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                      ],
                    ),

                    // Token status
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('Token:'),
                        const SizedBox(width: 8),
                        Expanded(
                          child:
                              _isLoadingToken
                                  ? const Text('Đang kiểm tra token...')
                                  : Text(
                                    _tokenStatus ?? 'Không có token',
                                    style: TextStyle(
                                      color:
                                          _tokenStatus != null &&
                                                  _tokenStatus!.contains(
                                                    'Valid',
                                                  )
                                              ? Colors.green
                                              : Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                        ),
                        if (_isLoadingToken)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    // Action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton(
                          onPressed: _testApiConnection,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                          ),
                          child: const Text('Kiểm tra lại'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            _apiDebugHelper.showUpdateApiUrlDialog(
                              context,
                              onUpdated: () {
                                _testApiConnection();
                                _checkToken();
                              },
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                          ),
                          child: const Text('Thay đổi URL'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Các API Endpoint',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            // List of available endpoints
            ...List.generate(_apiDebugHelper.debugEndpoints.length, (index) {
              final endpoint = _apiDebugHelper.debugEndpoints[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(endpoint['name']),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        endpoint['endpoint'],
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        endpoint['description'],
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      if (endpoint['requireAuth'] == true)
                        const Text(
                          "Yêu cầu xác thực",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                  trailing: ElevatedButton(
                    onPressed: () => _testEndpoint(endpoint),
                    child: const Text('Test'),
                  ),
                  onTap: () => _testEndpoint(endpoint),
                ),
              );
            }),

            // Result section
            if (_selectedEndpointResult != null) ...[
              const SizedBox(height: 24),
              const Text(
                'Kết quả kiểm tra',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _selectedEndpointResult!['success'] == true
                                ? Icons.check_circle
                                : Icons.error,
                            color:
                                _selectedEndpointResult!['success'] == true
                                    ? Colors.green
                                    : Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _selectedEndpointResult!['success'] == true
                                ? 'Thành công (${_selectedEndpointResult!['statusCode']})'
                                : 'Thất bại (${_selectedEndpointResult!['statusCode']})',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color:
                                  _selectedEndpointResult!['success'] == true
                                      ? Colors.green
                                      : Colors.red,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text('Phản hồi:'),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        width: double.infinity,
                        child: Text(
                          _selectedEndpointResult!['body'] != null
                              ? _selectedEndpointResult!['body']
                                          .toString()
                                          .length >
                                      500
                                  ? '${_selectedEndpointResult!['body'].toString().substring(0, 500)}...'
                                  : _selectedEndpointResult!['body'].toString()
                              : 'Không có dữ liệu phản hồi',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),
            // Troubleshooting section
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Xử lý sự cố',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '1. Kiểm tra ngrok URL có còn hoạt động không (thường hết hạn sau 2 giờ)',
                    ),
                    Text(
                      '2. Chạy lại ngrok trên máy local và cập nhật URL mới',
                    ),
                    Text('3. Kiểm tra backend API có đang chạy không'),
                    Text('4. Kiểm tra xác thực token còn hợp lệ không'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
