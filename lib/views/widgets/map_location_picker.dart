import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../services/location_service.dart';

class MapLocationPicker extends StatefulWidget {
  final String title;
  final String hintText;
  final Function(String) onLocationSelected;
  final LatLng? initialLocation;

  const MapLocationPicker({
    super.key,
    required this.title,
    required this.hintText,
    required this.onLocationSelected,
    this.initialLocation,
  });

  @override
  State<MapLocationPicker> createState() => _MapLocationPickerState();
}

class _MapLocationPickerState extends State<MapLocationPicker> {
  final LocationService _locationService = LocationService();
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  LatLng? _selectedLocation;
  LatLng? _currentLocation;
  bool _isLoadingLocation = false;
  String _selectedAddress = '';
  String? _selectedWard;
  String? _selectedDistrict;
  String? _selectedProvince;

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation;
    _loadCurrentLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      final currentLatLng = await _locationService.getCurrentLatLng();
      setState(() {
        _currentLocation = currentLatLng;
        if (_selectedLocation == null) {
          _selectedLocation = currentLatLng;
          _mapController.move(currentLatLng, 15.0);
        }
      });
      await _updateAddressFromCoordinates(currentLatLng);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể lấy vị trí hiện tại: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  Future<void> _updateAddressFromCoordinates(LatLng location) async {
    try {
      final address = await _locationService.getFormattedAddress(
        location.latitude,
        location.longitude,
      );

      // Parse address to extract ward, district, province
      final addressComponents = _parseAddressComponents(address);

      setState(() {
        _selectedAddress = address;
        _selectedWard = addressComponents['ward'];
        _selectedDistrict = addressComponents['district'];
        _selectedProvince = addressComponents['province'];
        _searchController.text = address;
      });
    } catch (e) {
      setState(() {
        _selectedAddress = 'Không thể xác định địa chỉ';
        _selectedWard = null;
        _selectedDistrict = null;
        _selectedProvince = null;
      });
    }
  }

  Map<String, String?> _parseAddressComponents(String fullAddress) {
    // Simple parsing logic for Vietnamese addresses
    // This is a basic implementation - you might want to use a more sophisticated geocoding service
    final address = fullAddress.toLowerCase();

    // Common Vietnamese administrative divisions
    final wards = ['phường', 'xã', 'thị trấn'];
    final districts = ['quận', 'huyện', 'thị xã', 'thành phố'];
    final provinces = [
      'an giang',
      'bà rịa - vũng tàu',
      'bắc giang',
      'bắc kạn',
      'bạc liêu',
      'bắc ninh',
      'bến tre',
      'bình định',
      'bình dương',
      'bình phước',
      'bình thuận',
      'cà mau',
      'cần thơ',
      'cao bằng',
      'đà nẵng',
      'đắk lắk',
      'đắk nông',
      'điện biên',
      'đồng nai',
      'đồng tháp',
      'gia lai',
      'hà giang',
      'hà nam',
      'hà nội',
      'hà tĩnh',
      'hải dương',
      'hải phòng',
      'hậu giang',
      'hòa bình',
      'hưng yên',
      'khánh hòa',
      'kiên giang',
      'kon tum',
      'lai châu',
      'lâm đồng',
      'lạng sơn',
      'lào cai',
      'long an',
      'nam định',
      'nghệ an',
      'ninh bình',
      'ninh thuận',
      'phú thọ',
      'phú yên',
      'quảng bình',
      'quảng nam',
      'quảng ngãi',
      'quảng ninh',
      'quảng trị',
      'sóc trăng',
      'sơn la',
      'tây ninh',
      'thái bình',
      'thái nguyên',
      'thanh hóa',
      'thừa thiên huế',
      'tiền giang',
      'tp hồ chí minh',
      'trà vinh',
      'tuyên quang',
      'vĩnh long',
      'vĩnh phúc',
      'yên bái',
    ];

    String? ward, district, province;

    // Extract province (usually at the end)
    for (final prov in provinces) {
      if (address.contains(prov)) {
        province = prov;
        break;
      }
    }

    // Extract district
    for (final dist in districts) {
      final index = address.indexOf(dist);
      if (index != -1) {
        final start = index + dist.length + 1;
        final end = address.indexOf(',', start);
        if (end != -1) {
          district = address.substring(start, end).trim();
        }
        break;
      }
    }

    // Extract ward
    for (final w in wards) {
      final index = address.indexOf(w);
      if (index != -1) {
        final start = index + w.length + 1;
        final end = address.indexOf(',', start);
        if (end != -1) {
          ward = address.substring(start, end).trim();
        }
        break;
      }
    }

    return {'ward': ward, 'district': district, 'province': province};
  }

  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) return;

    try {
      final locations = await _locationService.getCoordinatesFromAddress(query);
      if (locations.isNotEmpty) {
        final location = locations.first;
        final latLng = LatLng(location.latitude, location.longitude);
        setState(() {
          _selectedLocation = latLng;
        });
        _mapController.move(latLng, 15.0);
        await _updateAddressFromCoordinates(latLng);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không tìm thấy địa điểm')),
        );
      }
    }
  }

  void _onMapTap(TapPosition tapPosition, LatLng latLng) async {
    setState(() {
      _selectedLocation = latLng;
    });
    await _updateAddressFromCoordinates(latLng);
  }

  void _confirmLocation() {
    if (_selectedAddress.isNotEmpty) {
      Navigator.of(context).pop<Map<String, dynamic>>({
        'address': _selectedAddress,
        'latLng': _selectedLocation,
        'ward': _selectedWard,
        'district': _selectedDistrict,
        'province': _selectedProvince,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: const Color(0xFF00AEEF),
        actions: [
          TextButton(
            onPressed: _confirmLocation,
            child: const Text(
              'Xác nhận',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: widget.hintText,
                prefixIcon: const Icon(Icons.search),
                suffixIcon:
                    _isLoadingLocation
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : IconButton(
                          icon: const Icon(Icons.my_location),
                          onPressed: _loadCurrentLocation,
                        ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onSubmitted: _searchLocation,
            ),
          ),

          // Map
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                center:
                    _selectedLocation ??
                    const LatLng(21.0285, 105.8542), // Hanoi center
                zoom: 13.0,
                onTap: _onMapTap,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.sharexe.app',
                ),
                // Current location marker
                if (_currentLocation != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _currentLocation!,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.7),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.my_location,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                // Selected location marker
                if (_selectedLocation != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _selectedLocation!,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.8),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // Address display
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Địa điểm đã chọn:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00AEEF),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _selectedAddress.isNotEmpty
                      ? _selectedAddress
                      : 'Chưa chọn địa điểm',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
