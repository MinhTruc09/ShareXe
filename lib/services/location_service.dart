import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Request location permissions
  Future<LocationPermission> requestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission;
  }

  /// Get current position
  Future<Position> getCurrentPosition() async {
    final permission = await requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are denied');
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  /// Get current position as LatLng
  Future<LatLng> getCurrentLatLng() async {
    final position = await getCurrentPosition();
    return LatLng(position.latitude, position.longitude);
  }

  /// Convert coordinates to address (Reverse Geocoding)
  Future<List<Placemark>> getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      return await placemarkFromCoordinates(latitude, longitude);
    } catch (e) {
      throw Exception('Failed to get address: $e');
    }
  }

  /// Convert address to coordinates (Forward Geocoding)
  Future<List<Location>> getCoordinatesFromAddress(String address) async {
    try {
      return await locationFromAddress(address);
    } catch (e) {
      throw Exception('Failed to get coordinates: $e');
    }
  }

  /// Get formatted address from coordinates
  Future<String> getFormattedAddress(double latitude, double longitude) async {
    final placemarks = await getAddressFromCoordinates(latitude, longitude);
    if (placemarks.isNotEmpty) {
      final place = placemarks.first;
      final components = [
        place.street,
        place.subLocality,
        place.locality,
        place.administrativeArea,
        place.country,
      ].where((component) => component != null && component.isNotEmpty);

      return components.join(', ');
    }
    return 'Unknown location';
  }

  /// Calculate distance between two points
  double calculateDistance(LatLng point1, LatLng point2) {
    const Distance distance = Distance();
    return distance.as(LengthUnit.Kilometer, point1, point2);
  }

  /// Get location suggestions for search
  Future<List<String>> getLocationSuggestions(String query) async {
    if (query.isEmpty) return [];

    try {
      final locations = await locationFromAddress(query);
      final suggestions = <String>[];

      for (final location in locations.take(5)) {
        final address = await getFormattedAddress(
          location.latitude,
          location.longitude,
        );
        if (!suggestions.contains(address)) {
          suggestions.add(address);
        }
      }

      return suggestions;
    } catch (e) {
      return [];
    }
  }

  /// Check if coordinates are valid
  bool isValidCoordinates(double latitude, double longitude) {
    return latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180;
  }

  /// Stream position updates
  Stream<Position> getPositionStream({LocationSettings? locationSettings}) {
    return Geolocator.getPositionStream(
      locationSettings:
          locationSettings ??
          const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10, // Update every 10 meters
          ),
    );
  }

  /// Get current location as Position (alias for getCurrentPosition)
  Future<Position?> getCurrentLocation() async {
    try {
      return await getCurrentPosition();
    } catch (e) {
      print('Error getting current location: $e');
      return null;
    }
  }

  /// Get address from LatLng
  Future<String> getAddressFromLatLng(LatLng latLng) async {
    try {
      final placemarks = await getAddressFromCoordinates(
        latLng.latitude,
        latLng.longitude,
      );
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        return '${place.street ?? ''} ${place.locality ?? ''} ${place.administrativeArea ?? ''} ${place.country ?? ''}'
            .trim();
      }
      return '${latLng.latitude}, ${latLng.longitude}';
    } catch (e) {
      print('Error getting address from latlng: $e');
      return '${latLng.latitude}, ${latLng.longitude}';
    }
  }

  /// Get LatLng from address
  Future<LatLng?> getLocationFromAddress(String address) async {
    try {
      final locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        return LatLng(locations.first.latitude, locations.first.longitude);
      }
      return null;
    } catch (e) {
      print('Error getting location from address: $e');
      return null;
    }
  }

  /// Search places with better suggestions
  Future<List<String>> searchPlaces(String query) async {
    if (query.length < 2) return [];
    
    try {
      final locations = await locationFromAddress(query);
      final suggestions = <String>[];
      
      for (final location in locations.take(5)) {
        final address = await getFormattedAddress(
          location.latitude,
          location.longitude,
        );
        if (!suggestions.contains(address) && address.isNotEmpty) {
          suggestions.add(address);
        }
      }
      
      return suggestions;
    } catch (e) {
      print('Error searching places: $e');
      return [];
    }
  }

  /// Search places with detailed information
  Future<List<Map<String, dynamic>>> searchPlacesDetailed(String query) async {
    if (query.length < 2) return [];
    
    try {
      final locations = await locationFromAddress(query);
      final suggestions = <Map<String, dynamic>>[];
      
      for (final location in locations.take(5)) {
        final placemarks = await getAddressFromCoordinates(
          location.latitude,
          location.longitude,
        );
        
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          final address = getFormattedAddress(
            location.latitude,
            location.longitude,
          );
          
          suggestions.add({
            'address': address,
            'latitude': location.latitude,
            'longitude': location.longitude,
            'street': place.street,
            'locality': place.locality,
            'administrativeArea': place.administrativeArea,
            'country': place.country,
          });
        }
      }
      
      return suggestions;
    } catch (e) {
      print('Error searching places detailed: $e');
      return [];
    }
  }
}
