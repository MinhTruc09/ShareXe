import 'dart:async';
import 'package:flutter/material.dart';
import '../../../services/notification_service.dart';

class NotificationBadge extends StatefulWidget {
  final VoidCallback onPressed;
  final Color? iconColor;
  final double iconSize;

  const NotificationBadge({
    Key? key,
    required this.onPressed,
    this.iconColor,
    this.iconSize = 24.0,
  }) : super(key: key);

  @override
  State<NotificationBadge> createState() => _NotificationBadgeState();
}

class _NotificationBadgeState extends State<NotificationBadge> {
  final NotificationService _notificationService = NotificationService();
  int _unreadCount = 0;
  Timer? _refreshTimer;
  StreamSubscription? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();

    // Thiết lập timer để cập nhật số lượng thông báo chưa đọc mỗi phút
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _loadUnreadCount();
    });

    // Lắng nghe thông báo mới từ notification service
    _notificationSubscription = _notificationService.notificationStream.listen((
      notification,
    ) {
      // Tăng số lượng thông báo chưa đọc khi có thông báo mới
      setState(() {
        _unreadCount++;
      });
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _notificationSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadUnreadCount() async {
    try {
      final count = await _notificationService.getUnreadCount();
      if (mounted) {
        setState(() {
          _unreadCount = count;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _unreadCount = 0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: Icon(
            Icons.notifications,
            color: widget.iconColor,
            size: widget.iconSize,
          ),
          onPressed: () {
            // Gọi callback khi nhấn vào biểu tượng thông báo
            widget.onPressed();
          },
        ),
        if (_unreadCount > 0)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Center(
                child: Text(
                  _unreadCount > 99 ? '99+' : _unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
