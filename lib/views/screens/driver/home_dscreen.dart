import 'package:flutter/material.dart';
import 'package:sharexe/views/widgets/sharexe_background1.dart';
import 'package:sharexe/services/auth_service.dart';
import 'package:sharexe/controllers/auth_controller.dart';
import 'package:sharexe/app_route.dart';

class HomeDscreen extends StatefulWidget {
  const HomeDscreen({super.key});

  @override
  State<HomeDscreen> createState() => _HomeDscreenState();
}

class _HomeDscreenState extends State<HomeDscreen> {
  late AuthController _authController;

  @override
  void initState() {
    super.initState();
    _authController = AuthController(AuthService());
  }

  void _logout() async {
    await _authController.logout();
    if (mounted) {
      Navigator.pushReplacementNamed(context, AppRoute.role);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SharexeBackground1(
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: const Color(0xFF002D72),
            title: const Text('Trang chủ tài xế'),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: _logout,
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Card(
                  elevation: 4,
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chào mừng bạn đến với ShareXE',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Bạn đã đăng nhập với tư cách tài xế. Bạn có thể quản lý các chuyến đi và xem yêu cầu từ khách hàng.',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Các chuyến đi sắp tới',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 0, // Sẽ được cập nhật khi có dữ liệu thực tế
                  itemBuilder: (context, index) {
                    return const Card(
                      margin: EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        title: Text('Chuyến đi #...'),
                        subtitle: Text('Chưa có dữ liệu'),
                        trailing: Icon(Icons.arrow_forward),
                      ),
                    );
                  },
                ),
                if (0 == 0) // Nếu không có chuyến đi nào
                  const Card(
                    margin: EdgeInsets.only(bottom: 10),
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('Chưa có chuyến đi nào'),
                    ),
                  ),
                const SizedBox(height: 20),
                const Text(
                  'Yêu cầu chuyến đi',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 0, // Sẽ được cập nhật khi có dữ liệu thực tế
                  itemBuilder: (context, index) {
                    return const Card(
                      margin: EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        title: Text('Yêu cầu #...'),
                        subtitle: Text('Chưa có dữ liệu'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check, color: Colors.green),
                            SizedBox(width: 8),
                            Icon(Icons.close, color: Colors.red),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                if (0 == 0) // Nếu không có yêu cầu nào
                  const Card(
                    margin: EdgeInsets.only(bottom: 10),
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('Chưa có yêu cầu nào'),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 