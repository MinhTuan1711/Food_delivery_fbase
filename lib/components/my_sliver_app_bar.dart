import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:food_delivery_fbase/pages/user/cart_page.dart';
import 'package:food_delivery_fbase/pages/user/notifications_page.dart';
import 'package:food_delivery_fbase/components/user_info_widget.dart';
import 'package:food_delivery_fbase/components/cart_badge.dart';
import 'package:food_delivery_fbase/services/business/notification_service.dart';

class MySliverAppBar extends StatelessWidget {
  final Widget child;
  final Widget title;
  const MySliverAppBar({
    super.key,
    required this.child,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final notificationService = NotificationService();

    return SliverAppBar(
      expandedHeight: 280,
      collapsedHeight: 100,
      floating: false,
      pinned: true,
      actions: [
        // Notification button with badge
        if (user != null)
          CartBadge(
            useCartService: false,
            countStream: notificationService.getUnreadCountStream(user.uid),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NotificationsPage(),
              ),
            ),
            child: const Icon(Icons.notifications, size: 30),
          ),
        // Cart button with badge
        CartBadge(
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CartPage(),
              )),
          child: const Icon(Icons.shopping_cart, size: 30),
        ),
      ],
      backgroundColor: Theme.of(context).colorScheme.background,
      foregroundColor: Theme.of(context).colorScheme.inversePrimary,
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Sunset Diner",
            style: Theme.of(context).textTheme.titleLarge,
          ),
          UserGreetingWidget(
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      centerTitle: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Padding(
          padding: EdgeInsets.only(bottom: 50),
          child: child,
        ),
        title: title,
        centerTitle: true,
        titlePadding: const EdgeInsets.only(left: 0, right: 0, top: 0),
        expandedTitleScale: 1,
      ),
    );
  }
}
