import 'dart:math';

/// Kết quả thanh toán
enum PaymentResult {
  success,    // Thanh toán thành công
  failure,    // Thanh toán thất bại
  pending,    // Thanh toán đang xử lý
}

/// Thông tin giao dịch
class PaymentTransaction {
  final String transactionId;
  final PaymentResult result;
  final String? errorMessage;
  final DateTime timestamp;

  PaymentTransaction({
    required this.transactionId,
    required this.result,
    this.errorMessage,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'transactionId': transactionId,
      'result': result.name,
      'errorMessage': errorMessage,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

/// Service mô phỏng thanh toán (không dùng tiền thật)
/// Đảm bảo logic thanh toán đầy đủ: validation, xử lý các trường hợp, transaction ID
class PaymentSimulationService {
  // Random generator để tạo transaction ID và mô phỏng lỗi
  final Random _random = Random();

  /// Validate số thẻ tín dụng (Luhn algorithm)
  bool _validateCardNumber(String cardNumber) {
    // Loại bỏ khoảng trắng và dấu gạch ngang
    final cleaned = cardNumber.replaceAll(RegExp(r'[\s-]'), '');
    
    // Kiểm tra chỉ chứa số và độ dài hợp lệ (13-19 số)
    if (!RegExp(r'^\d{13,19}$').hasMatch(cleaned)) {
      return false;
    }

    // Luhn algorithm
    int sum = 0;
    bool alternate = false;
    
    for (int i = cleaned.length - 1; i >= 0; i--) {
      int digit = int.parse(cleaned[i]);
      
      if (alternate) {
        digit *= 2;
        if (digit > 9) {
          digit -= 9;
        }
      }
      
      sum += digit;
      alternate = !alternate;
    }
    
    return sum % 10 == 0;
  }

  /// Validate CVV (3-4 số)
  bool _validateCVV(String cvv) {
    return RegExp(r'^\d{3,4}$').hasMatch(cvv.trim());
  }

  /// Validate expiry date (MM/YY)
  bool _validateExpiry(String expiry) {
    final match = RegExp(r'^(\d{2})/(\d{2})$').firstMatch(expiry.trim());
    if (match == null) return false;

    final month = int.tryParse(match.group(1) ?? '');
    final year = int.tryParse(match.group(2) ?? '');

    if (month == null || year == null) return false;
    if (month < 1 || month > 12) return false;

    // Kiểm tra thẻ chưa hết hạn
    final now = DateTime.now();
    final currentYear = now.year % 100;
    final currentMonth = now.month;

    if (year < currentYear) return false;
    if (year == currentYear && month < currentMonth) return false;

    return true;
  }

  /// Validate số điện thoại Việt Nam
  bool _validatePhoneNumber(String phone) {
    // Loại bỏ khoảng trắng và dấu +, -
    final cleaned = phone.replaceAll(RegExp(r'[\s+-]'), '');
    
    // Format: 0xxxxxxxxx (10 số) hoặc 84xxxxxxxxx (11 số)
    return RegExp(r'^(0|84)\d{9,10}$').hasMatch(cleaned);
  }

  /// Validate thông tin thanh toán
  Map<String, dynamic> validatePaymentInfo({
    required String? cardNumber,
    required String? cvv,
    required String? expiry,
    required String? cardName,
    String? phoneNumber,
  }) {
    final errors = <String>[];

    // Validate số thẻ
    if (cardNumber == null || cardNumber.trim().isEmpty) {
      errors.add('Số thẻ không được để trống');
    } else if (!_validateCardNumber(cardNumber)) {
      errors.add('Số thẻ không hợp lệ');
    }

    // Validate CVV
    if (cvv == null || cvv.trim().isEmpty) {
      errors.add('CVV không được để trống');
    } else if (!_validateCVV(cvv)) {
      errors.add('CVV phải có 3-4 chữ số');
    }

    // Validate expiry
    if (expiry == null || expiry.trim().isEmpty) {
      errors.add('Ngày hết hạn không được để trống');
    } else if (!_validateExpiry(expiry)) {
      errors.add('Ngày hết hạn không hợp lệ hoặc đã hết hạn');
    }

    // Validate tên trên thẻ
    if (cardName == null || cardName.trim().isEmpty) {
      errors.add('Tên trên thẻ không được để trống');
    } else if (cardName.trim().length < 2) {
      errors.add('Tên trên thẻ phải có ít nhất 2 ký tự');
    }

    // Validate số điện thoại (nếu có)
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      if (!_validatePhoneNumber(phoneNumber)) {
        errors.add('Số điện thoại không hợp lệ');
      }
    }

    return {
      'isValid': errors.isEmpty,
      'errors': errors,
    };
  }

  /// Tạo transaction ID ngẫu nhiên
  String _generateTransactionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = _random.nextInt(10000).toString().padLeft(4, '0');
    return 'TXN-$timestamp-$random';
  }

  /// Mô phỏng thanh toán
  /// 
  /// Logic mô phỏng:
  /// - 85% thành công
  /// - 10% thất bại (lỗi thẻ, tài khoản không đủ tiền, v.v.)
  /// - 5% pending (cần xử lý sau)
  Future<PaymentTransaction> processPayment({
    required double amount,
    String? cardNumber,
    String? cvv,
    String? expiry,
    String? cardName,
    String? phoneNumber,
  }) async {
    // Validate thông tin thanh toán
    final validation = validatePaymentInfo(
      cardNumber: cardNumber,
      cvv: cvv,
      expiry: expiry,
      cardName: cardName,
      phoneNumber: phoneNumber,
    );

    if (!validation['isValid']) {
      return PaymentTransaction(
        transactionId: _generateTransactionId(),
        result: PaymentResult.failure,
        errorMessage: validation['errors'].join(', '),
        timestamp: DateTime.now(),
      );
    }

    // Mô phỏng thời gian xử lý thanh toán (1-3 giây)
    final processingTime = 1 + _random.nextDouble() * 2;
    await Future.delayed(Duration(milliseconds: (processingTime * 1000).toInt()));

    // Mô phỏng kết quả thanh toán
    final randomValue = _random.nextDouble();
    final transactionId = _generateTransactionId();

    if (randomValue < 0.85) {
      // 85% thành công
      return PaymentTransaction(
        transactionId: transactionId,
        result: PaymentResult.success,
        timestamp: DateTime.now(),
      );
    } else if (randomValue < 0.95) {
      // 10% thất bại
      final errorMessages = [
        'Thẻ không đủ hạn mức',
        'Tài khoản không đủ số dư',
        'Thẻ đã bị khóa',
        'Giao dịch bị từ chối bởi ngân hàng',
        'Thông tin thẻ không chính xác',
      ];
      final errorMessage = errorMessages[_random.nextInt(errorMessages.length)];

      return PaymentTransaction(
        transactionId: transactionId,
        result: PaymentResult.failure,
        errorMessage: errorMessage,
        timestamp: DateTime.now(),
      );
    } else {
      // 5% pending
      return PaymentTransaction(
        transactionId: transactionId,
        result: PaymentResult.pending,
        errorMessage: 'Giao dịch đang được xử lý, vui lòng chờ xác nhận',
        timestamp: DateTime.now(),
      );
    }
  }

  /// Mô phỏng thanh toán tiền mặt (COD - Cash on Delivery)
  /// Luôn thành công vì thanh toán khi nhận hàng
  Future<PaymentTransaction> processCashPayment({
    required double amount,
  }) async {
    // Mô phỏng thời gian xử lý ngắn (0.5-1 giây)
    await Future.delayed(Duration(milliseconds: 500 + _random.nextInt(500)));

    return PaymentTransaction(
      transactionId: _generateTransactionId(),
      result: PaymentResult.success,
      timestamp: DateTime.now(),
    );
  }

  /// Kiểm tra trạng thái thanh toán pending (mô phỏng)
  Future<PaymentTransaction> checkPendingPayment(String transactionId) async {
    // Mô phỏng thời gian kiểm tra
    await Future.delayed(const Duration(seconds: 1));

    // 80% sẽ thành công sau khi pending
    if (_random.nextDouble() < 0.8) {
      return PaymentTransaction(
        transactionId: transactionId,
        result: PaymentResult.success,
        timestamp: DateTime.now(),
      );
    } else {
      return PaymentTransaction(
        transactionId: transactionId,
        result: PaymentResult.failure,
        errorMessage: 'Thanh toán đã hết hạn hoặc bị từ chối',
        timestamp: DateTime.now(),
      );
    }
  }
}

