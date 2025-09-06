import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class NavBarItem {
  final String label;
  final IconData icon;
  final IconData? activeIcon;

  const NavBarItem({
    required this.label, 
    required this.icon, 
    this.activeIcon
  });
}

class CustomBottomNavBar extends StatefulWidget {
  final int? currentIndex;
  final Function(int)? onTabTapped;
  final Function()? onFabPressed;
  final List<NavBarItem>? navItems;
  final IconData? fabIcon;
  final Color? selectedColor;
  final Color? unselectedColor;
  final Color? backgroundColor;
  
  const CustomBottomNavBar({
    super.key,
    this.currentIndex,
    this.onTabTapped,
    this.onFabPressed,
    this.navItems,
    this.fabIcon,
    this.selectedColor,
    this.unselectedColor,
    this.backgroundColor,
  });

  @override
  CustomBottomNavBarState createState() => CustomBottomNavBarState();
}

class CustomBottomNavBarState extends State<CustomBottomNavBar>
    with TickerProviderStateMixin {
  late int _selectedIndex;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.currentIndex ?? 0;
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(CustomBottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIndex != oldWidget.currentIndex) {
      setState(() {
        _selectedIndex = widget.currentIndex ?? 0;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use custom colors or theme colors
    final primaryColor = widget.selectedColor ?? Theme.of(context).colorScheme.primary;
    final secondaryColor = widget.unselectedColor ?? Theme.of(context).colorScheme.onSurface.withOpacity(0.6);
    final backgroundColor = widget.backgroundColor ?? Theme.of(context).colorScheme.surface;
    
    // Default navigation items if none provided
    final defaultNavItems = [
      const NavBarItem(label: "Home", icon: CupertinoIcons.home),
      const NavBarItem(label: "Search", icon: CupertinoIcons.search),
      const NavBarItem(label: "Cart", icon: CupertinoIcons.cart),
      const NavBarItem(label: "Profile", icon: CupertinoIcons.person),
    ];
    
    final navItems = widget.navItems ?? defaultNavItems;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(navItems.length, (index) {
              final item = navItems[index];
              final isSelected = _selectedIndex == index;
              
              return Expanded(
                child: GestureDetector(
                  onTap: () => _onNavBarItemTapped(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Icon container with iOS-style selection
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? primaryColor.withOpacity(0.1) 
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            isSelected && item.activeIcon != null 
                                ? item.activeIcon! 
                                : item.icon,
                            size: 20,
                            color: isSelected ? primaryColor : secondaryColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        // Label with iOS typography
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected ? primaryColor : secondaryColor,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            })..insert(2, widget.fabIcon != null ? _buildFAB(primaryColor) : const SizedBox(width: 0)),
          ),
        ),
      ),
    );
  }

  Widget _buildFAB(Color primaryColor) {
    return Expanded(
      child: Center(
        child: GestureDetector(
          onTap: () {
            _animationController.forward().then((_) {
              _animationController.reverse();
            });
            widget.onFabPressed?.call();
          },
          child: AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: primaryColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    widget.fabIcon ?? CupertinoIcons.add,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _onNavBarItemTapped(int index) {
    if (index == _selectedIndex) return;
    
    setState(() {
      _selectedIndex = index;
    });
    
    // Call the external callback if provided
    widget.onTabTapped?.call(index);
  }
}

// iOS-style bottom navigation bar with blur effect
class CupertinoBottomNavBar extends StatefulWidget {
  final int? currentIndex;
  final Function(int)? onTabTapped;
  final Function()? onFabPressed;
  final List<NavBarItem>? navItems;
  final IconData? fabIcon;
  final Color? selectedColor;
  final Color? unselectedColor;
  
  const CupertinoBottomNavBar({
    super.key,
    this.currentIndex,
    this.onTabTapped,
    this.onFabPressed,
    this.navItems,
    this.fabIcon,
    this.selectedColor,
    this.unselectedColor,
  });

  @override
  CupertinoBottomNavBarState createState() => CupertinoBottomNavBarState();
}

class CupertinoBottomNavBarState extends State<CupertinoBottomNavBar>
    with TickerProviderStateMixin {
  late int _selectedIndex;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.currentIndex ?? 0;
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = widget.selectedColor ?? CupertinoColors.systemBlue;
    final secondaryColor = widget.unselectedColor ?? CupertinoColors.systemGrey;
    
    final defaultNavItems = [
      const NavBarItem(label: "Home", icon: CupertinoIcons.home),
      const NavBarItem(label: "Search", icon: CupertinoIcons.search),
      const NavBarItem(label: "Cart", icon: CupertinoIcons.cart),
      const NavBarItem(label: "Profile", icon: CupertinoIcons.person),
    ];
    
    final navItems = widget.navItems ?? defaultNavItems;

    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        backgroundColor: CupertinoColors.systemBackground.withOpacity(0.8),
        border: const Border(
          top: BorderSide(
            color: CupertinoColors.separator,
            width: 0.5,
          ),
        ),
        items: navItems.map((item) {
          final index = navItems.indexOf(item);
          final isSelected = _selectedIndex == index;
          
          return BottomNavigationBarItem(
            icon: Icon(
              isSelected && item.activeIcon != null 
                  ? item.activeIcon! 
                  : item.icon,
              color: isSelected ? primaryColor : secondaryColor,
            ),
            activeIcon: Icon(
              item.activeIcon ?? item.icon,
              color: primaryColor,
            ),
            label: item.label,
          );
        }).toList(),
        onTap: (index) => _onNavBarItemTapped(index),
      ),
      tabBuilder: (context, index) {
        return Container(); // Empty container as this is just for the tab bar
      },
    );
  }

  void _onNavBarItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    
    widget.onTabTapped?.call(index);
  }
}