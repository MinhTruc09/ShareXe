import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/ride_service.dart';

class PostRideScreen extends StatefulWidget {
  const PostRideScreen({Key? key}) : super(key: key);

  @override
  State<PostRideScreen> createState() => _PostRideScreenState();
}

class _PostRideScreenState extends State<PostRideScreen> {
  final _formKey = GlobalKey<FormState>();
  final _departureController = TextEditingController();
  final _destinationController = TextEditingController();
  final _priceController = TextEditingController();
  final _seatsController = TextEditingController();
  
  final RideService _rideService = RideService();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isLoading = false;
  String? _errorMessage;
  bool _isSuccess = false;

  @override
  void dispose() {
    _departureController.dispose();
    _destinationController.dispose();
    _priceController.dispose();
    _seatsController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF002D72),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF002D72),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        // Combine date and time
        final DateTime startDateTime = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          _selectedTime.hour,
          _selectedTime.minute,
        );

        // Format as ISO8601 string
        final String startTimeIso = startDateTime.toIso8601String();
        
        // Parse price with proper locale
        final priceText = _priceController.text.replaceAll('.', '');
        final double price = double.parse(priceText);
        
        // Parse seats
        final int seats = int.parse(_seatsController.text);

        final result = await _rideService.createRide(
          departure: _departureController.text,
          destination: _destinationController.text,
          startTime: startTimeIso,
          pricePerSeat: price,
          totalSeat: seats,
        );

        setState(() {
          _isLoading = false;
          _isSuccess = result;
          if (!result) {
            _errorMessage = 'Không thể tạo chuyến đi. Vui lòng thử lại sau.';
          }
        });

        if (result) {
          // Show success message and reset form
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tạo chuyến đi thành công!'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Clear form after success
          _departureController.clear();
          _destinationController.clear();
          _priceController.clear();
          _seatsController.clear();
          setState(() {
            _selectedDate = DateTime.now().add(const Duration(days: 1));
            _selectedTime = TimeOfDay.now();
          });

          // Navigate back after short delay
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              Navigator.pop(context, true);
            }
          });
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Đã xảy ra lỗi: $e';
        });
      }
    }
  }

  String _formatDateTime() {
    return '${_selectedTime.format(context)} ${DateFormat('dd/MM/yyyy').format(_selectedDate)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng chuyến đi'),
        backgroundColor: const Color(0xFF002D72),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                      side: BorderSide(color: Colors.blue.shade200, width: 1),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Thông tin chuyến đi',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF002D72),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Departure field
                          TextFormField(
                            controller: _departureController,
                            decoration: InputDecoration(
                              labelText: 'Xuất phát từ',
                              hintText: 'Nhập địa điểm xuất phát',
                              prefixIcon: const Icon(Icons.location_on_outlined, color: Color(0xFF002D72)),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF002D72), width: 2),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Vui lòng nhập điểm xuất phát';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          // Destination field
                          TextFormField(
                            controller: _destinationController,
                            decoration: InputDecoration(
                              labelText: 'Điểm đến',
                              hintText: 'Nhập địa điểm đến',
                              prefixIcon: const Icon(Icons.location_on, color: Color(0xFF002D72)),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF002D72), width: 2),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Vui lòng nhập điểm đến';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          // Date and time picker
                          InkWell(
                            onTap: () async {
                              await _selectDate(context);
                              await _selectTime(context);
                            },
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Thời gian xuất phát',
                                prefixIcon: const Icon(Icons.access_time, color: Color(0xFF002D72)),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(_formatDateTime()),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Price field
                          TextFormField(
                            controller: _priceController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Giá tiền mỗi ghế',
                              hintText: 'VD: 900000',
                              suffixText: 'VND',
                              prefixIcon: const Icon(Icons.attach_money, color: Color(0xFF002D72)),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF002D72), width: 2),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Vui lòng nhập giá tiền';
                              }
                              if (double.tryParse(value.replaceAll('.', '')) == null) {
                                return 'Giá tiền không hợp lệ';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          // Seats field
                          TextFormField(
                            controller: _seatsController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Số lượng ghế',
                              hintText: 'VD: 2',
                              prefixIcon: const Icon(Icons.airline_seat_recline_normal, color: Color(0xFF002D72)),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF002D72), width: 2),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Vui lòng nhập số lượng ghế';
                              }
                              final seats = int.tryParse(value);
                              if (seats == null) {
                                return 'Số lượng ghế không hợp lệ';
                              }
                              if (seats <= 0) {
                                return 'Số lượng ghế phải lớn hơn 0';
                              }
                              if (seats > 4) {
                                return 'Số lượng ghế tối đa là 4';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red.shade900),
                      ),
                    ),
                  
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF002D72),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                              SizedBox(width: 10),
                              Text('Đang tạo chuyến đi...'),
                            ],
                          )
                        : const Text(
                            'Đăng chuyến +',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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