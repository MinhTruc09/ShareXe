import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/notification_model.dart';
import '../../../services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }
  
  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final notifications = await _notificationService.getNotifications();
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể tải thông báo: $e')),
        );
      }
    }
  }
  
  Future<void> _markAsRead(int notificationId) async {
    await _notificationService.markAsRead(notificationId);
    setState(() {
      _notifications = _notifications.map((notification) {
        if (notification.id == notificationId) {
          return NotificationModel(
            id: notification.id,
            userEmail: notification.userEmail,
            title: notification.title,
            content: notification.content,
            type: notification.type,
            referenceId: notification.referenceId,
            read: true,
            createdAt: notification.createdAt,
          );
        }
        return notification;
      }).toList();
    });
  }
  
  Future<void> _markAllAsRead() async {
    final result = await _notificationService.markAllAsRead();
    if (result) {
      setState(() {
        _notifications = _notifications.map((notification) {
          return NotificationModel(
            id: notification.id,
            userEmail: notification.userEmail,
            title: notification.title,
            content: notification.content,
            type: notification.type,
            referenceId: notification.referenceId,
            read: true,
            createdAt: notification.createdAt,
          );
        }).toList();
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã đánh dấu tất cả thông báo là đã đọc')),
        );
      }
    }
  }
  
  void _handleNotificationTap(NotificationModel notification) async {
    // Đánh dấu là đã đọc khi nhấn vào
    if (!notification.read) {
      await _markAsRead(notification.id);
    }
    
    // Xử lý chuyển hướng tùy theo loại thông báo
    if (notification.type == 'BOOKING_REQUEST') {
      // Chuyển đến trang booking
      // Navigator.pushNamed(context, '/booking-detail', arguments: notification.referenceId);
    } else if (notification.type == 'CHAT_MESSAGE') {
      // Chuyển đến trang chat
      // Navigator.pushNamed(context, '/chat', arguments: notification.referenceId);
    }
    // Thêm các loại thông báo khác tùy theo nhu cầu của ứng dụng
  }
  
  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return DateFormat('dd/MM/yyyy').format(dateTime);
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        backgroundColor: const Color(0xFF002D72),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            onPressed: _notifications.isEmpty ? null : _markAllAsRead,
            tooltip: 'Đánh dấu tất cả là đã đọc',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadNotifications,
              child: _notifications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.notifications_off,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Bạn chưa có thông báo nào',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 32),
                          ElevatedButton(
                            onPressed: _loadNotifications,
                            child: const Text('Làm mới'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _notifications.length,
                      itemBuilder: (context, index) {
                        final notification = _notifications[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 4.0,
                          ),
                          color: notification.read 
                              ? Colors.white
                              : const Color(0xFFE3F2FD),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: notification.read
                                  ? Colors.grey
                                  : const Color(0xFF002D72),
                              child: _getIconForNotificationType(notification.type),
                            ),
                            title: Text(
                              notification.title,
                              style: TextStyle(
                                fontWeight: notification.read 
                                    ? FontWeight.normal
                                    : FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(notification.content),
                                Text(
                                  _formatDateTime(notification.createdAt),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            isThreeLine: true,
                            onTap: () => _handleNotificationTap(notification),
                            trailing: !notification.read
                                ? Icon(
                                    Icons.circle,
                                    size: 12,
                                    color: Colors.blue[700],
                                  )
                                : null,
                          ),
                        );
                      },
                    ),
            ),
    );
  }
  
  Widget _getIconForNotificationType(String type) {
    switch (type) {
      case 'BOOKING_REQUEST':
        return const Icon(Icons.car_rental, color: Colors.white);
      case 'BOOKING_ACCEPTED':
        return const Icon(Icons.check_circle, color: Colors.white);
      case 'BOOKING_REJECTED':
        return const Icon(Icons.cancel, color: Colors.white);
      case 'CHAT_MESSAGE':
        return const Icon(Icons.chat, color: Colors.white);
      case 'PAYMENT':
        return const Icon(Icons.payment, color: Colors.white);
      default:
        return const Icon(Icons.notifications, color: Colors.white);
    }
  }
} 