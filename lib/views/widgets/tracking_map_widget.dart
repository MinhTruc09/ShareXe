import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/ride.dart';
import '../../services/route_service.dart';

class TrackingMapWidget extends StatefulWidget {
  final Ride ride;
  final Position? currentPosition;
  final bool isTracking;
  final VoidCallback? onStartTracking;
  final VoidCallback? onStopTracking;

  const TrackingMapWidget({
    Key? key,
    required this.ride,
    this.currentPosition,
    this.isTracking = false,
    this.onStartTracking,
    this.onStopTracking,
  }) : super(key: key);

  @override
  State<TrackingMapWidget> createState() => _TrackingMapWidgetState();
}

class _TrackingMapWidgetState extends State<TrackingMapWidget> {
  final RouteService _routeService = RouteService();

  List<LatLng> _routePoints = [];
  bool _isLoadingRoute = false;
  double _routeDistance = 0.0;
  int _routeDuration = 0;

  @override
  void initState() {
    super.initState();
    _loadRoute();
  }

  @override
  void didUpdateWidget(TrackingMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentPosition != widget.currentPosition) {
      _loadRoute();
    }
  }

  Future<void> _loadRoute() async {
    if (widget.currentPosition == null) return;

    setState(() {
      _isLoadingRoute = true;
    });

    try {
      // Get route from current position to destination
      final routeData = await _routeService.calculateRoute(
        LatLng(
          widget.currentPosition!.latitude,
          widget.currentPosition!.longitude,
        ),
        LatLng(widget.ride.endLat ?? 0.0, widget.ride.endLng ?? 0.0),
      );

      if (routeData != null) {
        setState(() {
          _routePoints = routeData.points;
          _routeDistance = routeData.distance;
          _routeDuration = routeData.duration.toInt();
          _isLoadingRoute = false;
        });
      } else {
        setState(() {
          _isLoadingRoute = false;
        });
      }
    } catch (e) {
      print('❌ Lỗi khi tính toán tuyến đường: $e');
      setState(() {
        _isLoadingRoute = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Map
            FlutterMap(
              options: MapOptions(
                initialCenter: _getInitialCenter(),
                initialZoom: 15.0,
                minZoom: 5.0,
                maxZoom: 18.0,
              ),
              children: [
                // OpenStreetMap tiles
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.sharexe.app',
                ),

                // Route polyline
                if (_routePoints.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _routePoints,
                        strokeWidth: 4.0,
                        color: Colors.blue,
                      ),
                    ],
                  ),

                // Markers
                MarkerLayer(markers: _buildMarkers()),
              ],
            ),

            // Loading overlay
            if (_isLoadingRoute)
              Container(
                color: Colors.white.withOpacity(0.8),
                child: const Center(child: CircularProgressIndicator()),
              ),

            // Tracking controls overlay
            Positioned(top: 8, right: 8, child: _buildTrackingControls()),

            // Route info overlay
            if (_routeDistance > 0)
              Positioned(
                bottom: 8,
                left: 8,
                right: 8,
                child: _buildRouteInfo(),
              ),
          ],
        ),
      ),
    );
  }

  LatLng _getInitialCenter() {
    if (widget.currentPosition != null) {
      return LatLng(
        widget.currentPosition!.latitude,
        widget.currentPosition!.longitude,
      );
    }

    // Fallback to ride start location
    return LatLng(widget.ride.startLat ?? 0.0, widget.ride.startLng ?? 0.0);
  }

  List<Marker> _buildMarkers() {
    List<Marker> markers = [];

    // Start marker (current position or ride start)
    if (widget.currentPosition != null) {
      markers.add(
        Marker(
          point: LatLng(
            widget.currentPosition!.latitude,
            widget.currentPosition!.longitude,
          ),
          width: 40,
          height: 40,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: const Icon(Icons.location_on, color: Colors.white, size: 24),
          ),
        ),
      );
    } else if (widget.ride.startLat != null && widget.ride.startLng != null) {
      markers.add(
        Marker(
          point: LatLng(widget.ride.startLat!, widget.ride.startLng!),
          width: 40,
          height: 40,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: const Icon(Icons.location_on, color: Colors.white, size: 24),
          ),
        ),
      );
    }

    // Destination marker
    if (widget.ride.endLat != null && widget.ride.endLng != null) {
      markers.add(
        Marker(
          point: LatLng(widget.ride.endLat!, widget.ride.endLng!),
          width: 40,
          height: 40,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: const Icon(Icons.flag, color: Colors.white, size: 24),
          ),
        ),
      );
    }

    return markers;
  }

  Widget _buildTrackingControls() {
    return Container(
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
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.onStartTracking != null && !widget.isTracking)
            IconButton(
              onPressed: widget.onStartTracking,
              icon: const Icon(Icons.play_arrow, color: Colors.green),
              tooltip: 'Bắt đầu theo dõi',
            ),
          if (widget.onStopTracking != null && widget.isTracking)
            IconButton(
              onPressed: widget.onStopTracking,
              icon: const Icon(Icons.stop, color: Colors.red),
              tooltip: 'Dừng theo dõi',
            ),
          IconButton(
            onPressed: _loadRoute,
            icon: const Icon(Icons.refresh, color: Colors.blue),
            tooltip: 'Làm mới tuyến đường',
          ),
        ],
      ),
    );
  }

  Widget _buildRouteInfo() {
    return Container(
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
          const Icon(Icons.route, color: Colors.blue, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Khoảng cách: ${(_routeDistance / 1000).toStringAsFixed(1)} km',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Thời gian: ${(_routeDuration / 60).toStringAsFixed(0)} phút',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
