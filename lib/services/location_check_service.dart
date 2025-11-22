import 'package:food_delivery_fbase/models/user.dart';
import 'package:food_delivery_fbase/services/location_service.dart';
import 'package:food_delivery_fbase/services/delivery_range_service.dart';
import 'package:food_delivery_fbase/services/user_service.dart';

class LocationCheckResult {
  final bool isWithinRange;
  final String? userCountry;
  final String? deliveryCountry;
  final String? errorMessage;

  LocationCheckResult({
    required this.isWithinRange,
    this.userCountry,
    this.deliveryCountry,
    this.errorMessage,
  });
}

class LocationCheckService {
  final LocationService _locationService = LocationService();
  final DeliveryRangeService _deliveryRangeService = DeliveryRangeService();
  final UserService _userService = UserService();

  // Check if user location is set (first time login check)
  Future<bool> isFirstTimeLogin(UserModel? user) async {
    // If user doesn't have latitude/longitude, it's first time
    return user?.latitude == null || user?.longitude == null;
  }

  // Check location and delivery range (optimized to avoid duplicate calls)
  Future<LocationCheckResult> checkLocationAndRange() async {
    try {
      // Get current location
      final position = await _locationService.getCurrentLocation();
      
      // Fetch both country data in parallel to avoid sequential blocking
      final results = await Future.wait([
        _deliveryRangeService.getUserCountry(
          position.latitude,
          position.longitude,
        ),
        _deliveryRangeService.getDeliveryCountry(),
      ]);
      
      final userCountry = results[0] as String?;
      final deliveryCountry = results[1] as String;
      
      // Check if within delivery range using pre-fetched data (avoids duplicate calls)
      final isWithinRange = await _deliveryRangeService.isWithinDeliveryRange(
        position.latitude,
        position.longitude,
        deliveryCountry: deliveryCountry,
        userCountry: userCountry,
      );

      // Save location to user profile (don't wait for this to complete)
      _userService.updateUserLocation(
        position.latitude,
        position.longitude,
      ).catchError((e) {
        print('Error updating user location: $e');
        // Don't block on location save failure
      });

      return LocationCheckResult(
        isWithinRange: isWithinRange,
        userCountry: userCountry,
        deliveryCountry: deliveryCountry,
      );
    } catch (e) {
      return LocationCheckResult(
        isWithinRange: true, // Allow access if location check fails (fail open)
        errorMessage: e.toString(),
      );
    }
  }

  // Check location without saving (for re-checking, optimized)
  Future<LocationCheckResult> checkLocationOnly() async {
    try {
      final position = await _locationService.getCurrentLocation();
      
      // Fetch both country data in parallel to avoid sequential blocking
      final results = await Future.wait([
        _deliveryRangeService.getUserCountry(
          position.latitude,
          position.longitude,
        ),
        _deliveryRangeService.getDeliveryCountry(),
      ]);
      
      final userCountry = results[0] as String?;
      final deliveryCountry = results[1] as String;
      
      // Check if within delivery range using pre-fetched data (avoids duplicate calls)
      final isWithinRange = await _deliveryRangeService.isWithinDeliveryRange(
        position.latitude,
        position.longitude,
        deliveryCountry: deliveryCountry,
        userCountry: userCountry,
      );

      return LocationCheckResult(
        isWithinRange: isWithinRange,
        userCountry: userCountry,
        deliveryCountry: deliveryCountry,
      );
    } catch (e) {
      return LocationCheckResult(
        isWithinRange: true,
        errorMessage: e.toString(),
      );
    }
  }
}

