import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:food_delivery_fbase/models/order.dart' as order_model;

class StatisticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference _ordersCollection = FirebaseFirestore.instance.collection('orders');
  final CollectionReference _foodsCollection = FirebaseFirestore.instance.collection('foods');

  // Lấy doanh thu theo khoảng thời gian
  Future<double> getRevenueByDateRange(DateTime startDate, DateTime endDate) async {
    try {
      final querySnapshot = await _ordersCollection
          .where('orderDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('orderDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      double totalRevenue = 0.0;
      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final status = data['status'] as String?;
        // Chỉ tính doanh thu từ đơn hàng đã giao
        if (status == order_model.OrderStatus.delivered.name) {
          totalRevenue += (data['totalAmount'] ?? 0.0).toDouble();
        }
      }
      return totalRevenue;
    } catch (e) {
      throw Exception('Failed to get revenue: $e');
    }
  }

  // Lấy doanh thu theo ngày
  Future<double> getDailyRevenue(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return await getRevenueByDateRange(startOfDay, endOfDay);
  }

  // Lấy doanh thu theo tuần
  Future<double> getWeeklyRevenue(DateTime date) async {
    // Lấy thứ 2 của tuần
    final weekday = date.weekday;
    final startOfWeek = date.subtract(Duration(days: weekday - 1));
    final startOfWeekDay = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    final endOfWeekDay = startOfWeekDay.add(const Duration(days: 7));
    return await getRevenueByDateRange(startOfWeekDay, endOfWeekDay);
  }

  // Lấy doanh thu theo tháng
  Future<double> getMonthlyRevenue(DateTime date) async {
    final startOfMonth = DateTime(date.year, date.month, 1);
    final endOfMonth = DateTime(date.year, date.month + 1, 1);
    return await getRevenueByDateRange(startOfMonth, endOfMonth);
  }

  // Lấy số đơn hàng theo trạng thái trong khoảng thời gian
  Future<Map<String, int>> getOrdersCountByStatus(DateTime startDate, DateTime endDate) async {
    try {
      final querySnapshot = await _ordersCollection
          .where('orderDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('orderDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      int completed = 0;
      int cancelled = 0;
      int pending = 0;

      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final status = data['status'] as String?;
        
        if (status == order_model.OrderStatus.delivered.name) {
          completed++;
        } else if (status == order_model.OrderStatus.cancelled.name) {
          cancelled++;
        } else if (status == order_model.OrderStatus.pending.name ||
                   status == order_model.OrderStatus.confirmed.name ||
                   status == order_model.OrderStatus.preparing.name ||
                   status == order_model.OrderStatus.ready.name) {
          pending++;
        }
      }

      return {
        'completed': completed,
        'cancelled': cancelled,
        'pending': pending,
      };
    } catch (e) {
      throw Exception('Failed to get orders count: $e');
    }
  }

  // Lấy số đơn hàng theo ngày
  Future<Map<String, int>> getDailyOrdersCount(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return await getOrdersCountByStatus(startOfDay, endOfDay);
  }

  // Lấy số đơn hàng theo tuần
  Future<Map<String, int>> getWeeklyOrdersCount(DateTime date) async {
    final weekday = date.weekday;
    final startOfWeek = date.subtract(Duration(days: weekday - 1));
    final startOfWeekDay = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    final endOfWeekDay = startOfWeekDay.add(const Duration(days: 7));
    return await getOrdersCountByStatus(startOfWeekDay, endOfWeekDay);
  }

  // Lấy số đơn hàng theo tháng
  Future<Map<String, int>> getMonthlyOrdersCount(DateTime date) async {
    final startOfMonth = DateTime(date.year, date.month, 1);
    final endOfMonth = DateTime(date.year, date.month + 1, 1);
    return await getOrdersCountByStatus(startOfMonth, endOfMonth);
  }

  // Lấy số món đã bán trong khoảng thời gian
  Future<int> getSoldItemsCount(DateTime startDate, DateTime endDate) async {
    try {
      final querySnapshot = await _ordersCollection
          .where('orderDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('orderDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      int totalItems = 0;
      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final status = data['status'] as String?;
        // Chỉ tính món từ đơn hàng đã giao
        if (status == order_model.OrderStatus.delivered.name) {
          final items = data['items'] as List<dynamic>? ?? [];
          for (var item in items) {
            final itemMap = item as Map<String, dynamic>;
            totalItems += (itemMap['quantity'] ?? 1) as int;
          }
        }
      }
      return totalItems;
    } catch (e) {
      throw Exception('Failed to get sold items count: $e');
    }
  }

  // Lấy số món đã bán theo ngày
  Future<int> getDailySoldItems(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return await getSoldItemsCount(startOfDay, endOfDay);
  }

  // Lấy số món đã bán theo tuần
  Future<int> getWeeklySoldItems(DateTime date) async {
    final weekday = date.weekday;
    final startOfWeek = date.subtract(Duration(days: weekday - 1));
    final startOfWeekDay = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    final endOfWeekDay = startOfWeekDay.add(const Duration(days: 7));
    return await getSoldItemsCount(startOfWeekDay, endOfWeekDay);
  }

  // Lấy số món đã bán theo tháng
  Future<int> getMonthlySoldItems(DateTime date) async {
    final startOfMonth = DateTime(date.year, date.month, 1);
    final endOfMonth = DateTime(date.year, date.month + 1, 1);
    return await getSoldItemsCount(startOfMonth, endOfMonth);
  }

  // Lấy dữ liệu doanh thu theo ngày trong tuần (7 ngày gần nhất)
  Future<List<Map<String, dynamic>>> getWeeklyRevenueData() async {
    final now = DateTime.now();
    final List<Map<String, dynamic>> data = [];
    
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final revenue = await getDailyRevenue(date);
      data.add({
        'date': date,
        'revenue': revenue,
        'label': _formatDateLabel(date),
      });
    }
    return data;
  }

  // Lấy dữ liệu doanh thu theo tuần trong tháng (4 tuần gần nhất)
  Future<List<Map<String, dynamic>>> getMonthlyRevenueData() async {
    final now = DateTime.now();
    final List<Map<String, dynamic>> data = [];
    
    for (int i = 3; i >= 0; i--) {
      final weekStart = now.subtract(Duration(days: i * 7));
      final revenue = await getWeeklyRevenue(weekStart);
      data.add({
        'date': weekStart,
        'revenue': revenue,
        'label': 'Tuần ${4 - i}',
      });
    }
    return data;
  }

  // Lấy dữ liệu doanh thu theo tháng trong năm (12 tháng gần nhất)
  Future<List<Map<String, dynamic>>> getYearlyRevenueData() async {
    final now = DateTime.now();
    final List<Map<String, dynamic>> data = [];
    
    for (int i = 11; i >= 0; i--) {
      int targetMonth = now.month - i;
      int targetYear = now.year;
      
      // Xử lý trường hợp tháng âm (lùi về năm trước)
      while (targetMonth <= 0) {
        targetMonth += 12;
        targetYear -= 1;
      }
      
      final month = DateTime(targetYear, targetMonth, 1);
      final revenue = await getMonthlyRevenue(month);
      data.add({
        'date': month,
        'revenue': revenue,
        'label': _formatMonthLabel(month),
      });
    }
    return data;
  }

  String _formatDateLabel(DateTime date) {
    final weekdays = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
    return '${date.day}/${date.month}';
  }

  String _formatMonthLabel(DateTime date) {
    return 'T${date.month}/${date.year}';
  }

  // Lấy tổng số lượng tồn kho của tất cả sản phẩm
  Future<int> getTotalInventory() async {
    try {
      final querySnapshot = await _foodsCollection.get();
      int totalInventory = 0;
      
      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final quantity = data['quantity'] ?? 0;
        totalInventory += (quantity as num).toInt();
      }
      
      return totalInventory;
    } catch (e) {
      throw Exception('Failed to get total inventory: $e');
    }
  }

  // Lấy tổng số lượng sản phẩm đã bán (từ tất cả đơn hàng đã giao)
  Future<int> getTotalSoldProducts() async {
    try {
      final querySnapshot = await _ordersCollection.get();
      int totalSold = 0;
      
      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final status = data['status'] as String?;
        // Chỉ tính từ đơn hàng đã giao
        if (status == order_model.OrderStatus.delivered.name) {
          final items = data['items'] as List<dynamic>? ?? [];
          for (var item in items) {
            final itemMap = item as Map<String, dynamic>;
            totalSold += (itemMap['quantity'] ?? 1) as int;
          }
        }
      }
      
      return totalSold;
    } catch (e) {
      throw Exception('Failed to get total sold products: $e');
    }
  }
}

