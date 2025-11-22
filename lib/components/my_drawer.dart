import 'package:flutter/material.dart';
import 'package:food_delivery_fbase/components/my_drawer_tile.dart';
import 'package:food_delivery_fbase/pages/user/settings_page.dart';
import 'package:food_delivery_fbase/pages/admin/admin_page.dart';
import 'package:food_delivery_fbase/pages/admin/admin_statistics_page.dart';
import 'package:food_delivery_fbase/services/auth/auth_service.dart';
import 'package:food_delivery_fbase/services/auth/login_or_register.dart';
import 'package:food_delivery_fbase/pages/user/profile_page.dart';
import 'package:food_delivery_fbase/components/user_info_widget.dart';
import 'package:food_delivery_fbase/pages/user/my_orders_page.dart';
import 'package:food_delivery_fbase/pages/user/favorites_page.dart';
import 'package:food_delivery_fbase/components/cart_badge.dart';
import 'package:food_delivery_fbase/services/business/order_service.dart';
import 'package:food_delivery_fbase/services/business/favorite_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyDrawer extends StatefulWidget {
  const MyDrawer({super.key});

  @override
  State<MyDrawer> createState() => _MyDrawerState();
}

class _MyDrawerState extends State<MyDrawer> {
  final AuthService _authService = AuthService();
  final OrderService _orderService = OrderService();
  final FavoriteService _favoriteService = FavoriteService();
  bool _isAdmin = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    final isAdmin = await _authService.isAdmin();
    setState(() {
      _isAdmin = isAdmin;
      _isLoading = false;
    });
  }

  Future<void> logout() async {
    await _authService.signOut();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => LoginOrRegister(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.background,
      child: Column(
        children: [
          // User Profile Section
          Container(
            padding: const EdgeInsets.only(
                top: 100, bottom: 20, left: 20, right: 20),
            child: UserInfoWidget(
              showEmail: true,
              showAdminBadge: true,
              avatarRadius: 40,
              nameStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              emailStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfilePage(),
                  ),
                );
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Divider(
              color: Theme.of(context).colorScheme.inversePrimary,
            ),
          ),

          // Navigation items
          Expanded(
            child: Column(
              children: [
                // home list tile
                MyDrawerTile(
                  text: "T R A N G  C H Ủ",
                  icon: Icons.home,
                  onTap: () => Navigator.pop(context),
                ),

                // My Orders list tile with badge
                _buildOrdersTileWithBadge(),

                // Favorites list tile with badge
                _buildFavoritesTileWithBadge(),

                //settings list tile
                MyDrawerTile(
                  text: "C À I  Đ Ặ T",
                  icon: Icons.settings,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SettingsPage(),
                        ));
                  },
                ),

                MyDrawerTile(
                  text: "H Ồ  S Ơ",
                  icon: Icons.person,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfilePage(),
                        ));
                  },
                ),

                // Admin panel (only show if user is admin)
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  )
                else if (_isAdmin) ...[
                  // if user is admin, show admin panel and migration panel
                  MyDrawerTile(
                    text: "Q U Ả N  T R Ị",
                    icon: Icons.admin_panel_settings,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AdminPage(),
                          ));
                    },
                  ),
                  MyDrawerTile(
                    text: "T H Ố N G  K Ê",
                    icon: Icons.bar_chart,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AdminStatisticsPage(),
                          ));
                    },
                  ),
                ],
              ],
            ),
          ),

          //logout list tile
          MyDrawerTile(
            text: "Đ Ă N G  X U Ấ T",
            icon: Icons.logout,
            onTap: logout,
          ),
          const SizedBox(
            height: 25,
          )
        ],
      ),
    );
  }

  Widget _buildOrdersTileWithBadge() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return MyDrawerTile(
        text: "Đ Ơ N  H À N G",
        icon: Icons.shopping_bag,
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const MyOrdersPage(),
              ));
        },
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: CartBadge(
        useCartService: false,
        countStream: _orderService.getActiveOrdersCountStream(userId),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          title: Text(
            "Đ Ơ N  H À N G",
            style: TextStyle(
              color: Theme.of(context).colorScheme.inversePrimary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          leading: Icon(
            Icons.shopping_bag,
            color: Theme.of(context).colorScheme.inversePrimary,
            size: 24,
          ),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MyOrdersPage(),
                ));
          },
        ),
      ),
    );
  }

  Widget _buildFavoritesTileWithBadge() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return MyDrawerTile(
        text: "M Ó N  Y Ê U  T H Í C H",
        icon: Icons.favorite,
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const FavoritesPage(),
              ));
        },
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: CartBadge(
        useCartService: false,
        countStream: _favoriteService.getFavoritesCountStream(),
        child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              title: Text(
                "M Ó N  Y Ê U  T H Í C H",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.inversePrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              leading: Icon(
                Icons.favorite,
                color: Theme.of(context).colorScheme.inversePrimary,
                size: 24,
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FavoritesPage(),
                    ));
              },
            ),
          ),
    );
  }
}
