# Luồng Sự Kiện Quản Lý Đơn Hàng (Admin)

## Tổng Quan
Ứng dụng cho phép admin quản lý đơn hàng với các tính năng:
1. **Xem danh sách đơn hàng** (real-time updates)
2. **Lọc đơn hàng theo trạng thái** (Tất cả / Chờ xác nhận / Đang chuẩn bị / Sẵn sàng / Đã giao)
3. **Tìm kiếm đơn hàng** (theo mã đơn, tên khách hàng, SĐT, mã tracking)
4. **Cập nhật trạng thái đơn hàng** (pending → confirmed → preparing → ready → delivered)
5. **Cập nhật thông tin giao hàng** (shipper, tracking number, ngày/giờ giao)
6. **Xem chi tiết đơn hàng**
7. **Pull to refresh**

## Kiến Trúc

### 1. Service Layer: `OrderService`
**File:** `lib/services/order_service.dart`

#### Cấu trúc dữ liệu Firestore:
```
orders/
  └── {orderId}/
      ├── userId: string
      ├── orderCode: string (VD: DH-20240115-0001)
      ├── items: array<CartItem>
      ├── totalAmount: number
      ├── status: string (pending/confirmed/preparing/ready/delivered/cancelled)
      ├── paymentMethod: string (cash/stripe)
      ├── customerName: string
      ├── customerPhone: string
      ├── deliveryAddress: string
      ├── deliveryPerson: string? (tên shipper)
      ├── deliveryPersonPhone: string? (SĐT shipper)
      ├── trackingNumber: string? (mã theo dõi)
      ├── deliveryDate: timestamp? (ngày giao hàng)
      ├── deliveryTime: string? (thời gian giao hàng)
      ├── orderDate: timestamp
      ├── createdAt: timestamp
      └── updatedAt: timestamp?
```

#### Các phương thức chính:

**a) `getAllOrders()`**
- Lấy tất cả đơn hàng (cho admin)
- Query: `collection('orders').get()`
- Sort theo `orderDate` (mới nhất trước)
- Load food details cho từng item trong đơn hàng
- Trả về `Future<List<Order>>`

**b) `getAllOrdersStream()`**
- Trả về `Stream<List<Order>>` để theo dõi real-time
- Tự động cập nhật khi có thay đổi trong Firestore
- Load food details cho từng item

**c) `updateOrderStatus(String orderId, OrderStatus newStatus)`**
- Cập nhật trạng thái đơn hàng
- Nếu chuyển sang `cancelled`, tự động hoàn lại số lượng sản phẩm
- Gửi thông báo cho user khi trạng thái thay đổi
- Update `updatedAt` timestamp

**d) `updateOrderDeliveryInfo({...})`**
- Cập nhật thông tin giao hàng:
  - deliveryPerson (tên shipper)
  - deliveryPersonPhone (SĐT shipper)
  - trackingNumber (mã theo dõi)
  - deliveryDate (ngày giao hàng)
  - deliveryTime (thời gian giao hàng)

**e) `searchOrders(String query)`**
- Tìm kiếm đơn hàng theo:
  - orderCode
  - orderId
  - customerName
  - customerPhone
  - trackingNumber
- Trả về `Future<List<Order>>`

### 2. Model Layer: `Restaurant`
**File:** `lib/models/restaurant.dart`

#### Các phương thức quản lý đơn hàng:

**a) `loadAllOrders()`**
- Load tất cả đơn hàng và cache vào `_allOrders`
- Gọi `OrderService.getAllOrders()`
- `notifyListeners()` để cập nhật UI

**b) `getAllOrdersStream()`**
- Wrapper cho `OrderService.getAllOrdersStream()`
- Trả về `Stream<List<Order>>`

**c) `updateOrderStatus(String orderId, OrderStatus newStatus)`**
- Wrapper cho `OrderService.updateOrderStatus()`
- Reload orders sau khi cập nhật

**d) `updateOrderDeliveryInfo({...})`**
- Wrapper cho `OrderService.updateOrderDeliveryInfo()`

**e) `searchOrders(String query)`**
- Wrapper cho `OrderService.searchOrders()`

**f) `updateOrdersList(List<Order> orders)`**
- Cập nhật danh sách đơn hàng (dùng cho kết quả tìm kiếm)
- `notifyListeners()` để cập nhật UI

---

## Luồng Sự Kiện Chi Tiết

### Luồng 1: Mở Trang Quản Lý Đơn Hàng

```
┌─────────────────────────────────────────────────────────────┐
│ 1. Admin mở AdminOrderManagementPage                        │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. initState()                                               │
│    - Khởi tạo TabController (5 tabs)                        │
│    - Khởi tạo SearchController                              │
│    - Gọi restaurant.loadAllOrders() (postFrameCallback)     │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 3. Restaurant.loadAllOrders()                                │
│    - Gọi OrderService.getAllOrders()                         │
│    - Lưu vào _allOrders                                      │
│    - notifyListeners()                                       │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 4. OrderService.getAllOrders()                              │
│    - Query Firestore: collection('orders').get()             │
│    - Sort theo orderDate (mới nhất trước)                     │
│    - Load food details cho từng item trong từng đơn hàng     │
│    - Trả về List<Order>                                       │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 5. UI Render với StreamBuilder                               │
│    - Stream: restaurant.getAllOrdersStream()                │
│    - initialData: restaurant.allOrders (cached)                │
│    - Hiển thị 5 tabs với số lượng:                           │
│      • Tất cả (allOrders.length)                            │
│      • Chờ xác nhận (pendingOrders.length)                   │
│      • Đang chuẩn bị (preparingOrders.length)                │
│      • Sẵn sàng (readyOrders.length)                         │
│      • Đã giao (deliveredOrders.length)                      │
└─────────────────────────────────────────────────────────────┘
```

### Luồng 2: Lọc Đơn Hàng Theo Trạng Thái

```
┌─────────────────────────────────────────────────────────────┐
│ 1. Admin chọn tab (Tất cả / Chờ xác nhận / ...)            │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. TabController thay đổi tab                               │
│    - TabBarView hiển thị tab tương ứng                       │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 3. _buildOrdersList(filteredOrders)                          │
│    - Lọc orders theo status:                                │
│      • Tab "Tất cả": allOrders                                │
│      • Tab "Chờ xác nhận": status == pending                 │
│      • Tab "Đang chuẩn bị": status == preparing               │
│      • Tab "Sẵn sàng": status == ready                       │
│      • Tab "Đã giao": status == delivered                     │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 4. UI hiển thị danh sách đơn hàng đã lọc                    │
│    - Mỗi đơn hàng hiển thị:                                  │
│      • Mã đơn hàng, trạng thái (badge màu)                   │
│      • Tên khách hàng, SĐT                                    │
│      • Ngày đặt, số lượng món, tổng tiền                      │
│      • Nút "Xem chi tiết" và "Cập nhật"                      │
└─────────────────────────────────────────────────────────────┘
```

### Luồng 3: Tìm Kiếm Đơn Hàng

```
┌─────────────────────────────────────────────────────────────┐
│ 1. Admin nhập từ khóa vào SearchBar                         │
│    - Có thể tìm theo: mã đơn, tên khách hàng, SĐT, ...      │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. onChanged() - setState(_searchQuery = value)              │
│    - Cập nhật UI (hiển thị nút Clear nếu có text)            │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 3. Admin nhấn Enter (onSubmitted)                           │
│    - Gọi _searchOrders()                                    │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 4. _searchOrders()                                           │
│    - Nếu query rỗng: reload all orders                       │
│    - Nếu có query:                                           │
│      • Gọi restaurant.searchOrders(query)                   │
│      • restaurant.updateOrdersList(results)                  │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 5. OrderService.searchOrders(query)                          │
│    - Lấy tất cả orders (getAllOrders)                        │
│    - Lọc theo:                                               │
│      • orderCode?.toLowerCase().contains(query)              │
│      • id?.toLowerCase().contains(query)                     │
│      • customerName.toLowerCase().contains(query)            │
│      • customerPhone.contains(query)                         │
│      • trackingNumber?.toLowerCase().contains(query)        │
│    - Trả về List<Order> đã lọc                                │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 6. Restaurant.updateOrdersList(results)                      │
│    - _allOrders = results                                    │
│    - notifyListeners()                                       │
│    - UI tự động cập nhật với kết quả tìm kiếm                │
└─────────────────────────────────────────────────────────────┘
```

### Luồng 4: Cập Nhật Trạng Thái Đơn Hàng

```
┌─────────────────────────────────────────────────────────────┐
│ 1. Admin click "Cập nhật" trên OrderCard                    │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. _showStatusUpdateDialog(order)                            │
│    - Hiển thị Dialog với form cập nhật                       │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 3. _OrderUpdateDialog                                        │
│    - Hiển thị RadioListTile cho các trạng thái:              │
│      • Chờ xác nhận (pending)                                │
│      • Đã xác nhận (confirmed)                                │
│      • Đang chuẩn bị (preparing)                             │
│      • Sẵn sàng giao (ready)                                  │
│      • Đã giao (delivered)                                    │
│      • Đã hủy (cancelled)                                     │
│    - Form nhập thông tin shipper (tùy chọn)                  │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 4. Admin chọn trạng thái mới và điền thông tin shipper       │
│    - _selectedStatus = newStatus                             │
│    - _shipperNameController, _shipperPhoneController, ...   │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 5. Admin click "Cập nhật"                                    │
│    - _updateOrder() được gọi                                 │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 6. _updateOrder()                                            │
│    - Nếu status thay đổi:                                    │
│      • restaurant.updateOrderStatus(orderId, newStatus)      │
│    - Nếu có thông tin giao hàng thay đổi:                    │
│      • restaurant.updateOrderDeliveryInfo(...)               │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 7. OrderService.updateOrderStatus()                           │
│    - Lấy trạng thái cũ (oldStatus)                           │
│    - Update Firestore: status = newStatus.name               │
│    - updatedAt = FieldValue.serverTimestamp()                │
│    - Nếu newStatus == cancelled:                             │
│      • Hoàn lại số lượng sản phẩm cho từng item               │
│    - Gửi thông báo cho user (nếu status thay đổi)            │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 8. OrderService.updateOrderDeliveryInfo()                    │
│    - Update Firestore với các field:                          │
│      • deliveryPerson                                        │
│      • deliveryPersonPhone                                   │
│      • trackingNumber                                        │
│      • deliveryDate                                          │
│      • deliveryTime                                          │
│    - updatedAt = FieldValue.serverTimestamp()                │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 9. Restaurant.loadAllOrders() (sau khi cập nhật)             │
│    - Reload tất cả orders để cập nhật cache                 │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 10. Firestore Stream tự động cập nhật                         │
│     - getAllOrdersStream() emit data mới                      │
│     - UI tự động refresh với trạng thái mới                   │
│     - Tab badges tự động cập nhật số lượng                    │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 11. Hiển thị SnackBar                                        │
│     - "Đã cập nhật đơn hàng thành công"                       │
└─────────────────────────────────────────────────────────────┘
```

### Luồng 5: Xem Chi Tiết Đơn Hàng

```
┌─────────────────────────────────────────────────────────────┐
│ 1. Admin click "Xem chi tiết" trên OrderCard                │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. _navigateToOrderDetail(order)                              │
│    - Navigator.push(OrderDetailPage(order: order))          │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 3. OrderDetailPage                                           │
│    - Hiển thị chi tiết đơn hàng:                             │
│      • Order Status Card (trạng thái + màu sắc)              │
│      • Order Items Card (danh sách món + số lượng)          │
│      • Customer Info Card (tên, SĐT, địa chỉ)                │
│      • Payment Info Card (phương thức, tổng tiền)            │
│      • Delivery Info Card (shipper, tracking, thời gian)      │
│      • Order Timeline Card (tiến trình đơn hàng)             │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 4. Khi quay về (Navigator.pop)                               │
│    - restaurant.loadAllOrders() (refresh orders)            │
└─────────────────────────────────────────────────────────────┘
```

### Luồng 6: Pull to Refresh

```
┌─────────────────────────────────────────────────────────────┐
│ 1. Admin kéo xuống để refresh (Pull to Refresh)            │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. RefreshIndicator.onRefresh()                              │
│    - Gọi restaurant.loadAllOrders()                          │
│    - Reload data từ Firestore                                │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 3. UI tự động cập nhật với data mới                          │
│    - Tab badges cập nhật số lượng                             │
│    - Danh sách đơn hàng refresh                               │
└─────────────────────────────────────────────────────────────┘
```

### Luồng 7: Real-time Updates

```
┌─────────────────────────────────────────────────────────────┐
│ 1. Admin khác cập nhật trạng thái đơn hàng                   │
│    HOẶC user đặt đơn hàng mới                                │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. Firestore tự động emit change event                        │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 3. StreamBuilder trong AdminOrderManagementPage               │
│    - Nhận data mới từ getAllOrdersStream()                   │
│    - Tự động rebuild UI                                      │
│    - Cập nhật tab badges (số lượng đơn hàng)                 │
│    - Cập nhật danh sách đơn hàng                              │
└─────────────────────────────────────────────────────────────┘
```

### Luồng 8: Hoàn Lại Số Lượng Khi Hủy Đơn

```
┌─────────────────────────────────────────────────────────────┐
│ 1. Admin cập nhật trạng thái đơn hàng → cancelled           │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. OrderService.updateOrderStatus()                          │
│    - Kiểm tra: oldStatus != cancelled && newStatus == cancelled│
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 3. Hoàn lại số lượng sản phẩm                                │
│    - Với mỗi item trong order.items:                          │
│      • FoodService.updateFoodQuantity(item.foodId, +item.quantity)│
│      • Tăng số lượng sản phẩm lên                             │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 4. Firestore tự động cập nhật                                 │
│    - foods/{foodId}.quantity được tăng lên                   │
│    - AdminProductManagementPage tự động refresh               │
└─────────────────────────────────────────────────────────────┘
```

---

## Các Trạng Thái Đơn Hàng

| Trạng thái | Mô tả | Màu sắc | Thứ tự |
|------------|-------|---------|--------|
| `pending` | Chờ xác nhận | Orange | 1 |
| `confirmed` | Đã xác nhận | Blue | 2 |
| `preparing` | Đang chuẩn bị | Purple | 3 |
| `ready` | Sẵn sàng giao | Green | 4 |
| `delivered` | Đã giao | Green | 5 |
| `cancelled` | Đã hủy | Red | - |

**Lưu ý:** Admin có thể chuyển đơn hàng sang bất kỳ trạng thái nào, không nhất thiết phải theo thứ tự.

---

## Các Component Chính

### 1. AdminOrderManagementPage
- **File:** `lib/pages/admin_order_management_page.dart`
- **Chức năng:**
  - Hiển thị danh sách đơn hàng với 5 tabs
  - Tìm kiếm đơn hàng
  - Navigate to OrderDetailPage
  - Cập nhật trạng thái và thông tin giao hàng
  - Pull to refresh

### 2. _OrderUpdateDialog
- **File:** `lib/pages/admin_order_management_page.dart` (nested class)
- **Chức năng:**
  - Dialog cập nhật trạng thái đơn hàng
  - Form nhập thông tin shipper (tên, SĐT, tracking, ngày/giờ giao)
  - Radio buttons để chọn trạng thái mới

### 3. OrderDetailPage
- **File:** `lib/pages/order_detail_page.dart`
- **Chức năng:**
  - Hiển thị chi tiết đơn hàng
  - Real-time updates qua Stream
  - Refresh thủ công

### 4. OrderService
- **File:** `lib/services/order_service.dart`
- **Chức năng:**
  - Query orders từ Firestore
  - Stream orders real-time
  - Cập nhật trạng thái và thông tin giao hàng
  - Tìm kiếm đơn hàng
  - Hoàn lại số lượng khi hủy đơn
  - Gửi thông báo cho user

### 5. Restaurant Model
- **File:** `lib/models/restaurant.dart`
- **Chức năng:**
  - Cache all orders (`_allOrders`)
  - Wrapper cho OrderService
  - Notify listeners khi có thay đổi
  - Cập nhật danh sách đơn hàng (cho tìm kiếm)

### 6. Order Model
- **File:** `lib/models/order.dart`
- **Chức năng:**
  - Model đại diện cho đơn hàng
  - Chứa: orderCode, items, status, customer info, delivery info, ...
  - `statusDisplayText`: text hiển thị trạng thái
  - `canBeCancelled`: kiểm tra có thể hủy không

---

## Tối Ưu Hóa

1. **Caching:** Sử dụng `initialData` trong StreamBuilder để hiển thị ngay cached data
2. **Lazy Loading:** Chỉ load food details khi cần thiết
3. **Real-time:** Sử dụng Firestore Stream để tự động cập nhật
4. **Error Handling:** Hiển thị error message và nút "Thử lại" khi có lỗi
5. **Loading States:** Hiển thị loading indicator khi đang fetch data
6. **Search Optimization:** Cache kết quả tìm kiếm trong Restaurant model

---

## Lưu Ý

- Admin có thể chuyển đơn hàng sang bất kỳ trạng thái nào, không cần theo thứ tự
- Khi hủy đơn hàng (cancelled), số lượng sản phẩm sẽ được hoàn lại tự động
- Real-time updates hoạt động tự động qua Firestore Stream
- Order code format: `DH-YYYYMMDD-XXXX` (VD: DH-20240115-0001)
- Tab badges hiển thị số lượng đơn hàng theo từng trạng thái
- Thông tin shipper là tùy chọn, có thể để trống
- Khi cập nhật trạng thái, hệ thống tự động gửi thông báo cho user
- Tìm kiếm không phân biệt hoa thường, tìm theo nhiều trường

