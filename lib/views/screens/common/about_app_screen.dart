import 'package:flutter/material.dart';

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Giới thiệu ứng dụng'),
        backgroundColor: const Color(0xFF00AEEF),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo và slogan
            Center(
              child: Column(
                children: [
                  Container(
                    height: 120,
                    width: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(15),
                    child: Image.asset(
                      'assets/images/logo.png', 
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.directions_car,
                        size: 80,
                        color: Color(0xFF00AEEF),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'ShareXE',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF002D72),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Chia sẻ hành trình - Kết nối cộng đồng',
                    style: TextStyle(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      color: Color(0xFF00AEEF),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Phiên bản 1.0.0',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Giới thiệu
            _buildSectionTitle('Giới thiệu'),
            _buildInfoText(
              'ShareXE là ứng dụng di chuyển chung xe hơi đáng tin cậy, kết nối những người có chung lộ trình di chuyển. Chúng tôi giúp tối ưu chi phí di chuyển, giảm tắc nghẽn giao thông và góp phần bảo vệ môi trường.',
            ),
            _buildInfoText(
              'Được phát triển bởi đội ngũ sinh viên nhiệt huyết, ShareXE mang đến trải nghiệm đi chung xe an toàn, tiện lợi và thân thiện.',
            ),
            
            const SizedBox(height: 24),
            
            // Tính năng nổi bật
            _buildSectionTitle('Tính năng nổi bật'),
            _buildFeatureItem(
              icon: Icons.search,
              title: 'Tìm kiếm chuyến đi',
              description: 'Dễ dàng tìm kiếm các chuyến đi phù hợp với lịch trình của bạn.',
            ),
            _buildFeatureItem(
              icon: Icons.directions_car_filled,
              title: 'Đăng ký làm tài xế',
              description: 'Chia sẻ chuyến đi của bạn và kiếm thêm thu nhập.',
            ),
            _buildFeatureItem(
              icon: Icons.security,
              title: 'An toàn và tin cậy',
              description: 'Xác thực người dùng và đánh giá sau mỗi chuyến đi.',
            ),
            _buildFeatureItem(
              icon: Icons.chat,
              title: 'Trò chuyện trực tiếp',
              description: 'Liên lạc dễ dàng giữa hành khách và tài xế.',
            ),
            
            const SizedBox(height: 24),
            
            // Đội ngũ phát triển
            _buildSectionTitle('Đội ngũ phát triển'),
            _buildDeveloperItem(
              name: 'Nguyễn Văn An',
              role: 'Trưởng nhóm & Full-stack Developer',
            ),
            _buildDeveloperItem(
              name: 'Trần Thị Bình',
              role: 'UX/UI Designer',
            ),
            _buildDeveloperItem(
              name: 'Lê Văn Chính',
              role: 'Mobile Developer',
            ),
            _buildDeveloperItem(
              name: 'Phạm Thị Dung',
              role: 'Backend Developer',
            ),
            _buildDeveloperItem(
              name: 'Hoàng Văn Em',
              role: 'QA Specialist',
            ),
            
            const SizedBox(height: 24),
            
            // Bản quyền
            Center(
              child: Column(
                children: [
                  Text(
                    '© 2023 ShareXE. Tất cả các quyền được bảo lưu.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Made with ❤️ in Việt Nam',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFF002D72),
        ),
      ),
    );
  }

  Widget _buildInfoText(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          height: 1.5,
        ),
        textAlign: TextAlign.justify,
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF00AEEF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF00AEEF),
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF002D72),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeveloperItem({
    required String name,
    required String role,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFF00AEEF).withOpacity(0.2),
            child: Text(
              name.substring(0, 1),
              style: const TextStyle(
                color: Color(0xFF002D72),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  role,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 