# ShareXe - Ứng dụng Đi chung xe

<div align="center">
  <img src="assets/images/logo.png" alt="ShareXe Logo" width="300"/>
  
  <br>
  <p><b>Kết nối hành trình - Chia sẻ niềm vui</b></p>
  
  <div>
    <img src="https://img.shields.io/badge/Flutter-3.0.0+-02569B?style=flat-square&logo=flutter" alt="Flutter 3.0.0+"/>
    <img src="https://img.shields.io/badge/Dart-2.17.0+-0175C2?style=flat-square&logo=dart" alt="Dart 2.17.0+"/>
    <img src="https://img.shields.io/badge/Version-1.0.0-brightgreen?style=flat-square" alt="Version 1.0.0"/>
    <img src="https://img.shields.io/badge/License-UTH-blue?style=flat-square" alt="License UTH"/>
  </div>
</div>

<br>

ShareXe là ứng dụng di chuyển chung xe hơi (carpooling) kết nối những người có chung lộ trình di chuyển, giúp tối ưu chi phí di chuyển, giảm tắc nghẽn giao thông và góp phần bảo vệ môi trường.

## 📥 Tải xuống

<div align="center">
  <img src="assets/images/qr.png" alt="ShareXe QR Code" width="200"/>
  <p>Quét mã QR để tải ứng dụng</p>
</div>

Bạn có thể tải xuống phiên bản mới nhất của ứng dụng ShareXe qua các cách sau:

- [Tải APK trực tiếp](https://drive.google.com/file/d/1tYj4mNkX7vTg3W8HpRy9i_pTp7JQwRvp/view?usp=sharing) (v1.0.0)
- [Google Play Store](#) (Đang chờ phê duyệt)

**Lưu ý khi cài đặt APK**: Trên Android, bạn cần cho phép cài đặt ứng dụng từ nguồn không xác định trong cài đặt bảo mật của thiết bị.

## 📋 Tính năng

### Dành cho Hành khách
- Đăng ký/Đăng nhập tài khoản
- Tìm kiếm chuyến đi phù hợp
- Đặt chỗ và thanh toán trực tuyến
- Theo dõi lịch sử chuyến đi
- Nhắn tin trực tiếp với tài xế
- Đánh giá sau chuyến đi

### Dành cho Tài xế
- Đăng ký/Xác thực tài khoản tài xế
- Tạo và quản lý chuyến đi
- Chấp nhận/Từ chối yêu cầu đặt chỗ
- Quản lý lịch sử chuyến đi
- Nhắn tin với hành khách
- Nhận đánh giá và phản hồi

## 🌟 Ưu điểm

- **Tối ưu chi phí**: Chia sẻ chi phí nhiên liệu và phí cầu đường
- **Bảo vệ môi trường**: Giảm lượng khí thải CO2 bằng cách giảm số lượng xe trên đường
- **Giảm kẹt xe**: Góp phần giảm áp lực giao thông trong giờ cao điểm
- **An toàn đáng tin cậy**: Xác thực người dùng, đánh giá sau chuyến đi
- **Kết nối cộng đồng**: Tạo cơ hội gặp gỡ những người mới có chung sở thích/công việc

## 🛠️ Công nghệ sử dụng

- **Frontend**: Flutter, Dart
- **Backend**: Node.js, Express.js
- **Database**: MongoDB
- **Realtime Communication**: Socket.io
- **Authentication**: JWT, Firebase Auth
- **Payment Integration**: VNPay, MoMo
- **Maps & Location**: Google Maps API
- **Cloud Services**: Firebase, Render

## 🛠️ Yêu cầu hệ thống

- Flutter SDK (phiên bản 3.0.0 trở lên)
- Dart (phiên bản 2.17.0 trở lên)
- Android Studio hoặc Visual Studio Code
- Thiết bị di động chạy Android (API level 21+) hoặc iOS (iOS 11+)

## ⚙️ Cài đặt

### 1. Cài đặt Flutter SDK
Tải và cài đặt Flutter SDK từ [trang web chính thức](https://flutter.dev/docs/get-started/install).

```bash
# Kiểm tra cài đặt Flutter
flutter doctor
```

### 2. Cài đặt các công cụ phát triển
Cài đặt Android Studio hoặc Visual Studio Code:
- [Android Studio](https://developer.android.com/studio)
- [Visual Studio Code](https://code.visualstudio.com/) với [Flutter extension](https://marketplace.visualstudio.com/items?itemName=Dart-Code.flutter)

### 3. Clone dự án từ GitHub
```bash
git clone https://github.com/MinhTruc09/ShareXe.git
cd ShareXe
```

### 4. Cài đặt các phụ thuộc
```bash
flutter pub get
```

### 5. Cấu hình Firebase
Dự án sử dụng Firebase cho các tính năng xác thực và lưu trữ.

1. Tạo dự án Firebase tại [Firebase Console](https://console.firebase.google.com/)
2. Thêm ứng dụng Android và iOS vào dự án Firebase:
   - Đối với Android: Thêm file `google-services.json` vào `/android/app/`
   - Đối với iOS: Thêm file `GoogleService-Info.plist` vào `/ios/Runner/`

### 6. Cấu hình biến môi trường
Tạo file `.env` trong thư mục gốc của dự án:

```
API_BASE_URL=https://your-backend-api-url.com
```

### 7. Chạy ứng dụng
```bash
flutter run
```

### 8. Lưu ý khi clone dự án cùng backend
Nếu bạn clone cả phần backend của dự án, hãy cấu hình lại API_BASE_URL trong file `.env` để kết nối với backend local:

```
API_BASE_URL=http://localhost:8080
```

Mặc định, dự án đang sử dụng API_BASE_URL được cấu hình để kết nối đến server backend production. Khi phát triển và chạy backend locally, việc thay đổi API_BASE_URL là cần thiết để ứng dụng kết nối đúng với backend của bạn.

#### Khởi động backend local
```bash
# Di chuyển vào thư mục backend
cd ../ShareXe-backend

# Cài đặt các phụ thuộc
npm install

# Khởi động server
npm run dev
```

## 📂 Cấu trúc dự án

```
lib/
├── app_route.dart             # Định tuyến với không gian tên riêng cho tài xế và hành khách
├── main.dart                  # Khởi tạo ứng dụng
├── services/                  # Dịch vụ API và logic kinh doanh
├── models/                    # Mô hình dữ liệu
├── controllers/               # Bộ điều khiển quản lý trạng thái
├── utils/                     # Tiện ích và hỗ trợ
└── views/                     # Thành phần UI
    ├── screens/               # Màn hình ứng dụng
    │   ├── common/            # Màn hình chung (splash, chọn vai trò, v.v.)
    │   ├── passenger/         # Màn hình dành cho hành khách
    │   ├── driver/            # Màn hình dành cho tài xế
    │   └── chat/              # Màn hình chức năng chat
    ├── widgets/               # Thành phần UI có thể tái sử dụng
    └── theme/                 # Cấu hình giao diện
```

## 🚀 API Documentation

ShareXe sử dụng REST API được xây dựng trên Node.js và Express. API cung cấp các endpoint để:
- Xác thực người dùng (đăng ký, đăng nhập, làm mới token)
- Quản lý thông tin cá nhân
- Tìm kiếm và đặt chuyến đi
- Quản lý chuyến đi (tạo, hủy, cập nhật trạng thái)
- Giao tiếp thông qua chat
- Thanh toán trực tuyến

Xem tài liệu API đầy đủ tại [ShareXe API Documentation](assets/api.pdf).

## 🧪 Kiểm thử

Chạy các bài kiểm thử tự động:
```bash
flutter test
```

## 🔒 Quyền riêng tư và bảo mật

- Ứng dụng yêu cầu quyền truy cập vị trí để tìm kiếm chuyến đi gần bạn
- Đối với tài xế, ứng dụng cần quyền truy cập camera để tải lên giấy phép lái xe
- Dữ liệu người dùng được mã hóa và bảo vệ theo tiêu chuẩn ngành
- Thông tin thanh toán được xử lý qua các cổng thanh toán an toàn

## 👨‍💻 Đội ngũ phát triển

- **Nguyễn Minh Trực** - Thiết kế UI, Front-end Mobile Passenger - [GitHub](https://github.com/MinhTruc09)
- **Nguyễn Thanh Khang** - Backend Carpooling, Front-end Mobile Driver - [GitHub](https://github.com/tkhan2004)
- **Trần Minh Hoàng** - Front-end Admin page management - [GitHub](https://github.com/TranMinhHoang267)

## 📜 Giấy phép

Dự án thuộc sở hữu của Trường Đại học Giao thông vận tải TP.HCM (UTH) - Lớp CN22G

## 🌎 Ngôn ngữ hỗ trợ

- Tiếng Việt (mặc định)
- Tiếng Anh

## 📞 Liên hệ hỗ trợ

- **Email**: sharexe.project@gmail.com
- **Website**: [www.sharexe.vn](#)
- **Facebook**: [ShareXe Vietnam](#)

---

<div align="center">
  <p>© 2023 ShareXe - Phát triển bởi sinh viên ĐH Giao thông vận tải TP.HCM</p>
  <p>🚗 Cùng nhau đi xa hơn, rẻ hơn, xanh hơn 🌳</p>
</div>