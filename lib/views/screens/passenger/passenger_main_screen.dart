import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:sharexe/app_route.dart';
import 'new_home_pscreen.dart';
import '../chat/user_list_screen.dart';
import 'profile_screen.dart';
import '../../widgets/notification_badge.dart';
import 'passenger_bookings_screen.dart';
import '../../widgets/custom_bottom_nav_bar.dart';

// InheritedWidget để cung cấp truy cập vào điều hướng bottom bar
class TabNavigator extends InheritedWidget {
  final Function(int) navigateToTab;
  final int currentIndex;
  final Function(BuildContext, String, {Object? arguments}) navigateTo;
  final VoidCallback refreshHomeTab;

  const TabNavigator({
    Key? key,
    required this.navigateToTab,
    required this.currentIndex,
    required this.navigateTo,
    required this.refreshHomeTab,
    required Widget child,
  }) : super(key: key, child: child);

  static TabNavigator? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<TabNavigator>();
  }

  @override
  bool updateShouldNotify(TabNavigator oldWidget) {
    return currentIndex != oldWidget.currentIndex;
  }
}

class PassengerMainScreen extends StatefulWidget {
  const PassengerMainScreen({Key? key}) : super(key: key);

  // Get TabNavigator from context
  static TabNavigator? of(BuildContext context) {
    return TabNavigator.of(context);
  }

  @override
  State<PassengerMainScreen> createState() => _PassengerMainScreenState();
}

class _PassengerMainScreenState extends State<PassengerMainScreen> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  final GlobalKey<NewHomePscreenState> _homeScreenKey = GlobalKey<NewHomePscreenState>();

  // Danh sách các màn hình chính
  late final List<Widget> _screens;

  // Các tùy chọn menu cho Passenger
  final List<NavBarItem> _navItems = [
    const NavBarItem(
      icon: CupertinoIcons.home,
      activeIcon: CupertinoIcons.house_fill,
      label: 'Trang chủ',
    ),
    const NavBarItem(
      icon: CupertinoIcons.clock,
      activeIcon: CupertinoIcons.clock_fill,
      label: 'Đặt chỗ',
    ),
    const NavBarItem(
      icon: CupertinoIcons.chat_bubble,
      activeIcon: CupertinoIcons.chat_bubble_fill,
      label: 'Liên hệ',
    ),
    const NavBarItem(
      icon: CupertinoIcons.person,
      activeIcon: CupertinoIcons.person_fill,
      label: 'Cá nhân',
    ),
  ];

  @override
  void initState() {
    super.initState();
    
    // Initialize screens with key for home screen
    _screens = [
      NewHomePscreen(key: _homeScreenKey),
      const PassengerBookingsScreen(),
      const UserListScreen(),
      const ProfileScreen(),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (index == _currentIndex) return;

    setState(() {
      _currentIndex = index;
    });

    // Sử dụng PageController để chuyển tab ngay lập tức
    _pageController.jumpToPage(index);
  }

  void _onPageChanged(int index) {
    if (index == _currentIndex) return;

    setState(() {
      _currentIndex = index;
    });
  }

  // Điều hướng đến các màn hình không được quản lý bởi TabNavigator
  void _navigateTo(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    Navigator.pushNamed(context, routeName, arguments: arguments);
  }
  
  // Method to refresh the home tab
  void _refreshHomeTab() {
    if (_homeScreenKey.currentState != null) {
      print('✅ Refreshing home tab from PassengerMainScreen');
      _homeScreenKey.currentState!.loadAvailableRides();
      
      // If we're not on the home tab, switch to it
      if (_currentIndex != 0) {
        _onTabTapped(0);
      }
    } else {
      print('⚠️ Home screen state is null, cannot refresh');
    }
  }

  @override
  Widget build(BuildContext context) {
    return TabNavigator(
      navigateToTab: _onTabTapped,
      currentIndex: _currentIndex,
      navigateTo: _navigateTo,
      refreshHomeTab: _refreshHomeTab,
      child: Scaffold(
        appBar: _buildAppBar(),
        body: PageView(
          controller: _pageController,
          onPageChanged: _onPageChanged,
          physics: const NeverScrollableScrollPhysics(), // Ngăn người dùng vuốt giữa các trang
          children: _screens,
        ),
        bottomNavigationBar: CustomBottomNavBar(
          currentIndex: _currentIndex,
          onTabTapped: _onTabTapped,
          navItems: _navItems,
          selectedColor: const Color(0xFF00AEEF),
          unselectedColor: Colors.grey.shade600,
          backgroundColor: Colors.white,
        ),
      ),
    );
  }

  // Xây dựng thanh AppBar với NotificationBadge
  PreferredSizeWidget? _buildAppBar() {
    if (_currentIndex == 0) {
      // Chỉ hiển thị AppBar ở màn hình chính
      return AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF00AEEF),
        title: const Row(
          children: [
            Icon(Icons.directions_car_rounded, color: Colors.white, size: 32),
            SizedBox(width: 8),
            Text(
              'ShareXE',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          NotificationBadge(
            iconColor: Colors.white,
            onPressed: () {
              // Điều hướng đến màn hình thông báo tab
              Navigator.pushNamed(context, AppRoute.notificationTabs);
            },
          ),
          const SizedBox(width: 8),
        ],
      );
    }
    return null; // Không hiển thị AppBar ở các tab khác
  }
} 