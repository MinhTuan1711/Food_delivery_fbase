# Luồng Sự Kiện Xem Thống Kê (Admin)

## Tổng Quan
Ứng dụng cho phép admin xem thống kê với các tính năng:
1. **Xem doanh thu** (theo ngày/tháng)
2. **Xem số đơn hàng** (hoàn thành/đang chờ/đã hủy)
3. **Xem số món đã bán** (theo khoảng thời gian)
4. **Xem số lượng sản phẩm đã bán** (tổng từ tất cả đơn hàng)
5. **Xem tồn kho** (tổng số lượng sản phẩm hiện có)
6. **Xem biểu đồ doanh thu** (line chart)
7. **Xem biểu đồ trạng thái đơn hàng** (pie chart)
8. **Chọn khoảng thời gian** (Ngày/Tháng)
9. **Pull to refresh**

## Kiến Trúc

### 1. Service Layer: `StatisticsService`
**File:** `lib/services/statistics_service.dart`

#### Cấu trúc dữ liệu Firestore:
```
orders/
  └── {orderId}/
      ├── orderDate: timestamp
      ├── status: string (pending/confirmed/preparing/ready/delivered/cancelled)
      ├── totalAmount: number
      └── items: array<CartItem>
          └── quantity: number

foods/
  └── {foodId}/
      └── quantity: number (tồn kho)
```

#### Các phương thức chính:

**a) Doanh thu:**
- `getRevenueByDateRange(DateTime startDate, DateTime endDate)`
  - Lấy doanh thu trong khoảng thời gian
  - Chỉ tính từ đơn hàng có `status == delivered`
  - Trả về `Future<double>`
- `getDailyRevenue(DateTime date)` - Doanh thu theo ngày
- `getMonthlyRevenue(DateTime date)` - Doanh thu theo tháng

**b) Số đơn hàng:**
- `getOrdersCountByStatus(DateTime startDate, DateTime endDate)`
  - Đếm đơn hàng theo trạng thái trong khoảng thời gian
  - Phân loại: `completed` (delivered), `cancelled`, `pending` (pending/confirmed/preparing/ready)
  - Trả về `Future<Map<String, int>>`
- `getDailyOrdersCount(DateTime date)` - Số đơn hàng theo ngày
- `getMonthlyOrdersCount(DateTime date)` - Số đơn hàng theo tháng

**c) Số món đã bán:**
- `getSoldItemsCount(DateTime startDate, DateTime endDate)`
  - Đếm tổng số lượng món đã bán trong khoảng thời gian
  - Chỉ tính từ đơn hàng có `status == delivered`
  - Trả về `Future<int>`
- `getDailySoldItems(DateTime date)` - Số món đã bán theo ngày
- `getMonthlySoldItems(DateTime date)` - Số món đã bán theo tháng

**d) Dữ liệu biểu đồ:**
- `getWeeklyRevenueData()`
  - Lấy doanh thu 7 ngày gần nhất
  - Trả về `Future<List<Map<String, dynamic>>>`
  - Format: `[{date, revenue, label}, ...]`
- `getMonthlyRevenueData()`
  - Lấy doanh thu 4 tuần gần nhất
  - Trả về `Future<List<Map<String, dynamic>>>`
- `getYearlyRevenueData()`
  - Lấy doanh thu 12 tháng gần nhất
  - Trả về `Future<List<Map<String, dynamic>>>`

**e) Tồn kho và sản phẩm:**
- `getTotalInventory()`
  - Lấy tổng số lượng tồn kho của tất cả sản phẩm
  - Query tất cả documents trong collection `foods`
  - Tính tổng `quantity` của tất cả sản phẩm
  - Trả về `Future<int>`
- `getTotalSoldProducts()`
  - Lấy tổng số lượng sản phẩm đã bán (từ tất cả đơn hàng đã giao)
  - Chỉ tính từ đơn hàng có `status == delivered`
  - Trả về `Future<int>`

### 2. UI Layer: `AdminStatisticsPage`
**File:** `lib/pages/admin_statistics_page.dart`

#### Các component chính:
- **Period Selector**: Chọn khoảng thời gian (Ngày/Tháng)
- **Revenue Card**: Hiển thị doanh thu
- **Orders Card**: Hiển thị số đơn hàng (hoàn thành/đang chờ/đã hủy)
- **Sold Items Card**: Hiển thị số món đã bán
- **Sold Products Card**: Hiển thị tổng số lượng sản phẩm đã bán
- **Inventory Card**: Hiển thị tổng tồn kho
- **Revenue Chart**: Biểu đồ đường doanh thu (LineChart)
- **Orders Status Chart**: Biểu đồ tròn trạng thái đơn hàng (PieChart)

---

## Luồng Sự Kiện Chi Tiết

### Luồng 1: Mở Trang Thống Kê

```
┌─────────────────────────────────────────────────────────────┐
│ 1. Admin mở AdminStatisticsPage                               │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. initState()                                               │
│    - Khởi tạo _selectedPeriod = 0 (Ngày)                    │
│    - _isLoading = true                                       │
│    - Gọi _loadStatistics()                                   │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 3. _loadStatistics()                                         │
│    - setState(_isLoading = true)                              │
│    - Xác định khoảng thời gian dựa trên _selectedPeriod:      │
│      • 0: Ngày (hôm nay)                                     │
│      • 1: Tháng (tháng này)                                   │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 4. Gọi StatisticsService theo khoảng thời gian              │
│    - getDailyRevenue(now) / getMonthlyRevenue(now)            │
│    - getDailyOrdersCount(now) / getMonthlyOrdersCount(now)    │
│    - getDailySoldItems(now) / getMonthlySoldItems(now)        │
│    - getWeeklyRevenueData() / getYearlyRevenueData()          │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 5. StatisticsService thực hiện query Firestore                │
│    - Query orders collection với điều kiện:                   │
│      • orderDate >= startDate                                 │
│      • orderDate <= endDate                                   │
│    - Lọc đơn hàng có status == delivered (cho doanh thu)     │
│    - Tính toán và trả về kết quả                              │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 6. Lấy dữ liệu không phụ thuộc thời gian                      │
│    - getTotalSoldProducts() (tất cả đơn hàng đã giao)        │
│    - getTotalInventory() (tất cả sản phẩm)                    │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 7. setState() - Cập nhật UI                                  │
│    - _revenue = revenue                                       │
│    - _ordersCount = ordersCount                               │
│    - _soldItems = soldItems                                   │
│    - _totalSoldProducts = totalSoldProducts                   │
│    - _totalInventory = totalInventory                        │
│    - _revenueChartData = chartData                           │
│    - _isLoading = false                                       │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 8. UI Render                                                  │
│    - Hiển thị Period Selector (Ngày/Tháng)                    │
│    - Hiển thị Revenue Card                                    │
│    - Hiển thị Orders Card (3 số liệu)                         │
│    - Hiển thị Sold Items Card                                 │
│    - Hiển thị Sold Products Card                              │
│    - Hiển thị Inventory Card                                  │
│    - Hiển thị Revenue Chart (LineChart)                       │
│    - Hiển thị Orders Status Chart (PieChart)                  │
└─────────────────────────────────────────────────────────────┘
```

### Luồng 2: Chọn Khoảng Thời Gian

```
┌─────────────────────────────────────────────────────────────┐
│ 1. Admin click nút "Ngày" / "Tháng"                          │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. _buildPeriodButton() - onTap()                            │
│    - setState(_selectedPeriod = index)                       │
│    - Gọi _loadStatistics()                                   │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 3. _loadStatistics() - Xác định khoảng thời gian mới         │
│    - switch (_selectedPeriod):                                │
│      • case 0: Ngày                                          │
│        - getDailyRevenue(now)                                │
│        - getDailyOrdersCount(now)                             │
│        - getDailySoldItems(now)                               │
│        - getWeeklyRevenueData() (biểu đồ 7 ngày)              │
│      • case 1: Tháng                                          │
│        - getMonthlyRevenue(now)                               │
│        - getMonthlyOrdersCount(now)                            │
│        - getMonthlySoldItems(now)                             │
│        - getYearlyRevenueData() (biểu đồ 12 tháng)            │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 4. StatisticsService tính toán theo khoảng thời gian mới     │
│    - Tính startDate và endDate                                │
│    - Query Firestore với điều kiện mới                       │
│    - Trả về kết quả                                           │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 5. setState() - Cập nhật UI với dữ liệu mới                  │
│    - Cập nhật tất cả cards                                    │
│    - Cập nhật biểu đồ với dữ liệu mới                         │
└─────────────────────────────────────────────────────────────┘
```

### Luồng 3: Tính Doanh Thu

```
┌─────────────────────────────────────────────────────────────┐
│ 1. StatisticsService.getDailyRevenue(date)                   │
│    - Tính startOfDay và endOfDay                              │
│    - Gọi getRevenueByDateRange(startOfDay, endOfDay)         │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. StatisticsService.getRevenueByDateRange()                  │
│    - Query Firestore:                                         │
│      • collection('orders')                                   │
│      • where('orderDate', >= startDate)                       │
│      • where('orderDate', <= endDate)                         │
│      • get()                                                   │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 3. Lọc và tính toán                                           │
│    - Duyệt qua từng document                                  │
│    - Kiểm tra status == 'delivered'                           │
│    - Cộng dồn totalAmount vào totalRevenue                    │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 4. Trả về totalRevenue (double)                               │
└─────────────────────────────────────────────────────────────┘
```

### Luồng 4: Tính Số Đơn Hàng Theo Trạng Thái

```
┌─────────────────────────────────────────────────────────────┐
│ 1. StatisticsService.getDailyOrdersCount(date)                │
│    - Tính startOfDay và endOfDay                              │
│    - Gọi getOrdersCountByStatus(startOfDay, endOfDay)         │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. StatisticsService.getOrdersCountByStatus()                │
│    - Query Firestore:                                         │
│      • collection('orders')                                   │
│      • where('orderDate', >= startDate)                       │
│      • where('orderDate', <= endDate)                         │
│      • get()                                                   │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 3. Phân loại đơn hàng theo trạng thái                         │
│    - Duyệt qua từng document                                  │
│    - Kiểm tra status:                                         │
│      • 'delivered' → completed++                               │
│      • 'cancelled' → cancelled++                              │
│      • 'pending'/'confirmed'/'preparing'/'ready' → pending++   │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 4. Trả về Map<String, int>                                    │
│    {                                                           │
│      'completed': completed,                                  │
│      'cancelled': cancelled,                                   │
│      'pending': pending                                        │
│    }                                                           │
└─────────────────────────────────────────────────────────────┘
```

### Luồng 5: Tính Số Món Đã Bán

```
┌─────────────────────────────────────────────────────────────┐
│ 1. StatisticsService.getDailySoldItems(date)                  │
│    - Tính startOfDay và endOfDay                              │
│    - Gọi getSoldItemsCount(startOfDay, endOfDay)              │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. StatisticsService.getSoldItemsCount()                      │
│    - Query Firestore:                                         │
│      • collection('orders')                                   │
│      • where('orderDate', >= startDate)                       │
│      • where('orderDate', <= endDate)                         │
│      • get()                                                   │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 3. Đếm số lượng món                                           │
│    - Duyệt qua từng document                                  │
│    - Kiểm tra status == 'delivered'                           │
│    - Duyệt qua items array                                    │
│    - Cộng dồn quantity của từng item vào totalItems          │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 4. Trả về totalItems (int)                                    │
└─────────────────────────────────────────────────────────────┘
```

### Luồng 6: Lấy Dữ Liệu Biểu Đồ Doanh Thu

```
┌─────────────────────────────────────────────────────────────┐
│ 1. StatisticsService.getWeeklyRevenueData()                   │
│    - Lấy doanh thu 7 ngày gần nhất                            │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. Vòng lặp 7 ngày (từ 6 ngày trước đến hôm nay)            │
│    - for (i = 6; i >= 0; i--):                                │
│      • date = now.subtract(Duration(days: i))                │
│      • revenue = await getDailyRevenue(date)                   │
│      • data.add({date, revenue, label})                       │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 3. Trả về List<Map<String, dynamic>>                         │
│    [                                                           │
│      {date: DateTime, revenue: double, label: 'DD/MM'},        │
│      ...                                                       │
│    ]                                                           │
└─────────────────────────────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 4. UI Render LineChart                                        │
│    - Sử dụng fl_chart package                                 │
│    - Vẽ đường doanh thu với các điểm dữ liệu                  │
│    - Hiển thị label trên trục X (ngày)                        │
│    - Hiển thị giá trị trên trục Y (doanh thu)                 │
└─────────────────────────────────────────────────────────────┘
```

### Luồng 7: Lấy Tổng Tồn Kho

```
┌─────────────────────────────────────────────────────────────┐
│ 1. StatisticsService.getTotalInventory()                      │
│    - Query Firestore: collection('foods').get()               │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. Tính tổng quantity                                         │
│    - Duyệt qua từng document                                  │
│    - Lấy quantity từ data                                    │
│    - Cộng dồn vào totalInventory                             │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 3. Trả về totalInventory (int)                                │
└─────────────────────────────────────────────────────────────┘
```

### Luồng 8: Lấy Tổng Sản Phẩm Đã Bán

```
┌─────────────────────────────────────────────────────────────┐
│ 1. StatisticsService.getTotalSoldProducts()                   │
│    - Query Firestore: collection('orders').get()              │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. Đếm số lượng sản phẩm từ đơn hàng đã giao                 │
│    - Duyệt qua từng document                                  │
│    - Kiểm tra status == 'delivered'                           │
│    - Duyệt qua items array                                    │
│    - Cộng dồn quantity của từng item vào totalSold          │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 3. Trả về totalSold (int)                                     │
└─────────────────────────────────────────────────────────────┘
```

### Luồng 9: Hiển Thị Biểu Đồ Trạng Thái Đơn Hàng

```
┌─────────────────────────────────────────────────────────────┐
│ 1. _buildOrdersStatusChart()                                  │
│    - Tính total = completed + pending + cancelled            │
│    - Nếu total == 0: không hiển thị                           │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. Tạo PieChart với 3 sections                                │
│    - PieChartSectionData:                                     │
│      • completed: value, title, color (green)                │
│      • pending: value, title, color (orange)                  │
│      • cancelled: value, title, color (red)                   │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 3. UI Render PieChart                                         │
│    - Sử dụng fl_chart package                                 │
│    - Hiển thị 3 phần với màu sắc và số liệu                   │
└─────────────────────────────────────────────────────────────┘
```

### Luồng 10: Pull to Refresh

```
┌─────────────────────────────────────────────────────────────┐
│ 1. Admin kéo xuống để refresh (Pull to Refresh)            │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. RefreshIndicator.onRefresh()                             │
│    - Gọi _loadStatistics()                                    │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 3. _loadStatistics() - Reload tất cả dữ liệu                  │
│    - Query lại Firestore                                      │
│    - Tính toán lại các chỉ số                                 │
│    - Cập nhật UI                                               │
└─────────────────────────────────────────────────────────────┘
```

---

## Các Khoảng Thời Gian

| Khoảng thời gian | Mô tả | Biểu đồ |
|------------------|-------|---------|
| **Ngày** | Hôm nay (00:00 - 23:59) | 7 ngày gần nhất |
| **Tháng** | Tháng này (từ ngày 1 đến cuối tháng) | 12 tháng gần nhất |

---

## Các Chỉ Số Thống Kê

### 1. Doanh thu
- **Nguồn dữ liệu**: Đơn hàng có `status == delivered`
- **Công thức**: Tổng `totalAmount` của các đơn hàng đã giao
- **Hiển thị**: Format tiền tệ (₫)

### 2. Số đơn hàng
- **Phân loại**:
  - **Hoàn thành** (`completed`): `status == delivered`
  - **Đang chờ** (`pending`): `status == pending/confirmed/preparing/ready`
  - **Đã hủy** (`cancelled`): `status == cancelled`

### 3. Số món đã bán
- **Nguồn dữ liệu**: Đơn hàng có `status == delivered`
- **Công thức**: Tổng `quantity` của tất cả items trong các đơn hàng đã giao

### 4. Số lượng sản phẩm đã bán
- **Nguồn dữ liệu**: Tất cả đơn hàng có `status == delivered` (không phụ thuộc khoảng thời gian)
- **Công thức**: Tổng `quantity` của tất cả items trong tất cả đơn hàng đã giao

### 5. Tồn kho
- **Nguồn dữ liệu**: Collection `foods` (không phụ thuộc khoảng thời gian)
- **Công thức**: Tổng `quantity` của tất cả sản phẩm

---

## Các Component Chính

### 1. AdminStatisticsPage
- **File:** `lib/pages/admin_statistics_page.dart`
- **Chức năng:**
  - Hiển thị tất cả các chỉ số thống kê
  - Chọn khoảng thời gian (Ngày/Tháng)
  - Hiển thị biểu đồ doanh thu và trạng thái đơn hàng
  - Pull to refresh

### 2. StatisticsService
- **File:** `lib/services/statistics_service.dart`
- **Chức năng:**
  - Query và tính toán các chỉ số thống kê từ Firestore
  - Xử lý các khoảng thời gian (ngày/tháng)
  - Lấy dữ liệu cho biểu đồ

### 3. Biểu Đồ
- **Revenue Chart (LineChart)**:
  - Sử dụng `fl_chart` package
  - Hiển thị xu hướng doanh thu theo thời gian
  - Có thể zoom và tương tác
  
- **Orders Status Chart (PieChart)**:
  - Sử dụng `fl_chart` package
  - Hiển thị phân bố trạng thái đơn hàng
  - Màu sắc: Green (hoàn thành), Orange (đang chờ), Red (đã hủy)

---

## Tối Ưu Hóa

1. **Caching**: Có thể cache dữ liệu thống kê để giảm số lần query Firestore
2. **Lazy Loading**: Chỉ load dữ liệu khi cần thiết
3. **Error Handling**: Hiển thị error message khi có lỗi
4. **Loading States**: Hiển thị loading indicator khi đang fetch data
5. **Pull to Refresh**: Cho phép admin refresh dữ liệu thủ công

---

## Lưu Ý

- **Doanh thu chỉ tính từ đơn hàng đã giao** (`status == delivered`)
- **Số món đã bán chỉ tính từ đơn hàng đã giao**
- **Tháng được tính từ ngày 1 đến cuối tháng**
- **Tồn kho và sản phẩm đã bán không phụ thuộc vào khoảng thời gian** (tính tổng từ tất cả dữ liệu)
- **Biểu đồ doanh thu hiển thị dữ liệu theo khoảng thời gian lớn hơn** (ngày → 7 ngày, tháng → 12 tháng)
- **Format tiền tệ**: Sử dụng `NumberFormat.currency` với locale `vi_VN` và symbol `₫`

