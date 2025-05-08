import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/ride.dart';
import '../../../services/ride_service.dart';
import '../../widgets/ride_card.dart';
import 'create_ride_screen.dart';
import '../../../app_route.dart';

class MyRidesScreen extends StatefulWidget {
  const MyRidesScreen({Key? key}) : super(key: key);

  @override
  State<MyRidesScreen> createState() => _MyRidesScreenState();
}

class _MyRidesScreenState extends State<MyRidesScreen> {
  final RideService _rideService = RideService();
  List<Ride> _myRides = [];
  bool _isLoading = true;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _loadRides();
  }

  Future<void> _loadRides() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final rides = await _rideService.getDriverRides();

      if (mounted) {
        setState(() {
          _myRides = rides;
          _isLoading = false;
        });
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
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _refreshRides,
                child:
                    _myRides.isEmpty ? _buildEmptyState() : _buildRidesList(),
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewRide,
        backgroundColor: const Color(0xFF00AEEF),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
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
          const Text(
            'Bạn chưa có chuyến đi nào',
            style: TextStyle(fontSize: 18, color: Color(0xFF666666)),
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

  Widget _buildRidesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _myRides.length,
      itemBuilder: (context, index) {
        final ride = _myRides[index];
        return Column(
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
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _cancelRide(ride.id),
                  icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                  label: const Text('Hủy', style: TextStyle(color: Colors.red)),
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
}
