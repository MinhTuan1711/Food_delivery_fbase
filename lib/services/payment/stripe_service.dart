import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer' as developer;

/// Service xử lý thanh toán với Stripe Test Mode
/// 
/// Lưu ý: Service này sử dụng Stripe Test Mode, không dùng tiền thật
/// Cần setup Stripe publishable key và secret key trong environment
class StripeService {
  // Stripe publishable key (Test Mode)
  // Lấy từ: https://dashboard.stripe.com/test/apikeys
  // TODO: Thay bằng publishable key thật của bạn
  static const String _publishableKey = 'pk_test_51SRc65HlqwsH1NfxNbbNTqRCi8z7rRcf62F75NNuYlT5M6ZBdJu0VLoFeEXdWpAXZBkkuLXKruE0nCZLhl5gJsp300ybZ94sR7';
  
  // Backend URL để tạo Payment Intent
  // Firebase Cloud Function URL (sau khi deploy)
  // Format: https://{region}-{project-id}.cloudfunctions.net/{function-name}
  //static const String _backendUrl = 'https://us-central1-deliveryfood-7e554.cloudfunctions.net/createPaymentIntent';
  static const String _backendUrl = 'https://createpaymentintent-47kfepwoqq-uc.a.run.app';
  bool _initialized = false;

  /// Khởi tạo Stripe với publishable key
  Future<void> initialize() async {
    if (_initialized) return;
    
    Stripe.publishableKey = _publishableKey;
    await Stripe.instance.applySettings();
    _initialized = true;
  }

  /// Tạo Payment Intent từ backend
  /// 
  /// Trong production, bạn cần có backend server để tạo Payment Intent
  /// vì cần secret key (không được expose trong app)
  /// 
  /// Để test nhanh, có thể dùng Stripe CLI hoặc mock server
  Future<String> _createPaymentIntent({
    required double amount,
    required String currency,
  }) async {
    try {
      developer.log('Đang tạo Payment Intent: amount=$amount, currency=$currency', name: 'StripeService');
      developer.log('Backend URL: $_backendUrl', name: 'StripeService');
      
      // Gọi API backend để tạo Payment Intent
      final response = await http.post(
        Uri.parse(_backendUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'amount': amount, // Backend sẽ xử lý conversion sang cents
          'currency': currency.toLowerCase(),
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Kết nối backend quá lâu. Vui lòng kiểm tra kết nối internet và thử lại.');
        },
      );

      developer.log('Response status: ${response.statusCode}', name: 'StripeService');
      developer.log('Response body: ${response.body}', name: 'StripeService');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final clientSecret = data['clientSecret'] as String?;
        if (clientSecret == null || clientSecret.isEmpty) {
          developer.log('Backend không trả về clientSecret', name: 'StripeService', level: 1000);
          throw Exception('Backend không trả về clientSecret. Vui lòng kiểm tra cấu hình backend.');
        }
        developer.log('Payment Intent tạo thành công', name: 'StripeService');
        return clientSecret;
      } else {
        String errorMsg = 'Unknown error';
        try {
          final errorData = jsonDecode(response.body);
          errorMsg = errorData['message'] ?? errorData['error'] ?? 'Unknown error';
        } catch (_) {
          errorMsg = 'HTTP ${response.statusCode}: ${response.body}';
        }
        developer.log('Lỗi tạo Payment Intent: $errorMsg', name: 'StripeService', level: 1000);
        throw Exception('Không thể tạo Payment Intent: $errorMsg');
      }
    } on http.ClientException catch (e) {
      developer.log('Lỗi kết nối: $e', name: 'StripeService', level: 1000);
      throw Exception('Không thể kết nối đến backend. Vui lòng kiểm tra kết nối internet.\nLỗi: ${e.message}');
    } on FormatException catch (e) {
      developer.log('Lỗi định dạng response: $e', name: 'StripeService', level: 1000);
      throw Exception('Backend trả về dữ liệu không hợp lệ. Vui lòng kiểm tra cấu hình backend.');
    } catch (e) {
      developer.log('Lỗi không xác định: $e', name: 'StripeService', level: 1000);
      // Nếu không có backend, hướng dẫn user setup
      if (e.toString().contains('SocketException') || e.toString().contains('Failed host lookup')) {
        throw Exception('Không thể kết nối đến backend.\nVui lòng kiểm tra:\n1. Kết nối internet\n2. Backend đã được deploy chưa\n3. URL backend có đúng không');
      }
      throw Exception(
        'Lỗi tạo Payment Intent: $e\n\n'
        'Vui lòng kiểm tra:\n'
        '1. Backend đã được deploy và hoạt động\n'
        '2. Stripe secret key đã được cấu hình trong backend\n'
        '3. Xem hướng dẫn trong STRIPE_INTEGRATION_GUIDE.md'
      );
    }
  }

  /// Xử lý thanh toán với Stripe Payment Sheet
  /// 
  /// Sử dụng Stripe Payment Sheet - UI sẵn có của Stripe
  /// An toàn và tuân thủ PCI DSS
  Future<StripePaymentResult> processPayment({
    required double amount,
    required String currency,
  }) async {
    try {
      developer.log('Bắt đầu xử lý thanh toán Stripe: amount=$amount, currency=$currency', name: 'StripeService');
      
      // Đảm bảo Stripe đã được khởi tạo
      await initialize();
      developer.log('Stripe đã được khởi tạo', name: 'StripeService');

      // Tạo Payment Intent từ backend
      developer.log('Đang tạo Payment Intent từ backend...', name: 'StripeService');
      final clientSecret = await _createPaymentIntent(
        amount: amount,
        currency: currency,
      );
      developer.log('Payment Intent đã được tạo thành công', name: 'StripeService');

      // Khởi tạo Payment Sheet
      developer.log('Đang khởi tạo Payment Sheet...', name: 'StripeService');
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Food Delivery App',
          style: ThemeMode.system,
        ),
      );
      developer.log('Payment Sheet đã được khởi tạo', name: 'StripeService');

      // Hiển thị Payment Sheet
      developer.log('Đang hiển thị Payment Sheet...', name: 'StripeService');
      await Stripe.instance.presentPaymentSheet();
      developer.log('Payment Sheet đã được hiển thị và thanh toán thành công', name: 'StripeService');

      // Lấy Payment Intent ID từ client secret
      // Format: pi_xxx_secret_yyy -> pi_xxx
      final paymentIntentId = clientSecret.split('_secret_').first;

      // Thanh toán thành công
      return StripePaymentResult(
        success: true,
        paymentIntentId: paymentIntentId,
      );
    } on StripeException catch (e) {
      // Xử lý lỗi từ Stripe
      developer.log('StripeException: ${e.error.code} - ${e.error.message}', name: 'StripeService', level: 1000);
      
      String errorMessage = 'Thanh toán thất bại';
      
      switch (e.error.code) {
        case FailureCode.Canceled:
          errorMessage = 'Thanh toán đã bị hủy bởi người dùng';
          break;
        case FailureCode.Failed:
          errorMessage = 'Thanh toán thất bại: ${e.error.message ?? "Không xác định"}';
          break;
        case FailureCode.Timeout:
          errorMessage = 'Thanh toán hết thời gian chờ. Vui lòng thử lại.';
          break;
        default:
          errorMessage = 'Lỗi thanh toán Stripe: ${e.error.message ?? "Không xác định"}';
      }

      return StripePaymentResult(
        success: false,
        errorMessage: errorMessage,
      );
    } catch (e) {
      developer.log('Lỗi không xác định trong processPayment: $e', name: 'StripeService', level: 1000);
      return StripePaymentResult(
        success: false,
        errorMessage: 'Lỗi xử lý thanh toán: $e',
      );
    }
  }

  /// Xử lý thanh toán với thẻ tín dụng thủ công (Card Field)
  /// 
  /// Phương pháp này cho phép custom UI nhưng vẫn an toàn
  /// Vì Stripe xử lý thông tin thẻ, không gửi về server
  Future<StripePaymentResult> processPaymentWithCard({
    required double amount,
    required String currency,
    required CardFieldInputDetails cardDetails,
  }) async {
    try {
      await initialize();

      // Tạo Payment Intent
      final clientSecret = await _createPaymentIntent(
        amount: amount,
        currency: currency,
      );

      // Xác nhận thanh toán với thẻ
      // Lưu ý: Trong flutter_stripe 11.x, confirmPayment dùng named parameters
      await Stripe.instance.confirmPayment(
        paymentIntentClientSecret: clientSecret,
        data: PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(
            billingDetails: BillingDetails(
              // CardFieldInputDetails không có property name
              // Có thể bỏ qua hoặc lấy từ form khác
            ),
          ),
        ),
      );

      // Sau khi confirmPayment thành công, lấy payment intent từ client secret
      // Trong flutter_stripe 11.x, confirmPayment không trả về PaymentIntent
      // Nếu thành công (không throw exception), coi như đã thành công
      final paymentIntentId = clientSecret.split('_secret_').first;
      
      return StripePaymentResult(
        success: true,
        paymentIntentId: paymentIntentId,
      );
    } on StripeException catch (e) {
      return StripePaymentResult(
        success: false,
        errorMessage: e.error.message ?? 'Lỗi thanh toán',
      );
    } catch (e) {
      return StripePaymentResult(
        success: false,
        errorMessage: 'Lỗi: $e',
      );
    }
  }
}

/// Kết quả thanh toán Stripe
class StripePaymentResult {
  final bool success;
  final String? paymentIntentId;
  final String? errorMessage;

  StripePaymentResult({
    required this.success,
    this.paymentIntentId,
    this.errorMessage,
  });
}

