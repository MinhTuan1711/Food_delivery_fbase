import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';

class DeliveryRangeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Default delivery country
  static const String defaultDeliveryCountry = 'Vietnam';
  
  // Alternative country names that should be accepted
  static const List<String> validCountryNames = [
    'Vietnam',
    'Việt Nam',
    'Viet Nam',
    'VN',
  ];

  // Cache for delivery country (valid for 5 minutes)
  String? _cachedDeliveryCountry;
  DateTime? _deliveryCountryCacheTime;
  static const Duration _cacheValidDuration = Duration(minutes: 5);

  // Cache for reverse geocoding (valid for 10 minutes)
  final Map<String, _CachedCountry> _geocodingCache = {};
  static const Duration _geocodingCacheValidDuration = Duration(minutes: 10);

  // Get delivery country from Firestore or use default (with caching)
  Future<String> getDeliveryCountry({bool forceRefresh = false}) async {
    // Return cached value if still valid
    if (!forceRefresh && 
        _cachedDeliveryCountry != null && 
        _deliveryCountryCacheTime != null &&
        DateTime.now().difference(_deliveryCountryCacheTime!) < _cacheValidDuration) {
      return _cachedDeliveryCountry!;
    }

    try {
      final doc = await _firestore
          .collection('restaurant_config')
          .doc('delivery_range')
          .get()
          .timeout(const Duration(seconds: 5));

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final country = data['country'] ?? defaultDeliveryCountry;
        
        // Update cache
        _cachedDeliveryCountry = country;
        _deliveryCountryCacheTime = DateTime.now();
        
        return country;
      }
    } catch (e) {
      print('Error getting delivery country from Firestore: $e');
    }

    // Return default country if Firestore fails or doesn't exist
    final country = defaultDeliveryCountry;
    _cachedDeliveryCountry = country;
    _deliveryCountryCacheTime = DateTime.now();
    return country;
  }

  // Get country name from coordinates using reverse geocoding (with caching)
  Future<String?> getCountryFromCoordinates(double latitude, double longitude) async {
    // Create cache key (rounded to 2 decimal places to allow some tolerance)
    final cacheKey = '${latitude.toStringAsFixed(2)}_${longitude.toStringAsFixed(2)}';
    
    // Check cache first
    final cached = _geocodingCache[cacheKey];
    if (cached != null && 
        DateTime.now().difference(cached.timestamp) < _geocodingCacheValidDuration) {
      return cached.country;
    }

    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        final country = placemarks.first.country;
        
        // Update cache
        _geocodingCache[cacheKey] = _CachedCountry(
          country: country,
          timestamp: DateTime.now(),
        );
        
        // Limit cache size to prevent memory issues
        if (_geocodingCache.length > 100) {
          // Remove oldest entries
          final sortedEntries = _geocodingCache.entries.toList()
            ..sort((a, b) => a.value.timestamp.compareTo(b.value.timestamp));
          for (var i = 0; i < 20; i++) {
            _geocodingCache.remove(sortedEntries[i].key);
          }
        }
        
        return country;
      }
    } catch (e) {
      print('Error getting country from coordinates: $e');
    }
    return null;
  }

  // Check if user location is within delivery range (Vietnam)
  // Accepts optional pre-fetched data to avoid duplicate calls
  Future<bool> isWithinDeliveryRange(
    double userLat, 
    double userLon, {
    String? deliveryCountry,
    String? userCountry,
  }) async {
    try {
      // Use provided data or fetch if not provided
      final delivery = deliveryCountry ?? await getDeliveryCountry();
      final user = userCountry ?? await getCountryFromCoordinates(userLat, userLon);
      
      if (user == null) {
        // If we can't determine country, allow access (fail open)
        print('Could not determine country from coordinates, allowing access');
        return true;
      }

      // Check if user's country matches delivery country
      // Normalize country names for comparison
      final normalizedUserCountry = user.trim();
      final normalizedDeliveryCountry = delivery.trim();
      
      // Check exact match or if user country is in valid country names list
      final isMatch = normalizedUserCountry.toLowerCase() == normalizedDeliveryCountry.toLowerCase() ||
          validCountryNames.any((name) => 
            normalizedUserCountry.toLowerCase() == name.toLowerCase() ||
            normalizedUserCountry.toLowerCase().contains('vietnam') ||
            normalizedUserCountry.toLowerCase().contains('việt nam')
          );

      return isMatch;
    } catch (e) {
      print('Error checking delivery range: $e');
      // If there's an error, allow access (fail open)
      return true;
    }
  }

  // Get user's country name for display
  Future<String?> getUserCountry(double userLat, double userLon) async {
    return await getCountryFromCoordinates(userLat, userLon);
  }
}

// Helper class for caching geocoding results
class _CachedCountry {
  final String? country;
  final DateTime timestamp;

  _CachedCountry({
    required this.country,
    required this.timestamp,
  });
}

