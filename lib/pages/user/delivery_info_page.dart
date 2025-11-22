import 'dart:async';
import 'package:flutter/material.dart';
import 'package:food_delivery_fbase/services/business/user_service.dart';
import 'package:food_delivery_fbase/services/location/location_service.dart';
import 'package:food_delivery_fbase/models/user.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class DeliveryInfoPage extends StatefulWidget {
  const DeliveryInfoPage({super.key});

  @override
  State<DeliveryInfoPage> createState() => _DeliveryInfoPageState();
}

class _DeliveryInfoPageState extends State<DeliveryInfoPage> {
  final UserService _userService = UserService();
  final LocationService _locationService = LocationService();
  final _formKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isGettingLocation = false;
  double? _currentLatitude;
  double? _currentLongitude;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = await _userService.getCurrentUser();
      if (user != null) {
        setState(() {
          _nameController.text = user.deliveryName ?? '';
          _phoneController.text = user.deliveryPhone ?? '';
          _addressController.text = user.deliveryAddress ?? '';
          _currentLatitude = user.latitude;
          _currentLongitude = user.longitude;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tải thông tin: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isGettingLocation = true;
    });

    try {
      // Get current location
      final position = await _locationService.getCurrentLocation();
      
      // Convert to address
      final address = await _locationService.getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );

      // Update address field
      setState(() {
        _addressController.text = address;
      });

      // Also save location coordinates
      await _userService.updateUserLocation(
        position.latitude,
        position.longitude,
      );

      setState(() {
        _currentLatitude = position.latitude;
        _currentLongitude = position.longitude;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã lấy vị trí và điền địa chỉ thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi lấy vị trí: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGettingLocation = false;
        });
      }
    }
  }

  Future<void> _saveDeliveryInfo() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSaving = true;
      });

      try {
        await _userService.updateUserProfile(
          deliveryName: _nameController.text.trim(),
          deliveryPhone: _phoneController.text.trim(),
          deliveryAddress: _addressController.text.trim(),
        );

        // Also save location if available
        if (_currentLatitude != null && _currentLongitude != null) {
          await _userService.updateUserLocation(
            _currentLatitude!,
            _currentLongitude!,
          );
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lưu thông tin giao hàng thành công!'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context, true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi lưu thông tin: $e')),
        );
      } finally {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _openMapDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _MapSelectionDialog(
        initialLatitude: _currentLatitude,
        initialLongitude: _currentLongitude,
      ),
    );

    if (result != null) {
      setState(() {
        _addressController.text = result['address'] ?? '';
        _currentLatitude = result['latitude'];
        _currentLongitude = result['longitude'];
      });

      // Save location immediately
      if (_currentLatitude != null && _currentLongitude != null) {
        try {
          await _userService.updateUserLocation(
            _currentLatitude!,
            _currentLongitude!,
          );
        } catch (e) {
          // Silently fail, location will be saved when form is saved
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text("Thông tin giao hàng"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Thông tin giao hàng',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Thông tin này sẽ được lưu lại và tự động điền vào các lần thanh toán tiếp theo',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _nameController,
                              enableIMEPersonalizedLearning: true,
                              decoration: const InputDecoration(
                                labelText: 'Họ và tên người nhận *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.person),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Vui lòng nhập họ tên';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _phoneController,
                              enableIMEPersonalizedLearning: true,
                              decoration: const InputDecoration(
                                labelText: 'Số điện thoại *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.phone),
                              ),
                              keyboardType: TextInputType.phone,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Vui lòng nhập số điện thoại';
                                }
                                if (value.trim().length < 10) {
                                  return 'Số điện thoại phải có ít nhất 10 số';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _addressController,
                                    enableIMEPersonalizedLearning: true,
                                    decoration: const InputDecoration(
                                      labelText: 'Địa chỉ giao hàng *',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.location_on),
                                    ),
                                    maxLines: 3,
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return 'Vui lòng nhập địa chỉ giao hàng';
                                      }
                                      if (value.trim().length < 10) {
                                        return 'Địa chỉ phải có ít nhất 10 ký tự';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _isGettingLocation ? null : _getCurrentLocation,
                                    icon: _isGettingLocation
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          )
                                        : const Icon(Icons.my_location),
                                    label: Text(
                                      _isGettingLocation ? 'Đang lấy...' : 'Lấy vị trí hiện tại',
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      foregroundColor: Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _openMapDialog,
                                    icon: const Icon(Icons.map),
                                    label: const Text('Chọn trên bản đồ'),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      foregroundColor: Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveDeliveryInfo,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                'Lưu thông tin',
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
            ),
    );
  }
}

// Map Selection Dialog Widget
class _MapSelectionDialog extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;

  const _MapSelectionDialog({
    this.initialLatitude,
    this.initialLongitude,
  });

  @override
  State<_MapSelectionDialog> createState() => _MapSelectionDialogState();
}

class _MapSelectionDialogState extends State<_MapSelectionDialog> {
  final LocationService _locationService = LocationService();
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
  void initState() {
    super.initState();
    // Initialize with provided location or default
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _selectedLocation = LatLng(widget.initialLatitude!, widget.initialLongitude!);
      _latitude = widget.initialLatitude;
      _longitude = widget.initialLongitude;
      _currentZoom = 15.0;
      _loadAddressForLocation(_selectedLocation!);
    }
  }

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
      final position = await _locationService.getCurrentLocation();
      final location = LatLng(position.latitude, position.longitude);
      await _updateLocation(location);
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

  Future<void> _loadAddressForLocation(LatLng location) async {
    setState(() {
      _isLoadingAddress = true;
      _currentAddress = null;
    });

    try {
      final address = await _locationService.getAddressFromCoordinates(
        location.latitude,
        location.longitude,
      );
      setState(() {
        _currentAddress = address;
      });
    } catch (e) {
      setState(() {
        _currentAddress = 'Không thể xác định địa chỉ';
      });
    } finally {
      setState(() {
        _isLoadingAddress = false;
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
      final placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );

      if (placemarks.isNotEmpty) {
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
        if (placemark.subAdministrativeArea != null &&
            placemark.subAdministrativeArea!.isNotEmpty) {
          addressParts.add(placemark.subAdministrativeArea!);
        }
        if (placemark.administrativeArea != null &&
            placemark.administrativeArea!.isNotEmpty) {
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
    }
  }

  void _onSearchChanged(String value) {
    setState(() {
      _hasSearchText = value.isNotEmpty;
    });

    _searchDebounce?.cancel();
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
    _mapController.move(latLng, 15.0);
    await _updateLocation(latLng);
  }

  void _confirmSelection() {
    if (_latitude != null && _longitude != null && _currentAddress != null) {
      Navigator.of(context).pop({
        'latitude': _latitude,
        'longitude': _longitude,
        'address': _currentAddress,
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn vị trí trước khi xác nhận'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Chọn vị trí trên bản đồ',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // Map section
            Expanded(
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _selectedLocation ?? _defaultPosition,
                      initialZoom: _currentZoom,
                      onTap: _onMapTap,
                      minZoom: 3.0,
                      maxZoom: 18.0,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all,
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.food_delivery_fbase',
                        maxZoom: 19,
                      ),
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
                                        if (snapshot.connectionState ==
                                            ConnectionState.waiting) {
                                          return const Text(
                                            'Đang tải địa chỉ...',
                                            style: TextStyle(fontSize: 12),
                                          );
                                        }
                                        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                                          final placemark = snapshot.data!.first;
                                          final addressParts = <String>[];

                                          if (placemark.street != null &&
                                              placemark.street!.isNotEmpty) {
                                            addressParts.add(placemark.street!);
                                          }
                                          if (placemark.subLocality != null &&
                                              placemark.subLocality!.isNotEmpty) {
                                            addressParts.add(placemark.subLocality!);
                                          }
                                          if (placemark.locality != null &&
                                              placemark.locality!.isNotEmpty) {
                                            addressParts.add(placemark.locality!);
                                          }
                                          if (placemark.administrativeArea != null &&
                                              placemark.administrativeArea!.isNotEmpty) {
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
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_errorMessage != null) ...[
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
                    const SizedBox(height: 12),
                  ],
                  if (_currentAddress != null) ...[
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
                    const SizedBox(height: 12),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Hủy'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _confirmSelection,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Theme.of(context).colorScheme.onPrimary,
                          ),
                          child: const Text('Xác nhận'),                          
                        ),
                      ),
                    ],
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
