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

    setState(() {
      _isSubmitting = true;
    });

    try {
      final rideData = {
        'departure': _departure,
        'destination': _destination,
        'startTime': _departureDate!.toIso8601String(),
        'totalSeat': _totalSeats,
        'pricePerSeat': _pricePerSeat,
        'status': 'ACTIVE',
      };

      bool success;

      if (_isEditMode && _rideId != null) {
        // Cập nhật chuyến đi
        success = await _rideService.updateRide(_rideId!, rideData);
      } else {
        // Tạo chuyến đi mới
        success = await _rideService.createRide(rideData);
      }

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditMode
                  ? 'Cập nhật chuyến đi thành công'
                  : 'Tạo chuyến đi thành công',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(
          context,
          true,
        ); // Quay lại màn hình trước với kết quả thành công
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditMode
                  ? 'Không thể cập nhật chuyến đi'
                  : 'Không thể tạo chuyến đi',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
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
                        hintText: 'Thời gian xuất phát',
                        initialDate: _departureDate,
                        onDateSelected: (date) {
                          setState(() {
                            _departureDate = date;
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
