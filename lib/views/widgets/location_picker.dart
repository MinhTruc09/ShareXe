import 'package:flutter/material.dart';
import 'map_location_picker.dart';
import 'package:latlong2/latlong.dart';

// Data class for location information
class LocationData {
  final String address;
  final LatLng? latLng;

  const LocationData({required this.address, this.latLng});
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
  final List<String> _locations = [
    'An Giang',
    'Bà Rịa - Vũng Tàu',
    'Bắc Giang',
    'Bắc Kạn',
    'Bạc Liêu',
    'Bắc Ninh',
    'Bến Tre',
    'Bình Định',
    'Bình Dương',
    'Bình Phước',
    'Bình Thuận',
    'Cà Mau',
    'Cần Thơ',
    'Cao Bằng',
    'Đà Nẵng',
    'Đắk Lắk',
    'Đắk Nông',
    'Điện Biên',
    'Đồng Nai',
    'Đồng Tháp',
    'Gia Lai',
    'Hà Giang',
    'Hà Nam',
    'Hà Nội',
    'Hà Tĩnh',
    'Hải Dương',
    'Hải Phòng',
    'Hậu Giang',
    'Hòa Bình',
    'Hưng Yên',
    'Khánh Hòa',
    'Kiên Giang',
    'Kon Tum',
    'Lai Châu',
    'Lâm Đồng',
    'Lạng Sơn',
    'Lào Cai',
    'Long An',
    'Nam Định',
    'Nghệ An',
    'Ninh Bình',
    'Ninh Thuận',
    'Phú Thọ',
    'Phú Yên',
    'Quảng Bình',
    'Quảng Nam',
    'Quảng Ngãi',
    'Quảng Ninh',
    'Quảng Trị',
    'Sóc Trăng',
    'Sơn La',
    'Tây Ninh',
    'Thái Bình',
    'Thái Nguyên',
    'Thanh Hóa',
    'Thừa Thiên Huế',
    'Tiền Giang',
    'TP Hồ Chí Minh',
    'Trà Vinh',
    'Tuyên Quang',
    'Vĩnh Long',
    'Vĩnh Phúc',
    'Yên Bái',
  ];
  List<String> _filteredLocations = [];
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null && widget.initialValue!.isNotEmpty) {
      _controller.text = widget.initialValue!;
    }

    _filteredLocations = _locations;

    _focusNode.addListener(() {
      setState(() {
        _showSuggestions = _focusNode.hasFocus;
      });
    });

    _controller.addListener(() {
      _filterLocations();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _filterLocations() {
    if (_controller.text.isEmpty) {
      setState(() {
        _filteredLocations = _locations;
      });
    } else {
      setState(() {
        _filteredLocations =
            _locations
                .where(
                  (location) => location.toLowerCase().contains(
                    _controller.text.toLowerCase(),
                  ),
                )
                .toList();
      });
    }
  }

  void _selectLocation(String location) {
    _controller.text = location;
    widget.onLocationSelected(LocationData(address: location));
    setState(() {
      _showSuggestions = false;
    });
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
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                style: const TextStyle(color: Colors.black87, fontSize: 16),
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  hintStyle: const TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (value) {
                  _filterLocations();
                },
                onTap: () {
                  setState(() {
                    _showSuggestions = true;
                  });
                },
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
                  setState(() {
                    _showSuggestions = false;
                  });
                  FocusScope.of(context).unfocus();
                }
              },
              tooltip: 'Chọn trên bản đồ',
            ),
          ],
        ),
        if (_showSuggestions && _filteredLocations.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(left: 32),
            height: 200,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _filteredLocations.length,
              itemBuilder: (context, index) {
                return ListTile(
                  dense: true,
                  title: Text(_filteredLocations[index]),
                  onTap: () => _selectLocation(_filteredLocations[index]),
                );
              },
            ),
          ),
      ],
    );
  }
}
