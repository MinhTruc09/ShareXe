import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
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
      setState(() {
        _selectedAddress = address;
        _searchController.text = address;
      });
    } catch (e) {
      setState(() {
        _selectedAddress = 'Không thể xác định địa chỉ';
      });
    }
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
