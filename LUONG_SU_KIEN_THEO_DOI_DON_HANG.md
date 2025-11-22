# Luồng Sự Kiện Theo Dõi Đơn Hàng (User)

## Tổng Quan
Ứng dụng cho phép user theo dõi đơn hàng của mình với các tính năng:
1. **Xem danh sách đơn hàng** (Tất cả / Đang xử lý / Hoàn thành)
2. **Xem chi tiết đơn hàng** với real-time updates
3. **Hủy đơn hàng** (nếu đơn ở trạng thái có thể hủy)
4. **Cập nhật real-time** qua Firestore Stream

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
      ├── orderDate: timestamp
      └── ...
```

#### Các phương thức chính:

**a) `getUserOrders()`**
- Lấy danh sách đơn hàng của user hiện tại
- Query: `where('userId', isEqualTo: userId).orderBy('createdAt', descending: true)`
- Load food details cho từng item trong đơn hàng
- Trả về `Future<List<Order>>`

**b) `getUserOrdersStream()`**
- Trả về `Stream<List<Order>>` để theo dõi real-time
- Tự động cập nhật khi có thay đổi trong Firestore

**c) `getOrderById(String orderId)`**
- Lấy chi tiết một đơn hàng cụ thể
- Load đầy đủ food details cho items

**d) `getOrderByIdStream(String orderId)`**
- Trả về `Stream<Order?>` để theo dõi real-time một đơn hàng

**e) `cancelOrder(String orderId)`**
- Hủy đơn hàng (chỉ khi `order.canBeCancelled == true`)
- Cập nhật status thành `cancelled`

---

## Luồng Sự Kiện Chi Tiết

### Luồng 1: Mở Trang Theo Dõi Đơn Hàng

```
┌─────────────────────────────────────────────────────────────┐
│ 1. User mở OrderTrackingPage                                 │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. initState()                                               │
│    - Khởi tạo TabController (3 tabs)                        │
│    - Gọi restaurant.loadUserOrders()                         │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 3. Restaurant.loadUserOrders()                               │
│    - Gọi OrderService.getUserOrders()                        │
│    - Lưu vào _userOrders                                     │
│    - notifyListeners()                                       │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 4. OrderService.getUserOrders()                              │
│    - Query Firestore: where('userId', == currentUserId)      │
│    - orderBy('createdAt', descending: true)                  │
│    - Load food details cho từng item                         │
│    - Trả về List<Order>                                      │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 5. UI Render với StreamBuilder                               │
│    - Stream: restaurant.getUserOrdersStream()                │
│    - initialData: restaurant.userOrders (cached)             │
│    - Hiển thị 3 tabs:                                         │
│      • Tất cả (allOrders)                                    │
│      • Đang xử lý (activeOrders)                             │
│      • Hoàn thành (completedOrders)                          │
└─────────────────────────────────────────────────────────────┘
```

### Luồng 2: Xem Chi Tiết Đơn Hàng

```
┌─────────────────────────────────────────────────────────────┐
│ 1. User click "Xem chi tiết" trên OrderCard                 │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. _navigateToOrderDetail(order)                             │
│    - Navigator.push(OrderDetailPage(order: order))           │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 3. OrderDetailPage.initState()                               │
│    - Lưu order vào _order                                    │
│    - Gọi _listenToOrderUpdates()                             │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 4. _listenToOrderUpdates()                                   │
│    - Gọi OrderService.getOrderByIdStream(orderId)            │
│    - Lắng nghe Stream để cập nhật real-time                  │
│    - setState() khi có thay đổi                              │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 5. UI Hiển thị Chi Tiết                                      │
│    - Order Status Card (trạng thái + màu sắc)                │
│    - Order Items Card (danh sách món + số lượng)             │
│    - Customer Info Card (tên, SĐT, địa chỉ)                  │
│    - Payment Info Card (phương thức, tổng tiền)              │
│    - Delivery Info Card (shipper, tracking, thời gian)       │
│    - Order Timeline Card (tiến trình đơn hàng)                │
└─────────────────────────────────────────────────────────────┘
```

### Luồng 3: Hủy Đơn Hàng

```
┌─────────────────────────────────────────────────────────────┐
│ 1. User click "Hủy đơn" trên OrderCard hoặc OrderDetailPage │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. Kiểm tra order.canBeCancelled                             │
│    - Chỉ cho phép hủy khi:                                  │
│      • status == pending HOẶC                                │
│      • status == confirmed                                   │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 3. _showCancelDialog(order)                                   │
│    - Hiển thị AlertDialog xác nhận                          │
│    - "Bạn có chắc chắn muốn hủy đơn hàng #XXX?"             │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 4. User xác nhận "Có, hủy đơn hàng"                         │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 5. _cancelOrder(order)                                        │
│    - Gọi restaurant.cancelOrder(orderId)                     │
│    - Hoặc OrderService.cancelOrder(orderId)                  │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 6. OrderService.cancelOrder(orderId)                          │
│    - Update Firestore: status = 'cancelled'                 │
│    - updatedAt = FieldValue.serverTimestamp()                │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 7. Firestore Stream tự động cập nhật                         │
│    - getUserOrdersStream() emit data mới                    │
│    - getOrderByIdStream() emit order mới                     │
│    - UI tự động refresh                                       │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 8. Hiển thị SnackBar                                         │
│    - "Đã hủy đơn hàng thành công"                           │
└─────────────────────────────────────────────────────────────┘
```

### Luồng 4: Real-time Updates

```
┌─────────────────────────────────────────────────────────────┐
│ 1. Admin cập nhật trạng thái đơn hàng                        │
│    - Ví dụ: pending → confirmed → preparing → ready        │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. Firestore tự động emit change event                       │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 3. StreamBuilder trong OrderTrackingPage                     │
│    - Nhận data mới từ getUserOrdersStream()                  │
│    - Tự động rebuild UI                                      │
│    - Cập nhật badge số lượng đơn đang xử lý                  │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 4. StreamBuilder trong OrderDetailPage                       │
│    - Nhận data mới từ getOrderByIdStream()                   │
│    - Cập nhật trạng thái, timeline, delivery info           │
│    - setState() để refresh UI                                │
└─────────────────────────────────────────────────────────────┘
```

### Luồng 5: Pull to Refresh

```
┌─────────────────────────────────────────────────────────────┐
│ 1. User kéo xuống để refresh (Pull to Refresh)              │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. RefreshIndicator.onRefresh()                              │
│    - Gọi restaurant.loadUserOrders()                         │
│    - Reload data từ Firestore                                │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 3. UI tự động cập nhật với data mới                          │
└─────────────────────────────────────────────────────────────┘
```

---

## Các Trạng Thái Đơn Hàng

| Trạng thái | Mô tả | Màu sắc | Có thể hủy? |
|------------|-------|---------|-------------|
| `pending` | Chờ xác nhận | Orange | ✅ |
| `confirmed` | Đã xác nhận | Blue | ✅ |
| `preparing` | Đang chuẩn bị | Purple | ❌ |
| `ready` | Sẵn sàng giao | Green | ❌ |
| `delivered` | Đã giao | Green | ❌ |
| `cancelled` | Đã hủy | Red | ❌ |

---

## Các Component Chính

### 1. OrderTrackingPage
- **File:** `lib/pages/order_tracking_page.dart`
- **Chức năng:**
  - Hiển thị danh sách đơn hàng với 3 tabs
  - Pull to refresh
  - Navigate to OrderDetailPage
  - Hủy đơn hàng

### 2. OrderDetailPage
- **File:** `lib/pages/order_detail_page.dart`
- **Chức năng:**
  - Hiển thị chi tiết đơn hàng
  - Real-time updates qua Stream
  - Hủy đơn hàng
  - Refresh thủ công

### 3. OrderService
- **File:** `lib/services/order_service.dart`
- **Chức năng:**
  - Query orders từ Firestore
  - Stream orders real-time
  - Hủy đơn hàng
  - Load food details

### 4. Restaurant Model
- **File:** `lib/models/restaurant.dart`
- **Chức năng:**
  - Cache user orders
  - Wrapper cho OrderService
  - Notify listeners khi có thay đổi

---

## Tối Ưu Hóa

1. **Caching:** Sử dụng `initialData` trong StreamBuilder để hiển thị ngay cached data
2. **Lazy Loading:** Chỉ load food details khi cần thiết
3. **Real-time:** Sử dụng Firestore Stream để tự động cập nhật
4. **Error Handling:** Hiển thị error message và nút "Thử lại" khi có lỗi
5. **Loading States:** Hiển thị loading indicator khi đang fetch data

---

## Lưu Ý

- User chỉ có thể hủy đơn khi `status == pending || status == confirmed`
- Real-time updates hoạt động tự động qua Firestore Stream
- Order code format: `DH-YYYYMMDD-XXXX` (VD: DH-20240115-0001)
- Timeline hiển thị các bước đã hoàn thành dựa trên status hiện tại


