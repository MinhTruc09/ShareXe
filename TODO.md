# Enhanced Search with Detailed Location Data - Implementation Plan

## Current State Analysis:
- ✅ Map integration is working with MapLocationPicker
- ✅ LocationService provides detailed geocoding (street, ward, district, province)
- ✅ Current search only sends simple strings to API
- ✅ API supports detailed location data in response but not in search parameters

## Implementation Plan:

### 1. Update RideService.searchRides method
- [x] Add coordinate parameters (departureLat, departureLng, destinationLat, destinationLng)
- [x] Send coordinates in query parameters for proximity-based search
- [x] Maintain backward compatibility with string-based search

### 2. Enhance LocationPicker widget
- [x] Modify to capture and return detailed location data (coordinates + address components)
- [x] Update callback to return LocationData object instead of just string
- [x] Integrate with MapLocationPicker to get coordinates

### 3. Update new_home_pscreen.dart
- [ ] Store departure and destination coordinates
- [ ] Update search logic to send coordinates to RideService
- [ ] Handle detailed location data from LocationPicker

### 4. Add proximity-based search
- [ ] Implement coordinate-based filtering in search results
- [ ] Add distance calculation for better matching

### 5. Test and verify
- [ ] Test enhanced search with coordinates
- [ ] Verify location data mapping accuracy
- [ ] Test proximity-based filtering

## Files to be edited:
- `lib/services/ride_service.dart` - Update searchRides method
- `lib/views/widgets/location_picker.dart` - Add detailed location data capture
- `lib/views/screens/passenger/new_home_pscreen.dart` - Update search logic and state management
- `lib/services/location_service.dart` - Ensure detailed geocoding is available

## Followup steps:
- Test enhanced search with coordinates
- Verify location data mapping accuracy
- Test proximity-based filtering
- Add route preview functionality
