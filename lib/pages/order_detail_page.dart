import 'package:flutter/material.dart';
import 'package:food_delivery_fbase/models/order.dart' as order_model;
import 'package:food_delivery_fbase/services/order_service.dart';
import 'package:food_delivery_fbase/utils/currency_formatter.dart';

class OrderDetailPage extends StatefulWidget {
  final order_model.Order order;

  const OrderDetailPage({super.key, required this.order});

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  final OrderService _orderService = OrderService();
  late order_model.Order _order;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    _listenToOrderUpdates();
  }

  void _listenToOrderUpdates() {
    if (_order.id != null) {
      _orderService.getOrderByIdStream(_order.id!).listen((updatedOrder) {
        if (updatedOrder != null && mounted) {
          setState(() {
            _order = updatedOrder;
          });
        }
      });
    }
  }

  Future<void> _refreshOrder() async {
    if (_order.id == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final updatedOrder = await _orderService.getOrderById(_order.id!);
      if (updatedOrder != null && mounted) {
        setState(() {
          _order = updatedOrder;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải đơn hàng: $e')),
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

  Future<void> _cancelOrder() async {
    try {
      setState(() {
        _isLoading = true;
      });

      await _orderService.cancelOrder(_order.id!);

      // Refresh order data
      final updatedOrder = await _orderService.getOrderById(_order.id!);
      if (updatedOrder != null) {
        setState(() {
          _order = updatedOrder;
        });
      }

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
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hủy đơn hàng'),
        content: Text(
            'Bạn có chắc chắn muốn hủy đơn hàng #${_order.displayOrderCode}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Không'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _cancelOrder();
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
        title: Text('Đơn hàng #${_order.displayOrderCode}'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _refreshOrder,
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới',
          ),
          if (_order.canBeCancelled)
            IconButton(
              onPressed: _isLoading ? null : _showCancelDialog,
              icon: const Icon(Icons.cancel_outlined),
              tooltip: 'Hủy đơn hàng',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order Status Card
                  _buildOrderStatusCard(),
                  const SizedBox(height: 16),

                  // Order Items
                  _buildOrderItemsCard(),
                  const SizedBox(height: 16),

                  // Customer Information
                  _buildCustomerInfoCard(),
                  const SizedBox(height: 16),

                  // Payment Information
                  _buildPaymentInfoCard(),
                  const SizedBox(height: 16),

                  // Delivery Information (always show if there's any delivery info)
                  if (_order.deliveryPerson != null ||
                      _order.deliveryPersonPhone != null ||
                      _order.trackingNumber != null ||
                      _order.deliveryTime != null ||
                      _order.deliveryDate != null)
                    _buildDeliveryInfoCard(),

                  const SizedBox(height: 16),

                  // Order Timeline
                  _buildOrderTimelineCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildOrderStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Trạng thái đơn hàng',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(_order.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _getStatusColor(_order.status).withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    _order.statusDisplayText,
                    style: TextStyle(
                      color: _getStatusColor(_order.status),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Đặt hàng lúc: ${_formatDateTime(_order.orderDate)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
            if (_order.deliveryDate != null)
              Text(
                'Giao hàng dự kiến: ${_formatDateTime(_order.deliveryDate!)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItemsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Món đã đặt',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            ..._order.items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      // Product image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: item.food?.imagePath != null &&
                                item.food!.imagePath.isNotEmpty &&
                                item.food!.imagePath.startsWith('https://')
                            ? Image.network(
                                item.food!.imagePath,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildOrderItemImagePlaceholder(),
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .outline
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Center(
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2),
                                      ),
                                    ),
                                  );
                                },
                              )
                            : _buildOrderItemImagePlaceholder(),
                      ),
                      const SizedBox(width: 12),
                      // Product details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.food?.name ?? 'Món ăn',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Số lượng: ${item.quantity}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.outline,
                                  ),
                            ),
                            if (item.selectedAddons.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Thêm: ${item.selectedAddons.map((a) => a.name).join(', ')}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color:
                                          Theme.of(context).colorScheme.outline,
                                    ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Text(
                        CurrencyFormatter.formatTotal(item.totalPrice),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ],
                  ),
                )),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tổng cộng:',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  CurrencyFormatter.formatTotal(_order.totalAmount),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thông tin khách hàng',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.person, 'Họ tên', _order.customerName),
            _buildInfoRow(Icons.phone, 'Số điện thoại', _order.customerPhone),
            _buildInfoRow(
                Icons.location_on, 'Địa chỉ giao hàng', _order.deliveryAddress),
            if (_order.notes != null && _order.notes!.isNotEmpty)
              _buildInfoRow(Icons.note, 'Ghi chú', _order.notes!),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thông tin thanh toán',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
                Icons.payment, 'Phương thức', _order.paymentMethodDisplayText),
            _buildInfoRow(Icons.attach_money, 'Tổng tiền',
                CurrencyFormatter.formatTotal(_order.totalAmount)),
            if (_order.paymentDetails != null) ...[
              const SizedBox(height: 8),
              Text(
                'Chi tiết thanh toán:',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _order.paymentDetails!.entries
                      .map((e) => '${e.key}: ${e.value}')
                      .join('\n'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryInfoCard() {
    final hasShipperInfo =
        _order.deliveryPerson != null || _order.deliveryPersonPhone != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.delivery_dining,
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Thông tin giao hàng',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (hasShipperInfo) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primaryContainer
                      .withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_order.deliveryPerson != null)
                      _buildInfoRow(
                          Icons.person, 'Tên shipper', _order.deliveryPerson!),
                    if (_order.deliveryPerson != null &&
                        _order.deliveryPersonPhone != null)
                      const SizedBox(height: 8),
                    if (_order.deliveryPersonPhone != null)
                      _buildInfoRow(Icons.phone, 'SĐT shipper',
                          _order.deliveryPersonPhone!),
                  ],
                ),
              ),
              if (_order.trackingNumber != null ||
                  _order.deliveryTime != null ||
                  _order.deliveryDate != null)
                const SizedBox(height: 12),
            ],
            if (_order.trackingNumber != null)
              _buildInfoRow(
                  Icons.local_shipping, 'Mã theo dõi', _order.trackingNumber!),
            if (_order.deliveryDate != null)
              _buildInfoRow(Icons.calendar_today, 'Ngày giao hàng',
                  _formatDateTime(_order.deliveryDate!)),
            if (_order.deliveryTime != null)
              _buildInfoRow(
                  Icons.schedule, 'Thời gian giao', _order.deliveryTime!),
            if (!hasShipperInfo &&
                _order.trackingNumber == null &&
                _order.deliveryTime == null &&
                _order.deliveryDate == null)
              Text(
                'Chưa có thông tin giao hàng',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                      fontStyle: FontStyle.italic,
                    ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderTimelineCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tiến trình đơn hàng',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildTimelineItem(
              'Đặt hàng',
              'Đơn hàng đã được đặt thành công',
              _order.orderDate,
              true,
            ),
            if (_order.status.index >= order_model.OrderStatus.confirmed.index)
              _buildTimelineItem(
                'Xác nhận',
                'Đơn hàng đã được xác nhận',
                _order.orderDate.add(const Duration(minutes: 5)),
                true,
              ),
            if (_order.status.index >= order_model.OrderStatus.preparing.index)
              _buildTimelineItem(
                'Chuẩn bị',
                'Đang chuẩn bị món ăn',
                _order.orderDate.add(const Duration(minutes: 10)),
                true,
              ),
            if (_order.status.index >= order_model.OrderStatus.ready.index)
              _buildTimelineItem(
                'Sẵn sàng',
                'Món ăn đã sẵn sàng giao',
                _order.orderDate.add(const Duration(minutes: 20)),
                true,
              ),
            if (_order.status == order_model.OrderStatus.delivered)
              _buildTimelineItem(
                'Đã giao',
                'Đơn hàng đã được giao thành công',
                _order.deliveryDate ??
                    _order.orderDate.add(const Duration(minutes: 30)),
                true,
              ),
            if (_order.status == order_model.OrderStatus.cancelled)
              _buildTimelineItem(
                'Đã hủy',
                'Đơn hàng đã bị hủy',
                _order.orderDate.add(const Duration(minutes: 5)),
                true,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(
      String title, String description, DateTime date, bool isCompleted) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: isCompleted
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outline.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: isCompleted
                            ? Theme.of(context).colorScheme.onSurface
                            : Theme.of(context).colorScheme.outline,
                      ),
                ),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
                Text(
                  _formatDateTime(date),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                        fontSize: 11,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
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

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
  Widget _buildOrderItemImagePlaceholder() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.fastfood,
        color: Theme.of(context).colorScheme.outline,
        size: 30,
      ),
    );
  }
}
