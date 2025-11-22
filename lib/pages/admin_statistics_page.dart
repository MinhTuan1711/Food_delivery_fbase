import 'package:flutter/material.dart';
import 'package:food_delivery_fbase/services/statistics_service.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class AdminStatisticsPage extends StatefulWidget {
  const AdminStatisticsPage({super.key});

  @override
  State<AdminStatisticsPage> createState() => _AdminStatisticsPageState();
}

class _AdminStatisticsPageState extends State<AdminStatisticsPage> {
  final StatisticsService _statisticsService = StatisticsService();
  int _selectedPeriod = 0; // 0: Ngày, 1: Tháng
  bool _isLoading = true;

  // Dữ liệu thống kê
  double _revenue = 0.0;
  Map<String, int> _ordersCount = {'completed': 0, 'cancelled': 0, 'pending': 0};
  int _soldItems = 0;
  int _totalSoldProducts = 0;
  int _totalInventory = 0;
  List<Map<String, dynamic>> _revenueChartData = [];

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final now = DateTime.now();
      double revenue;
      Map<String, int> ordersCount;
      int soldItems;
      List<Map<String, dynamic>> chartData;

      switch (_selectedPeriod) {
        case 0: // Ngày
          revenue = await _statisticsService.getDailyRevenue(now);
          ordersCount = await _statisticsService.getDailyOrdersCount(now);
          soldItems = await _statisticsService.getDailySoldItems(now);
          chartData = await _statisticsService.getWeeklyRevenueData();
          break;
        case 1: // Tháng
          revenue = await _statisticsService.getMonthlyRevenue(now);
          ordersCount = await _statisticsService.getMonthlyOrdersCount(now);
          soldItems = await _statisticsService.getMonthlySoldItems(now);
          chartData = await _statisticsService.getYearlyRevenueData();
          break;
        default:
          revenue = 0.0;
          ordersCount = {'completed': 0, 'cancelled': 0, 'pending': 0};
          soldItems = 0;
          chartData = [];
      }

      // Lấy số lượng sản phẩm đã bán và tồn kho (không phụ thuộc vào khoảng thời gian)
      final totalSoldProducts = await _statisticsService.getTotalSoldProducts();
      final totalInventory = await _statisticsService.getTotalInventory();

      setState(() {
        _revenue = revenue;
        _ordersCount = ordersCount;
        _soldItems = soldItems;
        _totalSoldProducts = totalSoldProducts;
        _totalInventory = totalInventory;
        _revenueChartData = chartData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi tải dữ liệu: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('Thống kê'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.background,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStatistics,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Chọn khoảng thời gian
                    _buildPeriodSelector(),
                    const SizedBox(height: 24),
                    
                    // Thẻ doanh thu
                    _buildRevenueCard(),
                    const SizedBox(height: 16),
                    
                    // Thẻ số đơn hàng
                    _buildOrdersCard(),
                    const SizedBox(height: 16),
                    
                    // Thẻ số món đã bán
                    _buildSoldItemsCard(),
                    const SizedBox(height: 16),
                    
                    // Thẻ số lượng sản phẩm đã bán
                    _buildSoldProductsCard(),
                    const SizedBox(height: 16),
                    
                    // Thẻ số lượng tồn kho
                    _buildInventoryCard(),
                    const SizedBox(height: 16),
                    
                    // Biểu đồ doanh thu
                    _buildRevenueChart(),
                    const SizedBox(height: 16),
                    
                    // Biểu đồ trạng thái đơn hàng
                    _buildOrdersStatusChart(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildPeriodButton('Ngày', 0),
          ),
          Expanded(
            child: _buildPeriodButton('Tháng', 1),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String label, int index) {
    final isSelected = _selectedPeriod == index;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedPeriod = index;
        });
        _loadStatistics();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildRevenueCard() {
    final periodLabel = ['Hôm nay', 'Tháng này'][_selectedPeriod];
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.attach_money,
                  color: Colors.green,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Doanh thu $periodLabel',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _formatCurrency(_revenue),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersCard() {
    final periodLabel = ['Hôm nay', 'Tháng này'][_selectedPeriod];
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.shopping_bag,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Đơn hàng $periodLabel',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildOrderStatusItem(
                  'Hoàn thành',
                  _ordersCount['completed'] ?? 0,
                  Colors.green,
                ),
                _buildOrderStatusItem(
                  'Đang chờ',
                  _ordersCount['pending'] ?? 0,
                  Colors.orange,
                ),
                _buildOrderStatusItem(
                  'Đã hủy',
                  _ordersCount['cancelled'] ?? 0,
                  Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderStatusItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildSoldItemsCard() {
    final periodLabel = ['Hôm nay', 'Tháng này'][_selectedPeriod];
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.restaurant,
                  color: Colors.blue,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Món đã bán $periodLabel',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _soldItems.toString(),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueChart() {
    if (_revenueChartData.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Biểu đồ doanh thu',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            _formatCurrency(value),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 &&
                              value.toInt() < _revenueChartData.length) {
                            return Text(
                              _revenueChartData[value.toInt()]['label'],
                              style: const TextStyle(fontSize: 10),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _revenueChartData.asMap().entries.map((entry) {
                        return FlSpot(
                          entry.key.toDouble(),
                          entry.value['revenue'] as double,
                        );
                      }).toList(),
                      isCurved: true,
                      color: Colors.green,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.green.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersStatusChart() {
    final total = _ordersCount['completed']! +
        _ordersCount['pending']! +
        _ordersCount['cancelled']!;
    
    if (total == 0) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Phân bố trạng thái đơn hàng',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      value: _ordersCount['completed']!.toDouble(),
                      title: '${_ordersCount['completed']}\nHoàn thành',
                      color: Colors.green,
                      radius: 80,
                    ),
                    PieChartSectionData(
                      value: _ordersCount['pending']!.toDouble(),
                      title: '${_ordersCount['pending']}\nĐang chờ',
                      color: Colors.orange,
                      radius: 80,
                    ),
                    PieChartSectionData(
                      value: _ordersCount['cancelled']!.toDouble(),
                      title: '${_ordersCount['cancelled']}\nĐã hủy',
                      color: Colors.red,
                      radius: 80,
                    ),
                  ],
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSoldProductsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.shopping_cart,
                  color: Colors.purple,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Sản phẩm đã bán',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _totalSoldProducts.toString(),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.purple,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tổng số lượng sản phẩm đã bán từ tất cả đơn hàng',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.inventory_2,
                  color: Colors.teal,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Tồn kho',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _totalInventory.toString(),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.teal,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tổng số lượng sản phẩm hiện có trong kho',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }
}

