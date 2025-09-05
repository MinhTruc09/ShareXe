import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';

class RouteService {
  static final RouteService _instance = RouteService._internal();
  factory RouteService() => _instance;
  RouteService._internal();

  /// Calculate route using OSRM (Open Source Routing Machine)
  Future<RouteData?> calculateRoute(LatLng start, LatLng end) async {
    try {
      final url =
          'https://router.project-osrm.org/route/v1/driving/'
          '${start.longitude},${start.latitude};'
          '${end.longitude},${end.latitude}'
          '?overview=full&geometries=geojson&steps=true';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final geometry = route['geometry']['coordinates'] as List;

          // Convert coordinates to LatLng points
          final points =
              geometry.map<LatLng>((coord) {
                return LatLng(coord[1], coord[0]); // OSRM returns [lng, lat]
              }).toList();

          final distance = route['distance'] / 1000; // Convert to km
          final duration = route['duration'] / 60; // Convert to minutes

          return RouteData(
            points: points,
            distance: distance,
            duration: duration,
            instructions: _extractInstructions(route['legs'][0]['steps']),
          );
        }
      }
    } catch (e) {
      print('Error calculating route: $e');
    }
    return null;
  }

  /// Extract turn-by-turn instructions from route steps
  List<String> _extractInstructions(List steps) {
    final instructions = <String>[];

    for (final step in steps) {
      final maneuver = step['maneuver'];
      final type = maneuver['type'];
      final modifier = maneuver['modifier'] ?? '';

      String instruction = _getInstructionText(type, modifier);
      if (step['name'] != null && step['name'].isNotEmpty) {
        instruction += ' onto ${step['name']}';
      }

      instructions.add(instruction);
    }

    return instructions;
  }

  /// Get human-readable instruction text
  String _getInstructionText(String type, String modifier) {
    switch (type) {
      case 'turn':
        switch (modifier) {
          case 'left':
            return 'Turn left';
          case 'right':
            return 'Turn right';
          case 'sharp left':
            return 'Turn sharp left';
          case 'sharp right':
            return 'Turn sharp right';
          case 'slight left':
            return 'Turn slight left';
          case 'slight right':
            return 'Turn slight right';
          default:
            return 'Turn $modifier';
        }
      case 'new name':
        return 'Continue';
      case 'depart':
        return 'Depart';
      case 'arrive':
        return 'Arrive at destination';
      case 'merge':
        return 'Merge';
      case 'on ramp':
        return 'Take ramp';
      case 'off ramp':
        return 'Take exit';
      case 'fork':
        return 'At fork, $modifier';
      case 'end of road':
        return 'At end of road, $modifier';
      case 'continue':
        return 'Continue';
      case 'roundabout':
        return 'Enter roundabout';
      case 'rotary':
        return 'Enter rotary';
      case 'roundabout turn':
        return 'At roundabout, $modifier';
      case 'notification':
        return 'Notification';
      default:
        return type;
    }
  }

  /// Calculate distance between two points using Haversine formula
  double calculateDistance(LatLng point1, LatLng point2) {
    const Distance distance = Distance();
    return distance.as(LengthUnit.Kilometer, point1, point2);
  }

  /// Estimate duration based on distance (rough estimate: 40 km/h average speed)
  double estimateDuration(double distanceKm) {
    const averageSpeedKmh = 40.0;
    return (distanceKm / averageSpeedKmh) * 60; // Return minutes
  }

  /// Check if a point is near a route (within tolerance)
  bool isPointNearRoute(
    LatLng point,
    List<LatLng> routePoints, {
    double toleranceKm = 1.0,
  }) {
    for (final routePoint in routePoints) {
      final distance = calculateDistance(point, routePoint);
      if (distance <= toleranceKm) {
        return true;
      }
    }
    return false;
  }

  /// Get route bounds for map fitting
  RouteBounds getRouteBounds(List<LatLng> points) {
    if (points.isEmpty) {
      return RouteBounds(
        southwest: const LatLng(0, 0),
        northeast: const LatLng(0, 0),
      );
    }

    double minLat = points[0].latitude;
    double maxLat = points[0].latitude;
    double minLng = points[0].longitude;
    double maxLng = points[0].longitude;

    for (final point in points) {
      minLat = min(minLat, point.latitude);
      maxLat = max(maxLat, point.latitude);
      minLng = min(minLng, point.longitude);
      maxLng = max(maxLng, point.longitude);
    }

    return RouteBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }
}

class RouteData {
  final List<LatLng> points;
  final double distance; // in km
  final double duration; // in minutes
  final List<String> instructions;

  RouteData({
    required this.points,
    required this.distance,
    required this.duration,
    required this.instructions,
  });

  @override
  String toString() {
    return 'RouteData(distance: ${distance.toStringAsFixed(1)} km, '
        'duration: ${duration.toStringAsFixed(0)} min, '
        'points: ${points.length})';
  }
}

class RouteBounds {
  final LatLng southwest;
  final LatLng northeast;

  RouteBounds({required this.southwest, required this.northeast});

  @override
  String toString() {
    return 'RouteBounds(southwest: $southwest, northeast: $northeast)';
  }
}
