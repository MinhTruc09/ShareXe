import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/ride.dart';
import '../../../services/ride_service.dart';
import '../../../services/auth_service.dart';
import '../../widgets/ride_card.dart';
import '../../widgets/location_picker.dart';
import '../../widgets/date_picker.dart';
import '../../widgets/passenger_counter.dart';
import '../../../app_route.dart';
import '../chat/chat_list_screen.dart';
import 'package:sharexe/controllers/auth_controller.dart';
import 'package:sharexe/views/screens/passenger/profile_screen.dart';
import 'package:sharexe/views/widgets/sharexe_background2.dart';
import 'package:sharexe/views/widgets/ride_search_card.dart';
import 'package:sharexe/views/widgets/recent_searches.dart';

class HomePscreen extends StatefulWidget {
  const HomePscreen({super.key});

  @override
  State<HomePscreen> createState() => _HomePscreenState();
}

class _HomePscreenState extends State<HomePscreen> {
  final RideService _rideService = RideService();
  final AuthService _authService = AuthService();
  late AuthController _authController;
  int _currentIndex = 0;

  String _departure = '';
  String _destination = '';
  DateTime? _departureDate;
  int _passengerCount = 1;

  List<Ride> _availableRides = [];
  bool _isLoading = false;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _authController = AuthController(AuthService());
    _fetchAvailableRides();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _fetchAvailableRides() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('🔍 Fetching available rides from API...');
      // Fetching available rides from the specific endpoint
      final rides = await _rideService.getAvailableRides();

      print('✅ Successfully fetched ${rides.length} rides from API');

      if (mounted) {
        setState(() {
          _availableRides = rides;
          _isLoading = false;
        });

        if (rides.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không có chuyến xe phù hợp')),
          );
        }
      }
    } catch (e) {
      print('❌ Error fetching rides: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          // Set empty list on error
          _availableRides = [];
        });
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể tải danh sách chuyến xe: $e')),
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
      print('🔄 Refreshing available rides from API...');
      final rides = await _rideService.getAvailableRides();

      print('✅ Successfully refreshed ${rides.length} rides from API');

      if (mounted) {
        setState(() {
          _availableRides = rides;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã cập nhật danh sách chuyến xe')),
        );
      }
    } catch (e) {
      print('❌ Error refreshing rides: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể cập nhật danh sách: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  Future<void> _searchRides() async {
    if (_departure.isEmpty && _destination.isEmpty && _departureDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập ít nhất một điều kiện tìm kiếm'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final rides = await _rideService.searchRides(
        departure: _departure,
        destination: _destination,
        startTime: _departureDate,
        passengerCount: _passengerCount,
      );

      setState(() {
        _availableRides = rides;
        _isLoading = false;
      });

      if (rides.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không tìm thấy chuyến xe phù hợp')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tìm thấy ${rides.length} chuyến đi phù hợp')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi tìm kiếm: $e')));
    }
  }

  void _logout() async {
    try {
      await _authController.logout();
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoute.role);
      }
    } catch (e) {
      print(e);
    }
  }

  void _onBottomNavTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeContent();
      case 1:
        return const Center(child: Text('Trang Chuyến đi'));
      case 2:
        return const ChatListScreen();
      case 3:
        return const ProfileScreen();
      default:
        return _buildHomeContent();
    }
  }

  Widget _buildHomeContent() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: RideSearchCard(
              onSearch: (departure, destination, date) {
                setState(() {
                  _departure = departure;
                  _destination = destination;
                  _departureDate = date;
                });
                _searchRides();
              },
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: RecentSearches(),
          ),
          // Display available rides
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: CircularProgressIndicator(),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildRidesList(),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SharexeBackground2(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('ShareXE'),
          backgroundColor: const Color(0xFF00AEEF),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _logout,
            ),
          ],
        ),
        body: _buildBody(),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF00AEEF),
          unselectedItemColor: Colors.grey,
          currentIndex: _currentIndex,
          onTap: _onBottomNavTap,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
            BottomNavigationBarItem(
              icon: Icon(Icons.history),
              label: 'Chuyến đi',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Tin nhắn'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Cá nhân'),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            LocationPicker(
              title: 'Điểm đi',
              icon: Icons.circle_outlined,
              hintText: 'Xuất phát từ',
              onLocationSelected: (location) {
                setState(() {
                  _departure = location;
                });
              },
            ),
            const Divider(height: 1),
            LocationPicker(
              title: 'Điểm đến',
              icon: Icons.location_on_outlined,
              hintText: 'Điểm đến',
              onLocationSelected: (location) {
                setState(() {
                  _destination = location;
                });
              },
            ),
            const Divider(height: 1),
            DatePickerField(
              icon: Icons.access_time,
              hintText: 'Thời gian xuất phát',
              onDateSelected: (date) {
                setState(() {
                  _departureDate = date;
                });
              },
            ),
            const Divider(height: 1),
            PassengerCounter(
              icon: Icons.people_outline,
              hintText: 'Số lượng',
              onCountChanged: (count) {
                setState(() {
                  _passengerCount = count;
                });
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _searchRides,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF002D62),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Tìm chuyến', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRidesList() {
    if (_availableRides.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Text(
            'Không có chuyến xe nào phù hợp với tìm kiếm của bạn',
            style: TextStyle(color: Colors.white, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _availableRides.length,
      itemBuilder: (context, index) {
        try {
          return RideCard(
            ride: _availableRides[index],
            onTap: () async {
              // Load ride details when tapped
              final rideId = _availableRides[index].id;
              final rideDetails = await _rideService.getRideDetails(rideId);

              if (mounted && rideDetails != null) {
                // Show ride details (you'd have a screen for this)
                Navigator.pushNamed(
                  context,
                  AppRoute.rideDetails,
                  arguments: rideDetails,
                );
              }
            },
          );
        } catch (e) {
          // Handle any rendering errors for individual cards
          print('Error rendering ride card at index $index: $e');
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            color: Colors.red.shade100,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Lỗi hiển thị chuyến xe: $e',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          );
        }
      },
    );
  }
}
