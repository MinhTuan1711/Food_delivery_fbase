import 'dart:async';
import 'package:flutter/material.dart';
import 'package:food_delivery_fbase/pages/home_page.dart';
import 'package:food_delivery_fbase/services/location_service.dart';
import 'package:food_delivery_fbase/services/user_service.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class LocationSelectionPage extends StatefulWidget {
  final bool allowBack;
  
  const LocationSelectionPage({
    super.key,
    this.allowBack = false,
  });

  @override
  State<LocationSelectionPage> createState() => _LocationSelectionPageState();
}

class _LocationSelectionPageState extends State<LocationSelectionPage> {
  final LocationService _locationService = LocationService();
  final UserService _userService = UserService();
  
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  
  bool _isLoading = false;
  bool _isLoadingAddress = false;
  bool _isSearching = false;
  String? _errorMessage;
  String? _currentAddress;
  double? _latitude;
  double? _longitude;
  
  // Default location (Hà Đông, Hà Nội)
  static const LatLng _defaultPosition = LatLng(20.9716, 105.7784);
  static const double _defaultZoom = 13.0;
  
  LatLng? _selectedLocation;
  double _currentZoom = _defaultZoom;
  List<Location> _searchResults = [];
  bool _showSearchResults = false;
  bool _hasSearchText = false;
  String _currentSearchQuery = '';

  @override
  void dispose() {
    _mapController.dispose();
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentAddress = null;
    });

    try {
      // Get current location
      final position = await _locationService.getCurrentLocation();
      
      final location = LatLng(position.latitude, position.longitude);
      await _updateLocation(location);
      
      // Move camera to current location
      _mapController.move(location, 15.0);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateLocation(LatLng location) async {
    setState(() {
      _latitude = location.latitude;
      _longitude = location.longitude;
      _selectedLocation = location;
      _isLoadingAddress = true;
      _currentAddress = null;
    });

    try {
      // Convert coordinates to address
      final placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        // Build address string
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

        final address = addressParts.join(', ');
        
        setState(() {
          _currentAddress = address.isNotEmpty ? address : 'Không thể xác định địa chỉ';
        });
      } else {
        setState(() {
          _currentAddress = 'Không thể xác định địa chỉ';
        });
      }
    } catch (e) {
      setState(() {
        _currentAddress = 'Không thể xác định địa chỉ: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoadingAddress = false;
      });
    }
  }

  Future<void> _onMapTap(TapPosition tapPosition, LatLng location) async {
    // Hide search results when tapping on map
    setState(() {
      _showSearchResults = false;
    });
    await _updateLocation(location);
  }

  Future<void> _searchAddress(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _showSearchResults = false;
        _isSearching = false;
        _currentSearchQuery = '';
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _showSearchResults = true;
      _currentSearchQuery = query;
    });

    try {
      final locations = await locationFromAddress(query);
      
      setState(() {
        _searchResults = locations;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      
      // Show error only if query is not empty
      if (query.trim().isNotEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không tìm thấy địa chỉ: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _onSearchChanged(String value) {
    setState(() {
      _hasSearchText = value.isNotEmpty;
    });
    
    // Cancel previous debounce timer
    _searchDebounce?.cancel();
    
    // Create new debounce timer
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      _searchAddress(value);
    });
  }

  Future<void> _selectSearchResult(Location location) async {
    setState(() {
      _showSearchResults = false;
      _hasSearchText = false;
      _searchController.clear();
    });

    final latLng = LatLng(location.latitude, location.longitude);
    
    // Move map to selected location
    _mapController.move(latLng, 15.0);
    
    // Update location and get address
    await _updateLocation(latLng);
  }

  Future<void> _saveLocation() async {
    if (_latitude == null || _longitude == null || _currentAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn vị trí trước khi lưu'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Save location coordinates
      await _userService.updateUserLocation(_latitude!, _longitude!);
      
      // Save address to delivery address
      await _userService.updateUserProfile(
        deliveryAddress: _currentAddress,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã lưu vị trí thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // If allowBack is true, just pop (opened from profile)
        // Otherwise, navigate to home page (first time setup)
        if (widget.allowBack) {
          Navigator.of(context).pop();
        } else {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const HomePage()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi lưu vị trí: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Allow back navigation if allowBack is true (when opened from profile)
        return widget.allowBack;
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        appBar: AppBar(
          title: const Text('Xác định vị trí'),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          foregroundColor: Theme.of(context).colorScheme.inversePrimary,
          automaticallyImplyLeading: widget.allowBack, // Show back button if allowBack is true
          leading: widget.allowBack ? null : const SizedBox.shrink(), // Hide back button if not allowed
        ),
        body: Column(
          children: [
            // Map section
            Expanded(
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _defaultPosition,
                      initialZoom: _defaultZoom,
                      onTap: _onMapTap,
                      onMapReady: () {
                        print('OpenStreetMap created successfully');
                      },
                      minZoom: 3.0,
                      maxZoom: 18.0,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all,
                      ),
                    ),
                    children: [
                      // OpenStreetMap tile layer
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.food_delivery_fbase',
                        maxZoom: 19,
                      ),
                      // Marker layer
                      if (_selectedLocation != null)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _selectedLocation!,
                              width: 50,
                              height: 50,
                              child: Icon(
                                Icons.location_on,
                                color: Theme.of(context).colorScheme.primary,
                                size: 50,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  // Center marker indicator - only show when no marker is selected
                  if (_selectedLocation == null)
                    Center(
                      child: Icon(
                        Icons.location_on,
                        size: 50,
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                      ),
                    ),
                  // Get current location button
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: FloatingActionButton(
                      mini: true,
                      onPressed: _isLoading ? null : _getCurrentLocation,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.my_location, color: Colors.white),
                    ),
                  ),
                  // Search bar
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Search TextField
                        Card(
                          elevation: 4,
                          child: TextField(
                            controller: _searchController,
                            onChanged: _onSearchChanged,
                            decoration: InputDecoration(
                              hintText: 'Tìm kiếm địa chỉ...',
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: _hasSearchText
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() {
                                          _hasSearchText = false;
                                          _searchResults = [];
                                          _showSearchResults = false;
                                        });
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                        // Search results
                        if (_showSearchResults && _searchResults.isNotEmpty)
                          Card(
                            elevation: 4,
                            margin: const EdgeInsets.only(top: 8),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 200),
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: _searchResults.length,
                                itemBuilder: (context, index) {
                                  final location = _searchResults[index];
                                  return ListTile(
                                    leading: const Icon(Icons.location_on, color: Colors.blue),
                                    title: Text(
                                      _currentSearchQuery,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    subtitle: FutureBuilder<List<Placemark>>(
                                      future: placemarkFromCoordinates(
                                        location.latitude,
                                        location.longitude,
                                      ),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState == ConnectionState.waiting) {
                                          return const Text(
                                            'Đang tải địa chỉ...',
                                            style: TextStyle(fontSize: 12),
                                          );
                                        }
                                        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                                          final placemark = snapshot.data!.first;
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
                                          if (placemark.administrativeArea != null && placemark.administrativeArea!.isNotEmpty) {
                                            addressParts.add(placemark.administrativeArea!);
                                          }
                                          
                                          return Text(
                                            addressParts.isNotEmpty 
                                                ? addressParts.join(', ')
                                                : '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}',
                                            style: const TextStyle(fontSize: 12),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          );
                                        }
                                        return Text(
                                          '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}',
                                          style: const TextStyle(fontSize: 12),
                                        );
                                      },
                                    ),
                                    onTap: () => _selectSearchResult(location),
                                  );
                                },
                              ),
                            ),
                          ),
                        // Loading indicator for search
                        if (_isSearching)
                          Card(
                            margin: const EdgeInsets.only(top: 8),
                            child: const Padding(
                              padding: EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                  SizedBox(width: 12),
                                  Text('Đang tìm kiếm...'),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Info section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Instructions
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Chạm vào bản đồ để chọn vị trí hoặc nhấn nút để lấy vị trí hiện tại',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  // Error message
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  // Address display
                  if (_currentAddress != null) ...[
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: 20,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Địa chỉ đã chọn:',
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (_isLoadingAddress)
                              const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            else
                              Text(
                                _currentAddress!,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  
                  // Save button
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: (_isLoading || _currentAddress == null) ? null : _saveLocation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Lưu vị trí và tiếp tục',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
