import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/ride_service.dart';
import '../../widgets/location_picker.dart';
import '../../widgets/date_picker.dart';
import '../../widgets/passenger_counter.dart';
import '../../../app_route.dart';
import '../../widgets/sharexe_background2.dart';

class CreateRideScreen extends StatefulWidget {
  const CreateRideScreen({super.key});

  @override
  State<CreateRideScreen> createState() => _CreateRideScreenState();
}

class _CreateRideScreenState extends State<CreateRideScreen> {
  final RideService _rideService = RideService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _priceController = TextEditingController();

  String _departure = '';
  String _destination = '';
  DateTime? _departureDateTime;
  int _totalSeats = 4;
  bool _isCreating = false;
  String _errorMessage = '';
  bool _showAdvancedOptions = false;
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _createRide() async {
    if (!_validateForm()) return;

    setState(() {
      _isCreating = true;
      _errorMessage = '';
    });

    try {
      // Lấy giá trị từ controller
      final double price = double.tryParse(_priceController.text.trim()) ?? 0;

      // Tạo chuyến đi mới
      final result = await _rideService.createRide(
        departure: _departure,
        destination: _destination,
        startTime: _departureDateTime!,
        pricePerSeat: price,
        totalSeat: _totalSeats,
      );

      if (result['success'] == true) {
        if (mounted) {
          // Hiển thị thông báo thành công
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tạo chuyến đi thành công'),
              backgroundColor: Colors.green,
            ),
          );

          // Đợi 1 giây để người dùng thấy thông báo
          await Future.delayed(const Duration(seconds: 1));

          // Quay lại trang trước
          if (mounted) {
            Navigator.of(
              context,
            ).pop(true); // Trả về true để biết đã tạo thành công
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = result['message'] ?? 'Tạo chuyến đi thất bại';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Lỗi: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }

  bool _validateForm() {
    if (_formKey.currentState?.validate() != true) {
      return false;
    }

    if (_departure.isEmpty) {
      setState(() {
        _errorMessage = 'Vui lòng chọn điểm đi';
      });
      return false;
    }

    if (_destination.isEmpty) {
      setState(() {
        _errorMessage = 'Vui lòng chọn điểm đến';
      });
      return false;
    }

    if (_departureDateTime == null) {
      setState(() {
        _errorMessage = 'Vui lòng chọn thời gian khởi hành';
      });
      return false;
    }

    if (_departure == _destination) {
      setState(() {
        _errorMessage = 'Điểm đi và điểm đến không được trùng nhau';
      });
      return false;
    }

    // Kiểm tra thời gian khởi hành phải sau thời điểm hiện tại
    final now = DateTime.now();
    if (_departureDateTime!.isBefore(now)) {
      setState(() {
        _errorMessage = 'Thời gian khởi hành phải sau thời điểm hiện tại';
      });
      return false;
    }

    double? price = double.tryParse(_priceController.text.trim());
    if (price == null || price <= 0) {
      setState(() {
        _errorMessage = 'Giá phải là số dương';
      });
      return false;
    }

    return true;
  }

  // Hiển thị dialog lỗi kết nối
  void _showOfflineDialog(String message) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.wifi_off, color: Colors.red[700]),
              const SizedBox(width: 10),
              const Text('Lỗi Kết Nối'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message),
              const SizedBox(height: 10),
              const Text(
                'Thông tin chuyến đi sẽ được lưu trữ tạm thời và đồng bộ khi có kết nối.',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Quay lại'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF002D72),
              ),
              child: const Text('Lưu nháp'),
              onPressed: () {
                // TODO: Thêm logic lưu nháp
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã lưu nháp thông tin chuyến đi!'),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.of(context).pop();
                Navigator.pushReplacementNamed(context, AppRoute.homeDriver);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SharexeBackground2(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: const Color(0xFF002D72),
          title: const Text('Đăng Chuyến Đi'),
          elevation: 0,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Card thông tin chính
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    color: Colors.white,
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Tiêu đề
                          Row(
                            children: [
                              const Icon(
                                Icons.directions_car,
                                color: Color(0xFF002D72),
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Thông tin chuyến đi',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF002D72),
                                ),
                              ),
                              const Spacer(),
                              // Huy hiệu
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00AEEF).withAlpha(30),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'Tài xế',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF00AEEF),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Trường tuyến đường
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Tuyến đường',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF002D72),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                LocationPicker(
                                  title: 'Điểm đi',
                                  icon: Icons.circle_outlined,
                                  hintText: 'Xuất phát từ',
                                  onLocationSelected: (location) {
                                    setState(() {
                                      _departure = location;
                                    });
                                  },
                                ),
                                const Padding(
                                  padding: EdgeInsets.only(left: 10),
                                  child: SizedBox(
                                    height: 20,
                                    child: VerticalDivider(
                                      color: Colors.grey,
                                      thickness: 1,
                                      width: 20,
                                    ),
                                  ),
                                ),
                                LocationPicker(
                                  title: 'Điểm đến',
                                  icon: Icons.location_on_outlined,
                                  hintText: 'Điểm đến',
                                  onLocationSelected: (location) {
                                    setState(() {
                                      _destination = location;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Thời gian khởi hành
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Thời gian khởi hành',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF002D72),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                DatePickerField(
                                  icon: Icons.access_time,
                                  hintText: 'Chọn thời gian xuất phát',
                                  onDateSelected: (date) {
                                    setState(() {
                                      _departureDateTime = date;
                                    });
                                  },
                                ),
                                if (_departureDateTime != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      'Thời gian khởi hành: ${DateFormat('HH:mm dd/MM/yyyy').format(_departureDateTime!)}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.blue,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Thông tin ghế và giá
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Thông tin chỗ ngồi và giá',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF002D72),
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Số ghế
                                PassengerCounter(
                                  icon: Icons.airline_seat_recline_normal,
                                  hintText: 'Số chỗ',
                                  onCountChanged: (count) {
                                    setState(() {
                                      _totalSeats = count;
                                    });
                                  },
                                  initialCount: 4,
                                  maxCount: 10,
                                ),
                                const SizedBox(height: 12),

                                // Giá mỗi ghế
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.monetization_on_outlined,
                                      color: Colors.grey,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _priceController,
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                          hintText: 'Giá mỗi ghế (VND)',
                                          hintStyle: TextStyle(
                                            color: Colors.grey,
                                          ),
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.zero,
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Vui lòng nhập giá';
                                          }
                                          if (double.tryParse(value) == null) {
                                            return 'Giá phải là số';
                                          }
                                          return null;
                                        },
                                        onChanged: (value) {
                                          setState(
                                            () {},
                                          ); // Cập nhật UI để hiển thị giá định dạng
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                if (_priceController.text.isNotEmpty &&
                                    double.tryParse(_priceController.text) !=
                                        null)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      top: 8.0,
                                      left: 32.0,
                                    ),
                                    child: Text(
                                      'Giá: ${currencyFormat.format(double.parse(_priceController.text))}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.blue,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          // Tùy chọn nâng cao
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _showAdvancedOptions = !_showAdvancedOptions;
                                });
                              },
                              child: Row(
                                children: [
                                  Icon(
                                    _showAdvancedOptions
                                        ? Icons.keyboard_arrow_up
                                        : Icons.keyboard_arrow_down,
                                    color: const Color(0xFF002D72),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Tùy chọn nâng cao',
                                    style: TextStyle(
                                      color: Color(0xFF002D72),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Nội dung tùy chọn nâng cao (chỉ hiển thị khi _showAdvancedOptions = true)
                          if (_showAdvancedOptions)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F5F5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Lưu ý cho hành khách',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF002D72),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const TextField(
                                    maxLines: 3,
                                    decoration: InputDecoration(
                                      hintText:
                                          'Nhập lưu ý cho hành khách (tùy chọn)',
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.all(12),
                                    ),
                                  ),

                                  const SizedBox(height: 16),

                                  const Text(
                                    'Điểm dừng trung gian',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF002D72),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const TextField(
                                    decoration: InputDecoration(
                                      hintText: 'Điểm dừng (tùy chọn)',
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.all(12),
                                    ),
                                  ),

                                  const SizedBox(height: 16),

                                  CheckboxListTile(
                                    title: const Text(
                                      'Cho phép mang hành lý lớn',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                    value: false,
                                    onChanged: (value) {},
                                    contentPadding: EdgeInsets.zero,
                                    dense: true,
                                    checkColor: Colors.white,
                                    activeColor: const Color(0xFF002D72),
                                  ),

                                  CheckboxListTile(
                                    title: const Text(
                                      'Cho phép hút thuốc',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                    value: false,
                                    onChanged: (value) {},
                                    contentPadding: EdgeInsets.zero,
                                    dense: true,
                                    checkColor: Colors.white,
                                    activeColor: const Color(0xFF002D72),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // Hiển thị thông báo lỗi nếu có
                  if (_errorMessage.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 16.0),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withAlpha(30),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withAlpha(100)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 20),

                  // Nút đăng chuyến đi
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isCreating ? null : _createRide,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF002D62),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        disabledBackgroundColor: Colors.grey,
                      ),
                      child:
                          _isCreating
                              ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    'Đang tạo chuyến...',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ],
                              )
                              : const Text(
                                'Đăng Chuyến Đi',
                                style: TextStyle(fontSize: 16),
                              ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Ghi chú quan trọng
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.withAlpha(100)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.amber),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Lưu ý: Đảm bảo thông tin chuyến đi chính xác. Sau khi đăng, hệ thống sẽ hiển thị chuyến đi này cho hành khách.',
                            style: TextStyle(fontSize: 12),
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
      ),
    );
  }
}
