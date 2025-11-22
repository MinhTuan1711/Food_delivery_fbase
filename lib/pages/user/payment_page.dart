import 'package:flutter/material.dart';
import 'package:food_delivery_fbase/services/business/cart_service.dart';
import 'package:food_delivery_fbase/services/business/order_service.dart';
import 'package:food_delivery_fbase/services/business/user_service.dart';
import 'package:food_delivery_fbase/services/payment/payment_simulation_service.dart';
import 'package:food_delivery_fbase/services/payment/stripe_service.dart';
import 'package:food_delivery_fbase/models/cart_item.dart';
import 'package:food_delivery_fbase/models/order.dart' as order_model;
import 'package:food_delivery_fbase/models/user.dart';
import 'package:food_delivery_fbase/utils/currency_formatter.dart';
import 'package:food_delivery_fbase/pages/user/delivery_info_page.dart';
import 'package:food_delivery_fbase/pages/user/thank_you_page.dart';

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

enum PaymentMethod {
  cash,
  stripe,
}

class _PaymentPageState extends State<PaymentPage> {
  final CartService _cartService = CartService();
  final OrderService _orderService = OrderService();
  final UserService _userService = UserService();
  final PaymentSimulationService _paymentService = PaymentSimulationService();
  final StripeService _stripeService = StripeService();
  PaymentMethod _selectedPaymentMethod = PaymentMethod.cash;

  // Form controllers
  final _notesController = TextEditingController();

  List<CartItem> _cartItems = [];
  double _totalAmount = 0.0;
  bool _isLoading = true;
  bool _isProcessing = false;
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadCartData();
    // Khởi tạo Stripe khi trang được load
    _stripeService.initialize();
  }

  Future<void> _loadCartData() async {
    try {
      final selectedItems = await _cartService.getSelectedItems();
      final total = await _cartService.getSelectedItemsTotal();
      final user = await _userService.getCurrentUser();

      if (!mounted) return;
      setState(() {
        _cartItems = selectedItems;
        _totalAmount = total;
        _currentUser = user;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tải giỏ hàng: $e')),
      );
    }
  }

  Future<void> _processPayment() async {
    if (!_validateForm()) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      order_model.OrderPaymentMethod orderPaymentMethod;
      PaymentTransaction? paymentTransaction;

      // Xử lý thanh toán theo phương thức
      switch (_selectedPaymentMethod) {
        case PaymentMethod.stripe:
          orderPaymentMethod = order_model.OrderPaymentMethod.stripe;

          // Thanh toán với Stripe
          try {
            final stripeResult = await _stripeService.processPayment(
              amount: _totalAmount,
              currency: 'vnd',
            );

            if (!stripeResult.success) {
              final errorMsg =
                  stripeResult.errorMessage ?? 'Thanh toán thất bại';
              _showError(errorMsg);
              setState(() {
                _isProcessing = false;
              });
              return;
            }

            paymentTransaction = PaymentTransaction(
              transactionId: stripeResult.paymentIntentId ??
                  'STRIPE-${DateTime.now().millisecondsSinceEpoch}',
              result: PaymentResult.success,
              timestamp: DateTime.now(),
            );
          } catch (e) {
            // Xử lý lỗi nếu có exception không được catch trong service
            _showError('Lỗi thanh toán Stripe: $e');
            setState(() {
              _isProcessing = false;
            });
            return;
          }
          break;

        case PaymentMethod.cash:
          orderPaymentMethod = order_model.OrderPaymentMethod.cash;

          // Thanh toán tiền mặt (COD)
          paymentTransaction = await _paymentService.processCashPayment(
            amount: _totalAmount,
          );
          break;
      }

      // Kiểm tra kết quả thanh toán
      if (paymentTransaction == null) {
        throw Exception('Không thể xử lý thanh toán');
      }

      final transaction = paymentTransaction;
      if (transaction.result == PaymentResult.failure) {
        _showError(
          transaction.errorMessage ?? 'Thanh toán thất bại. Vui lòng thử lại.',
        );
        setState(() {
          _isProcessing = false;
        });
        return;
      }

      if (transaction.result == PaymentResult.pending) {
        if (!mounted) return;
        final shouldWait = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Thanh toán đang xử lý'),
            content: Text(transaction.errorMessage ?? 'Vui lòng chờ xác nhận'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Hủy'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Chờ xác nhận'),
              ),
            ],
          ),
        );

        if (shouldWait == true) {
          final updatedTransaction = await _paymentService.checkPendingPayment(
            transaction.transactionId,
          );

          if (updatedTransaction.result != PaymentResult.success) {
            _showError(
              updatedTransaction.errorMessage ?? 'Thanh toán không thành công',
            );
            setState(() {
              _isProcessing = false;
            });
            return;
          }
          paymentTransaction = updatedTransaction;
        } else {
          setState(() {
            _isProcessing = false;
          });
          return;
        }
      }

      // Thanh toán thành công - tạo đơn hàng
      final finalTransaction = paymentTransaction;
      final orderId = await _orderService.createOrderWithStockCheck(
        items: _cartItems,
        totalAmount: _totalAmount,
        paymentMethod: orderPaymentMethod,
        customerName: _currentUser?.deliveryName ?? 'Khách hàng',
        customerPhone: _currentUser?.deliveryPhone ?? '',
        deliveryAddress: _currentUser?.deliveryAddress ?? '',
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        transactionId: finalTransaction.transactionId,
      );

      // Xóa các món đã thanh toán khỏi giỏ hàng
      for (final item in _cartItems) {
        if (item.id != null) {
          try {
            await _cartService.removeFromCart(item.id!);
          } catch (e) {
            // Ignore errors when removing items from cart
          }
        }
      }

      // Lấy đơn hàng đã tạo để hiển thị trang cảm ơn
      final createdOrder = await _orderService.getOrderById(orderId);

      if (createdOrder != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ThankYouPage(order: createdOrder),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Thanh toán thành công! Mã đơn hàng: $orderId'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      String errorMessage = 'Lỗi thanh toán: $e';

      if (e.toString().contains('hết hàng') ||
          e.toString().contains('không đủ')) {
        errorMessage =
            'Sản phẩm đã hết hàng hoặc không đủ số lượng. Vui lòng kiểm tra lại giỏ hàng.';
      } else if (e.toString().contains('không tồn tại')) {
        errorMessage =
            'Một số sản phẩm không còn tồn tại. Vui lòng kiểm tra lại giỏ hàng.';
      } else if (e.toString().contains('network') ||
          e.toString().contains('connection')) {
        errorMessage = 'Lỗi kết nối. Vui lòng kiểm tra internet và thử lại.';
      }

      if (mounted) {
        _showError(errorMessage);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  bool _validateForm() {
    if (_currentUser?.deliveryName?.isEmpty ?? true) {
      _showError('Vui lòng cập nhật thông tin giao hàng');
      return false;
    }

    if (_currentUser?.deliveryPhone?.isEmpty ?? true) {
      _showError('Vui lòng cập nhật thông tin giao hàng');
      return false;
    }

    if (_currentUser?.deliveryAddress?.isEmpty ?? true) {
      _showError('Vui lòng cập nhật thông tin giao hàng');
      return false;
    }

    return true;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text("Thanh toán"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _cartItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shopping_cart_outlined,
                        size: 64,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Không có món nào được chọn',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Vui lòng quay lại giỏ hàng để chọn món muốn thanh toán',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Quay lại giỏ hàng'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildOrderSummary(),
                      const SizedBox(height: 20),
                      _buildCustomerInfo(),
                      const SizedBox(height: 20),
                      _buildPaymentMethodSelection(),
                      const SizedBox(height: 20),
                      _buildPaymentMethodDetails(),
                      const SizedBox(height: 20),
                      _buildPaymentButton(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildOrderSummary() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.receipt_long,
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Tóm tắt đơn hàng',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._cartItems.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          item.food?.imagePath ?? '',
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
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
                              child: Icon(
                                Icons.fastfood,
                                color: Theme.of(context).colorScheme.outline,
                                size: 30,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
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
            const Divider(height: 24),
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
                  CurrencyFormatter.formatTotal(_totalAmount),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.inversePrimary,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerInfo() {
    final hasDeliveryInfo = _currentUser?.deliveryName?.isNotEmpty == true &&
        _currentUser?.deliveryPhone?.isNotEmpty == true &&
        _currentUser?.deliveryAddress?.isNotEmpty == true;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: Theme.of(context).colorScheme.inversePrimary,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Thông tin giao hàng',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DeliveryInfoPage(),
                      ),
                    );
                    if (result == true) {
                      _loadCartData();
                    }
                  },
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Chỉnh sửa'),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.onSurface,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (hasDeliveryInfo) ...[
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
                    Row(
                      children: [
                        Icon(
                          Icons.person,
                          size: 20,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _currentUser?.deliveryName ?? '',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.phone,
                          size: 20,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _currentUser?.deliveryPhone ?? '',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 20,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _currentUser?.deliveryAddress ?? '',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .errorContainer
                      .withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.error.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.warning_amber,
                      color: Theme.of(context).colorScheme.error,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Chưa có thông tin giao hàng',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.error,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Vui lòng cập nhật thông tin giao hàng để tiếp tục',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.error,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const DeliveryInfoPage(),
                          ),
                        );
                        if (result == true) {
                          _loadCartData();
                        }
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Thêm thông tin giao hàng'),
                      style: TextButton.styleFrom(
                        foregroundColor:
                            Theme.of(context).colorScheme.inversePrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              enableIMEPersonalizedLearning: true,
              decoration: InputDecoration(
                labelText: 'Ghi chú (tùy chọn)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.note),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSelection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.payment,
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Phương thức thanh toán',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildPaymentMethodOption(
              method: PaymentMethod.cash,
              title: 'Tiền mặt',
              subtitle: 'Thanh toán khi nhận hàng (COD)',
              icon: Icons.money,
              color: Colors.green,
            ),
            const SizedBox(height: 8),
            _buildPaymentMethodOption(
              method: PaymentMethod.stripe,
              title: 'Stripe',
              subtitle: 'Thẻ tín dụng, thẻ ghi nợ',
              icon: Icons.credit_card,
              color: Colors.blue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodOption({
    required PaymentMethod method,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _selectedPaymentMethod == method;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = method;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(0.1)
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? color
                : Theme.of(context).colorScheme.outline.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                ],
              ),
            ),
            Radio<PaymentMethod>(
              value: method,
              groupValue: _selectedPaymentMethod,
              onChanged: (PaymentMethod? value) {
                setState(() {
                  _selectedPaymentMethod = value!;
                });
              },
              activeColor: color,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodDetails() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Thông tin thanh toán',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_selectedPaymentMethod == PaymentMethod.stripe) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue),
                ),
                child: Column(
                  children: [
                    Icon(Icons.credit_card, color: Colors.blue, size: 32),
                    const SizedBox(height: 8),
                    Text(
                      'Thanh toán bằng Stripe',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Nhập thông tin thẻ trong cửa sổ thanh toán Stripe khi nhấn nút "Thanh toán".',
                      style: TextStyle(color: Colors.blue.shade700),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Thẻ test Stripe:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Số thẻ: 4242 4242 4242 4242\n'
                            'Ngày hết hạn: Bất kỳ tương lai\n'
                            'CVV: Bất kỳ 3 số',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Bạn sẽ thanh toán bằng tiền mặt khi nhận hàng. Vui lòng chuẩn bị đúng số tiền.',
                        style: TextStyle(color: Colors.green.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isProcessing ? null : _processPayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: _isProcessing
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.payment, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Thanh toán ', //${CurrencyFormatter.formatTotal(_totalAmount)}
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
