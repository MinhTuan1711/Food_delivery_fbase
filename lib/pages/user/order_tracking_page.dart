import 'package:flutter/material.dart';
import 'package:food_delivery_fbase/models/order.dart' as order_model;
import 'package:food_delivery_fbase/services/business/order_service.dart';
import 'package:food_delivery_fbase/utils/currency_formatter.dart';
import 'package:food_delivery_fbase/pages/user/order_detail_page.dart';
import 'package:food_delivery_fbase/components/cart_badge.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:food_delivery_fbase/models/restaurant.dart';

class OrderTrackingPage extends StatefulWidget {
  const OrderTrackingPage({super.key});

  @override
  State<OrderTrackingPage> createState() => _OrderTrackingPageState();
}

class _OrderTrackingPageState extends State<OrderTrackingPage>
    with SingleTickerProviderStateMixin {
  final OrderService _orderService = OrderService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Preload orders when page opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final restaurant = Provider.of<Restaurant>(context, listen: false);
      restaurant.loadUserOrders();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _cancelOrder(order_model.Order order) async {
    try {
      final restaurant = Provider.of<Restaurant>(context, listen: false);
      await restaurant.cancelOrder(order.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã hủy đơn hàng thành công'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi hủy đơn hàng: $e')),
        );
      }
    }
  }

  void _showCancelDialog(order_model.Order order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hủy đơn hàng'),
        content: Text('Bạn có chắc chắn muốn hủy đơn hàng #${order.displayOrderCode}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Không'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _cancelOrder(order);
            },
            child: const Text('Có, hủy đơn hàng'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('Đơn hàng của tôi'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).colorScheme.inversePrimary,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Consumer<Restaurant>(
            builder: (context, restaurant, child) {
              final allOrders = restaurant.userOrders;
              final activeOrders = allOrders.where((order) => order.isActive).toList();
              final completedOrders = allOrders.where((order) => order.isCompleted).toList();
              
              return TabBar(
                controller: _tabController,
                labelColor: Theme.of(context).colorScheme.onSurface,
                unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
                indicatorColor: Theme.of(context).colorScheme.onSurface,
                tabs: [
                  Tab(text: 'Tất cả (${allOrders.length})'),
                  _buildTabWithBadge('Đang xử lý', activeOrders.length),
                  Tab(text: 'Hoàn thành (${completedOrders.length})'),
                ],
              );
            },
          ),
        ),
      ),
      body: Consumer<Restaurant>(
        builder: (context, restaurant, child) {
          return StreamBuilder<List<order_model.Order>>(
            stream: restaurant.getUserOrdersStream(),
            initialData: restaurant.userOrders, // Use cached data immediately
            builder: (context, snapshot) {
              // Show loading only if we have no data at all
              if (snapshot.connectionState == ConnectionState.waiting && 
                  (snapshot.data == null || snapshot.data!.isEmpty)) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Lỗi: ${snapshot.error}'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => restaurant.loadUserOrders(),
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                );
              }

              final allOrders = snapshot.data ?? restaurant.userOrders;
              final activeOrders = allOrders.where((order) => order.isActive).toList();
              final completedOrders = allOrders.where((order) => order.isCompleted).toList();

              return Stack(
                children: [
                  TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOrdersList(allOrders),
                      _buildOrdersList(activeOrders),
                      _buildOrdersList(completedOrders),
                    ],
                  ),
                  // Show subtle loading indicator when data is being refreshed
                  if (snapshot.connectionState == ConnectionState.waiting && 
                      snapshot.data != null && snapshot.data!.isNotEmpty)
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildOrdersList(List<order_model.Order> orders) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Chưa có đơn hàng nào',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Hãy đặt món để xem đơn hàng ở đây',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        final restaurant = Provider.of<Restaurant>(context, listen: false);
        await restaurant.loadUserOrders();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return _buildOrderCard(order);
        },
      ),
    );
  }

  Widget _buildOrderCard(order_model.Order order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _navigateToOrderDetail(order),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order header
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Đơn hàng #${order.displayOrderCode}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(order.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getStatusColor(order.status).withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      order.statusDisplayText,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Order date and total
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${_formatDate(order.orderDate)} • ${order.items.length} món',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    CurrencyFormatter.formatTotal(order.totalAmount),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Order items preview
              ...order.items.take(2).map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Text(
                      '${item.quantity}x ',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        item.food?.name ?? 'Món ăn',
                        style: Theme.of(context).textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              )),
              if (order.items.length > 2)
                Text(
                  '... và ${order.items.length - 2} món khác',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              const SizedBox(height: 12),
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _navigateToOrderDetail(order),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.onSurface,
                      ),
                      child: const Text('Xem chi tiết'),
                    ),
                  ),
                  if (order.canBeCancelled) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _showCancelDialog(order),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                        child: const Text('Hủy đơn'),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToOrderDetail(order_model.Order order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderDetailPage(order: order),
      ),
    ).then((_) {
      // Refresh orders when returning from detail page
      final restaurant = Provider.of<Restaurant>(context, listen: false);
      restaurant.loadUserOrders();
    });
  }

  Color _getStatusColor(order_model.OrderStatus status) {
    switch (status) {
      case order_model.OrderStatus.pending:
        return Colors.orange;
      case order_model.OrderStatus.confirmed:
        return Colors.blue;
      case order_model.OrderStatus.preparing:
        return Colors.purple;
      case order_model.OrderStatus.ready:
        return Colors.green;
      case order_model.OrderStatus.delivered:
        return Colors.green;
      case order_model.OrderStatus.cancelled:
        return Colors.red;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildTabWithBadge(String title, int count) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return Tab(text: '$title ($count)');
    }

    return Tab(
      child: CartBadge(
        useCartService: false,
        countStream: _orderService.getActiveOrdersCountStream(userId),
        child: Text('$title ($count)'),
      ),
    );
  }
}
