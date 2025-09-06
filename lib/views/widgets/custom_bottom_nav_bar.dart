import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class BottomNavCurvePainter extends CustomPainter {
  Color backgroundColor;
  double insetRadius;

  BottomNavCurvePainter({
    this.backgroundColor = Colors.black,
    this.insetRadius = 38,
  });

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint =
        Paint()
          ..color = backgroundColor
          ..style = PaintingStyle.fill;

    Path path = Path()..moveTo(0, 12);

    double insetCurveBeginnningX = size.width / 2 - insetRadius;
    double insetCurveEndX = size.width / 2 + insetRadius;
    double transitionToInsetCurveWidth = size.width * .05;

    path.quadraticBezierTo(
      size.width * 0.20,
      0,
      insetCurveBeginnningX - transitionToInsetCurveWidth,
      0,
    );
    path.quadraticBezierTo(
      insetCurveBeginnningX,
      0,
      insetCurveBeginnningX,
      insetRadius / 2,
    );

    path.arcToPoint(
      Offset(insetCurveEndX, insetRadius / 2),
      radius: const Radius.circular(10.0),
      clockwise: false,
    );

    path.quadraticBezierTo(
      insetCurveEndX,
      0,
      insetCurveEndX + transitionToInsetCurveWidth,
      0,
    );
    path.quadraticBezierTo(size.width * 0.80, 0, size.width, 12);
    path.lineTo(size.width, size.height + 56);
    path.lineTo(0, size.height + 56);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}

class CustomBottomNavBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<NavBarItem> items;
  final Color? backgroundColor;
  final Color? selectedColor;
  final Color? unselectedColor;
  final IconData? fabIcon;
  final VoidCallback? onFabPressed;
  final bool showFab;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.backgroundColor,
    this.selectedColor,
    this.unselectedColor,
    this.fabIcon,
    this.onFabPressed,
    this.showFab = true,
  });

  @override
  State<CustomBottomNavBar> createState() => _CustomBottomNavBarState();
}

class _CustomBottomNavBarState extends State<CustomBottomNavBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    double height = 70;

    final backgroundColor =
        widget.backgroundColor ?? Theme.of(context).colorScheme.surface;
    final selectedColor =
        widget.selectedColor ?? Theme.of(context).colorScheme.primary;
    final unselectedColor =
        widget.unselectedColor ??
        Theme.of(context).colorScheme.onSurface.withOpacity(0.6);

    return BottomAppBar(
      color: Colors.transparent,
      elevation: 0,
      child: Stack(
        children: [
          CustomPaint(
            size: Size(size.width, height + 10),
            painter: BottomNavCurvePainter(backgroundColor: Colors.transparent),
          ),
          if (widget.showFab)
            Center(
              heightFactor: 0.6,
              child: AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: FloatingActionButton(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100.0),
                      ),
                      backgroundColor: selectedColor,
                      elevation: 8,
                      onPressed: () {
                        _animationController.forward().then((_) {
                          _animationController.reverse();
                        });
                        widget.onFabPressed?.call();
                      },
                      child: Icon(
                        widget.fabIcon ?? Icons.add,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  );
                },
              ),
            ),
          SizedBox(
            height: height,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(widget.items.length, (index) {
                final item = widget.items[index];
                final isSelected = widget.currentIndex == index;

                return NavBarIcon(
                  text: item.label,
                  icon: item.icon,
                  selected: isSelected,
                  onPressed: () {
                    _animationController.forward().then((_) {
                      _animationController.reverse();
                    });
                    widget.onTap(index);
                  },
                  defaultColor: unselectedColor,
                  selectedColor: selectedColor,
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class NavBarItem {
  final String label;
  final IconData icon;
  final IconData? activeIcon;

  const NavBarItem({required this.label, required this.icon, this.activeIcon});
}

class NavBarIcon extends StatelessWidget {
  final String text;
  final IconData icon;
  final bool selected;
  final Function() onPressed;
  final Color defaultColor;
  final Color selectedColor;

  const NavBarIcon({
    super.key,
    required this.text,
    required this.icon,
    required this.selected,
    required this.onPressed,
    this.selectedColor = const Color(0xffFF8527),
    this.defaultColor = Colors.black54,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow:
              selected
                  ? [
                    BoxShadow(
                      color: selectedColor.withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                      offset: const Offset(0, 2),
                    ),
                  ]
                  : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: selected ? 15 : 14,
              color: selected ? selectedColor : defaultColor,
            ),
            if (selected) ...[
              const SizedBox(height: 2),
              Text(
                text,
                style: TextStyle(
                  color: selectedColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
