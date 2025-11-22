import 'package:flutter/material.dart';
import 'package:food_delivery_fbase/models/order.dart' as order_model;
import 'package:food_delivery_fbase/services/business/order_service.dart';
import 'package:food_delivery_fbase/utils/currency_formatter.dart';
import 'package:food_delivery_fbase/pages/user/order_detail_page.dart';
import 'package:provider/provider.dart';
import 'package:food_delivery_fbase/models/restaurant.dart';

class AdminOrderManagementPage extends StatefulWidget {
  const AdminOrderManagementPage({super.key});

  @override
  State<AdminOrderManagementPage> createState() =>
      _AdminOrderManagementPageState();
}

class _AdminOrderManagementPageState extends State<AdminOrderManagementPage>
    with SingleTickerProviderStateMixin {
  final OrderService _orderService = OrderService();
  late TabController _tabController;

  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    // Preload orders when page opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final restaurant = Provider.of<Restaurant>(context, listen: false);
      restaurant.loadAllOrders();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _updateOrderStatus(
      String orderId, order_model.OrderStatus newStatus) async {
    try {
      final restaurant = Provider.of<Restaurant>(context, listen: false);
      await restaurant.updateOrderStatus(orderId, newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã cập nhật trạng thái đơn hàng'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi cập nhật trạng thái: $e')),
        );
      }
    }
  }

  Future<void> _searchOrders() async {
    if (_searchQuery.trim().isEmpty) {
      final restaurant = Provider.of<Restaurant>(context, listen: false);
      await restaurant.loadAllOrders();
      return;
    }

    try {
      final restaurant = Provider.of<Restaurant>(context, listen: false);
      final orders = await restaurant.searchOrders(_searchQuery.trim());

      // Update restaurant with search results
      restaurant.updateOrdersList(orders);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tìm kiếm: $e')),
        );
      }
    }
  }

  void _showStatusUpdateDialog(order_model.Order order) {
    showDialog(
      context: context,
      builder: (context) => _OrderUpdateDialog(order: order),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('Quản lý đơn hàng'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).colorScheme.inversePrimary,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Consumer<Restaurant>(
            builder: (context, restaurant, child) {
              final allOrders = restaurant.allOrders;
              final pendingOrders = allOrders
                  .where((o) => o.status == order_model.OrderStatus.pending)
                  .toList();
              final preparingOrders = allOrders
                  .where((o) => o.status == order_model.OrderStatus.preparing)
                  .toList();
              final readyOrders = allOrders
                  .where((o) => o.status == order_model.OrderStatus.ready)
                  .toList();
              final deliveredOrders = allOrders
                  .where((o) => o.status == order_model.OrderStatus.delivered)
                  .toList();

              return TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: Theme.of(context).colorScheme.onSurface,
                unselectedLabelColor:
                    Theme.of(context).colorScheme.onSurfaceVariant,
                indicatorColor: Theme.of(context).colorScheme.onSurface,
                tabs: [
                  Tab(text: 'Tất cả (${allOrders.length})'),
                  Tab(text: 'Chờ xác nhận (${pendingOrders.length})'),
                  Tab(text: 'Đang chuẩn bị (${preparingOrders.length})'),
                  Tab(text: 'Sẵn sàng (${readyOrders.length})'),
                  Tab(text: 'Đã giao (${deliveredOrders.length})'),
                ],
              );
            },
          ),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              enableIMEPersonalizedLearning: true,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm theo mã đơn hàng, tên khách hàng, SĐT...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                          final restaurant =
                              Provider.of<Restaurant>(context, listen: false);
                          restaurant.loadAllOrders();
                        },
                        icon: const Icon(Icons.clear),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              onSubmitted: (_) => _searchOrders(),
            ),
          ),

          // Tab content
          Expanded(
            child: Consumer<Restaurant>(
              builder: (context, restaurant, child) {
                return StreamBuilder<List<order_model.Order>>(
                  stream: restaurant.getAllOrdersStream(),
                  initialData:
                      restaurant.allOrders, // Use cached data immediately
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
                            const Icon(Icons.error,
                                size: 64, color: Colors.red),
                            const SizedBox(height: 16),
                            Text('Lỗi: ${snapshot.error}'),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => restaurant.loadAllOrders(),
                              child: const Text('Thử lại'),
                            ),
                          ],
                        ),
                      );
                    }

                    final allOrders = snapshot.data ?? restaurant.allOrders;
                    final pendingOrders = allOrders
                        .where(
                            (o) => o.status == order_model.OrderStatus.pending)
                        .toList();
                    final preparingOrders = allOrders
                        .where((o) =>
                            o.status == order_model.OrderStatus.preparing)
                        .toList();
                    final readyOrders = allOrders
                        .where((o) => o.status == order_model.OrderStatus.ready)
                        .toList();
                    final deliveredOrders = allOrders
                        .where((o) =>
                            o.status == order_model.OrderStatus.delivered)
                        .toList();

                    return Stack(
                      children: [
                        TabBarView(
                          controller: _tabController,
                          children: [
                            _buildOrdersList(allOrders),
                            _buildOrdersList(pendingOrders),
                            _buildOrdersList(preparingOrders),
                            _buildOrdersList(readyOrders),
                            _buildOrdersList(deliveredOrders),
                          ],
                        ),
                        // Show subtle loading indicator when data is being refreshed
                        if (snapshot.connectionState ==
                                ConnectionState.waiting &&
                            snapshot.data != null &&
                            snapshot.data!.isNotEmpty)
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
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
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
          ),
        ],
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
              'Không có đơn hàng nào',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
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
        await restaurant.loadAllOrders();
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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

              // Customer info
              Row(
                children: [
                  Icon(
                    Icons.person,
                    size: 16,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      order.customerName,
                      style: Theme.of(context).textTheme.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.phone,
                    size: 16,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      order.customerPhone,
                      style: Theme.of(context).textTheme.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Order details
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

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _navigateToOrderDetail(order),
                      style: OutlinedButton.styleFrom(
                        foregroundColor:
                            Theme.of(context).colorScheme.onSurface,
                      ),
                      child: const Text('Xem chi tiết'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _showStatusUpdateDialog(order),
                      style: ElevatedButton.styleFrom(
                        foregroundColor:
                            Theme.of(context).colorScheme.onSurface,
                      ),
                      child: const Text('Cập nhật'),
                    ),
                  ),
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
      restaurant.loadAllOrders();
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

  String _getStatusDisplayText(order_model.OrderStatus status) {
    switch (status) {
      case order_model.OrderStatus.pending:
        return 'Chờ xác nhận';
      case order_model.OrderStatus.confirmed:
        return 'Đã xác nhận';
      case order_model.OrderStatus.preparing:
        return 'Đang chuẩn bị';
      case order_model.OrderStatus.ready:
        return 'Sẵn sàng giao';
      case order_model.OrderStatus.delivered:
        return 'Đã giao';
      case order_model.OrderStatus.cancelled:
        return 'Đã hủy';
    }
  }
}

// Dialog for updating order status and shipper information
class _OrderUpdateDialog extends StatefulWidget {
  final order_model.Order order;

  const _OrderUpdateDialog({required this.order});

  @override
  State<_OrderUpdateDialog> createState() => _OrderUpdateDialogState();
}

class _OrderUpdateDialogState extends State<_OrderUpdateDialog> {
  late order_model.OrderStatus _selectedStatus;
  final TextEditingController _shipperNameController = TextEditingController();
  final TextEditingController _shipperPhoneController = TextEditingController();
  final TextEditingController _trackingNumberController =
      TextEditingController();
  final TextEditingController _deliveryTimeController = TextEditingController();
  DateTime? _selectedDeliveryDate;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.order.status;
    _shipperNameController.text = widget.order.deliveryPerson ?? '';
    _shipperPhoneController.text = widget.order.deliveryPersonPhone ?? '';
    _trackingNumberController.text = widget.order.trackingNumber ?? '';
    _deliveryTimeController.text = widget.order.deliveryTime ?? '';
    _selectedDeliveryDate = widget.order.deliveryDate;
  }

  @override
  void dispose() {
    _shipperNameController.dispose();
    _shipperPhoneController.dispose();
    _trackingNumberController.dispose();
    _deliveryTimeController.dispose();
    super.dispose();
  }

  Future<void> _updateOrder() async {
    if (_isUpdating) return;

    setState(() {
      _isUpdating = true;
    });

    try {
      final restaurant = Provider.of<Restaurant>(context, listen: false);

      // Update order status if changed
      if (_selectedStatus != widget.order.status) {
        await restaurant.updateOrderStatus(widget.order.id!, _selectedStatus);
      }

      // Update delivery info if any field changed
      final hasDeliveryInfoChanged = _shipperNameController.text.trim() !=
              (widget.order.deliveryPerson ?? '') ||
          _shipperPhoneController.text.trim() !=
              (widget.order.deliveryPersonPhone ?? '') ||
          _trackingNumberController.text.trim() !=
              (widget.order.trackingNumber ?? '') ||
          _deliveryTimeController.text.trim() !=
              (widget.order.deliveryTime ?? '') ||
          _selectedDeliveryDate != widget.order.deliveryDate;

      if (hasDeliveryInfoChanged) {
        await restaurant.updateOrderDeliveryInfo(
          orderId: widget.order.id!,
          deliveryPerson: _shipperNameController.text.trim().isEmpty
              ? null
              : _shipperNameController.text.trim(),
          deliveryPersonPhone: _shipperPhoneController.text.trim().isEmpty
              ? null
              : _shipperPhoneController.text.trim(),
          trackingNumber: _trackingNumberController.text.trim().isEmpty
              ? null
              : _trackingNumberController.text.trim(),
          deliveryTime: _deliveryTimeController.text.trim().isEmpty
              ? null
              : _deliveryTimeController.text.trim(),
          deliveryDate: _selectedDeliveryDate,
        );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã cập nhật đơn hàng thành công'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi cập nhật đơn hàng: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  Future<void> _selectDeliveryDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDeliveryDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDeliveryDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Cập nhật đơn hàng #${widget.order.displayOrderCode}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  IconButton(
                    onPressed:
                        _isUpdating ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Order Status Section
                    Text(
                      'Trạng thái đơn hàng',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    ...order_model.OrderStatus.values.map((status) {
                      return RadioListTile<order_model.OrderStatus>(
                        title: Text(_getStatusDisplayText(status)),
                        value: status,
                        groupValue: _selectedStatus,
                        onChanged: _isUpdating
                            ? null
                            : (order_model.OrderStatus? value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedStatus = value;
                                  });
                                }
                              },
                      );
                    }).toList(),

                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),

                    // Shipper Information Section
                    Text(
                      'Thông tin shipper',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Nhập thông tin shipper để mô phỏng quá trình giao hàng',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                    const SizedBox(height: 16),

                    // Shipper Name
                    TextField(
                      controller: _shipperNameController,
                      enabled: !_isUpdating,
                      decoration: InputDecoration(
                        labelText: 'Tên shipper',
                        hintText: 'Nhập tên người giao hàng',
                        prefixIcon: const Icon(Icons.person),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Shipper Phone
                    TextField(
                      controller: _shipperPhoneController,
                      enabled: !_isUpdating,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Số điện thoại shipper',
                        hintText: 'Nhập SĐT người giao hàng',
                        prefixIcon: const Icon(Icons.phone),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Tracking Number
                    TextField(
                      controller: _trackingNumberController,
                      enabled: !_isUpdating,
                      decoration: InputDecoration(
                        labelText: 'Mã theo dõi (tùy chọn)',
                        hintText: 'Nhập mã theo dõi đơn hàng',
                        prefixIcon: const Icon(Icons.local_shipping),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Delivery Date
                    InkWell(
                      onTap: _isUpdating ? null : _selectDeliveryDate,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Ngày giao hàng (tùy chọn)',
                          prefixIcon: const Icon(Icons.calendar_today),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          _selectedDeliveryDate != null
                              ? '${_selectedDeliveryDate!.day}/${_selectedDeliveryDate!.month}/${_selectedDeliveryDate!.year}'
                              : 'Chọn ngày giao hàng',
                          style: TextStyle(
                            color: _selectedDeliveryDate != null
                                ? Theme.of(context).colorScheme.onSurface
                                : Theme.of(context).colorScheme.outline,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Delivery Time
                    TextField(
                      controller: _deliveryTimeController,
                      enabled: !_isUpdating,
                      decoration: InputDecoration(
                        labelText: 'Thời gian giao hàng (tùy chọn)',
                        hintText: 'VD: 14:00 - 16:00',
                        prefixIcon: const Icon(Icons.schedule),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Divider(height: 1),

            // Actions
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed:
                        _isUpdating ? null : () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.onSurface,
                    ),
                    child: const Text('Hủy'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isUpdating ? null : _updateOrder,
                    child: _isUpdating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Cập nhật'),
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.onSurface,
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

  String _getStatusDisplayText(order_model.OrderStatus status) {
    switch (status) {
      case order_model.OrderStatus.pending:
        return 'Chờ xác nhận';
      case order_model.OrderStatus.confirmed:
        return 'Đã xác nhận';
      case order_model.OrderStatus.preparing:
        return 'Đang chuẩn bị';
      case order_model.OrderStatus.ready:
        return 'Sẵn sàng giao';
      case order_model.OrderStatus.delivered:
        return 'Đã giao';
      case order_model.OrderStatus.cancelled:
        return 'Đã hủy';
    }
  }
}
