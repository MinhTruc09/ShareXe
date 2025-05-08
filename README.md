# Cập nhật tính năng Đăng Chuyến Đi cho ShareXe

## Những cải tiến chính

### 1. API Integration
- Đã sửa lại phương thức `createRide` trong `RideService` để tương thích với API endpoint `/api/ride`
- Thêm hỗ trợ cho HTTP status code 200 và 201 (created)
- Sử dụng baseUrl chung được cấu hình trong AppConfig

### 2. Cải thiện giao diện tài xế
- Thiết kế lại màn hình chính tài xế (HomeDscreen) với giao diện trực quan, thân thiện hơn
- Thêm dashboard hiển thị thông tin tổng quan:
  - Số chuyến đi hiện tại
  - Số chuyến đi đã hoàn thành
  - Tổng thu nhập
- Làm nổi bật nút "Đăng Chuyến Đi Mới" giúp dễ dàng tiếp cận
- Cải thiện hiển thị yêu cầu đặt chỗ chờ xử lý

### 3. Cải thiện màn hình Đăng Chuyến Đi
- Thiết kế lại giao diện với phân vùng rõ ràng
- Thêm trực quan hóa tuyến đường (điểm đi - điểm đến)
- Hiển thị thông tin giá tiền đã định dạng
- Thêm tùy chọn mở rộng (Advanced Options)
- Tăng cường kiểm tra validation với thông báo lỗi rõ ràng
- Thêm hiệu ứng trực quan khi nhập dữ liệu

### 4. Cấu trúc Request API
```json
{
  "departure": "An Giang",
  "destination": "Sài Gòn",
  "startTime": "2025-06-06T08:00:00",
  "pricePerSeat": 200000,
  "totalSeat": 4
}
```

### 5. Endpoint URL
`https://209b-2405-4803-c83c-6d40-8464-c5f5-c484-d512.ngrok-free.app/api/ride`

## Hướng dẫn sử dụng
1. Đăng nhập vào ứng dụng với tư cách tài xế
2. Từ màn hình chính, nhấn nút "Đăng Chuyến Đi Mới"
3. Nhập đầy đủ thông tin:
   - Điểm đi
   - Điểm đến
   - Thời gian khởi hành
   - Số ghế
   - Giá mỗi ghế
4. Nếu cần, mở rộng phần "Tùy chọn nâng cao" để cung cấp thêm thông tin
5. Nhấn nút "Đăng Chuyến Đi" để tạo chuyến đi mới

## Lưu ý
- Ứng dụng yêu cầu người dùng đăng nhập với vai trò DRIVER để sử dụng tính năng này
- API endpoint yêu cầu token xác thực hợp lệ (Bearer token) trong header
- Phải nhập đầy đủ thông tin bắt buộc trước khi đăng chuyến đi
