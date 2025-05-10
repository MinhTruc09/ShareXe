import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:developer' as developer;
import '../../../models/ride.dart';
import '../../../services/ride_service.dart';
import '../../../utils/app_config.dart'; 
import '../../widgets/ride_card.dart';
import 'create_ride_screen.dart';
import '../../../app_route.dart';
import 'driver_main_screen.dart';

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

  // Danh sách đã phân loại theo trạng thái
  List<Ride> get _activeRides =>
      _myRides.where((ride) {
        final status = ride.status.toUpperCase();
        return status == 'ACTIVE' || status == 'AVAILABLE';
      }).toList();

  List<Ride> get _canceledRides =>
      _myRides.where((ride) {
        final status = ride.status.toUpperCase();
        // Sửa để khớp với trạng thái từ backend (CANCELLED có 2 chữ L)
        return status == 'CANCELLED' || status == 'CANCEL';
      }).toList();

  List<Ride> get _completedRides =>
      _myRides.where((ride) {
        final status = ride.status.toUpperCase();
        return status == 'COMPLETED' ||
            status == 'DONE' ||
            status == 'FINISHED';
      }).toList();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadRides();
  }

  @override
  void dispose() {
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
    });

    try {
      developer.log('Bắt đầu tải danh sách chuyến đi của tài xế...', name: 'my_rides');
      developer.log('API Base URL: ${_appConfig.fullApiUrl}', name: 'my_rides');
      
      final stopwatch = Stopwatch()..start();
      final rides = await _rideService.getDriverRides();
      stopwatch.stop();
      
      // Kiểm tra xem đây có phải là dữ liệu mẫu hay không (dựa trên ID)
      final isMockData = rides.isNotEmpty && 
                      rides.every((ride) => ride.id >= 1000 && ride.id < 2000);
      
      if (_isDebugMode) {
        setState(() {
          _isUsingMockData = isMockData;
          _apiResponse = isMockData 
              ? 'Đang sử dụng dữ liệu mẫu. Không thể kết nối đến API thực. Đã cố gắng $_apiCallAttempts lần.'
              : 'Đã lấy ${rides.length} chuyến đi từ API trong ${stopwatch.elapsedMilliseconds}ms';
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
        });

        // Sau khi cập nhật state, log thống kê số lượng chuyến đi theo tab
        developer.log('Phân loại chuyến đi:', name: 'my_rides');
        developer.log('- Active rides: ${_activeRides.length}', name: 'my_rides');
        developer.log('- Cancelled rides: ${_canceledRides.length}', name: 'my_rides');
        developer.log('- Completed rides: ${_completedRides.length}', name: 'my_rides');

        // Log chi tiết các chuyến đã hủy để kiểm tra
        if (_canceledRides.isNotEmpty) {
          developer.log('Danh sách chuyến đã hủy:', name: 'my_rides');
          for (var ride in _canceledRides) {
            developer.log(
              '  - Ride #${ride.id}: ${ride.departure} → ${ride.destination} (${ride.status})',
              name: 'my_rides'
            );
          }
        } else {
          developer.log('Không có chuyến đi nào đã hủy', name: 'my_rides');
        }
      }
    } catch (e) {
      developer.log('Lỗi khi tải danh sách chuyến đi: $e', name: 'my_rides', error: e);
      
      if (_isDebugMode) {
        setState(() {
          _apiResponse = 'Lỗi: $e';
          _isUsingMockData = true;
        });
      }
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể tải danh sách chuyến đi: $e')),
        );
      }
    }
  }

  Future<void> _refreshRides() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      final rides = await _rideService.getDriverRides();

      if (mounted) {
        setState(() {
          _myRides = rides;
          _isRefreshing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã cập nhật danh sách chuyến đi')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể cập nhật danh sách: $e')),
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
        _tabController.animateTo(1); // Index 1 là tab "Đã hủy"

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
    // Nếu đang ở trong DriverMainScreen, sử dụng TabNavigator
    final tabNavigator = TabNavigator.of(context);

    if (tabNavigator != null) {
      // Sử dụng navigateTo từ TabNavigator
      tabNavigator.navigateTo(context, AppRoute.createRide);
      return;
    }

    // Fallback to normal navigation
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateRideScreen()),
    );

    if (result == true) {
      _loadRides(); // Refresh the list if creation was successful
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF002D72),
        title: const Text('Chuyến đi của tôi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: _toggleDebugMode,
          ),
          if (_isDebugMode)
            IconButton(
              icon: const Icon(Icons.link),
              onPressed: _updateApiUrl,
              tooltip: 'Cập nhật API URL',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isRefreshing ? null : _refreshRides,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Đang hoạt động (${_activeRides.length})'),
            Tab(text: 'Đã hủy (${_canceledRides.length})'),
            Tab(text: 'Đã hoàn thành (${_completedRides.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_isDebugMode) _buildDebugPanel(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildRideList(_activeRides, 'ACTIVE'),
                      _buildRideList(_canceledRides, 'CANCELLED'),
                      _buildRideList(_completedRides, 'COMPLETED'),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF002D72),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateRideScreen(),
            ),
          );
          
          if (result == true) {
            _loadRides();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState([String message = 'Bạn chưa có chuyến đi nào']) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.directions_car_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(fontSize: 18, color: Color(0xFF666666)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Nhấn nút + để tạo chuyến đi mới',
            style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _createNewRide,
            icon: const Icon(Icons.add),
            label: const Text('Tạo chuyến đi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00AEEF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRideList(List<Ride> rides, String status) {
    String emptyMessage;
    
    switch (status) {
      case 'ACTIVE':
        emptyMessage = 'Bạn chưa có chuyến đi nào đang hoạt động';
        break;
      case 'CANCELLED':
        emptyMessage = 'Không có chuyến đi nào đã hủy';
        break;
      case 'COMPLETED':
        emptyMessage = 'Chưa có chuyến đi nào hoàn thành';
        break;
      default:
        emptyMessage = 'Không có chuyến đi nào trong danh sách này';
    }
    
    return RefreshIndicator(
      onRefresh: _refreshRides,
      child: rides.isEmpty
          ? _buildEmptyState(emptyMessage)
          : _buildRidesList(
              rides, 
              showActionButtons: status == 'ACTIVE', // Chỉ hiển thị nút hành động cho chuyến đang hoạt động
            ),
    );
  }

  Widget _buildRidesList(List<Ride> rides, {bool showActionButtons = true}) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: rides.length,
      itemBuilder: (context, index) {
        final ride = rides[index];
        return Column(
          children: [
            Stack(
              children: [
                RideCard(
                  ride: ride,
                  showFavorite: false,
                  showStatus: false,
                  onTap: () async {
                    // Sử dụng route riêng cho tài xế
                    Navigator.pushNamed(
                      context,
                      DriverRoutes.rideDetails,
                      arguments: ride,
                    );
                  },
                ),
                // Thêm badge trạng thái ở góc phải
                Positioned(
                  top: 12,
                  right: 12,
                  child: _buildStatusBadge(ride.status),
                ),
              ],
            ),
            if (showActionButtons) // Chỉ hiện nút hành động cho chuyến đi đang hoạt động
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _cancelRide(ride.id),
                    icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                    label: const Text(
                      'Hủy',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: ride.status.toUpperCase() == 'CANCELLED' 
                      ? null // Disable button if ride is cancelled
                      : () => _editRide(ride),
                    icon: Icon(
                      Icons.edit_outlined,
                      color: ride.status.toUpperCase() == 'CANCELLED'
                        ? Colors.grey // Grey out the icon if disabled
                        : const Color(0xFF00AEEF),
                    ),
                    label: Text(
                      'Sửa',
                      style: TextStyle(
                        color: ride.status.toUpperCase() == 'CANCELLED'
                          ? Colors.grey // Grey out the text if disabled
                          : const Color(0xFF00AEEF),
                      ),
                    ),
                  ),
                ],
              ),
            const Divider(),
          ],
        );
      },
    );
  }

  // Tạo widget hiển thị trạng thái
  Widget _buildStatusBadge(String status) {
    Color badgeColor;
    IconData badgeIcon;
    String badgeText;

    switch (status.toUpperCase()) {
      case 'ACTIVE':
      case 'AVAILABLE':
        badgeColor = Colors.green;
        badgeIcon = Icons.check_circle;
        badgeText = 'Đang hoạt động';
        break;
      case 'CANCELLED':
      case 'CANCEL':
        badgeColor = Colors.red;
        badgeIcon = Icons.cancel;
        badgeText = 'Đã hủy';
        break;
      case 'COMPLETED':
      case 'DONE':
      case 'FINISHED':
        badgeColor = Colors.blue;
        badgeIcon = Icons.task_alt;
        badgeText = 'Đã hoàn thành';
        break;
      default:
        badgeColor = Colors.grey;
        badgeIcon = Icons.info;
        badgeText = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: badgeColor.withOpacity(0.5), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badgeIcon, size: 14, color: badgeColor),
          const SizedBox(width: 4),
          Text(
            badgeText,
            style: TextStyle(
              color: badgeColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
