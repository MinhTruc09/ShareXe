import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

class AboutAppScreen extends StatefulWidget {
  const AboutAppScreen({Key? key}) : super(key: key);

  @override
  State<AboutAppScreen> createState() => _AboutAppScreenState();
}

class _AboutAppScreenState extends State<AboutAppScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeInAnimation;
  late Animation<Offset> _slideAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    
    _controller.forward();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
    
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: ColorScheme.fromSwatch().copyWith(secondary: const Color(0xFF00AEEF)),
      ),
      child: Scaffold(
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 180.0,
              floating: false,
              pinned: true,
              stretch: true,
              backgroundColor: const Color(0xFF00AEEF),
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: true,
                title: const Text(
                  'Giới thiệu ứng dụng',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            const Color(0xFF00AEEF),
                            const Color(0xFF002D72).withOpacity(0.9),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: -50,
                      left: -50,
                      child: Container(
                        height: 150,
                        width: 150,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -20,
                      right: -20,
                      child: Container(
                        height: 100,
                        width: 100,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildListDelegate([
                SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeInAnimation,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Logo và slogan
                          Center(
                            child: Column(
                              children: [
                                Hero(
                                  tag: 'app_logo',
                                  child: Container(
                                    height: 120,
                                    width: 120,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(24),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF00AEEF).withOpacity(0.3),
                                          blurRadius: 15,
                                          offset: const Offset(0, 8),
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
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  'ShareXE',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF002D72),
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00AEEF).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: const Text(
                                    'Chia sẻ hành trình - Kết nối cộng đồng',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontStyle: FontStyle.italic,
                                      color: Color(0xFF00AEEF),
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF002D72).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    'Phiên bản 1.0.0',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: const Color(0xFF002D72).withOpacity(0.8),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 40),
                          
                          // Giới thiệu
                          _buildSectionTitle('Giới thiệu'),
                          _buildInfoText(
                            'ShareXE là ứng dụng di chuyển chung xe hơi đáng tin cậy, kết nối những người có chung lộ trình di chuyển. Chúng tôi giúp tối ưu chi phí di chuyển, giảm tắc nghẽn giao thông và góp phần bảo vệ môi trường.',
                          ),
                          _buildInfoText(
                            'Được phát triển bởi đội ngũ sinh viên nhiệt huyết, ShareXE mang đến trải nghiệm đi chung xe an toàn, tiện lợi và thân thiện.',
                          ),
                          
                          const SizedBox(height: 30),
                          
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
                          
                          const SizedBox(height: 30),
                          
                          // Đội ngũ phát triển
                          _buildSectionTitle('Đội ngũ phát triển'),
                          _buildDeveloperItem(
                            name: 'Nguyễn Minh Trực',
                            role: 'Thiết kế UI, Front-end Mobile Passenger',
                            mssv: '2251120392',
                            github: 'https://github.com/MinhTruc09',
                            facebook: 'https://www.facebook.com/nguyen.truc.101966/',
                            onTap: () => _launchUrl('https://github.com/MinhTruc09'),
                          ),
                          _buildDeveloperItem(
                            name: 'Nguyễn Thanh Khang',
                            role: 'Backend Carpooling, Front-end Mobile Driver',
                            mssv: '2251120355',
                            github: 'https://github.com/tkhan2004',
                            facebook: 'https://www.facebook.com/thanh.khang.827850',
                            onTap: () => _launchUrl('https://github.com/tkhan2004'),
                          ),
                          _buildDeveloperItem(
                            name: 'Trần Minh Hoàng',
                            role: 'Front-end Admin page management',
                            mssv: '2251120351',
                            github: 'https://github.com/TranMinhHoang267',
                            facebook: '',
                            onTap: () => _launchUrl('https://github.com/TranMinhHoang267'),
                          ),
                          
                          const SizedBox(height: 30),
                          
                          // Thông tin học phần
                          _buildSectionTitle('Thông tin học phần'),
                          Card(
                            elevation: 4,
                            shadowColor: Colors.grey.withOpacity(0.2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF00AEEF).withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.school,
                                          color: Color(0xFF00AEEF),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      const Expanded(
                                        child: Text(
                                          'Đồ án thực tế công nghệ phần mềm',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF002D72),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 24),
                                  _buildInfoRow(
                                    icon: Icons.people,
                                    text: 'Sinh viên năm 3 - Lớp CN22G - Trường Đại học Giao thông vận tải TP.HCM (UTH)',
                                  ),
                                  const SizedBox(height: 12),
                                  _buildInfoRow(
                                    icon: Icons.phone,
                                    text: 'Liên hệ: 0384584931',
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 32),
                          
                          // Bản quyền
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(
                                  color: Colors.grey.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                            ),
                            child: Center(
                              child: Column(
                                children: [
                                  Text(
                                    '© 2024 ShareXE. Tất cả các quyền được bảo lưu.',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.favorite,
                                        color: Colors.redAccent,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Made with love in Việt Nam',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                          fontStyle: FontStyle.italic,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF002D72),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 4,
            width: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF00AEEF),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoText(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          height: 1.6,
          color: Color(0xFF333333),
        ),
        textAlign: TextAlign.justify,
      ),
    );
  }
  
  Widget _buildInfoRow({required IconData icon, required String text}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: const Color(0xFF00AEEF),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              height: 1.5,
              color: Color(0xFF333333),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00AEEF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xFF00AEEF),
                    size: 24,
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
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF002D72),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Color(0xFF555555),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeveloperItem({
    required String name,
    required String role,
    required String mssv,
    required String github,
    required String facebook,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF00AEEF),
                            width: 2,
                          ),
                        ),
                        child: CircleAvatar(
                          backgroundColor: const Color(0xFF00AEEF).withOpacity(0.1),
                          radius: 28,
                          child: Text(
                            name.substring(0, 1),
                            style: const TextStyle(
                              color: Color(0xFF002D72),
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF002D72),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF002D72).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'MSSV: $mssv',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: const Color(0xFF002D72).withOpacity(0.8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00AEEF).withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF00AEEF).withOpacity(0.1),
                      ),
                    ),
                    child: Text(
                      role,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF00AEEF),
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSocialButton(
                        icon: Icons.code,
                        label: 'GitHub',
                        onTap: () => _launchUrl(github),
                      ),
                      if (facebook.isNotEmpty)
                        _buildSocialButton(
                          icon: Icons.facebook,
                          label: 'Facebook',
                          onTap: () => _launchUrl(facebook),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF00AEEF).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF00AEEF).withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: const Color(0xFF00AEEF),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF00AEEF),
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw 'Could not launch $url';
      }
    } catch (e) {
      print('Could not launch $url: $e');
    }
  }
} 