import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import '../../../services/location_service.dart';
import '../../../services/route_service.dart';

class RouteMapPicker extends StatefulWidget {
  final String title;
  final LatLng? initialDeparture;
  final LatLng? initialDestination;
  final Function(
    String departureAddress,
    LatLng departureLatLng,
    String destinationAddress,
    LatLng destinationLatLng,
    List<LatLng> polylinePoints,
  )
  onRouteSelected;

  const RouteMapPicker({
    super.key,
    required this.title,
    required this.onRouteSelected,
    this.initialDeparture,
    this.initialDestination,
  });

  @override
  State<RouteMapPicker> createState() => _RouteMapPickerState();
}

class _RouteMapPickerState extends State<RouteMapPicker> {
  final LocationService _locationService = LocationService();
  final RouteService _routeService = RouteService();
  final MapController _mapController = MapController();
  final TextEditingController _departureController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();

  LatLng? _departureLocation;
  LatLng? _destinationLocation;
  LatLng? _currentLocation;
  bool _isLoadingLocation = false;
  bool _isCalculatingRoute = false;

  String _departureAddress = '';
  String _destinationAddress = '';

  List<LatLng> _polylinePoints = [];
  double _routeDistance = 0.0;
  int _routeDuration = 0;

  @override
  void initState() {
    super.initState();
    _departureLocation = widget.initialDeparture;
    _destinationLocation = widget.initialDestination;
    _loadCurrentLocation();
  }

  @override
  void dispose() {
    _departureController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      final position = await _locationService.getCurrentLocation();
      if (position != null) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
          if (_departureLocation == null) {
            _departureLocation = _currentLocation;
            _getAddressFromLatLng(_departureLocation!, true);
          }
        });
      }
    } catch (e) {
      print('Error getting current location: $e');
    } finally {
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  Future<void> _getAddressFromLatLng(LatLng latLng, bool isDeparture) async {
    try {
      final address = await _locationService.getAddressFromLatLng(latLng);
      if (isDeparture) {
        setState(() {
          _departureAddress = address;
          _departureController.text = address;
        });
      } else {
        setState(() {
          _destinationAddress = address;
          _destinationController.text = address;
        });
      }
    } catch (e) {
      print('Error getting address: $e');
    }
  }

  Future<void> _searchLocation(String query, bool isDeparture) async {
    if (query.isEmpty) return;

    try {
      final location = await _locationService.getLocationFromAddress(query);
      if (location != null) {
        setState(() {
          if (isDeparture) {
            _departureLocation = location;
            _departureAddress = query;
            _departureController.text = query;
          } else {
            _destinationLocation = location;
            _destinationAddress = query;
            _destinationController.text = query;
          }
        });

        // Calculate route if both locations are selected
        if (_departureLocation != null && _destinationLocation != null) {
          await _calculateRoute();
        }
      }
    } catch (e) {
      print('Error searching location: $e');
    }
  }

  Future<void> _calculateRoute() async {
    if (_departureLocation == null || _destinationLocation == null) return;

    setState(() {
      _isCalculatingRoute = true;
    });

    try {
      final routeData = await _routeService.calculateRoute(
        _departureLocation!,
        _destinationLocation!,
      );

      if (routeData != null) {
        setState(() {
          _polylinePoints = routeData.points;
          _routeDistance = routeData.distance;
          _routeDuration = routeData.duration.round();
        });

        // Fit map to show the entire route
        if (_polylinePoints.isNotEmpty) {
          final bounds = LatLngBounds.fromPoints(_polylinePoints);
          _mapController.fitCamera(
            CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)),
          );
        }
      }
    } catch (e) {
      print('Error calculating route: $e');
    } finally {
      setState(() {
        _isCalculatingRoute = false;
      });
    }
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    // Determine which location to update based on which is closer
    if (_departureLocation == null || _destinationLocation == null) {
      if (_departureLocation == null) {
        setState(() {
          _departureLocation = point;
        });
        _getAddressFromLatLng(point, true);
      } else {
        setState(() {
          _destinationLocation = point;
        });
        _getAddressFromLatLng(point, false);
        _calculateRoute();
      }
    } else {
      // If both are set, update the closer one
      final distanceToDeparture = Distance().as(
        LengthUnit.Meter,
        _departureLocation!,
        point,
      );
      final distanceToDestination = Distance().as(
        LengthUnit.Meter,
        _destinationLocation!,
        point,
      );

      if (distanceToDeparture < distanceToDestination) {
        setState(() {
          _departureLocation = point;
        });
        _getAddressFromLatLng(point, true);
      } else {
        setState(() {
          _destinationLocation = point;
        });
        _getAddressFromLatLng(point, false);
      }
      _calculateRoute();
    }
  }

  void _confirmRoute() {
    if (_departureLocation != null && _destinationLocation != null) {
      widget.onRouteSelected(
        _departureAddress,
        _departureLocation!,
        _destinationAddress,
        _destinationLocation!,
        _polylinePoints,
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: const Color(0xFF00AEEF),
        actions: [
          if (_departureLocation != null && _destinationLocation != null)
            TextButton(
              onPressed: _confirmRoute,
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
          // Search bars
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                // Departure search
                TypeAheadField<String>(
                  controller: _departureController,
                  builder: (context, controller, focusNode) {
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: InputDecoration(
                        labelText: 'Điểm đi',
                        prefixIcon: const Icon(
                          Icons.location_on,
                          color: Colors.green,
                        ),
                        border: const OutlineInputBorder(),
                        suffixIcon:
                            _departureLocation != null
                                ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    setState(() {
                                      _departureLocation = null;
                                      _departureAddress = '';
                                      _departureController.clear();
                                      _polylinePoints.clear();
                                    });
                                  },
                                )
                                : null,
                      ),
                    );
                  },
                  suggestionsCallback: (pattern) async {
                    if (pattern.length < 3) return [];
                    return await _locationService.searchPlaces(pattern);
                  },
                  itemBuilder: (context, suggestion) {
                    return ListTile(
                      leading: const Icon(
                        Icons.location_on,
                        color: Colors.green,
                      ),
                      title: Text(suggestion),
                    );
                  },
                  onSelected: (suggestion) {
                    _searchLocation(suggestion, true);
                  },
                ),
                const SizedBox(height: 12),
                // Destination search
                TypeAheadField<String>(
                  controller: _destinationController,
                  builder: (context, controller, focusNode) {
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: InputDecoration(
                        labelText: 'Điểm đến',
                        prefixIcon: const Icon(
                          Icons.location_on,
                          color: Colors.red,
                        ),
                        border: const OutlineInputBorder(),
                        suffixIcon:
                            _destinationLocation != null
                                ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    setState(() {
                                      _destinationLocation = null;
                                      _destinationAddress = '';
                                      _destinationController.clear();
                                      _polylinePoints.clear();
                                    });
                                  },
                                )
                                : null,
                      ),
                    );
                  },
                  suggestionsCallback: (pattern) async {
                    if (pattern.length < 3) return [];
                    return await _locationService.searchPlaces(pattern);
                  },
                  itemBuilder: (context, suggestion) {
                    return ListTile(
                      leading: const Icon(Icons.location_on, color: Colors.red),
                      title: Text(suggestion),
                    );
                  },
                  onSelected: (suggestion) {
                    _searchLocation(suggestion, false);
                  },
                ),
                if (_routeDistance > 0) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildRouteInfo(
                        Icons.straighten,
                        'Khoảng cách',
                        '${(_routeDistance / 1000).toStringAsFixed(1)} km',
                      ),
                      _buildRouteInfo(
                        Icons.access_time,
                        'Thời gian',
                        '${(_routeDuration / 60).toStringAsFixed(0)} phút',
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          // Map
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter:
                        _currentLocation ?? const LatLng(10.7769, 106.7009),
                    initialZoom: 13.0,
                    onTap: _onMapTap,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.sharexe.app',
                    ),
                    // Polyline for route
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
                    // Markers
                    MarkerLayer(
                      markers: [
                        if (_departureLocation != null)
                          Marker(
                            point: _departureLocation!,
                            width: 40,
                            height: 40,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3,
                                ),
                              ),
                              child: const Icon(
                                Icons.location_on,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                        if (_destinationLocation != null)
                          Marker(
                            point: _destinationLocation!,
                            width: 40,
                            height: 40,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3,
                                ),
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
                if (_isLoadingLocation || _isCalculatingRoute)
                  const Center(child: CircularProgressIndicator()),
                // Instructions
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
                    child: const Text(
                      'Chạm vào bản đồ để chọn điểm đi và điểm đến',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteInfo(IconData icon, String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }
}
