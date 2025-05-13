import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hỗ trợ khách hàng'),
        backgroundColor: const Color(0xFF00AEEF),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner hỗ trợ
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00AEEF), Color(0xFF0078A8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.support_agent,
                          color: Colors.white,
                          size: 30,
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
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '24/7 - Phản hồi trong vòng 30 phút',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.phone),
                    label: const Text('Gọi ngay'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: const Color(0xFF00AEEF),
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 24,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: () => _makePhoneCall('0987654321'),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Kênh hỗ trợ
            _buildSectionTitle('Kênh hỗ trợ'),
            
            _buildContactItem(
              icon: Icons.phone,
              title: 'Hotline',
              subtitle: '0987654321 (8:00 - 22:00)',
              onTap: () => _makePhoneCall('0987654321'),
              actionIcon: Icons.call,
              actionText: 'Gọi',
            ),
            
            _buildContactItem(
              icon: Icons.email,
              title: 'Email',
              subtitle: 'support@sharexe.vn',
              onTap: () => _launchEmail('support@sharexe.vn'),
              actionIcon: Icons.send,
              actionText: 'Gửi',
            ),
            
            _buildContactItem(
              icon: Icons.facebook,
              title: 'Facebook',
              subtitle: 'facebook.com/sharexevn',
              onTap: () => _launchUrl('https://facebook.com/sharexevn'),
              actionIcon: Icons.open_in_new,
              actionText: 'Mở',
            ),
            
            _buildContactItem(
              icon: Icons.web,
              title: 'Website',
              subtitle: 'www.sharexe.vn',
              onTap: () => _launchUrl('https://www.sharexe.vn'),
              actionIcon: Icons.open_in_new,
              actionText: 'Mở',
            ),
            
            const SizedBox(height: 24),
            
            // FAQ
            _buildSectionTitle('Câu hỏi thường gặp'),
            
            _buildFaqItem(
              question: 'ShareXE là gì?',
              answer: 'ShareXE là ứng dụng di chuyển chung xe hơi, kết nối những người có chung lộ trình di chuyển, giúp tối ưu chi phí và bảo vệ môi trường.',
            ),
            
            _buildFaqItem(
              question: 'Làm thế nào để đăng ký làm tài xế?',
              answer: 'Để đăng ký làm tài xế, bạn cần đăng nhập vào ứng dụng, chọn "Đăng ký làm tài xế" trong menu cài đặt, và cung cấp thông tin cần thiết như giấy phép lái xe, bảo hiểm xe và thông tin cá nhân.',
            ),
            
            _buildFaqItem(
              question: 'Có thể hủy chuyến đi không?',
              answer: 'Có, bạn có thể hủy chuyến đi của mình. Tuy nhiên, việc hủy trước 24 giờ sẽ không bị tính phí, còn hủy trong vòng 24 giờ trước chuyến đi có thể phải chịu phí hủy chuyến.',
            ),
            
            _buildFaqItem(
              question: 'Làm thế nào để liên hệ với tài xế trước chuyến đi?',
              answer: 'Sau khi đặt chỗ, bạn có thể sử dụng tính năng chat trong ứng dụng để liên hệ trực tiếp với tài xế về chi tiết chuyến đi.',
            ),
            
            _buildFaqItem(
              question: 'ShareXE có an toàn không?',
              answer: 'ShareXE ưu tiên sự an toàn của người dùng. Chúng tôi xác thực danh tính của tất cả người dùng, có hệ thống đánh giá sau mỗi chuyến đi, và cung cấp tính năng chia sẻ hành trình với người thân.',
            ),
            
            const SizedBox(height: 24),
            
            // Đội ngũ hỗ trợ
            _buildSectionTitle('Văn phòng hỗ trợ'),
            
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: Color(0xFF00AEEF),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Trụ sở chính',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF002D72),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '266 Đội Cấn, Ba Đình, Hà Nội',
                    style: TextStyle(fontSize: 15),
                  ),
                  const Text(
                    'Giờ làm việc: 8:00 - 18:00 (Thứ 2 - Thứ 6)',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => _launchMap('266 Đội Cấn, Ba Đình, Hà Nội'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFF00AEEF)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.map,
                            size: 16,
                            color: Color(0xFF00AEEF),
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Xem bản đồ',
                            style: TextStyle(
                              color: Color(0xFF00AEEF),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: Color(0xFF00AEEF),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Văn phòng TP.HCM',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF002D72),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '123 Nguyễn Văn Linh, Quận 7, TP.HCM',
                    style: TextStyle(fontSize: 15),
                  ),
                  const Text(
                    'Giờ làm việc: 8:00 - 18:00 (Thứ 2 - Thứ 7)',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => _launchMap('123 Nguyễn Văn Linh, Quận 7, TP.HCM'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFF00AEEF)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.map,
                            size: 16,
                            color: Color(0xFF00AEEF),
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Xem bản đồ',
                            style: TextStyle(
                              color: Color(0xFF00AEEF),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Bản quyền
            Center(
              child: Column(
                children: [
                  const Text(
                    'Hỗ trợ kỹ thuật: tech@sharexe.vn',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '© 2023 ShareXE. Tất cả các quyền được bảo lưu.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
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
      padding: const EdgeInsets.only(bottom: 16.0),
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

  Widget _buildContactItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required IconData actionIcon,
    required String actionText,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00AEEF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
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
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF002D72),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  icon: Icon(actionIcon, size: 16),
                  label: Text(actionText),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00AEEF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  onPressed: onTap,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFaqItem({
    required String question,
    required String answer,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF002D72),
          ),
        ),
        collapsedIconColor: const Color(0xFF00AEEF),
        iconColor: const Color(0xFF00AEEF),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              answer,
              style: const TextStyle(height: 1.5),
            ),
          ),
        ],
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
        print('Link đã được copy: $textToCopy');
      }
    }
  }
} 