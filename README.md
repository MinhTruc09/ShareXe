# ShareXe - Ứng dụng Đi chung xe

![ShareXe Logo](https://via.placeholder.com/150x50?text=ShareXe)

ShareXe là ứng dụng di chuyển chung xe hơi (carpooling) kết nối những người có chung lộ trình di chuyển, giúp tối ưu chi phí di chuyển, giảm tắc nghẽn giao thông và góp phần bảo vệ môi trường.

## 📥 Tải xuống

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

## 🧪 Kiểm thử

Chạy các bài kiểm thử tự động:
```bash
flutter test
```

## 🔒 Quyền riêng tư và bảo mật

- Ứng dụng yêu cầu quyền truy cập vị trí để tìm kiếm chuyến đi gần bạn
- Đối với tài xế, ứng dụng cần quyền truy cập camera để tải lên giấy phép lái xe
- Dữ liệu người dùng được mã hóa và bảo vệ theo tiêu chuẩn ngành

## 👨‍💻 Đội ngũ phát triển

- **Nguyễn Minh Trực** - Thiết kế UI, Front-end Mobile Passenger - [GitHub](https://github.com/MinhTruc09)
- **Nguyễn Thanh Khang** - Backend Carpooling, Front-end Mobile Driver - [GitHub](https://github.com/tkhan2004)
- **Trần Minh Hoàng** - Front-end Admin page management - [GitHub](https://github.com/TranMinhHoang267)

## 📜 Giấy phép

Dự án thuộc sở hữu của Trường Đại học Giao thông vận tải TP.HCM (UTH) - Lớp CN22G

## 📞 Liên hệ hỗ trợ

Email: sharexe.project@gmail.com