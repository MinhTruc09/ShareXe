import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/ride_service.dart';
import '../../../services/profile_service.dart';
import '../../../services/route_service.dart';
import '../../../models/user_profile.dart';
import '../../widgets/location_picker.dart';
import '../../widgets/date_picker.dart';
import '../../widgets/passenger_counter.dart';
import '../../widgets/sharexe_background2.dart';
import '../../../utils/app_config.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';

class CreateRideScreen extends StatefulWidget {
  final Map<String, dynamic>?
  existingRide; // null nếu tạo mới, có giá trị nếu cập nhật

  const CreateRideScreen({Key? key, this.existingRide}) : super(key: key);

  @override
  State<CreateRideScreen> createState() => _CreateRideScreenState();
}

class _CreateRideScreenState extends State<CreateRideScreen> {
  final RideService _rideService = RideService();
  final ProfileService _profileService = ProfileService();
  final _formKey = GlobalKey<FormState>();

  LocationData? _departure;
  LocationData? _destination;
  DateTime? _departureDate;
  int _totalSeats = 4;
  double _pricePerSeat = 0;
  bool _isSubmitting = false;
  bool _isEditMode = false;
  bool _isLoading = true;
  bool _isDriverApproved = false;
  bool _isCalculatingRoute = false;
  String? _driverStatus;
  int? _rideId;

  final TextEditingController _priceController = TextEditingController();

  // Additional detailed location fields for departure
  String? _departureWard;
  String? _departureDistrict;
  String? _departureProvince;
  double? _departureLat;
  double? _departureLng;

  // Additional detailed location fields for destination
  String? _destinationWard;
  String? _destinationDistrict;
  String? _destinationProvince;
  double? _destinationLat;
  double? _destinationLng;

  // Route polyline data
  List<LatLng> _polylinePoints = [];
  double _routeDistance = 0.0;
  int _routeDuration = 0;

  // Driver information (removed as not needed for API)

  @override
  void initState() {
    super.initState();
    _checkDriverStatus();

    // Nếu có existingRide thì đây là chế độ cập nhật
    if (widget.existingRide != null) {
      _isEditMode = true;
      _loadExistingRideData();

      // Kiểm tra trạng thái của chuyến đi
      if (widget.existingRide?['status']?.toString().toUpperCase() ==
          'CANCELLED') {
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

  Future<void> _checkDriverStatus() async {
    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
        });
      }

      final response = await _profileService.getUserProfile();

      if (mounted) {
        setState(() {
          _isLoading = false;

          if (response.success && response.data != null) {
            final UserProfile userProfile = response.data!;
            _driverStatus = userProfile.status;
            _isDriverApproved = userProfile.status == 'APPROVED';

            // Lưu thông tin tài xế để gửi API
            // Driver info loaded successfully

            // Nếu không phải là chế độ chỉnh sửa chuyến và tài xế chưa được duyệt,
            // hiển thị thông báo
            if (!_isEditMode && !_isDriverApproved) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _showDriverNotApprovedDialog();
              });
            }
          } else {
            // Nếu không lấy được thông tin hồ sơ, giả định tài xế chưa được duyệt
            _isDriverApproved = false;
            _driverStatus = 'UNKNOWN';

            if (!_isEditMode) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _showDriverNotApprovedDialog();
              });
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isDriverApproved = false;
          _driverStatus = 'ERROR';
        });
      }

      if (!_isEditMode) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showDriverNotApprovedDialog();
        });
      }
    }
  }

  void _showDriverNotApprovedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                _driverStatus == 'PENDING'
                    ? Icons.hourglass_top
                    : Icons.error_outline,
                color: _driverStatus == 'PENDING' ? Colors.orange : Colors.red,
              ),
              const SizedBox(width: 8),
              Text(
                _driverStatus == 'PENDING'
                    ? 'Đang chờ phê duyệt'
                    : 'Chưa được phê duyệt',
                style: TextStyle(
                  color:
                      _driverStatus == 'PENDING'
                          ? Colors.orange[700]
                          : Colors.red[700],
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _driverStatus == 'PENDING'
                    ? 'Tài khoản tài xế của bạn đang trong quá trình xét duyệt. Vui lòng đợi phê duyệt trước khi tạo chuyến đi.'
                    : 'Tài khoản của bạn chưa được duyệt. Vui lòng kiểm tra thông báo và cập nhật hồ sơ trước khi tạo chuyến đi.',
                style: const TextStyle(fontSize: 14),
              ),
            ],
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
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  void _loadExistingRideData() {
    final ride = widget.existingRide!;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _rideId = ride['id'];

        _departure = LocationData(
          address: ride['departure'] ?? '',
          ward: ride['startWard'],
          district: ride['startDistrict'],
          province: ride['startProvince'],
          latLng:
              (ride['startLat'] != null && ride['startLng'] != null)
                  ? LatLng(ride['startLat'], ride['startLng'])
                  : null,
        );

        _destination = LocationData(
          address: ride['destination'] ?? '',
          ward: ride['endWard'],
          district: ride['endDistrict'],
          province: ride['endProvince'],
          latLng:
              (ride['endLat'] != null && ride['endLng'] != null)
                  ? LatLng(ride['endLat'], ride['endLng'])
                  : null,
        );

        _departureWard = ride['startWard'];
        _departureDistrict = ride['startDistrict'];
        _departureProvince = ride['startProvince'];
        _departureLat =
            ride['startLat'] != null ? ride['startLat'].toDouble() : null;
        _departureLng =
            ride['startLng'] != null ? ride['startLng'].toDouble() : null;

        _destinationWard = ride['endWard'];
        _destinationDistrict = ride['endDistrict'];
        _destinationProvince = ride['endProvince'];
        _destinationLat =
            ride['endLat'] != null ? ride['endLat'].toDouble() : null;
        _destinationLng =
            ride['endLng'] != null ? ride['endLng'].toDouble() : null;

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
      });
    });
  }

  // Hàm tự động tạo polyline giữa điểm đi và điểm đến sử dụng RouteService
  Future<void> _generatePolyline() async {
    print('_generatePolyline called - departure: $_departureLat, $_departureLng, destination: $_destinationLat, $_destinationLng');
    
    if (_departureLat != null && _departureLng != null && 
        _destinationLat != null && _destinationLng != null) {
      
      print('Starting route calculation...');
      setState(() {
        _isCalculatingRoute = true;
      });

      try {
        final routeService = RouteService();
        final routeData = await routeService.calculateRoute(
          LatLng(_departureLat!, _departureLng!),
          LatLng(_destinationLat!, _destinationLng!),
        );

        if (routeData != null) {
          print('Route calculated successfully: ${routeData.points.length} points, ${routeData.distance}km, ${routeData.duration}min');
          setState(() {
            _polylinePoints = routeData.points;
            _routeDistance = routeData.distance;
            _routeDuration = routeData.duration.round();
          });
        } else {
          print('Route calculation failed, using fallback');
          // Fallback: tạo polyline đơn giản nếu không tính được route
          setState(() {
            _polylinePoints = [
              LatLng(_departureLat!, _departureLng!),
              LatLng(_destinationLat!, _destinationLng!),
            ];
          });
        }
      } catch (e) {
        print('Error calculating route: $e');
        // Fallback: tạo polyline đơn giản
        setState(() {
          _polylinePoints = [
            LatLng(_departureLat!, _departureLng!),
            LatLng(_destinationLat!, _destinationLng!),
          ];
        });
      } finally {
        setState(() {
          _isCalculatingRoute = false;
        });
        print('Route calculation completed. Polyline points: ${_polylinePoints.length}');
      }
    } else {
      print('Missing coordinates - cannot generate polyline');
    }
  }


  Future<void> _submitRide() async {
    // Chỉ cho phép chỉnh sửa nếu trạng thái chuyến đi là ACTIVE
    if (_isEditMode && widget.existingRide != null) {
      final rideStatus =
          widget.existingRide?['status']?.toString().toUpperCase();
      if (rideStatus != AppConfig.RIDE_STATUS_ACTIVE) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Chỉ có thể chỉnh sửa chuyến đi khi trạng thái là "Đang mở" (ACTIVE)',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    // Kiểm tra trạng thái tài xế trước khi tạo chuyến mới
    if (!_isEditMode && !_isDriverApproved) {
      _showDriverNotApprovedDialog();
      return;
    }

    if (_formKey.currentState?.validate() != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng điền đầy đủ thông tin')),
      );
      return;
    }

    if (_departure == null || _destination == null || _departureDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng điền đầy đủ thông tin chuyến đi'),
        ),
      );
      return;
    }

    // Kiểm tra tọa độ trước khi gửi
    if (_departureLat == null || _departureLng == null || 
        _destinationLat == null || _destinationLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn địa điểm trên bản đồ để có tọa độ chính xác'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Kiểm tra trạng thái của chuyến đi nếu đang ở chế độ chỉnh sửa
    if (_isEditMode && widget.existingRide != null) {
      final rideStatus =
          widget.existingRide?['status']?.toString().toUpperCase();

      // Danh sách các trạng thái không được phép chỉnh sửa
      final List<String> nonEditableStatuses = [
        AppConfig.RIDE_STATUS_DRIVER_CONFIRMED,
        AppConfig.RIDE_STATUS_COMPLETED,
        AppConfig.RIDE_STATUS_CANCELLED,
        'IN_PROGRESS',
        'PASSENGER_CONFIRMED',
      ];

      // Kiểm tra nếu trạng thái của chuyến đi không cho phép chỉnh sửa
      if (nonEditableStatuses.contains(rideStatus)) {
        String statusMessage =
            'Không thể chỉnh sửa chuyến đi trong trạng thái hiện tại';

        if (rideStatus == AppConfig.RIDE_STATUS_CANCELLED) {
          statusMessage = 'Không thể chỉnh sửa chuyến đi đã hủy';
        } else if (rideStatus == AppConfig.RIDE_STATUS_COMPLETED) {
          statusMessage = 'Không thể chỉnh sửa chuyến đi đã hoàn thành';
        } else if (rideStatus == AppConfig.RIDE_STATUS_DRIVER_CONFIRMED) {
          statusMessage =
              'Không thể chỉnh sửa chuyến đi đã xác nhận hoàn thành';
        } else if (rideStatus == 'IN_PROGRESS') {
          statusMessage = 'Không thể chỉnh sửa chuyến đi đang diễn ra';
        } else if (rideStatus == 'PASSENGER_CONFIRMED') {
          statusMessage =
              'Không thể chỉnh sửa chuyến đi đã được hành khách xác nhận';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(statusMessage), backgroundColor: Colors.red),
        );
        return;
      }

      // Kiểm tra thời gian bắt đầu
      if (widget.existingRide?['startTime'] != null) {
        try {
          final DateTime startTime = DateTime.parse(
            widget.existingRide!['startTime'],
          );
          final DateTime now = DateTime.now();

          // Không cho phép chỉnh sửa nếu chuyến đi sắp bắt đầu trong vòng 30 phút
          if (now.isAfter(startTime.subtract(const Duration(minutes: 30)))) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Không thể chỉnh sửa chuyến đi đã hoặc sắp diễn ra (trong vòng 30 phút)',
                ),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }
        } catch (e) {
          print('Lỗi khi kiểm tra thời gian: $e');
        }
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


      // Chuẩn bị dữ liệu chuyến đi theo API specification
      final rideData = {
        'departure': _departure!.address,
        'startLat': _departureLat!,
        'startLng': _departureLng!,
        'startAddress': _departure!.address,
        'startWard': _departureWard ?? '',
        'startDistrict': _departureDistrict ?? '',
        'startProvince': _departureProvince ?? '',
        'endLat': _destinationLat!,
        'endLng': _destinationLng!,
        'endAddress': _destination!.address,
        'endWard': _destinationWard ?? '',
        'endDistrict': _destinationDistrict ?? '',
        'endProvince': _destinationProvince ?? '',
        'destination': _destination!.address,
        'startTime': _departureDate!.toIso8601String().split('.')[0], // Format: yyyy-MM-ddTHH:mm:ss
        'pricePerSeat': _pricePerSeat,
        'totalSeat': _totalSeats,
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
                  Text(
                    'Đang xử lý, vui lòng đợi...',
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
              title: Text(
                _isEditMode
                    ? 'Cập nhật thành công'
                    : 'Tạo chuyến đi thành công',
              ),
              content: Text(
                _isEditMode
                    ? 'Thông tin chuyến đi đã được cập nhật.'
                    : 'Chuyến đi mới đã được tạo thành công và đã có trong danh sách chuyến đi của bạn.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Đóng dialog
                    Navigator.of(context).pop(
                      true,
                    ); // Quay lại màn hình trước với kết quả thành công
                  },
                  child: Text('OK'),
                ),
              ],
            );
          },
        );
      } else {
        // Kiểm tra lại trạng thái tài xế để hiển thị thông báo phù hợp
        if (!_isEditMode) {
          try {
            final response = await _profileService.getUserProfile();
            if (response.success && response.data != null) {
              final UserProfile userProfile = response.data!;
              if (userProfile.status != 'APPROVED') {
                // Hiển thị thông báo tài xế chưa được duyệt
                _showDriverNotApprovedDialog();
                return;
              }
            }
          } catch (e) {
            print('Lỗi khi kiểm tra lại trạng thái tài xế: $e');
          }
        }

        // Hiển thị thông báo lỗi mặc định
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditMode
                  ? 'Không thể cập nhật chuyến đi. Vui lòng kiểm tra kết nối mạng và thử lại.'
                  : 'Không thể tạo chuyến đi. Vui lòng kiểm tra kết nối mạng và thử lại.',
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
            action: SnackBarAction(label: 'Thử lại', onPressed: _submitRide),
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

      // Kiểm tra lỗi để hiển thị thông báo phù hợp
      if (e.toString().contains('permission') ||
          e.toString().contains('unauthorized') ||
          e.toString().contains('approved')) {
        // Hiển thị thông báo tài xế chưa được duyệt
        _showDriverNotApprovedDialog();
      } else {
        // Hiển thị thông báo lỗi chung
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã xảy ra lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SharexeBackground2(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: const Color(0xFF002D72),
          title: const Text('Tạo chuyến đi mới'),
        ),
        body:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Form(
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
                                  initialValue: _departure?.address ?? '',
                                  onLocationSelected: (location) async {
                                    setState(() {
                                      _departure = location;
                                      _departureWard = location.ward;
                                      _departureDistrict = location.district;
                                      _departureProvince = location.province;
                                      _departureLat = location.latLng?.latitude;
                                      _departureLng = location.latLng?.longitude;
                                    });
                                    
                                    // Tự động tạo polyline nếu có cả điểm đi và điểm đến
                                    if (_departureLat != null && _departureLng != null && 
                                        _destinationLat != null && _destinationLng != null) {
                                      await _generatePolyline();
                                    }
                                  },
                                ),
                                // Hiển thị địa chỉ chi tiết điểm đi
                                if (_departure != null && _departure!.address.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.blue.shade200),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(Icons.location_on, color: Colors.blue.shade700, size: 16),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Địa chỉ chi tiết:',
                                              style: TextStyle(
                                                color: Colors.blue.shade700,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${_departure!.address}${_departureWard != null ? ', $_departureWard' : ''}${_departureDistrict != null ? ', $_departureDistrict' : ''}${_departureProvince != null ? ', $_departureProvince' : ''}',
                                          style: TextStyle(
                                            color: Colors.blue.shade600,
                                            fontSize: 11,
                                          ),
                                        ),
                                        if (_departureLat != null && _departureLng != null)
                                          Text(
                                            'Tọa độ: ${_departureLat!.toStringAsFixed(6)}, ${_departureLng!.toStringAsFixed(6)}',
                                            style: TextStyle(
                                              color: Colors.blue.shade500,
                                              fontSize: 10,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                                const Divider(height: 16),
                                LocationPicker(
                                  title: 'Điểm đến',
                                  icon: Icons.location_on_outlined,
                                  hintText: 'Điểm đến',
                                  initialValue: _destination?.address ?? '',
                                  onLocationSelected: (location) async {
                                    setState(() {
                                      _destination = location;
                                      _destinationWard = location.ward;
                                      _destinationDistrict = location.district;
                                      _destinationProvince = location.province;
                                      _destinationLat = location.latLng?.latitude;
                                      _destinationLng = location.latLng?.longitude;
                                    });
                                    
                                    // Tự động tạo polyline nếu có cả điểm đi và điểm đến
                                    if (_departureLat != null && _departureLng != null && 
                                        _destinationLat != null && _destinationLng != null) {
                                      await _generatePolyline();
                                    }
                                  },
                                ),
                                // Hiển thị địa chỉ chi tiết điểm đến
                                if (_destination != null && _destination!.address.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.green.shade200),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(Icons.location_on, color: Colors.green.shade700, size: 16),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Địa chỉ chi tiết:',
                                              style: TextStyle(
                                                color: Colors.green.shade700,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${_destination!.address}${_destinationWard != null ? ', $_destinationWard' : ''}${_destinationDistrict != null ? ', $_destinationDistrict' : ''}${_destinationProvince != null ? ', $_destinationProvince' : ''}',
                                          style: TextStyle(
                                            color: Colors.green.shade600,
                                            fontSize: 11,
                                          ),
                                        ),
                                        if (_destinationLat != null && _destinationLng != null)
                                          Text(
                                            'Tọa độ: ${_destinationLat!.toStringAsFixed(6)}, ${_destinationLng!.toStringAsFixed(6)}',
                                            style: TextStyle(
                                              color: Colors.green.shade500,
                                              fontSize: 10,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                                const Divider(height: 16),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.blue.shade200),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.info_outline, color: Colors.blue.shade700, size: 16),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Chọn địa điểm để tự động hiển thị bản đồ với tuyến đường',
                                          style: TextStyle(
                                            color: Colors.blue.shade700,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Hiển thị bản đồ với polyline tự động
                                if (_departureLat != null && _departureLng != null) ...[
                                  const SizedBox(height: 16),
                                  Container(
                                    height: 200,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.grey.shade300),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Stack(
                                        children: [
                                          // Bản đồ với polyline
                                          if (_departureLat != null && _departureLng != null)
                                            Stack(
                                              children: [
                                                FlutterMap(
                                                  options: MapOptions(
                                                    initialCenter: _destinationLat != null && _destinationLng != null
                                                        ? LatLng(
                                                            (_departureLat! + _destinationLat!) / 2,
                                                            (_departureLng! + _destinationLng!) / 2,
                                                          )
                                                        : LatLng(_departureLat!, _departureLng!),
                                                    initialZoom: _destinationLat != null && _destinationLng != null ? 12.0 : 13.0,
                                                    minZoom: 5.0,
                                                    maxZoom: 18.0,
                                                  ),
                                                  children: [
                                                    TileLayer(
                                                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                                      userAgentPackageName: 'com.sharexe.app',
                                                    ),
                                                    // Polyline layer cho route
                                                    if (_polylinePoints.isNotEmpty)
                                                      PolylineLayer(
                                                        polylines: [
                                                          Polyline(
                                                            points: _polylinePoints,
                                                            strokeWidth: 4.0,
                                                            color: const Color(0xFF00AEEF),
                                                          ),
                                                        ],
                                                      ),
                                                    // Marker layer
                                                    MarkerLayer(
                                                      markers: [
                                                        // Marker điểm đi
                                                        Marker(
                                                          point: LatLng(_departureLat!, _departureLng!),
                                                          width: 40,
                                                          height: 40,
                                                          child: Container(
                                                            decoration: BoxDecoration(
                                                              color: const Color(0xFF00AEEF),
                                                              shape: BoxShape.circle,
                                                              border: Border.all(color: Colors.white, width: 3),
                                                              boxShadow: [
                                                                BoxShadow(
                                                                  color: Colors.black.withOpacity(0.3),
                                                                  blurRadius: 4,
                                                                  offset: const Offset(0, 2),
                                                                ),
                                                              ],
                                                            ),
                                                            child: const Center(
                                                              child: Text(
                                                                'A',
                                                                style: TextStyle(
                                                                  color: Colors.white,
                                                                  fontWeight: FontWeight.bold,
                                                                  fontSize: 16,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                        // Marker điểm đến nếu có
                                                        if (_destinationLat != null && _destinationLng != null)
                                                          Marker(
                                                            point: LatLng(_destinationLat!, _destinationLng!),
                                                            width: 40,
                                                            height: 40,
                                                            child: Container(
                                                              decoration: BoxDecoration(
                                                                color: const Color(0xFF4CAF50),
                                                                shape: BoxShape.circle,
                                                                border: Border.all(color: Colors.white, width: 3),
                                                                boxShadow: [
                                                                  BoxShadow(
                                                                    color: Colors.black.withOpacity(0.3),
                                                                    blurRadius: 4,
                                                                    offset: const Offset(0, 2),
                                                                  ),
                                                                ],
                                                              ),
                                                              child: const Center(
                                                                child: Text(
                                                                  'B',
                                                                  style: TextStyle(
                                                                    color: Colors.white,
                                                                    fontWeight: FontWeight.bold,
                                                                    fontSize: 16,
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                                // Placeholder khi chưa có polyline
                                                if (_polylinePoints.isEmpty && !_isCalculatingRoute)
                                                  Container(
                                                    width: double.infinity,
                                                    height: double.infinity,
                                                    color: Colors.grey.shade100,
                                                    child: const Center(
                                                      child: Column(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          Icon(
                                                            Icons.map_outlined,
                                                            size: 48,
                                                            color: Colors.grey,
                                                          ),
                                                          SizedBox(height: 16),
                                                          Text(
                                                            'Đang tải bản đồ...',
                                                            style: TextStyle(
                                                              color: Colors.grey,
                                                              fontSize: 16,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                // Loading indicator khi đang tính route
                                                if (_isCalculatingRoute)
                                                  Container(
                                                    width: double.infinity,
                                                    height: double.infinity,
                                                    color: Colors.black.withOpacity(0.3),
                                                    child: const Center(
                                                      child: Column(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          CircularProgressIndicator(
                                                            color: Colors.white,
                                                          ),
                                                          SizedBox(height: 16),
                                                          Text(
                                                            'Đang tính toán đường đi...',
                                                            style: TextStyle(
                                                              color: Colors.white,
                                                              fontSize: 16,
                                                              fontWeight: FontWeight.w500,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                // Thông tin route
                                                if (_polylinePoints.isNotEmpty && !_isCalculatingRoute && _routeDistance > 0)
                                                  Positioned(
                                                    top: 16,
                                                    left: 16,
                                                    right: 16,
                                                    child: Container(
                                                      padding: const EdgeInsets.all(12),
                                                      decoration: BoxDecoration(
                                                        color: Colors.white,
                                                        borderRadius: BorderRadius.circular(8),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: Colors.black.withOpacity(0.1),
                                                            blurRadius: 4,
                                                            offset: const Offset(0, 2),
                                                          ),
                                                        ],
                                                      ),
                                                      child: Row(
                                                        children: [
                                                          const Icon(
                                                            Icons.route,
                                                            color: Color(0xFF00AEEF),
                                                            size: 20,
                                                          ),
                                                          const SizedBox(width: 8),
                                                          Expanded(
                                                            child: Column(
                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                              children: [
                                                                Text(
                                                                  'Khoảng cách: ${_routeDistance.toStringAsFixed(1)} km',
                                                                  style: const TextStyle(
                                                                    fontSize: 14,
                                                                    fontWeight: FontWeight.w500,
                                                                  ),
                                                                ),
                                                                Text(
                                                                  'Thời gian: ${_routeDuration} phút',
                                                                  style: const TextStyle(
                                                                    fontSize: 12,
                                                                    color: Colors.grey,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          // Overlay thông tin
                                          Positioned(
                                            top: 8,
                                            left: 8,
                                            right: 8,
                                            child: Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(0.9),
                                                borderRadius: BorderRadius.circular(8),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withOpacity(0.1),
                                                    blurRadius: 4,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons.route,
                                                        color: Colors.blue.shade700,
                                                        size: 16,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        'Tuyến đường đã chọn',
                                                        style: TextStyle(
                                                          color: Colors.blue.shade700,
                                                          fontWeight: FontWeight.w600,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  if (_departure != null && _destination != null) ...[
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      'Từ: ${_departure!.address}',
                                                      style: TextStyle(
                                                        color: Colors.blue.shade600,
                                                        fontSize: 10,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                    Text(
                                                      'Đến: ${_destination!.address}',
                                                      style: TextStyle(
                                                        color: Colors.green.shade600,
                                                        fontSize: 10,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                                const Divider(height: 16),
                                DatePickerField(
                                  icon: Icons.access_time,
                                  hintText: 'Thời gian xuất phát (ngày và giờ)',
                                  initialDate: _departureDate,
                                  includeTime: true,
                                  onDateSelected: (date) {
                                    setState(() {
                                      _departureDate = date;
                                      print(
                                        'Đã chọn thời gian: ${DateFormat('dd/MM/yyyy HH:mm').format(date)}',
                                      );
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
                                            _pricePerSeat =
                                                double.tryParse(value) ?? 0;
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
                            onPressed:
                                (_isSubmitting ||
                                        (_isEditMode &&
                                            widget.existingRide != null &&
                                            widget.existingRide?['status']
                                                    ?.toString()
                                                    .toUpperCase() !=
                                                AppConfig.RIDE_STATUS_ACTIVE))
                                    ? null
                                    : _submitRide,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  (_isEditMode &&
                                          widget.existingRide != null &&
                                          widget.existingRide?['status']
                                                  ?.toString()
                                                  .toUpperCase() !=
                                              AppConfig.RIDE_STATUS_ACTIVE)
                                      ? Colors.grey.shade400
                                      : const Color(0xFF002D72),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child:
                                _isSubmitting
                                    ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
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
      ),
    );
  }
}

