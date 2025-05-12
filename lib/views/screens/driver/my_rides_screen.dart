import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:developer' as developer;
import '../../../models/ride.dart';
import '../../../services/ride_service.dart';
import '../../../utils/app_config.dart'; 
import '../../widgets/ride_card.dart';
import '../../widgets/sharexe_background2.dart';
import 'create_ride_screen.dart';
import '../../../app_route.dart';
import 'driver_main_screen.dart';
import '../../../utils/api_debug_helper.dart';
import '../../../utils/navigation_helper.dart';
import 'dart:io';
import 'dart:async'; // Thêm import Timer

class MyRidesScreen extends StatefulWidget {
  const MyRidesScreen({Key? key}) : super(key: key);

  @override
  State<MyRidesScreen> createState() => _MyRidesScreenState();
}

class _MyRidesScreenState extends State<MyRidesScreen>
    with SingleTickerProviderStateMixin {
  final RideService _rideService = RideService();
  final AppConfig _appConfig = AppConfig();
  List<Ride> _myRides = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  late TabController _tabController;
  bool _isDebugMode = false;
  String _apiResponse = '';
  bool _isUsingMockData = false;
  DateTime _lastRefreshTime = DateTime.now();
  int _apiCallAttempts = 0;
  bool _hasNetworkError = false;
  String _errorMessage = '';
  Timer? _autoRefreshTimer; // Timer để tự động làm mới
  List<int> _inProgressRideIds = []; // Lưu ID các chuyến đang diễn ra để phát hiện thay đổi

  // Danh sách đã phân loại theo trạng thái
  // Hàm chung để so sánh 2 chuyến đi theo thời gian mới nhất đến cũ nhất
  int _compareRidesByDate(Ride a, Ride b) {
    try {
      DateTime dateA = DateTime.tryParse(a.startTime) ?? DateTime.now();
      DateTime dateB = DateTime.tryParse(b.startTime) ?? DateTime.now();
      return dateB.compareTo(dateA); // Sắp xếp giảm dần (mới nhất trước)
    } catch (e) {
      developer.log('❌ Lỗi khi so sánh ngày: $e', name: 'my_rides');
      return 0; // Giữ nguyên thứ tự nếu có lỗi
    }
  }

  // Kiểm tra nếu chuyến đi đang diễn ra
  bool _isRideInProgress(Ride ride) {
    try {
      // Sử dụng trạng thái IN_PROGRESS mới từ backend
      return ride.status.toUpperCase() == 'IN_PROGRESS';
    } catch (e) {
      developer.log('❌ Lỗi khi kiểm tra trạng thái chuyến đi: $e', name: 'my_rides');
      return false;
    }
  }

  List<Ride> get _pendingRides =>
      _myRides.where((ride) {
        final status = ride.status.toUpperCase();
        return status == 'PENDING' || status == 'WAITING_APPROVAL';
      }).toList()
      ..sort(_compareRidesByDate);
      
  List<Ride> get _activeRides =>
      _myRides.where((ride) {
        final status = ride.status.toUpperCase();
        // Chỉ hiển thị chuyến đi có trạng thái ACTIVE 
        // và KHÔNG nằm trong nhóm chuyến đang diễn ra
        return (status == 'ACTIVE' || status == 'AVAILABLE') && !_isRideInProgress(ride);
      }).toList()
      ..sort(_compareRidesByDate);

  List<Ride> get _inProgressRides =>
      _myRides.where((ride) {
        // Chuyến đang diễn ra:
        // Trạng thái ACTIVE và đang trong thời gian diễn ra
        return _isRideInProgress(ride);
      }).toList()
      ..sort(_compareRidesByDate);

  List<Ride> get _canceledRides =>
      _myRides.where((ride) {
        final status = ride.status.toUpperCase();
        // Sửa để khớp với trạng thái từ backend (CANCELLED có 2 chữ L)
        return status == 'CANCELLED' || status == 'CANCEL';
      }).toList()
      ..sort(_compareRidesByDate);

  List<Ride> get _completedRides =>
      _myRides.where((ride) {
        final status = ride.status.toUpperCase();
        return status == 'COMPLETED' ||
            status == 'DONE' ||
            status == 'FINISHED';
      }).toList()
      ..sort(_compareRidesByDate);

  List<Ride> get _driverConfirmedRides =>
      _myRides.where((ride) {
        final status = ride.status.toUpperCase();
        return status == 'DRIVER_CONFIRMED';
      }).toList()
      ..sort(_compareRidesByDate);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this); // Thêm 1 tab cho Driver Confirmed
    _loadRides();
    // Khởi tạo timer làm mới tự động mỗi 30 giây
    _startAutoRefreshTimer();
  }

  void _startAutoRefreshTimer() {
    // Hủy timer cũ nếu có
    _autoRefreshTimer?.cancel();
    // Tạo timer mới để làm mới mỗi 30 giây
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      // Chỉ làm mới nếu màn hình đang hiển thị và không đang trong quá trình làm mới
      if (mounted && !_isRefreshing && !_isLoading) {
        _silentRefreshRides();
      }
    });
  }

  // Làm mới "im lặng" không hiển thị loading spinner hay thông báo
  Future<void> _silentRefreshRides() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      // Lưu lại danh sách ID chuyến đang diễn ra trước khi làm mới
      final previousInProgressRideIds = _inProgressRideIds.toList();
      
      final rides = await _rideService.getDriverRides();
      rides.sort(_compareRidesByDate);

      if (mounted) {
        setState(() {
          _myRides = rides;
          _isRefreshing = false;
          _lastRefreshTime = DateTime.now();
          
          // Cập nhật danh sách ID chuyến đi đang diễn ra
          final inProgressRides = rides.where(
            (ride) => _isRideInProgress(ride)
          ).toList();
          final currentInProgressRideIds = inProgressRides.map((ride) => ride.id).toList();
          
          // Tìm các chuyến đi mới chuyển sang trạng thái "Đang diễn ra"
          final newInProgressRides = currentInProgressRideIds
              .where((id) => !previousInProgressRideIds.contains(id))
              .toList();
          
          // Cập nhật danh sách ID
          _inProgressRideIds = currentInProgressRideIds;
          
          // Nếu có chuyến mới bắt đầu và đang ở tab khác, thông báo và chuyển tab
          if (newInProgressRides.isNotEmpty && _tabController.index != 2) {
            // Hiển thị thông báo có chuyến đi mới bắt đầu
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Có ${newInProgressRides.length} chuyến đi mới bắt đầu'),
                  action: SnackBarAction(
                    label: 'Xem ngay',
                    onPressed: () {
                      // Chuyển đến tab "Đang diễn ra"
                      _tabController.animateTo(2);
                    },
                  ),
                ),
              );
            });
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
        
        // Không hiển thị thông báo lỗi khi làm mới im lặng
        developer.log('Lỗi khi làm mới im lặng: $e', name: 'my_rides');
      }
    }
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel(); // Hủy timer khi widget bị hủy
    _tabController.dispose();
    super.dispose();
  }

  void _toggleDebugMode() {
    setState(() {
      _isDebugMode = !_isDebugMode;
    });
    
    if (_isDebugMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã bật chế độ debug')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã tắt chế độ debug')),
      );
    }
  }

  void _updateApiUrl() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
                  
                  _loadRides();
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
              _appConfig.updateBaseUrl('https://6e3a-1-54-152-77.ngrok-free.app');
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã cập nhật về URL mặc định')),
              );
              
              _loadRides();
            },
            child: const Text('Khôi phục mặc định'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadRides() async {
    setState(() {
      _isLoading = true;
      _apiResponse = '';
      _apiCallAttempts++;
      _hasNetworkError = false;
      _errorMessage = '';
    });

    try {
      developer.log('Bắt đầu tải danh sách chuyến đi của tài xế...', name: 'my_rides');
      developer.log('API Base URL: ${_appConfig.fullApiUrl}', name: 'my_rides');
      
      final stopwatch = Stopwatch()..start();
      final rides = await _rideService.getDriverRides();
      stopwatch.stop();
      
      // Sắp xếp chuyến đi theo thời gian mới nhất đến cũ nhất ngay khi nhận từ API
      rides.sort(_compareRidesByDate);
      developer.log('Đã sắp xếp ${rides.length} chuyến đi theo thời gian mới nhất', name: 'my_rides');
      
      // Thêm debug log để kiểm tra tất cả trạng thái trong response
      _debugLogAllRideStatuses(rides);
      
      // Kiểm tra xem đây có phải là dữ liệu mẫu hay không (dựa trên ID)
      final isMockData = rides.isNotEmpty && 
                      rides.every((ride) => ride.id >= 1000 && ride.id < 2000);
      
      if (_isDebugMode) {
        setState(() {
          _isUsingMockData = isMockData;
          _apiResponse = isMockData 
              ? 'Đang sử dụng dữ liệu mẫu' 
              : 'Đã lấy ${rides.length} chuyến đi từ API trong ${_getElapsedTime()}ms';
          _lastRefreshTime = DateTime.now();
        });
      }

      if (mounted) {
        // Kiểm tra trạng thái thực tế của chuyến đi
        for (var ride in rides) {
          developer.log(
            'Ride #${ride.id}: Status = ${ride.status} (${ride.status.toUpperCase()})',
            name: 'my_rides'
          );
        }

        setState(() {
          _myRides = rides;
          _isLoading = false;
          _hasNetworkError = false;
          
          // Khởi tạo danh sách ID chuyến đi đang diễn ra
          final inProgressRides = rides.where(
            (ride) => _isRideInProgress(ride)
          ).toList();
          _inProgressRideIds = inProgressRides.map((ride) => ride.id).toList();
          
          // Kiểm tra nếu có chuyến đi đang diễn ra, tự động chuyển tab
          if (inProgressRides.isNotEmpty) {
            // Chỉ hiển thị thông báo nếu tab hiện tại không phải Đang diễn ra (index 2)
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_tabController.index != 2) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Bạn có ${inProgressRides.length} chuyến đi đang diễn ra'),
                    action: SnackBarAction(
                      label: 'Xem ngay',
                      onPressed: () {
                        _tabController.animateTo(2);
                      },
                    ),
                  ),
                );
              }
            });
          }
        });

        // Sau khi cập nhật state, log thống kê số lượng chuyến đi theo tab
        developer.log('Phân loại chuyến đi:', name: 'my_rides');
        developer.log('- Pending rides: ${_pendingRides.length}', name: 'my_rides');
        developer.log('- Active rides: ${_activeRides.length}', name: 'my_rides');
        developer.log('- In Progress rides: ${_inProgressRides.length}', name: 'my_rides');
        developer.log('- Driver Confirmed rides: ${_driverConfirmedRides.length}', name: 'my_rides');
        developer.log('- Cancelled rides: ${_canceledRides.length}', name: 'my_rides');
        developer.log('- Completed rides: ${_completedRides.length}', name: 'my_rides');

        // Log chi tiết các chuyến đang chờ duyệt
        if (_pendingRides.isNotEmpty) {
          developer.log('Danh sách chuyến đang chờ duyệt:', name: 'my_rides');
          for (var ride in _pendingRides) {
            developer.log(
              '  - Ride #${ride.id}: ${ride.departure} → ${ride.destination} (${ride.status}) - Time: ${ride.startTime}',
              name: 'my_rides'
            );
          }
        } else {
          developer.log('Không có chuyến đi nào đang chờ duyệt', name: 'my_rides');
        }
      }
    } catch (e) {
      developer.log('Lỗi khi tải danh sách chuyến đi: $e', name: 'my_rides', error: e);
      
      // Xác định loại lỗi
      String errorMessage = 'Không thể tải danh sách chuyến đi';
      bool isNetworkError = false;

      if (e is SocketException || 
          e.toString().contains('SocketException') || 
          e.toString().contains('Network is unreachable')) {
        errorMessage = 'Không có kết nối mạng. Vui lòng kiểm tra kết nối internet của bạn.';
        isNetworkError = true;
      } else if (e.toString().contains('TimeoutException')) {
        errorMessage = 'Kết nối tới máy chủ quá lâu. Vui lòng thử lại sau.';
        isNetworkError = true;
      }
      
      if (_isDebugMode) {
        setState(() {
          _apiResponse = 'Lỗi: $e';
          _isUsingMockData = true;
        });
      }
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasNetworkError = isNetworkError;
          _errorMessage = errorMessage;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Thử lại',
              textColor: Colors.white,
              onPressed: _loadRides,
            ),
          ),
        );
      }
    }
  }

  Future<void> _refreshRides() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
      _hasNetworkError = false;
    });

    try {
      // Lưu lại danh sách ID chuyến đang diễn ra trước khi làm mới
      final previousInProgressRideIds = _inProgressRideIds.toList();
      
      final rides = await _rideService.getDriverRides();
      
      // Sắp xếp chuyến đi theo thời gian mới nhất
      rides.sort(_compareRidesByDate);
      developer.log('Đã sắp xếp ${rides.length} chuyến đi sau khi làm mới', name: 'my_rides');

      // Kiểm tra xem đây có phải là dữ liệu mẫu hay không (dựa trên ID)
      final isMockData = rides.isNotEmpty && 
                      rides.every((ride) => ride.id >= 1000 && ride.id < 2000);
      
      if (_isDebugMode) {
        setState(() {
          _isUsingMockData = isMockData;
          _apiResponse = isMockData 
              ? 'Đang sử dụng dữ liệu mẫu' 
              : 'Đã lấy ${rides.length} chuyến đi từ API trong ${_getElapsedTime()}ms';
          _lastRefreshTime = DateTime.now();
        });
      }

      if (mounted) {
        setState(() {
          _myRides = rides;
          _isRefreshing = false;
          
          // Cập nhật danh sách ID chuyến đi đang diễn ra
          final inProgressRides = rides.where(
            (ride) => _isRideInProgress(ride)
          ).toList();
          final currentInProgressRideIds = inProgressRides.map((ride) => ride.id).toList();
          
          // Kiểm tra có chuyến đi mới chuyển sang trạng thái "Đang diễn ra" không
          final newInProgressRides = currentInProgressRideIds
              .where((id) => !previousInProgressRideIds.contains(id))
              .toList();
              
          // Cập nhật danh sách ID
          _inProgressRideIds = currentInProgressRideIds;
          
          // Nếu có chuyến mới bắt đầu và không đang ở tab Đang diễn ra
          if (newInProgressRides.isNotEmpty && _tabController.index != 2) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Có ${newInProgressRides.length} chuyến đi mới bắt đầu'),
                  action: SnackBarAction(
                    label: 'Xem ngay',
                    onPressed: () {
                      _tabController.animateTo(2);
                    },
                  ),
                ),
              );
            });
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã cập nhật danh sách chuyến đi')),
        );
      }
    } catch (e) {
      // Xác định loại lỗi
      String errorMessage = 'Không thể cập nhật danh sách';
      bool isNetworkError = false;

      if (e is SocketException || 
          e.toString().contains('SocketException') || 
          e.toString().contains('Network is unreachable')) {
        errorMessage = 'Không có kết nối mạng. Vui lòng kiểm tra kết nối internet của bạn.';
        isNetworkError = true;
      } else if (e.toString().contains('TimeoutException')) {
        errorMessage = 'Kết nối tới máy chủ quá lâu. Vui lòng thử lại sau.';
        isNetworkError = true;
      }
      
      if (mounted) {
        setState(() {
          _isRefreshing = false;
          if (isNetworkError) {
            _hasNetworkError = true;
            _errorMessage = errorMessage;
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Thử lại',
              textColor: Colors.white,
              onPressed: _refreshRides,
            ),
          ),
        );
      }
    }
  }

  Widget _buildDebugPanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      color: Colors.black87,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _isUsingMockData ? Icons.warning : Icons.check_circle,
                color: _isUsingMockData ? Colors.orange : Colors.green,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _isUsingMockData 
                      ? 'Đang sử dụng dữ liệu mẫu' 
                      : 'Đang sử dụng dữ liệu thực từ API',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                'Cập nhật: ${DateFormat('HH:mm:ss').format(_lastRefreshTime)}',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'API URL: ${_appConfig.fullApiUrl}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          if (_apiResponse.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _apiResponse,
                style: TextStyle(
                  color: _isUsingMockData ? Colors.orange : Colors.green,
                  fontSize: 12,
                ),
              ),
            ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: _loadRides,
                icon: const Icon(Icons.refresh, size: 14, color: Colors.white),
                label: const Text(
                  'Làm mới',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.blue.shade900,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _cancelRide(int rideId) async {
    // Hiển thị dialog xác nhận
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Xác nhận hủy chuyến đi'),
            content: const Text(
              'Bạn có chắc chắn muốn hủy chuyến đi này không?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Không'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Có, hủy chuyến'),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _rideService.cancelRide(rideId);

      if (success && mounted) {
        // Cập nhật danh sách sau khi hủy chuyến đi
        await _loadRides();

        // Chuyển sang tab "Đã hủy" để người dùng thấy ngay chuyến đi đã hủy
        _tabController.animateTo(4); // Index 4 là tab "Đã hủy" sau khi thêm tab Đã xác nhận

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã hủy chuyến đi thành công'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể hủy chuyến đi'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  Future<void> _editRide(Ride ride) async {
    // Kiểm tra trạng thái của chuyến đi
    if (ride.status.toUpperCase() == 'CANCELLED') {
      // Hiển thị thông báo không thể chỉnh sửa chuyến đi đã hủy
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể chỉnh sửa chuyến đi đã hủy'),
          backgroundColor: Colors.red,
        ),
      );
      return; // Ngừng thực hiện phương thức
    }

    final Map<String, dynamic> rideData = {
      'id': ride.id,
      'departure': ride.departure,
      'destination': ride.destination,
      'startTime': ride.startTime,
      'totalSeat': ride.totalSeat,
      'pricePerSeat': ride.pricePerSeat,
      'status': ride.status,
    };

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateRideScreen(existingRide: rideData),
      ),
    );

    if (result == true) {
      _loadRides(); // Refresh the list if edit was successful
    }
  }

  Future<void> _createNewRide() async {
    // Sử dụng NavigationHelper để điều hướng đến trang tạo chuyến đi
    final result = await Navigator.pushNamed(
      context, 
      DriverRoutes.createRide
    );

    if (result == true) {
      _loadRides(); // Refresh the list if creation was successful
    }
  }

  Future<void> _confirmRideCompletion(int rideId) async {
    // Hiển thị dialog xác nhận
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận hoàn thành'),
        content: const Text(
          'Bạn có chắc chắn muốn xác nhận chuyến đi này đã hoàn thành không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Không'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Có, xác nhận hoàn thành'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Gọi API để xác nhận chuyến đi đã hoàn thành
      final success = await _rideService.driverCompleteRide(rideId);

      if (success && mounted) {
        // Cập nhật danh sách 
        await _loadRides();

        // Chuyển sang tab "Đã xác nhận"
        _tabController.animateTo(3); // Index 3 là tab "Đã xác nhận" 

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã xác nhận hoàn thành chuyến đi thành công'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể xác nhận hoàn thành chuyến đi'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF002D72),
        title: const Text('Chuyến đi của tôi', 
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: 0.5,
          )
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report, color: Colors.white70),
            onPressed: _toggleDebugMode,
            tooltip: 'Debug mode',
          ),
          if (_isDebugMode)
            IconButton(
              icon: const Icon(Icons.link, color: Colors.white70),
              onPressed: _updateApiUrl,
              tooltip: 'Cập nhật API URL',
            ),
          IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return RotationTransition(
                  turns: animation,
                  child: FadeTransition(opacity: animation, child: child),
                );
              },
              child: _isRefreshing
                ? const Icon(Icons.refresh, key: ValueKey('refreshing'), color: Colors.white38)
                : const Icon(Icons.refresh, key: ValueKey('refresh'), color: Colors.white70),
            ),
            onPressed: _isRefreshing ? null : _refreshRides,
            tooltip: 'Làm mới',
          ),
        ],
        bottom: _hasNetworkError 
          ? null 
          : PreferredSize(
              preferredSize: const Size.fromHeight(kToolbarHeight),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF002D72),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.normal,
                    fontSize: 13,
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  indicatorColor: const Color(0xFF00AEEF),
                  indicatorWeight: 3,
                  indicatorSize: TabBarIndicatorSize.label,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  labelPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  tabs: [
                    _buildTabItem(Icons.pending_actions, 'Chờ duyệt', _pendingRides.length),
                    _buildTabItem(Icons.schedule, 'Sắp tới', _activeRides.length),
                    _buildTabItem(Icons.directions_car, 'Đang diễn ra', _inProgressRides.length),
                    _buildTabItem(Icons.verified, 'Đã xác nhận', _driverConfirmedRides.length),
                    _buildTabItem(Icons.cancel_outlined, 'Đã hủy', _canceledRides.length),
                    _buildTabItem(Icons.done_all, 'Đã hoàn thành', _completedRides.length),
                  ],
                ),
              ),
            ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00AEEF)))
          : _hasNetworkError 
              ? _buildNetworkErrorWidget()
              : SharexeBackground2(
                  child: Column(
                    children: [
                      if (_isDebugMode) _buildDebugPanel(),
                      
                      // Stats summary
                      if (!_isDebugMode && _myRides.isNotEmpty)
                        _buildStatsSummary(),
                      
                      Expanded(
                        child: RefreshIndicator(
                          color: const Color(0xFF00AEEF),
                          onRefresh: _refreshRides,
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              _buildRideList(_pendingRides, 'PENDING'),
                              _buildRideList(_activeRides, 'ACTIVE'),
                              _buildRideList(_inProgressRides, 'IN_PROGRESS'),
                              _buildRideList(_driverConfirmedRides, 'DRIVER_CONFIRMED'),
                              _buildRideList(_canceledRides, 'CANCELLED'),
                              _buildRideList(_completedRides, 'COMPLETED'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF00AEEF),
        elevation: 6,
        onPressed: _createNewRide,
        child: const Icon(Icons.add),
      ),
    );
  }

  // Tab item with icon and count
  Widget _buildTabItem(IconData icon, String text, int count) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 4),
          Text(text),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF00AEEF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Statistics summary at the top
  Widget _buildStatsSummary() {
    final totalRides = _myRides.length;
    final activeRides = _activeRides.length + _inProgressRides.length + _driverConfirmedRides.length;
    final completedRides = _completedRides.length;
    
    // Calculate total revenue from completed rides
    final totalRevenue = _completedRides.fold(0.0, 
      (sum, ride) => sum + (ride.pricePerSeat ?? 0.0) * (ride.totalSeat - (ride.availableSeats ?? 0)));
    
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 110, 16, 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF002D72), Color(0xFF00509E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 8, top: 4, bottom: 10),
            child: Text(
              'Tổng quan chuyến đi',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(Icons.directions_car, totalRides.toString(), 'Tổng số'),
              _buildStatItem(Icons.play_circle_outline, activeRides.toString(), 'Đang hoạt động'),
              _buildStatItem(Icons.done_all, completedRides.toString(), 'Đã hoàn thành'),
              _buildStatItem(Icons.attach_money, formatter.format(totalRevenue), 'Doanh thu'),
            ],
          ),
        ],
      ),
    );
  }

  // Single stat item
  Widget _buildStatItem(IconData icon, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkErrorWidget() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.cloud_off,
                size: 60,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _errorMessage,
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _loadRides,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00AEEF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            if (_isDebugMode) 
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: OutlinedButton.icon(
                  onPressed: _updateApiUrl,
                  icon: const Icon(Icons.settings),
                  label: const Text('Cấu hình API URL'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey.shade700,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    side: BorderSide(color: Colors.grey.shade400),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRideList(List<Ride> rides, String status) {
    String emptyMessage;
    IconData emptyIcon;
    
    switch (status) {
      case 'PENDING':
        emptyMessage = 'Không có chuyến đi nào đang chờ duyệt';
        emptyIcon = Icons.pending_actions;
        break;
      case 'ACTIVE':
        emptyMessage = 'Bạn chưa có chuyến đi nào sắp tới';
        emptyIcon = Icons.schedule;
        break;
      case 'IN_PROGRESS':
        emptyMessage = 'Không có chuyến đi nào đang diễn ra';
        emptyIcon = Icons.directions_car;
        break;
      case 'DRIVER_CONFIRMED':
        emptyMessage = 'Không có chuyến đi nào đã được xác nhận';
        emptyIcon = Icons.verified;
        break;
      case 'CANCELLED':
        emptyMessage = 'Không có chuyến đi nào đã hủy';
        emptyIcon = Icons.cancel_outlined;
        break;
      case 'COMPLETED':
        emptyMessage = 'Chưa có chuyến đi nào hoàn thành';
        emptyIcon = Icons.done_all;
        break;
      default:
        emptyMessage = 'Không có chuyến đi nào trong danh sách này';
        emptyIcon = Icons.directions_car_outlined;
    }
    
    if (rides.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(emptyIcon, size: 48, color: Colors.grey.shade400),
              ),
              const SizedBox(height: 24),
              Text(
                emptyMessage,
                style: TextStyle(
                  fontSize: 16, 
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Nhấn nút + để tạo chuyến đi mới',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _createNewRide,
                icon: const Icon(Icons.add),
                label: const Text('Tạo chuyến đi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00AEEF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 100, left: 16, right: 16, bottom: 24),
      itemCount: rides.length,
      itemBuilder: (context, index) {
        final ride = rides[index];
        
        // Xác định các hành động dựa trên trạng thái
        final bool canCancel = status == 'ACTIVE' || status == 'PENDING';
        final bool canEdit = status != 'CANCELLED' && status != 'COMPLETED' && 
                        status != 'DRIVER_CONFIRMED' && status != 'IN_PROGRESS';
        final bool canConfirm = status == 'IN_PROGRESS'; // Chỉ IN_PROGRESS mới có thể xác nhận
        
        return Column(
          children: [
            RideCard(
              ride: ride,
              showFavorite: false,
              showStatus: true,
              isDriverView: true, // Quan trọng: Đánh dấu đây là view của tài xế
              onTap: () async {
                // Sử dụng route riêng cho tài xế
                await Navigator.pushNamed(
                  context,
                  DriverRoutes.rideDetails,
                  arguments: ride,
                );
                // Làm mới danh sách sau khi quay lại
                _loadRides();
              },
              onConfirmComplete: canConfirm ? () => _confirmRideCompletion(ride.id) : null,
            ),
            
            // Hiển thị các nút hành động với thiết kế đẹp hơn
            if (canCancel || canEdit)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (canCancel)
                        OutlinedButton.icon(
                          onPressed: () => _cancelRide(ride.id),
                          icon: const Icon(Icons.cancel_outlined, size: 18),
                          label: const Text('Hủy chuyến'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                      if (canCancel && canEdit)
                        const SizedBox(width: 12),
                      if (canEdit)
                        ElevatedButton.icon(
                          onPressed: () => _editRide(ride),
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: const Text('Sửa thông tin'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00AEEF),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            if (!canCancel && !canEdit)
              const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  String _getElapsedTime() {
    final stopwatch = Stopwatch();
    stopwatch.start();
    stopwatch.stop();
    return stopwatch.elapsedMilliseconds.toString();
  }

  // Thêm phương thức debug để in ra tất cả trạng thái chuyến đi
  void _debugLogAllRideStatuses(List<Ride> rides) {
    developer.log('Danh sách trạng thái chuyến đi:', name: 'my_rides');
    for (var ride in rides) {
      developer.log('Ride #${ride.id}: ${ride.departure} -> ${ride.destination} | Status: ${ride.status}',
          name: 'my_rides');
    }
    
    // Tìm và in các chuyến đi ở trạng thái DRIVER_CONFIRMED nếu có
    final driverConfirmedRides = rides.where((r) => 
        r.status.toUpperCase() == 'DRIVER_CONFIRMED').toList();
    
    if (driverConfirmedRides.isNotEmpty) {
      developer.log('Tìm thấy ${driverConfirmedRides.length} chuyến ở trạng thái DRIVER_CONFIRMED:',
          name: 'my_rides');
      for (var ride in driverConfirmedRides) {
        developer.log('Driver confirmed ride #${ride.id}: ${ride.departure} -> ${ride.destination}',
            name: 'my_rides');
      }
    } else {
      developer.log('Không tìm thấy chuyến nào ở trạng thái DRIVER_CONFIRMED',
          name: 'my_rides');
    }
  }
}
