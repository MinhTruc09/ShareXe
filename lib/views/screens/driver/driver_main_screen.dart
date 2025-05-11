import 'package:flutter/material.dart';
import 'package:sharexe/app_route.dart';
import 'home_dscreen.dart';
import '../chat/user_list_screen.dart';
import 'driver_profile_screen.dart';
import '../../widgets/notification_badge.dart';
import 'my_rides_screen.dart';
import '../../../utils/navigation_helper.dart';

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

class _DriverMainScreenState extends State<DriverMainScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  late AnimationController _animationController;

  // Danh sách các màn hình chính
  final List<Widget> _screens = [
    const HomeDscreen(),
    const MyRidesScreen(),
    const UserListScreen(),
    const DriverProfileScreen(),
  ];

  // Các tùy chọn menu
  final List<Map<String, dynamic>> _navItems = [
    {
      'icon': Icons.home_outlined,
      'activeIcon': Icons.home,
      'label': 'Trang chủ',
      'gradient': [const Color(0xFF002D72), const Color(0xFF0052CC)],
    },
    {
      'icon': Icons.history_outlined,
      'activeIcon': Icons.history,
      'label': 'Chuyến đi',
      'gradient': [const Color(0xFF00AEEF), const Color(0xFF0078A8)],
    },
    {
      'icon': Icons.chat_bubble_outline,
      'activeIcon': Icons.chat_bubble,
      'label': 'Liên hệ',
      'gradient': [const Color(0xFF2AB05D), const Color(0xFF1F884A)],
    },
    {
      'icon': Icons.person_outline,
      'activeIcon': Icons.person,
      'label': 'Cá nhân',
      'gradient': [const Color(0xFFF57C00), const Color(0xFFE65100)],
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (index == _currentIndex) return;

    // Reset animation
    _animationController.reset();
    _animationController.forward();

    setState(() {
      _currentIndex = index;
    });

    // Sử dụng PageController để có hiệu ứng chuyển tab mượt hơn
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onPageChanged(int index) {
    if (index == _currentIndex) return;

    // Reset animation
    _animationController.reset();
    _animationController.forward();

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
          physics: const NeverScrollableScrollPhysics(), // Ngăn người dùng vuốt giữa các trang
          children: _screens,
        ),
        bottomNavigationBar: AnimatedBuilder(
          animation: _animationController,
          builder: (context, _) {
            return Container(
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(_navItems.length, (index) {
                  bool isSelected = _currentIndex == index;

                  // Animation scaling effect
                  double scale =
                      isSelected ? 1.0 + 0.1 * _animationController.value : 1.0;

                  return GestureDetector(
                    onTap: () => _onTabTapped(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: isSelected ? 70 : 50,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration:
                          isSelected
                              ? BoxDecoration(
                                gradient: LinearGradient(
                                  colors: _navItems[index]['gradient'],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: _navItems[index]['gradient'][0]
                                        .withOpacity(0.3),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              )
                              : null,
                      child: Transform.scale(
                        scale: scale,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isSelected
                                  ? _navItems[index]['activeIcon']
                                  : _navItems[index]['icon'],
                              color: isSelected
                                  ? Colors.white
                                  : Colors.grey.shade600,
                              size: 24,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _navItems[index]['label'],
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.grey.shade600,
                                fontSize: 10,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            );
          },
        ),
        floatingActionButton: _currentIndex == 0
            ? FloatingActionButton(
                backgroundColor: const Color(0xFF002D72),
                elevation: 8,
                onPressed: () {
                  NavigationHelper.navigateToCreateRide(context);
                },
                child: const Icon(Icons.add),
              )
            : null,
      ),
    );
  }
}
