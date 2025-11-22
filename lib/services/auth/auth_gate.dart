import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:food_delivery_fbase/pages/user/home_page.dart';
import 'package:food_delivery_fbase/pages/user/location_selection_page.dart';
import 'package:food_delivery_fbase/services/auth/login_or_register.dart';
import 'package:provider/provider.dart';
import 'package:food_delivery_fbase/models/restaurant.dart';
import 'package:food_delivery_fbase/services/business/user_service.dart';
import 'package:food_delivery_fbase/services/location/location_check_service.dart';
import 'package:food_delivery_fbase/widgets/delivery_range_dialog.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  User? _currentUser;
  bool _isLoading = true;
  bool _isCheckingLocation = false;
  bool _isCheckingDeliveryAddress = false;
  bool _hasDeliveryAddress = false;
  final UserService _userService = UserService();
  final LocationCheckService _locationCheckService = LocationCheckService();

  @override
  void initState() {
    super.initState();
    _checkAuthState();
    
    // Listen to auth state changes
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      print('AuthGate: Auth state changed - User: ${user?.uid}');
      if (mounted) {
        setState(() {
          _currentUser = user;
          _isLoading = false;
        });
        
        // Preload menu and cart data when user is authenticated
        if (user != null) {
          _checkDeliveryAddress(user);
          _preloadData();
          _checkLocationOnFirstLogin(user);
        }
      }
    });
  }

  // Preload menu, cart and orders data for faster loading
  Future<void> _preloadData() async {
    try {
      final restaurant = Provider.of<Restaurant>(context, listen: false);
      // Preload menu, cart and orders data with timeout
      await Future.wait([
        restaurant.preloadMenu(),
        restaurant.loadCartFromFirebase(),
        restaurant.loadUserOrders(),
      ]).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('AuthGate: Preload data timeout');
          return <void>[];
        },
      );
    } catch (e) {
      print('AuthGate: Failed to preload data: $e');
      // Don't block UI if preload fails
    }
  }

  // Check if user has delivery address set
  Future<void> _checkDeliveryAddress(User user) async {
    if (_isCheckingDeliveryAddress) return;
    
    setState(() {
      _isCheckingDeliveryAddress = true;
    });
    
    try {
      final userModel = await _userService.getCurrentUser();
      final hasAddress = userModel?.deliveryAddress != null && 
                        userModel!.deliveryAddress!.trim().isNotEmpty;
      
      if (mounted) {
        setState(() {
          _hasDeliveryAddress = hasAddress;
          _isCheckingDeliveryAddress = false;
        });
      }
    } catch (e) {
      print('AuthGate: Error checking delivery address: $e');
      if (mounted) {
        setState(() {
          _hasDeliveryAddress = false;
          _isCheckingDeliveryAddress = false;
        });
      }
    }
  }

  // Check location on first login (runs in background to avoid blocking UI)
  Future<void> _checkLocationOnFirstLogin(User user) async {
    if (_isCheckingLocation) return;
    
    // Run location check in background without blocking UI
    Future.microtask(() async {
      if (!mounted) return;
      
      try {
        _isCheckingLocation = true;
        
        // Get user data from Firestore
        final userModel = await _userService.getCurrentUser();
        
        // Check if this is first time login (no location saved)
        final isFirstTime = await _locationCheckService.isFirstTimeLogin(userModel);
        
        if (isFirstTime && mounted) {
          // Check location and delivery range (this may take a few seconds)
          final result = await _locationCheckService.checkLocationAndRange();
          
          if (mounted && !result.isWithinRange && result.userCountry != null) {
            // Show dialog if outside delivery range (not in Vietnam)
            // Use post-frame callback to ensure UI is ready
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => DeliveryRangeDialog(
                    userCountry: result.userCountry,
                    deliveryCountry: result.deliveryCountry,
                  ),
                );
              }
            });
          }
        }
      } catch (e) {
        print('AuthGate: Error checking location: $e');
        // Don't block user if location check fails
      } finally {
        if (mounted) {
          _isCheckingLocation = false;
        }
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _checkAuthState() async {
    try {
      // Wait a bit for Firebase to initialize
      await Future.delayed(const Duration(milliseconds: 200));
      
      final user = FirebaseAuth.instance.currentUser;
      print('AuthGate: Initial user check: ${user?.uid}');
      
      if (mounted) {
        setState(() {
          _currentUser = user;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('AuthGate: Error checking auth state: $e');
      if (mounted) {
        setState(() {
          _currentUser = null;
          _isLoading = false;
        });
      }
    }
    
    // Set a timeout to ensure loading state doesn't persist indefinitely
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && _isLoading) {
        print('AuthGate: Timeout reached, forcing loading to false');
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _isCheckingDeliveryAddress) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_currentUser != null) {
      print('AuthGate: User is authenticated: ${_currentUser!.uid}');
      
      // If user doesn't have delivery address, show location selection page
      if (!_hasDeliveryAddress) {
        return const LocationSelectionPage();
      }
      
      return const HomePage();
    } else {
      print('AuthGate: User is not authenticated, showing login/register');
      return const LoginOrRegister();
    }
  }
}