import 'package:flutter/material.dart';
import '../../../models/notification_model.dart';
import '../../../services/notification_service.dart';
import '../../../app_route.dart' show AppRoute, DriverRoutes;
import '../../../utils/app_config.dart';

class NotificationTabsScreen extends StatefulWidget {
  const NotificationTabsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationTabsScreen> createState() => _NotificationTabsScreenState();
}

class _NotificationTabsScreenState extends State<NotificationTabsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final NotificationService _notificationService = NotificationService();

  List<NotificationModel> _allNotifications = [];
  List<NotificationModel> _bookingNotifications = [];
  List<NotificationModel> _messageNotifications = [];
  List<NotificationModel> _driverNotifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadNotifications();

    // Đăng ký lắng nghe thông báo mới
    _setupNotificationListeners();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _setupNotificationListeners() {
    // Lắng nghe tất cả thông báo
    _notificationService.notificationStream.listen((notification) {
      if (mounted) {
        setState(() {
          _allNotifications.insert(0, notification);
        });
        _filterNotifications();
      }
    });

    // Lắng nghe thông báo tin nhắn
    _notificationService.messageNotificationStream.listen((notification) {
      if (mounted) {
        setState(() {
          // Thêm vào danh sách thông báo tin nhắn
          _messageNotifications.insert(0, notification);
        });
      }
    });

    // Lắng nghe thông báo booking
    _notificationService.bookingNotificationStream.listen((notification) {
      if (mounted) {
        setState(() {
          // Thêm vào danh sách thông báo booking
          _bookingNotifications.insert(0, notification);
        });
      }
    });

    // Lắng nghe thông báo tài xế
    _notificationService.driverNotificationStream.listen((notification) {
      if (mounted) {
        setState(() {
          // Thêm vào danh sách thông báo tài xế
          _driverNotifications.insert(0, notification);
        });
      }
    });
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final notifications = await _notificationService.getNotifications();

      if (mounted) {
        setState(() {
          _allNotifications = notifications;
          _isLoading = false;
        });

        // Phân loại thông báo
        _filterNotifications();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Không thể tải thông báo: $e')));
      }
    }
  }

  void _filterNotifications() {
    // Lọc thông báo liên quan đến chuyến đi
    _bookingNotifications =
        _allNotifications
            .where(
              (notification) =>
                  notification.type == AppConfig.NOTIFICATION_BOOKING_REQUEST ||
                  notification.type ==
                      AppConfig.NOTIFICATION_BOOKING_ACCEPTED ||
                  notification.type ==
                      AppConfig.NOTIFICATION_BOOKING_REJECTED ||
                  notification.type ==
                      AppConfig.NOTIFICATION_BOOKING_CANCELLED ||
                  notification.type == 'NEW_BOOKING',
            )
            .toList();

    // Lọc thông báo tin nhắn
    _messageNotifications =
        _allNotifications
            .where(
              (notification) =>
                  notification.type == AppConfig.NOTIFICATION_CHAT_MESSAGE,
            )
            .toList();

    // Lọc thông báo liên quan đến tài xế
    _driverNotifications =
        _allNotifications
            .where(
              (notification) =>
                  notification.type == AppConfig.NOTIFICATION_DRIVER_APPROVED ||
                  notification.type == AppConfig.NOTIFICATION_DRIVER_REJECTED,
            )
            .toList();
  }

  Future<void> _handleMarkAllAsRead() async {
    final result = await _notificationService.markAllAsRead();

    if (result) {
      setState(() {
        // Cập nhật trạng thái đã đọc cho tất cả thông báo
        _allNotifications =
            _allNotifications.map((notification) {
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

      // Phân loại lại thông báo
      _filterNotifications();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã đánh dấu tất cả thông báo là đã đọc')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Thông báo',
          style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF002D72),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            onPressed: _allNotifications.isEmpty ? null : _handleMarkAllAsRead,
            tooltip: 'Đánh dấu tất cả là đã đọc',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40.0),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF002D72),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              indicatorSize: TabBarIndicatorSize.label,
              tabs: [
                Tab(text: 'Tất cả ${_getUnreadCountBadge(_allNotifications)}'),
                Tab(
                  text:
                      'Chuyến đi ${_getUnreadCountBadge(_bookingNotifications)}',
                ),
                Tab(
                  text:
                      'Tin nhắn ${_getUnreadCountBadge(_messageNotifications)}',
                ),
                Tab(
                  text: 'Tài xế ${_getUnreadCountBadge(_driverNotifications)}',
                ),
              ],
            ),
          ),
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                controller: _tabController,
                children: [
                  // Tab tất cả thông báo
                  _buildNotificationTab(_allNotifications),

                  // Tab thông báo chuyến đi
                  _buildNotificationTab(_bookingNotifications),

                  // Tab thông báo tin nhắn
                  _buildNotificationTab(_messageNotifications),

                  // Tab thông báo tài xế
                  _buildNotificationTab(_driverNotifications),
                ],
              ),
    );
  }

  String _getUnreadCountBadge(List<NotificationModel> notifications) {
    final unreadCount = notifications.where((n) => !n.read).length;
    return unreadCount > 0 ? '($unreadCount)' : '';
  }

  Widget _buildNotificationTab(List<NotificationModel> notifications) {
    // Tái sử dụng logic của NotificationsScreen để hiển thị danh sách thông báo
    if (notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Không thông báo nào',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadNotifications,
              icon: const Icon(Icons.refresh),
              label: const Text('Làm mới'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF002D72),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return RefreshIndicator(
        onRefresh: _loadNotifications,
        color: const Color(0xFF002D72),
        child: ListView.builder(
          padding: const EdgeInsets.only(top: 8),
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final notification = notifications[index];
            final isDriverRejection = notification.type == 'DRIVER_REJECTED';

            return _buildNotificationItem(notification, isDriverRejection);
          },
        ),
      );
    }
  }

  Widget _buildNotificationItem(
    NotificationModel notification,
    bool isDriverRejection,
  ) {
    // Kiểm tra thông báo đặt chỗ mới
    final isNewBooking = notification.type == 'NEW_BOOKING';

    // Tái sử dụng logic hiển thị thông báo từ NotificationsScreen
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      color:
          notification.read
              ? Colors.white
              : isDriverRejection
              ? const Color(0xFFFFEBEE) // Màu đỏ nhạt cho từ chối
              : isNewBooking
              ? const Color(0xFFE8F5E9) // Màu xanh lá nhạt cho booking mới
              : const Color(0xFFE3F2FD),
      elevation: notification.read ? 1 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color:
              isDriverRejection
                  ? Colors.red[200]!
                  : isNewBooking
                  ? Colors.green[200]!
                  : Colors.transparent,
          width: isDriverRejection || isNewBooking ? 1 : 0,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _handleNotificationTap(notification),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar/Icon
                  Hero(
                    tag: 'notification_icon_${notification.id}',
                    child: Material(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: CircleAvatar(
                        backgroundColor:
                            notification.read
                                ? Colors.grey[300]
                                : isDriverRejection
                                ? Colors.red
                                : isNewBooking
                                ? Colors.green
                                : _getNotificationColor(notification.type),
                        radius: 24,
                        child: _getIconForNotificationType(notification.type),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tiêu đề và thời gian
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Tiêu đề
                            Expanded(
                              flex: 3,
                              child: Text(
                                notification.title,
                                style: TextStyle(
                                  fontWeight:
                                      notification.read
                                          ? FontWeight.normal
                                          : FontWeight.bold,
                                  color:
                                      isDriverRejection
                                          ? Colors.red[700]
                                          : isNewBooking
                                          ? Colors.green[700]
                                          : Colors.black87,
                                  fontSize: 15,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),

                            // Thời gian
                            Expanded(
                              flex: 1,
                              child: Text(
                                _formatDateTime(notification.createdAt),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 6),

                        // Nội dung
                        if (isDriverRejection)
                          _buildDriverRejectionContent(notification.content)
                        else
                          Text(
                            notification.content,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[800],
                              height: 1.3,
                            ),
                          ),

                        // Indicator chưa đọc
                        if (!notification.read)
                          Align(
                            alignment: Alignment.centerRight,
                            child: Container(
                              margin: const EdgeInsets.only(top: 8),
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color:
                                    isDriverRejection
                                        ? Colors.red
                                        : isNewBooking
                                        ? Colors.green
                                        : Colors.blue[700],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Nút hành động
            _buildActionButtons(notification),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(NotificationModel notification) {
    // Tùy theo loại thông báo, hiển thị các nút hành động phù hợp
    switch (notification.type) {
      case AppConfig.NOTIFICATION_DRIVER_REJECTED:
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, AppRoute.profileDriver);
            },
            icon: const Icon(Icons.edit, size: 18),
            label: const Text('Cập nhật hồ sơ'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        );

      case 'NEW_BOOKING':
        // Điều hướng đến màn hình quản lý booking
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, DriverRoutes.bookings);
            },
            icon: const Icon(Icons.visibility, size: 18),
            label: const Text('Xem chi tiết'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF002D72),
              foregroundColor: Colors.white,
              elevation: 2,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        );

      case AppConfig.NOTIFICATION_BOOKING_REQUEST:
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Xử lý từ chối yêu cầu
                    _handleRejectBooking(notification.referenceId);
                  },
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Từ chối'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    foregroundColor: Colors.red,
                    side: BorderSide(color: Colors.red[300]!),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Xử lý chấp nhận yêu cầu
                    _handleAcceptBooking(notification.referenceId);
                  },
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Chấp nhận'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF002D72),
                    foregroundColor: Colors.white,
                    elevation: 2,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );

      case AppConfig.NOTIFICATION_CHAT_MESSAGE:
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
          child: OutlinedButton.icon(
            onPressed: () {
              // Điều hướng đến màn hình chat
              Navigator.pushNamed(
                context,
                AppRoute.chatRoom,
                arguments: {
                  'roomId': notification.referenceId,
                  'partnerName': notification.title.replaceAll(
                    'Tin nhắn từ ',
                    '',
                  ),
                  'partnerEmail': notification.userEmail,
                },
              );
            },
            icon: const Icon(Icons.reply, size: 18),
            label: const Text('Trả lời'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.blue[700],
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: BorderSide(color: Colors.blue[300]!),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  // Xử lý chấp nhận booking
  Future<void> _handleAcceptBooking(int bookingId) async {
    try {
      // Hiển thị loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(child: CircularProgressIndicator());
        },
      );

      final result = await _notificationService.acceptBooking(bookingId);

      if (result) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã chấp nhận chuyến đi')));

        // Làm mới danh sách thông báo
        await _loadNotifications();

        // Đóng loading indicator
        Navigator.of(context, rootNavigator: true).pop();

        // Điều hướng đến trang quản lý booking
        Navigator.pushNamed(context, DriverRoutes.bookings);
      } else {
        // Đóng loading indicator
        Navigator.of(context, rootNavigator: true).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể chấp nhận chuyến đi')),
        );
      }
    } catch (e) {
      // Đóng loading indicator nếu có lỗi
      Navigator.of(context, rootNavigator: true).pop();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  // Xử lý từ chối booking
  Future<void> _handleRejectBooking(int bookingId) async {
    try {
      final result = await _notificationService.rejectBooking(bookingId);

      if (result) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã từ chối chuyến đi')));

        // Làm mới danh sách thông báo
        await _loadNotifications();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể từ chối chuyến đi')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'BOOKING_REQUEST':
      case 'BOOKING_ACCEPTED':
        return const Color(0xFF002D72);
      case 'CHAT_MESSAGE':
        return Colors.blue;
      case 'BOOKING_CANCELED':
        return Colors.orange;
      case 'DRIVER_APPROVED':
        return Colors.green;
      default:
        return const Color(0xFF002D72);
    }
  }

  Widget _buildDriverRejectionContent(String content) {
    // Sử dụng NotificationService để trích xuất lý do từ chối
    String? rejectionReason = _notificationService.extractRejectionReason(
      content,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          content.split('Lý do:').first.trim(),
          style: const TextStyle(fontSize: 14, height: 1.3),
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
        ),
        if (rejectionReason != null && rejectionReason.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8, bottom: 4),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red[100]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.red[700]),
                    const SizedBox(width: 6),
                    Text(
                      'Lý do từ chối:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.red[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  rejectionReason,
                  style: TextStyle(fontSize: 13, color: Colors.red[900]),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 3,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _handleNotificationTap(NotificationModel notification) async {
    // Đánh dấu thông báo là đã đọc
    if (!notification.read) {
      await _notificationService.markAsRead(notification.id);

      // Cập nhật trạng thái đã đọc trong danh sách
      setState(() {
        final index = _allNotifications.indexWhere(
          (n) => n.id == notification.id,
        );
        if (index != -1) {
          _allNotifications[index] = NotificationModel(
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
      });

      // Cập nhật phân loại
      _filterNotifications();
    }

    // Xử lý điều hướng theo loại thông báo
    switch (notification.type) {
      case 'NEW_BOOKING':
        // Thông báo đặt chỗ mới - điều hướng đến chi tiết chuyến đi
        if (notification.referenceId > 0) {
          Navigator.pushNamed(
            context,
            AppRoute.rideDetails,
            arguments: {'rideId': notification.referenceId},
          );
        } else {
          // Fallback nếu không có referenceId
          Navigator.pushNamed(context, DriverRoutes.bookings);
        }
        break;

      case AppConfig.NOTIFICATION_BOOKING_REQUEST:
      case AppConfig.NOTIFICATION_BOOKING_ACCEPTED:
      case AppConfig.NOTIFICATION_BOOKING_REJECTED:
      case AppConfig.NOTIFICATION_BOOKING_CANCELLED:
        // Điều hướng đến trang quản lý booking
        Navigator.pushNamed(context, DriverRoutes.bookings);
        break;

      case AppConfig.NOTIFICATION_CHAT_MESSAGE:
        // Điều hướng đến trang chat
        Navigator.pushNamed(
          context,
          AppRoute.chatRoom,
          arguments: {
            'roomId': notification.referenceId,
            'partnerName': notification.title.replaceAll('Tin nhắn từ ', ''),
            'partnerEmail': notification.userEmail,
          },
        );
        break;

      case AppConfig.NOTIFICATION_DRIVER_APPROVED:
        // Điều hướng đến trang thông tin tài xế
        Navigator.pushNamed(context, AppRoute.profileDriver);
        break;

      case AppConfig.NOTIFICATION_DRIVER_REJECTED:
        // Điều hướng đến trang chỉnh sửa hồ sơ tài xế
        Navigator.pushNamed(context, DriverRoutes.editProfile);
        break;
    }
  }

  Widget _getIconForNotificationType(String type) {
    switch (type) {
      case AppConfig.NOTIFICATION_BOOKING_REQUEST:
        return const Icon(Icons.car_rental, color: Colors.white);
      case AppConfig.NOTIFICATION_BOOKING_ACCEPTED:
        return const Icon(Icons.check_circle, color: Colors.white);
      case AppConfig.NOTIFICATION_BOOKING_REJECTED:
        return const Icon(Icons.cancel, color: Colors.white);
      case AppConfig.NOTIFICATION_BOOKING_CANCELLED:
        return const Icon(Icons.block, color: Colors.white);
      case AppConfig.NOTIFICATION_DRIVER_REJECTED:
        return const Icon(Icons.gpp_bad, color: Colors.white);
      case AppConfig.NOTIFICATION_DRIVER_APPROVED:
        return const Icon(Icons.verified_user, color: Colors.white);
      case AppConfig.NOTIFICATION_CHAT_MESSAGE:
        return const Icon(Icons.chat, color: Colors.white);
      case 'PAYMENT':
        return const Icon(Icons.payment, color: Colors.white);
      default:
        return const Icon(Icons.notifications, color: Colors.white);
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }
}
