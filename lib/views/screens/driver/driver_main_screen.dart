import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:sharexe/app_route.dart';
import 'home_dscreen.dart';
import '../chat/user_list_screen.dart';
import 'driver_profile_screen.dart';
import 'my_rides_screen.dart';
import '../../../utils/navigation_helper.dart';
import '../../widgets/custom_bottom_nav_bar.dart';

// InheritedWidget để cung cấp truy cập vào điều hướng bottom bar
class TabNavigator extends InheritedWidget {
  final Function(int) navigateToTab;
  final int currentIndex;
  final Function(BuildContext, String, {Object? arguments}) navigateTo;

  const TabNavigator({
    Key? key,
    required this.navigateToTab,
    required this.currentIndex,
    required this.navigateTo,
    required Widget child,
  }) : super(key: key, child: child);

  static TabNavigator? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<TabNavigator>();
  }

  // Phương thức chung để điều hướng đến màn hình tạo chuyến đi
  static void navigateToCreateRide(BuildContext context) {
    Navigator.pushNamed(context, DriverRoutes.createRide);
  }

  @override
  bool updateShouldNotify(TabNavigator oldWidget) {
    return currentIndex != oldWidget.currentIndex;
  }
}

class DriverMainScreen extends StatefulWidget {
  const DriverMainScreen({Key? key}) : super(key: key);

  @override
  State<DriverMainScreen> createState() => _DriverMainScreenState();
}

class _DriverMainScreenState extends State<DriverMainScreen> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  // Danh sách các màn hình chính
  final List<Widget> _screens = [
    const HomeDscreen(),
    const MyRidesScreen(),
    const UserListScreen(),
    const DriverProfileScreen(),
  ];

  // Các tùy chọn menu cho Driver
  final List<NavBarItem> _navItems = [
    const NavBarItem(
      icon: CupertinoIcons.home,
      activeIcon: CupertinoIcons.house_fill,
      label: 'Trang chủ',
    ),
    const NavBarItem(
      icon: CupertinoIcons.car,
      activeIcon: CupertinoIcons.car_fill,
      label: 'Chuyến đi',
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

  @override
  Widget build(BuildContext context) {
    return TabNavigator(
      navigateToTab: _onTabTapped,
      currentIndex: _currentIndex,
      navigateTo: _navigateTo,
      child: Scaffold(
        body: PageView(
          controller: _pageController,
          onPageChanged: _onPageChanged,
          physics:
              const NeverScrollableScrollPhysics(), // Ngăn người dùng vuốt giữa các trang
          children: _screens,
        ),
        bottomNavigationBar: CustomBottomNavBar(
          currentIndex: _currentIndex,
          onTabTapped: _onTabTapped,
          navItems: _navItems,
          fabIcon: CupertinoIcons.add,
          selectedColor: const Color(0xFF002D72),
          unselectedColor: Colors.grey.shade600,
          backgroundColor: Colors.white,
          onFabPressed: () {
            NavigationHelper.navigateToCreateRide(context);
          },
        ),
      ),
    );
  }
}
