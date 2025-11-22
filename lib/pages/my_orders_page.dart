import 'package:flutter/material.dart';
import 'package:food_delivery_fbase/pages/order_tracking_page.dart';

class MyOrdersPage extends StatelessWidget {
  const MyOrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Redirect to the new order tracking page
    return const OrderTrackingPage();
  }
}
