import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/ride.dart';
import '../../../services/ride_service.dart';
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
  List<Ride> _myRides = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  late TabController _tabController;

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

  Future<void> _loadRides() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final rides = await _rideService.getDriverRides();

      if (mounted) {
        // Kiểm tra trạng thái thực tế của chuyến đi
        for (var ride in rides) {
          print(
            '🚗 Ride #${ride.id}: Status = ${ride.status} (${ride.status.toUpperCase()})',
          );
        }

        setState(() {
          _myRides = rides;
          _isLoading = false;
        });

        // Sau khi cập nhật state, log thống kê số lượng chuyến đi theo tab
        print('📊 Phân loại chuyến đi:');
        print('- Active rides: ${_activeRides.length}');
        print('- Cancelled rides: ${_canceledRides.length}');
        print('- Completed rides: ${_completedRides.length}');

        // Log chi tiết các chuyến đã hủy để kiểm tra
        if (_canceledRides.isNotEmpty) {
          print('🚫 Danh sách chuyến đã hủy:');
          for (var ride in _canceledRides) {
            print(
              '  - Ride #${ride.id}: ${ride.departure} → ${ride.destination} (${ride.status})',
            );
          }
        } else {
          print('🚫 Không có chuyến đi nào đã hủy');
        }
      }
    } catch (e) {
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
          if (_isRefreshing)
            const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refreshRides,
            ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.directions_car), text: 'Đang có'),
            Tab(icon: Icon(Icons.cancel_outlined), text: 'Đã hủy'),
            Tab(icon: Icon(Icons.check_circle_outline), text: 'Hoàn thành'),
          ],
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Chuyến đi đang có
                  RefreshIndicator(
                    onRefresh: _refreshRides,
                    child:
                        _activeRides.isEmpty
                            ? _buildEmptyState(
                              'Bạn chưa có chuyến đi nào đang hoạt động',
                            )
                            : _buildRidesList(
                              _activeRides,
                              showActionButtons: true,
                            ),
                  ),
                  // Tab 2: Chuyến đi đã hủy
                  RefreshIndicator(
                    onRefresh: _refreshRides,
                    child:
                        _canceledRides.isEmpty
                            ? _buildEmptyState('Không có chuyến đi nào đã hủy')
                            : _buildRidesList(
                              _canceledRides,
                              showActionButtons: false,
                            ),
                  ),
                  // Tab 3: Chuyến đi đã hoàn thành
                  RefreshIndicator(
                    onRefresh: _refreshRides,
                    child:
                        _completedRides.isEmpty
                            ? _buildEmptyState(
                              'Chưa có chuyến đi nào hoàn thành',
                            )
                            : _buildRidesList(
                              _completedRides,
                              showActionButtons: false,
                            ),
                  ),
                ],
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewRide,
        backgroundColor: const Color(0xFF00AEEF),
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
                    onPressed: () => _editRide(ride),
                    icon: const Icon(
                      Icons.edit_outlined,
                      color: Color(0xFF00AEEF),
                    ),
                    label: const Text(
                      'Sửa',
                      style: TextStyle(color: Color(0xFF00AEEF)),
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
