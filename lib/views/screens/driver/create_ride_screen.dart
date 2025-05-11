import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/ride_service.dart';
import '../../../services/auth_manager.dart';
import '../../widgets/location_picker.dart';
import '../../widgets/date_picker.dart';
import '../../widgets/passenger_counter.dart';

class CreateRideScreen extends StatefulWidget {
  final Map<String, dynamic>?
  existingRide; // null nếu tạo mới, có giá trị nếu cập nhật

  const CreateRideScreen({Key? key, this.existingRide}) : super(key: key);

  @override
  State<CreateRideScreen> createState() => _CreateRideScreenState();
}

class _CreateRideScreenState extends State<CreateRideScreen> {
  final RideService _rideService = RideService();
  final AuthManager _authManager = AuthManager();
  final _formKey = GlobalKey<FormState>();

  String _departure = '';
  String _destination = '';
  DateTime? _departureDate;
  int _totalSeats = 4;
  double _pricePerSeat = 0;
  bool _isSubmitting = false;
  bool _isEditMode = false;
  int? _rideId;

  final TextEditingController _priceController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Nếu có existingRide thì đây là chế độ cập nhật
    if (widget.existingRide != null) {
      _isEditMode = true;
      _loadExistingRideData();
      
      // Kiểm tra trạng thái của chuyến đi
      if (widget.existingRide?['status']?.toString().toUpperCase() == 'CANCELLED') {
        // Sử dụng WidgetsBinding để đảm bảo dialog được hiển thị sau khi build hoàn tất
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Chuyến đi đã bị hủy'),
                content: const Text(
                  'Không thể chỉnh sửa chuyến đi đã bị hủy. Vui lòng tạo chuyến đi mới.',
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Đóng dialog
                      Navigator.of(context).pop(); // Quay lại màn hình trước
                    },
                    child: const Text('Đã hiểu'),
                  ),
                ],
              );
            },
          );
        });
      }
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  void _loadExistingRideData() {
    final ride = widget.existingRide!;

    _rideId = ride['id'];
    _departure = ride['departure'] ?? '';
    _destination = ride['destination'] ?? '';

    if (ride['startTime'] != null) {
      try {
        _departureDate = DateTime.parse(ride['startTime']);
      } catch (e) {
        print('Error parsing date: $e');
      }
    }

    _totalSeats = ride['totalSeat'] ?? 4;
    _pricePerSeat = (ride['pricePerSeat'] ?? 0).toDouble();
    _priceController.text = _pricePerSeat.toString();
  }

  Future<void> _submitRide() async {
    if (_formKey.currentState?.validate() != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng điền đầy đủ thông tin')),
      );
      return;
    }

    if (_departure.isEmpty || _destination.isEmpty || _departureDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng điền đầy đủ thông tin chuyến đi'),
        ),
      );
      return;
    }
    
    // Kiểm tra trạng thái của chuyến đi nếu đang ở chế độ chỉnh sửa
    if (_isEditMode && widget.existingRide != null) {
      final rideStatus = widget.existingRide?['status']?.toString().toUpperCase();
      if (rideStatus == 'CANCELLED') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể cập nhật chuyến đi đã bị hủy'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Kiểm tra ngày giờ xuất phát
      final now = DateTime.now();
      if (_departureDate!.isBefore(now)) {
        setState(() {
          _isSubmitting = false;
        });
        
        // Hiển thị cảnh báo nếu thời gian đã qua
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thời gian xuất phát không thể trong quá khứ'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      
      // Chuẩn bị dữ liệu chuyến đi
      final rideData = {
        'departure': _departure,
        'destination': _destination,
        'startTime': _departureDate!.toIso8601String(),
        'totalSeat': _totalSeats,
        'pricePerSeat': _pricePerSeat,
        'status': 'ACTIVE',
      };

      print('📝 Đang gửi dữ liệu chuyến đi: $rideData');
      
      // Hiển thị dialog để người dùng biết đang xử lý
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
            child: Container(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text('Đang xử lý, vui lòng đợi...',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          );
        },
      );

      bool success;

      if (_isEditMode && _rideId != null) {
        // Cập nhật chuyến đi
        success = await _rideService.updateRide(_rideId!, rideData);
      } else {
        // Tạo chuyến đi mới
        success = await _rideService.createRide(rideData);
      }

      // Đóng dialog xử lý
      Navigator.of(context).pop();

      setState(() {
        _isSubmitting = false;
      });

      if (success) {
        // Hiển thị thông báo thành công
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(_isEditMode ? 'Cập nhật thành công' : 'Tạo chuyến đi thành công'),
              content: Text(_isEditMode 
                  ? 'Thông tin chuyến đi đã được cập nhật.'
                  : 'Chuyến đi mới đã được tạo thành công và đã có trong danh sách chuyến đi của bạn.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Đóng dialog
                    Navigator.of(context).pop(true); // Quay lại màn hình trước với kết quả thành công
                  },
                  child: Text('OK'),
                ),
              ],
            );
          },
        );
      } else {
        // Hiển thị thông báo lỗi
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditMode 
                ? 'Không thể cập nhật chuyến đi. Vui lòng kiểm tra kết nối mạng và thử lại.'
                : 'Không thể tạo chuyến đi. Vui lòng kiểm tra kết nối mạng và thử lại.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Thử lại',
              onPressed: _submitRide,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
      
      // Đóng dialog xử lý nếu đang hiển thị
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      print('❌ Exception trong _submitRide: $e');
      
      // Hiển thị thông báo lỗi chi tiết
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã xảy ra lỗi: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Thử lại',
            onPressed: _submitRide,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF002D72),
        title: Text(_isEditMode ? 'Cập nhật chuyến đi' : 'Tạo chuyến đi mới'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      LocationPicker(
                        title: 'Điểm đi',
                        icon: Icons.circle_outlined,
                        hintText: 'Xuất phát từ',
                        initialValue: _departure,
                        onLocationSelected: (location) {
                          setState(() {
                            _departure = location;
                          });
                        },
                      ),
                      const Divider(height: 16),
                      LocationPicker(
                        title: 'Điểm đến',
                        icon: Icons.location_on_outlined,
                        hintText: 'Điểm đến',
                        initialValue: _destination,
                        onLocationSelected: (location) {
                          setState(() {
                            _destination = location;
                          });
                        },
                      ),
                      const Divider(height: 16),
                      DatePickerField(
                        icon: Icons.access_time,
                        hintText: 'Thời gian xuất phát (ngày và giờ)',
                        initialDate: _departureDate,
                        includeTime: true,
                        onDateSelected: (date) {
                          setState(() {
                            _departureDate = date;
                            print('Đã chọn thời gian: ${DateFormat('dd/MM/yyyy HH:mm').format(date)}');
                          });
                        },
                      ),
                      const Divider(height: 16),
                      PassengerCounter(
                        icon: Icons.people_outline,
                        hintText: 'Số ghế',
                        initialCount: _totalSeats,
                        maxCount: 8,
                        onCountChanged: (count) {
                          setState(() {
                            _totalSeats = count;
                          });
                        },
                      ),
                      const Divider(height: 16),
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
                              decoration: const InputDecoration(
                                hintText: 'Giá mỗi ghế (VND)',
                                border: InputBorder.none,
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                setState(() {
                                  _pricePerSeat = double.tryParse(value) ?? 0;
                                });
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Vui lòng nhập giá';
                                }
                                if (double.tryParse(value) == null) {
                                  return 'Giá không hợp lệ';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitRide,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF002D72),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child:
                      _isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                            _isEditMode
                                ? 'Cập nhật chuyến đi'
                                : 'Tạo chuyến đi',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
