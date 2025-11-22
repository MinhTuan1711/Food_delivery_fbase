import 'package:intl/intl.dart';

class CurrencyFormatter {
  // Format currency to Vietnamese Dong with proper formatting
  static String formatVND(double amount) {
    // Format with thousand separators
    final formatter = NumberFormat('#,###', 'vi_VN');
    return '${formatter.format(amount.round())}đ';
  }
  
  // Format currency for display in food tiles and other UI components
  static String formatPrice(double price) {
    return formatVND(price);
  }
  
  // Format total amount for cart and payment
  static String formatTotal(double total) {
    return formatVND(total);
  }
}
