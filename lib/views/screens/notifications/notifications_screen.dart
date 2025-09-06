import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/notification_model.dart';
import '../../../services/notification_service.dart';
import '../../../utils/app_config.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  List<NotificationModel> _driverRejectionNotifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForDriverRejection();
    });
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final notifications = await _notificationService.getNotifications();
      final rejectionNotifications =
          await _notificationService.getDriverRejectionNotifications();

      setState(() {
        _notifications = notifications;
        _driverRejectionNotifications = rejectionNotifications;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Không thể tải thông báo: $e')));
      }
    }
  }

  Future<void> _markAsRead(int notificationId) async {
    await _notificationService.markAsRead(notificationId);
    setState(() {
      _notifications =
          _notifications.map((notification) {
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
        _notifications =
            _notifications.map((notification) {
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
          const SnackBar(
            content: Text('Đã đánh dấu tất cả thông báo là đã đọc'),
          ),
        );
      }
    }
  }

  void _handleNotificationTap(NotificationModel notification) async {
    if (!notification.read) {
      await _markAsRead(notification.id);
    }

    // Xử lý điều hướng theo loại thông báo
    switch (notification.type) {
      case AppConfig.NOTIFICATION_BOOKING_REQUEST:
      case AppConfig.NOTIFICATION_BOOKING_ACCEPTED:
      case AppConfig.NOTIFICATION_BOOKING_REJECTED:
      case AppConfig.NOTIFICATION_BOOKING_CANCELLED:
        // Điều hướng đến trang quản lý booking
        Navigator.pushNamed(context, '/driver/bookings');
        break;
      case AppConfig.NOTIFICATION_CHAT_MESSAGE:
        // Điều hướng đến trang chat
        Navigator.pushNamed(
          context,
          '/chat_room',
          arguments: {
            'roomId': notification.referenceId,
            'partnerName': notification.title.replaceAll('Tin nhắn từ ', ''),
            'partnerEmail': notification.userEmail,
          },
        );
        break;
      case AppConfig.NOTIFICATION_DRIVER_APPROVED:
        // Điều hướng đến trang thông tin tài xế
        Navigator.pushNamed(context, '/driver/profile');
        break;
      case AppConfig.NOTIFICATION_DRIVER_REJECTED:
        // Điều hướng đến trang chỉnh sửa hồ sơ tài xế
        Navigator.pushNamed(context, '/driver/edit-profile');
        break;
    }
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

  Future<void> _checkForDriverRejection() async {
    await _notificationService.handleDriverRejection(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        backgroundColor: const Color(0xFF002D72),
        actions: [
          if (_driverRejectionNotifications.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: IconButton(
                icon: Badge(
                  label: Text(_driverRejectionNotifications.length.toString()),
                  backgroundColor: Colors.red,
                  child: const Icon(Icons.gpp_bad),
                ),
                onPressed: () {
                  _showDriverRejectionHistory();
                },
                tooltip: 'Xem lịch sử từ chối hồ sơ tài xế',
              ),
            ),
          IconButton(
            icon: const Icon(Icons.done_all),
            onPressed: _notifications.isEmpty ? null : _markAllAsRead,
            tooltip: 'Đánh dấu tất cả là đã đọc',
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _loadNotifications,
                child:
                    _notifications.isEmpty
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
                        : _buildNotificationsList(),
              ),
    );
  }

  Widget _buildNotificationsList() {
    return ListView.builder(
      itemCount: _notifications.length,
      itemBuilder: (context, index) {
        final notification = _notifications[index];
        final isDriverRejection =
            notification.type == AppConfig.NOTIFICATION_DRIVER_REJECTED;

        return _buildNotificationItem(notification, isDriverRejection);
      },
    );
  }

  Widget _buildNotificationItem(
    NotificationModel notification,
    bool isDriverRejection,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      color:
          notification.read
              ? Colors.white
              : isDriverRejection
              ? const Color(0xFFFFEBEE) // Màu đỏ nhạt cho từ chối
              : const Color(0xFFE3F2FD),
      elevation: isDriverRejection ? 3 : 1,
      shape:
          isDriverRejection
              ? RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.red[200]!),
              )
              : null,
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor:
                  notification.read
                      ? Colors.grey
                      : isDriverRejection
                      ? Colors.red
                      : const Color(0xFF002D72),
              child: _getIconForNotificationType(notification.type),
            ),
            title: Text(
              notification.title,
              style: TextStyle(
                fontWeight:
                    notification.read ? FontWeight.normal : FontWeight.bold,
                color: isDriverRejection ? Colors.red[700] : null,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isDriverRejection)
                  _buildDriverRejectionContent(notification.content)
                else
                  Text(notification.content),
                Text(
                  _formatDateTime(notification.createdAt),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            isThreeLine: true,
            onTap: () => _handleNotificationTap(notification),
            trailing:
                !notification.read
                    ? Icon(
                      Icons.circle,
                      size: 12,
                      color: isDriverRejection ? Colors.red : Colors.blue[700],
                    )
                    : null,
          ),

          if (isDriverRejection)
            Padding(
              padding: const EdgeInsets.only(
                bottom: 12.0,
                left: 16.0,
                right: 16.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/driver/edit-profile');
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Cập nhật hồ sơ'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red[700],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDriverRejectionContent(String content) {
    String? rejectionReason = _notificationService.extractRejectionReason(
      content,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          content.split('Lý do:').first.trim(),
          style: const TextStyle(fontSize: 14),
        ),
        if (rejectionReason != null && rejectionReason.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8, bottom: 4),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.red[100]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Lý do từ chối:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  rejectionReason,
                  style: TextStyle(fontSize: 13, color: Colors.red[900]),
                ),
              ],
            ),
          ),
      ],
    );
  }

  void _showDriverRejectionHistory() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: MediaQuery.of(context).size.height * 0.75,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.gpp_bad, color: Colors.red[700], size: 24),
                      const SizedBox(width: 8),
                      const Text(
                        'Lịch sử từ chối hồ sơ tài xế',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child:
                    _driverRejectionNotifications.isEmpty
                        ? const Center(
                          child: Text('Không có lịch sử từ chối hồ sơ'),
                        )
                        : ListView.builder(
                          itemCount: _driverRejectionNotifications.length,
                          itemBuilder: (context, index) {
                            final notification =
                                _driverRejectionNotifications[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              color: Colors.white,
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(color: Colors.red[100]!),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: Colors.red,
                                          radius: 16,
                                          child: const Icon(
                                            Icons.gpp_bad,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                notification.title,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Text(
                                                _formatDateTime(
                                                  notification.createdAt,
                                                ),
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    _buildDriverRejectionContent(
                                      notification.content,
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        OutlinedButton.icon(
                                          onPressed: () {
                                            Navigator.pop(context);
                                            Navigator.pushNamed(
                                              context,
                                              '/driver/edit-profile',
                                            );
                                          },
                                          icon: const Icon(Icons.edit),
                                          label: const Text('Cập nhật hồ sơ'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.red[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
              ),
              if (_driverRejectionNotifications.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/driver/edit-profile');
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Cập nhật hồ sơ tài xế'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _getIconForNotificationType(String type) {
    switch (type) {
      case AppConfig.NOTIFICATION_BOOKING_REQUEST:
        return const Icon(Icons.car_rental, color: Colors.white);
      case AppConfig.NOTIFICATION_BOOKING_ACCEPTED:
        return const Icon(Icons.check_circle, color: Colors.white);
      case AppConfig.NOTIFICATION_BOOKING_REJECTED:
        return const Icon(Icons.cancel, color: Colors.white);
      case AppConfig.NOTIFICATION_DRIVER_REJECTED:
        return const Icon(Icons.gpp_bad, color: Colors.white);
      case AppConfig.NOTIFICATION_CHAT_MESSAGE:
        return const Icon(Icons.chat, color: Colors.white);
      case 'PAYMENT':
        return const Icon(Icons.payment, color: Colors.white);
      default:
        return const Icon(Icons.notifications, color: Colors.white);
    }
  }
}
