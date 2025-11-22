import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  // Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  // Check location permission
  Future<LocationPermission> checkLocationPermission() async {
    return await Geolocator.checkPermission();
  }

  // Request location permission
  Future<LocationPermission> requestLocationPermission() async {
    // First check if location services are enabled
    bool serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Dịch vụ định vị chưa được bật. Vui lòng bật định vị trong cài đặt.');
    }

    // Check permission status
    LocationPermission permission = await checkLocationPermission();
    
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Quyền truy cập vị trí bị từ chối. Vui lòng cấp quyền để sử dụng tính năng này.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Quyền truy cập vị trí bị từ chối vĩnh viễn. Vui lòng cấp quyền trong cài đặt.');
    }

    return permission;
  }

  // Get current location (optimized for performance)
  Future<Position> getCurrentLocation() async {
    try {
      // Request permission first
      await requestLocationPermission();

      // Try to get last known location first (much faster)
      Position? lastKnown = await Geolocator.getLastKnownPosition();
      
      // If last known location is recent (within 30 seconds), use it
      if (lastKnown != null && 
          lastKnown.timestamp != null &&
          DateTime.now().difference(lastKnown.timestamp!) < const Duration(seconds: 30)) {
        return lastKnown;
      }

      // Otherwise get fresh location with balanced accuracy (not high to avoid long waits)
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium, // Changed from high to medium for faster response
        timeLimit: const Duration(seconds: 8), // Reduced from 10 to 8 seconds
      );

      return position;
    } catch (e) {
      // If getting current location fails, try last known as fallback
      Position? lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        return lastKnown;
      }
      throw Exception('Không thể lấy vị trí hiện tại: ${e.toString()}');
    }
  }

  // Get last known location (faster, but may be outdated)
  Future<Position?> getLastKnownLocation() async {
    try {
      return await Geolocator.getLastKnownPosition();
    } catch (e) {
      print('Error getting last known location: $e');
      return null;
    }
  }

  // Calculate distance between two coordinates in kilometers
  double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000; // Convert to km
  }

  // Convert coordinates to address string
  Future<String> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      
      if (placemarks.isEmpty) {
        return 'Không thể xác định địa chỉ';
      }

      final placemark = placemarks.first;
      final addressParts = <String>[];
      
      if (placemark.street != null && placemark.street!.isNotEmpty) {
        addressParts.add(placemark.street!);
      }
      if (placemark.subLocality != null && placemark.subLocality!.isNotEmpty) {
        addressParts.add(placemark.subLocality!);
      }
      if (placemark.locality != null && placemark.locality!.isNotEmpty) {
        addressParts.add(placemark.locality!);
      }
      if (placemark.subAdministrativeArea != null && placemark.subAdministrativeArea!.isNotEmpty) {
        addressParts.add(placemark.subAdministrativeArea!);
      }
      if (placemark.administrativeArea != null && placemark.administrativeArea!.isNotEmpty) {
        addressParts.add(placemark.administrativeArea!);
      }
      if (placemark.country != null && placemark.country!.isNotEmpty) {
        addressParts.add(placemark.country!);
      }

      return addressParts.isNotEmpty 
          ? addressParts.join(', ') 
          : 'Không thể xác định địa chỉ';
    } catch (e) {
      throw Exception('Không thể lấy địa chỉ từ tọa độ: ${e.toString()}');
    }
  }
}

