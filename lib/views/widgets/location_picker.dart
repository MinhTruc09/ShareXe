import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'map_location_picker.dart';
import 'package:latlong2/latlong.dart';
import '../../services/location_service.dart';

// Data class for location information
class LocationData {
  final String address;
  final LatLng? latLng;
  final String? ward;
  final String? district;
  final String? province;

  const LocationData({
    required this.address,
    this.latLng,
    this.ward,
    this.district,
    this.province,
  });
}

class LocationPicker extends StatefulWidget {
  final String title;
  final IconData icon;
  final String hintText;
  final Function(LocationData) onLocationSelected;
  final String? initialValue;
  final VoidCallback? onUseCurrentLocation;

  const LocationPicker({
    Key? key,
    required this.title,
    required this.icon,
    required this.hintText,
    required this.onLocationSelected,
    this.initialValue,
    this.onUseCurrentLocation,
  }) : super(key: key);

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final LocationService _locationService = LocationService();

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null && widget.initialValue!.isNotEmpty) {
      _controller.text = widget.initialValue!;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _selectLocation(String location) async {
    _controller.text = location;
    
    // Lấy tọa độ từ địa chỉ
    final latLng = await _locationService.getLocationFromAddress(location);
    
    widget.onLocationSelected(LocationData(
      address: location,
      latLng: latLng,
    ));
    
    FocusScope.of(context).unfocus();
  }


  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(widget.icon, color: Colors.grey, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: TypeAheadField<String>(
                controller: _controller,
                focusNode: _focusNode,
                builder: (context, controller, focusNode) {
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    style: const TextStyle(color: Colors.black87, fontSize: 16),
                    decoration: InputDecoration(
                      hintText: widget.hintText,
                      hintStyle: const TextStyle(color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  );
                },
                suggestionsCallback: (pattern) async {
                  if (pattern.length < 2) return [];
                  return await _locationService.searchPlaces(pattern);
                },
                itemBuilder: (context, suggestion) {
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.location_on, size: 20, color: Colors.grey),
                    title: Text(
                      suggestion,
                      style: const TextStyle(fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                },
                onSelected: (suggestion) {
                  _selectLocation(suggestion);
                },
                emptyBuilder: (context) => const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Không tìm thấy địa điểm nào',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                loadingBuilder: (context) => const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
                errorBuilder: (context, error) => const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Lỗi khi tìm kiếm địa điểm',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ),
            ),
            if (widget.onUseCurrentLocation != null)
              IconButton(
                icon: const Icon(
                  Icons.gps_fixed,
                  color: Color(0xFF00AEEF),
                  size: 20,
                ),
                onPressed: widget.onUseCurrentLocation,
                tooltip: 'Sử dụng vị trí hiện tại',
              ),
            IconButton(
              icon: const Icon(Icons.map, color: Color(0xFF00AEEF), size: 20),
              onPressed: () async {
                final result = await Navigator.of(
                  context,
                ).push<Map<String, dynamic>>(
                  MaterialPageRoute(
                    builder:
                        (context) => MapLocationPicker(
                          title: 'Chọn vị trí',
                          hintText: 'Tìm kiếm địa điểm',
                          onLocationSelected: (location) {},
                          initialLocation: null,
                        ),
                  ),
                );
                if (result != null) {
                  final address = result['address'] as String;
                  final latLng = result['latLng'] as LatLng?;
                  _controller.text = address;
                  widget.onLocationSelected(
                    LocationData(address: address, latLng: latLng),
                  );
                  FocusScope.of(context).unfocus();
                }
              },
              tooltip: 'Chọn trên bản đồ',
            ),
          ],
        ),
      ],
    );
  }
}
