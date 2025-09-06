import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/user_profile.dart';
import '../models/user_update_request.dart';
import '../utils/app_config.dart';
import 'auth_manager.dart';

class ProfileService {
  final AuthManager _authManager = AuthManager();
  final AppConfig _appConfig = AppConfig();

  // Phương thức lấy thông tin người dùng
  Future<ProfileResponse> getUserProfile() async {
    try {
      final token = await _authManager.getToken();
      if (token == null) {
        return ProfileResponse(
          success: false,
          message: 'Chưa đăng nhập',
          data: null,
        );
      }

      // Kiểm tra session có hợp lệ không trước khi gọi API
      final bool isSessionValid = await _authManager.validateSession();
      if (!isSessionValid) {
        print(
          'ProfileService: Phiên đăng nhập đã hết hạn (phát hiện trước khi gọi API)',
        );
        return ProfileResponse(
          success: false,
          message: 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
          data: null,
        );
      }

      // Lấy vai trò người dùng từ token
      final userRole = await _authManager.getUserRole();

      // Chọn endpoint phù hợp dựa vào vai trò
      String endpoint;
      if (userRole?.toUpperCase() == 'DRIVER') {
        endpoint = _appConfig.getEndpoint('driver/profile');
      } else {
        endpoint = _appConfig.getEndpoint('passenger/profile');
      }

      print('Đang gọi API: $endpoint');

      final response = await http
          .get(
            Uri.parse(endpoint),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Kết nối máy chủ quá hạn. Vui lòng thử lại sau.');
            },
          );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 401 || response.statusCode == 403) {
        print(
          'ProfileService: Phiên đăng nhập đã hết hạn (phát hiện từ response API)',
        );

        // Nếu API trả về lỗi xác thực, đảm bảo đăng xuất khỏi phiên hiện tại
        await _authManager.logout();

        return ProfileResponse(
          success: false,
          message: 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
          data: null,
        );
      }

      // Kiểm tra nếu response body rỗng hoặc không hợp lệ
      if (response.body == null || response.body.isEmpty) {
        return ProfileResponse(
          success: false,
          message: 'Máy chủ không trả về dữ liệu. Có thể URL ngrok đã hết hạn.',
          data: null,
        );
      }

      try {
        // Parse JSON từ response body
        final responseBody = json.decode(response.body);

        // Debug: In ra toàn bộ response body
        print('DEBUG: Parsed response body: $responseBody');

        // Kiểm tra cấu trúc response từ backend
        if (responseBody is Map<String, dynamic>) {
          // Kiểm tra nếu response có cấu trúc {success: true, message: "...", data: {...}}
          if (responseBody.containsKey('success')) {
            if (response.statusCode == 200 && responseBody['success'] == true) {
              // Debug: In ra data trước khi parse
              print(
                'DEBUG: Profile data before parsing: ${responseBody['data']}',
              );

              // Thêm debug cho URL avatar
              if (responseBody['data'] != null && responseBody['data'] is Map) {
                print(
                  'DEBUG: Avatar URL from API: ${responseBody['data']['avatarUrl']}',
                );
              }

              // Kiểm tra xem data có null không
              if (responseBody['data'] == null) {
                return ProfileResponse(
                  success: false,
                  message: 'Không có dữ liệu hồ sơ',
                  data: null,
                );
              }

              final profile = UserProfile.fromJson(responseBody['data']);

              // Debug: In ra profile sau khi parse
              print(
                'DEBUG: Profile after parsing - avatarUrl: ${profile.avatarUrl}',
              );

              return ProfileResponse(
                success: true,
                message: responseBody['message'] ?? 'Thành công',
                data: profile,
              );
            } else {
              return ProfileResponse(
                success: false,
                message:
                    responseBody['message'] ??
                    'Không thể tải thông tin người dùng',
                data: null,
              );
            }
          }
          // Nếu response là trực tiếp dữ liệu người dùng từ /api/driver/profile
          else if (responseBody.containsKey('id') &&
              (responseBody.containsKey('email') ||
                  responseBody.containsKey('fullName'))) {
            return ProfileResponse(
              success: true,
              message: 'Thành công',
              data: UserProfile.fromJson(responseBody),
            );
          }
          // Trường hợp khác
          else {
            return ProfileResponse(
              success: false,
              message: 'Định dạng dữ liệu không đúng',
              data: null,
            );
          }
        } else {
          return ProfileResponse(
            success: false,
            message: 'Định dạng dữ liệu không đúng',
            data: null,
          );
        }
      } catch (parseError) {
        print('Lỗi khi parse JSON: $parseError');
        print('Response body: ${response.body}');
        return ProfileResponse(
          success: false,
          message:
              'Không thể hiển thị hồ sơ, máy chủ trả về dữ liệu không hợp lệ.',
          data: null,
        );
      }
    } on SocketException catch (_) {
      return ProfileResponse(
        success: false,
        message:
            'Không thể kết nối đến máy chủ. Vui lòng kiểm tra kết nối mạng.',
        data: null,
      );
    } catch (e) {
      return ProfileResponse(
        success: false,
        message: 'Lỗi: ${e.toString()}',
        data: null,
      );
    }
  }

  // Phương thức cập nhật thông tin cá nhân của hành khách
  Future<ProfileResponse> updateUserProfile({
    required String fullName,
    required String phoneNumber,
    File? avatarImage,
  }) async {
    try {
      final token = await _authManager.getToken();
      if (token == null) {
        return ProfileResponse(
          success: false,
          message: 'Chưa đăng nhập',
          data: null,
        );
      }

      final uri = Uri.parse(_appConfig.getEndpoint('user/update-profile'));

      var request = http.MultipartRequest('PUT', uri);
      request.headers['Authorization'] = 'Bearer $token';

      // Thêm các trường text
      request.fields['fullName'] = fullName;
      request.fields['phone'] = phoneNumber;

      // Thêm ảnh đại diện nếu có
      if (avatarImage != null) {
        final fileExtension = avatarImage.path.split('.').last;
        request.files.add(
          await http.MultipartFile.fromPath(
            'avatarImage',
            avatarImage.path,
            contentType: MediaType('image', fileExtension),
          ),
        );
      }

      print('Đang gửi request cập nhật hồ sơ...');
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Kết nối máy chủ quá hạn. Vui lòng thử lại sau.');
        },
      );
      final response = await http.Response.fromStream(streamedResponse);
      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      // Xử lý lỗi xác thực nhưng KHÔNG trả về lỗi phiên đăng nhập hết hạn
      // nếu cập nhật thành công
      if (response.statusCode == 401 || response.statusCode == 403) {
        return ProfileResponse(
          success: false,
          message: 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
          data: null,
        );
      }

      try {
        if (response.body.isEmpty) {
          if (response.statusCode >= 200 && response.statusCode < 300) {
            return ProfileResponse(
              success: true,
              message: 'Cập nhật thành công',
              data: null,
            );
          } else {
            return ProfileResponse(
              success: false,
              message: 'Lỗi không xác định (${response.statusCode})',
              data: null,
            );
          }
        }

        final responseData = json.decode(response.body);
        if (response.statusCode == 200) {
          // Kiểm tra nếu response có trường success
          if (responseData is Map<String, dynamic> &&
              responseData.containsKey('success')) {
            if (responseData['success'] == true) {
              return ProfileResponse(
                success: true,
                message: responseData['message'] ?? 'Cập nhật thành công',
                data: null,
              );
            } else {
              return ProfileResponse(
                success: false,
                message: responseData['message'] ?? 'Lỗi không xác định',
                data: null,
              );
            }
          } else {
            // Nếu response không có trường success nhưng status code là 200
            // thì vẫn xem là thành công
            return ProfileResponse(
              success: true,
              message: 'Cập nhật thành công',
              data: null,
            );
          }
        } else {
          return ProfileResponse(
            success: false,
            message: responseData['message'] ?? 'Lỗi không xác định',
            data: null,
          );
        }
      } catch (parseError) {
        print('Lỗi khi parse JSON: $parseError');
        if (response.statusCode >= 200 && response.statusCode < 300) {
          // Nếu status code thành công nhưng không parse được JSON
          return ProfileResponse(
            success: true,
            message: 'Cập nhật thành công',
            data: null,
          );
        }
        return ProfileResponse(
          success: false,
          message: 'Lỗi định dạng dữ liệu: ${parseError.toString()}',
          data: null,
        );
      }
    } on SocketException catch (_) {
      return ProfileResponse(
        success: false,
        message:
            'Không thể kết nối đến máy chủ. Vui lòng kiểm tra kết nối mạng.',
        data: null,
      );
    } catch (e) {
      return ProfileResponse(success: false, message: 'Lỗi: $e', data: null);
    }
  }

  // Phương thức cập nhật thông tin cá nhân
  Future<ProfileResponse> updateProfile({
    required UserUpdateRequestDTO userUpdateRequestDTO,
  }) async {
    try {
      final token = await _authManager.getToken();
      if (token == null) {
        return ProfileResponse(
          success: false,
          message: 'Chưa đăng nhập',
          data: null,
        );
      }

      // Endpoint chung cho mọi người dùng
      final endpoint = _appConfig.getEndpoint('user/update-profile');

      print('Gửi request đến: $endpoint');

      final requestBody = {
        'userUpdateRequestDTO': userUpdateRequestDTO.toJson(),
      };

      print('Request body: $requestBody');

      final response = await http
          .put(
            Uri.parse(endpoint),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: json.encode(requestBody),
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw Exception('Kết nối máy chủ quá hạn. Vui lòng thử lại sau.');
            },
          );
      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      // Xử lý lỗi xác thực
      if (response.statusCode == 401 || response.statusCode == 403) {
        String errorMsg =
            'Phiên đăng nhập đã hết hạn hoặc không có quyền thực hiện. Vui lòng đăng nhập lại.';

        // Hiển thị thêm chi tiết lỗi để debug
        if (response.body.contains('@PutMapping') ||
            response.body.contains('@RequestParam')) {
          errorMsg =
              'Lỗi: Server trả về mã nguồn thay vì xử lý request. Vui lòng kiểm tra URL hoặc cấu hình server.';
        }

        return ProfileResponse(success: false, message: errorMsg, data: null);
      }

      try {
        if (response.body.isEmpty) {
          if (response.statusCode >= 200 && response.statusCode < 300) {
            return ProfileResponse(
              success: true,
              message: 'Cập nhật thành công',
              data: null,
            );
          } else {
            return ProfileResponse(
              success: false,
              message: 'Lỗi không xác định (${response.statusCode})',
              data: null,
            );
          }
        }

        // Kiểm tra response có phải là JSON không
        if (!response.body.startsWith('{') && !response.body.startsWith('[')) {
          // Không phải JSON, có thể là HTML hoặc văn bản khác
          if (response.statusCode >= 200 && response.statusCode < 300) {
            return ProfileResponse(
              success: true,
              message: 'Cập nhật thành công',
              data: null,
            );
          } else {
            return ProfileResponse(
              success: false,
              message: 'Lỗi server: ${response.statusCode}',
              data: null,
            );
          }
        }

        final responseData = json.decode(response.body);
        if (response.statusCode == 200) {
          // Kiểm tra nếu response có trường success
          if (responseData is Map<String, dynamic> &&
              responseData.containsKey('success')) {
            if (responseData['success'] == true) {
              return ProfileResponse(
                success: true,
                message: responseData['message'] ?? 'Cập nhật thành công',
                data: null,
              );
            } else {
              return ProfileResponse(
                success: false,
                message: responseData['message'] ?? 'Lỗi không xác định',
                data: null,
              );
            }
          } else {
            // Nếu response không có trường success nhưng status code là 200
            // thì vẫn xem là thành công
            return ProfileResponse(
              success: true,
              message: 'Cập nhật thành công',
              data: null,
            );
          }
        } else {
          return ProfileResponse(
            success: false,
            message: responseData['message'] ?? 'Lỗi không xác định',
            data: null,
          );
        }
      } catch (parseError) {
        print('Lỗi khi parse JSON: $parseError');
        if (response.statusCode >= 200 && response.statusCode < 300) {
          // Nếu status code thành công nhưng không parse được JSON
          return ProfileResponse(
            success: true,
            message: 'Cập nhật thành công',
            data: null,
          );
        }
        return ProfileResponse(
          success: false,
          message: 'Lỗi định dạng dữ liệu: ${parseError.toString()}',
          data: null,
        );
      }
    } on SocketException catch (_) {
      return ProfileResponse(
        success: false,
        message:
            'Không thể kết nối đến máy chủ. Vui lòng kiểm tra kết nối mạng.',
        data: null,
      );
    } catch (e) {
      return ProfileResponse(success: false, message: 'Lỗi: $e', data: null);
    }
  }

  // Phương thức đổi mật khẩu
  Future<ProfileResponse> changePassword({
    required ChangePasswordRequest changePasswordRequest,
  }) async {
    try {
      final token = await _authManager.getToken();
      if (token == null) {
        return ProfileResponse(
          success: false,
          message: 'Chưa đăng nhập',
          data: null,
        );
      }

      // Endpoint chung cho mọi người dùng
      final endpoint = _appConfig.getEndpoint('user/change-pass');
      print('Gửi request đổi mật khẩu đến: $endpoint');

      final response = await http
          .put(
            Uri.parse(endpoint),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: json.encode(changePasswordRequest.toJson()),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Kết nối máy chủ quá hạn. Vui lòng thử lại sau.');
            },
          );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 401 || response.statusCode == 403) {
        return ProfileResponse(
          success: false,
          message: 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
          data: null,
        );
      }

      if (response.statusCode == 200) {
        try {
          // Attempt to parse the response body as JSON
          final responseData = json.decode(response.body);
          if (responseData is String) {
            // If the response is a string, use it directly
            return ProfileResponse(
              success: true,
              message: responseData,
              data: null,
            );
          } else if (responseData is Map<String, dynamic>) {
            // If the response is an object with a message field
            return ProfileResponse(
              success: true,
              message: responseData['message'] ?? 'Đổi mật khẩu thành công',
              data: null,
            );
          } else {
            return ProfileResponse(
              success: true,
              message: 'Đổi mật khẩu thành công',
              data: null,
            );
          }
        } catch (parseError) {
          // If we can't parse the response as JSON, assume it's a direct message string
          return ProfileResponse(
            success: true,
            message: response.body,
            data: null,
          );
        }
      } else {
        try {
          final responseData = json.decode(response.body);
          return ProfileResponse(
            success: false,
            message: responseData['message'] ?? 'Lỗi không xác định',
            data: null,
          );
        } catch (parseError) {
          return ProfileResponse(
            success: false,
            message: 'Lỗi khi đổi mật khẩu: ${response.body}',
            data: null,
          );
        }
      }
    } on SocketException catch (_) {
      return ProfileResponse(
        success: false,
        message:
            'Không thể kết nối đến máy chủ. Vui lòng kiểm tra kết nối mạng.',
        data: null,
      );
    } catch (e) {
      return ProfileResponse(success: false, message: 'Lỗi: $e', data: null);
    }
  }
}

class ProfileResponse {
  final bool success;
  final String message;
  final UserProfile? data;

  ProfileResponse({required this.success, required this.message, this.data});
}
