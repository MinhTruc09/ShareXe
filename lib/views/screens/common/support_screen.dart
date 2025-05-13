import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({Key? key}) : super(key: key);

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  
  int _expandedFaqIndex = -1;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeIn,
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
    
    return Scaffold(
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
                'Hỗ trợ khách hàng',
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
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: [
                          const Color(0xFF00AEEF),
                          const Color(0xFF0078A8),
                        ],
                      ),
                    ),
                  ),
                  // Decorative elements
                  Positioned(
                    top: -30,
                    right: -30,
                    child: Container(
                      height: 140,
                      width: 140,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -50,
                    left: -20,
                    child: Container(
                      height: 180,
                      width: 180,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  // Support representative image or icon
                  Positioned(
                    bottom: 0,
                    right: 20,
                    child: Icon(
                      Icons.support_agent,
                      color: Colors.white.withOpacity(0.8),
                      size: 60,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Banner hỗ trợ
                      _buildSupportBanner(),
                      
                      const SizedBox(height: 30),
                      
                      // Kênh hỗ trợ
                      _buildSectionTitle('Kênh hỗ trợ'),
                      
                      _buildContactItem(
                        icon: Icons.phone,
                        title: 'Hotline',
                        subtitle: '0384584931 (8:00 - 22:00)',
                        onTap: () => _makePhoneCall('0384584931'),
                        actionIcon: Icons.call,
                        actionText: 'Gọi',
                        delay: 100,
                      ),
                      
                      _buildContactItem(
                        icon: Icons.email,
                        title: 'Email',
                        subtitle: 'sharexe.project@gmail.com',
                        onTap: () => _launchEmail('sharexe.project@gmail.com'),
                        actionIcon: Icons.send,
                        actionText: 'Gửi',
                        delay: 200,
                      ),
                      
                      _buildContactItem(
                        icon: Icons.facebook,
                        title: 'Facebook',
                        subtitle: 'facebook.com/nguyen.truc.101966',
                        onTap: () => _launchUrl('https://facebook.com/nguyen.truc.101966'),
                        actionIcon: Icons.open_in_new,
                        actionText: 'Mở',
                        delay: 300,
                      ),
                      
                      _buildContactItem(
                        icon: Icons.code,
                        title: 'GitHub',
                        subtitle: 'github.com/MinhTruc09/ShareXe',
                        onTap: () => _launchUrl('https://github.com/MinhTruc09/ShareXe'),
                        actionIcon: Icons.open_in_new,
                        actionText: 'Mở',
                        delay: 400,
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // FAQ
                      _buildSectionTitle('Câu hỏi thường gặp'),
                      
                      _buildFaqItem(
                        index: 0,
                        question: 'ShareXE là gì?',
                        answer: 'ShareXE là ứng dụng di chuyển chung xe hơi (carpooling), kết nối những người có chung lộ trình di chuyển, giúp tối ưu chi phí di chuyển, giảm tắc nghẽn giao thông và góp phần bảo vệ môi trường. Dự án được phát triển bởi sinh viên năm 3 lớp CN22G trong môn Đồ án thực tế công nghệ phần mềm.',
                      ),
                      
                      _buildFaqItem(
                        index: 1,
                        question: 'Làm thế nào để đăng ký làm tài xế?',
                        answer: 'Để đăng ký làm tài xế, bạn cần đăng nhập vào ứng dụng, chọn "Đăng ký làm tài xế" trong menu cài đặt, và cung cấp thông tin cần thiết như giấy phép lái xe, bảo hiểm xe và thông tin cá nhân.',
                      ),
                      
                      _buildFaqItem(
                        index: 2,
                        question: 'Có thể hủy chuyến đi không?',
                        answer: 'Có, bạn có thể hủy chuyến đi của mình. Tuy nhiên, việc hủy trước 24 giờ sẽ không bị tính phí, còn hủy trong vòng 24 giờ trước chuyến đi có thể phải chịu phí hủy chuyến.',
                      ),
                      
                      _buildFaqItem(
                        index: 3,
                        question: 'Làm thế nào để liên hệ với tài xế trước chuyến đi?',
                        answer: 'Sau khi đặt chỗ, bạn có thể sử dụng tính năng chat trong ứng dụng để liên hệ trực tiếp với tài xế về chi tiết chuyến đi.',
                      ),
                      
                      _buildFaqItem(
                        index: 4,
                        question: 'ShareXE có an toàn không?',
                        answer: 'ShareXE ưu tiên sự an toàn của người dùng. Chúng tôi xác thực danh tính của tất cả người dùng, có hệ thống đánh giá sau mỗi chuyến đi, và cung cấp tính năng chia sẻ hành trình với người thân.',
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // Văn phòng hỗ trợ
                      _buildSectionTitle('Văn phòng hỗ trợ'),
                      
                      _buildOfficeItem(
                        title: 'Trường Đại học Giao thông vận tải TP.HCM (UTH)',
                        address: 'Cơ sở 3: 70 Tô Ký, Trung Mỹ Tây, Quận 12, TP.HCM',
                        details: 'Lớp CN22G - Khoa Công nghệ thông tin',
                        mapUrl: '70 Tô Ký, Trung Mỹ Tây, Quận 12, TP.HCM',
                        delay: 100,
                      ),
                      
                      _buildOfficeItem(
                        title: 'Trường Đại học Giao thông vận tải TP.HCM (UTH)',
                        address: 'Cơ sở chính: Số 2, Võ Oanh, Phường 25, Quận Bình Thạnh, TP.HCM',
                        details: 'Phòng thực hành CNTT',
                        mapUrl: 'Số 2, Võ Oanh, Phường 25, Quận Bình Thạnh, TP.HCM',
                        delay: 200,
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // Bản quyền
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 20),
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
                              const Text(
                                'Hỗ trợ kỹ thuật: sharexe.project@gmail.com',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                '© 2024 ShareXE. Tất cả các quyền được bảo lưu.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
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
            ]),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _makePhoneCall('0384584931'),
        backgroundColor: const Color(0xFF00AEEF),
        elevation: 4,
        child: const Icon(
          Icons.phone,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildSupportBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00AEEF), Color(0xFF0078A8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00AEEF).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.support_agent,
                  color: Colors.white,
                  size: 34,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chúng tôi luôn sẵn sàng hỗ trợ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      '24/7 - Phản hồi trong vòng 30 phút',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.phone, size: 20),
            label: const Text(
              'Gọi ngay',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              foregroundColor: const Color(0xFF00AEEF),
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                vertical: 14,
                horizontal: 24,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 3,
            ),
            onPressed: () => _makePhoneCall('0384584931'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
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

  Widget _buildContactItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required IconData actionIcon,
    required String actionText,
    required int delay,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 500 + delay),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.12),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
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
                      size: 26,
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
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Color(0xFF555555),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    icon: Icon(actionIcon, size: 16),
                    label: Text(
                      actionText,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00AEEF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 2,
                    ),
                    onPressed: onTap,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFaqItem({
    required int index,
    required String question,
    required String answer,
  }) {
    final bool isExpanded = _expandedFaqIndex == index;
    
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
          onTap: () {
            setState(() {
              _expandedFaqIndex = isExpanded ? -1 : index;
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00AEEF).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Color(0xFF00AEEF),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        question,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF002D72),
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: isExpanded ? 0.25 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: Icon(
                        Icons.keyboard_arrow_right,
                        color: const Color(0xFF00AEEF),
                        size: 24,
                      ),
                    ),
                  ],
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: Container(
                    height: isExpanded ? null : 0,
                    margin: isExpanded
                        ? const EdgeInsets.only(top: 12)
                        : EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(),
                        const SizedBox(height: 8),
                        Text(
                          answer,
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.6,
                            color: Color(0xFF555555),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOfficeItem({
    required String title,
    required String address,
    required String details,
    required String mapUrl,
    required int delay,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 500 + delay),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.12),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.hardEdge,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 120,
                width: double.infinity,
                color: const Color(0xFF00AEEF).withOpacity(0.1),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(
                        Icons.map,
                        size: 60,
                        color: const Color(0xFF00AEEF).withOpacity(0.3),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              const Color(0xFF002D72).withOpacity(0.8),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Color(0xFF00AEEF),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            address,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Color(0xFF00AEEF),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          details,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () => _launchMap(mapUrl),
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFF00AEEF).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: const Color(0xFF00AEEF),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.directions,
                              color: Color(0xFF00AEEF),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Xem bản đồ',
                              style: TextStyle(
                                color: Color(0xFF00AEEF),
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    await _launchUrlWithFallback(launchUri);
  }

  Future<void> _launchEmail(String email) async {
    final Uri launchUri = Uri(
      scheme: 'mailto',
      path: email,
    );
    await _launchUrlWithFallback(launchUri);
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri launchUri = Uri.parse(urlString);
    await _launchUrlWithFallback(launchUri);
  }

  Future<void> _launchMap(String address) async {
    final String encodedAddress = Uri.encodeComponent(address);
    final Uri googleMapsUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=$encodedAddress');
    await _launchUrlWithFallback(googleMapsUrl);
  }

  Future<void> _launchUrlWithFallback(Uri url) async {
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw 'Could not launch $url';
      }
    } catch (e) {
      // Phương thức dự phòng: hiển thị dialog để copy
      if (url.toString().startsWith('tel:') || 
          url.toString().startsWith('mailto:') ||
          url.toString().startsWith('http')) {
        String textToCopy = url.toString().replaceFirst('tel:', '')
                                           .replaceFirst('mailto:', '');
        Clipboard.setData(ClipboardData(text: textToCopy));
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã sao chép: $textToCopy'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    }
  }
} 