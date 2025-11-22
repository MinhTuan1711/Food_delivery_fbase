# Luồng Sự Kiện Thêm Sản Phẩm Yêu Thích

## Tổng Quan
Ứng dụng cho phép người dùng thêm/xóa sản phẩm yêu thích từ 2 vị trí:
1. **FoodTile** (danh sách món ăn trên HomePage)
2. **FoodPage** (trang chi tiết món ăn)

## Kiến Trúc

### 1. Service Layer: `FavoriteService`
**File:** `lib/services/favorite_service.dart`

#### Cấu trúc dữ liệu Firestore:
```
user_favorites/
  └── {userId}/
      └── favorites/
          └── {foodId}/
              ├── foodId: string
              └── addedAt: timestamp
```

#### Các phương thức chính:

**a) `addToFavorites(String foodId)`**
- Kiểm tra user đã đăng nhập
- Kiểm tra sản phẩm đã có trong yêu thích chưa
- Nếu chưa có → Thêm vào Firestore với timestamp
- Nếu đã có → Không làm gì (idempotent)

**b) `removeFromFavorites(String foodId)`**
- Xóa document khỏi collection favorites

**c) `toggleFavorite(String foodId)`**
- Kiểm tra trạng thái hiện tại (`isFavorite`)
- Nếu đã yêu thích → Gọi `removeFromFavorites`
- Nếu chưa yêu thích → Gọi `addToFavorites`

**d) `isFavoriteStream(String foodId)`**
- Trả về Stream<bool> để theo dõi trạng thái real-time
- Sử dụng Firestore snapshots để tự động cập nhật UI

---

## Luồng Sự Kiện Chi Tiết

### Luồng 1: Thêm từ FoodTile (HomePage)

```
┌─────────────────────────────────────────────────────────────┐
│ 1. User nhấn nút yêu thích trên FoodTile                    │
│    Location: lib/components/my_food_tile.dart:296          │
└─────────────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────────┐
│ 2. _FavoriteButton.onPressed được trigger                  │
│    - Set _isToggling = true (disable button)                │
│    - Hiển thị loading state                                 │
└─────────────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────────┐
│ 3. Gọi FavoriteService.toggleFavorite(foodId)              │
│    Location: lib/services/favorite_service.dart:61          │
└─────────────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────────┐
│ 4. Kiểm tra trạng thái hiện tại                             │
│    - Gọi isFavorite(foodId)                                 │
│    - Query Firestore: user_favorites/{userId}/favorites/    │
│      {foodId}                                               │
└─────────────────────────────────────────────────────────────┘
                        ↓
        ┌───────────────┴───────────────┐
        │                               │
   Đã yêu thích                    Chưa yêu thích
        │                               │
        ↓                               ↓
┌──────────────────┐          ┌──────────────────┐
│ removeFromFavorites│          │ addToFavorites   │
│ - Xóa document   │          │ - Kiểm tra đã có?│
│   khỏi Firestore │          │ - Nếu chưa:      │
└──────────────────┘          │   + Tạo document │
                              │   + Set foodId   │
                              │   + Set addedAt  │
                              └──────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────────┐
│ 5. Firestore tự động cập nhật                               │
│    - Document được thêm/xóa                                 │
│    - isFavoriteStream() tự động emit giá trị mới            │
└─────────────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────────┐
│ 6. StreamBuilder trong _FavoriteButton rebuild               │
│    - Nhận giá trị mới từ isFavoriteStream                   │
│    - Cập nhật icon: favorite ↔ favorite_border              │
│    - Cập nhật màu: red ↔ onSurfaceVariant                   │
└─────────────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────────┐
│ 7. Hiển thị SnackBar thông báo                              │
│    - "Đã thêm vào món yêu thích"                            │
│    - hoặc "Đã xóa khỏi món yêu thích"                       │
│    - Duration: 1 giây                                       │
└─────────────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────────┐
│ 8. Set _isToggling = false                                  │
│    - Enable lại button                                      │
│    - Hoàn tất luồng                                         │
└─────────────────────────────────────────────────────────────┘
```

### Luồng 2: Thêm từ FoodPage

```
┌─────────────────────────────────────────────────────────────┐
│ 1. User nhấn nút yêu thích trên AppBar của FoodPage         │
│    Location: lib/pages/food_page.dart:117                    │
└─────────────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────────┐
│ 2. onPressed handler được trigger                           │
│    - Set _isTogglingFavorite = true                         │
│    - Disable button                                          │
└─────────────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────────┐
│ 3. Gọi FavoriteService.toggleFavorite(foodId)               │
│    (Tương tự như luồng 1, bước 3-5)                        │
└─────────────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────────┐
│ 4. StreamBuilder cập nhật icon và màu                       │
│    Location: lib/pages/food_page.dart:106-116                │
└─────────────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────────┐
│ 5. Hiển thị SnackBar                                        │
│    - Thông báo thành công/loại bỏ                           │
└─────────────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────────┐
│ 6. Set _isTogglingFavorite = false                          │
│    - Hoàn tất                                               │
└─────────────────────────────────────────────────────────────┘
```

---

## Các Tính Năng Bổ Sung

### 1. Real-time Updates
- Sử dụng `StreamBuilder` với `isFavoriteStream()`
- UI tự động cập nhật khi trạng thái thay đổi (kể cả từ thiết bị khác)
- Không cần refresh thủ công

### 2. Loading States
- Disable button khi đang xử lý (`_isToggling`, `_isTogglingFavorite`)
- Tránh double-click và duplicate requests

### 3. Error Handling
- Try-catch trong mọi async operations
- Hiển thị SnackBar khi có lỗi
- Graceful fallback nếu user chưa đăng nhập

### 4. Authentication Check
- Chỉ hiển thị nút yêu thích khi user đã đăng nhập
- `FirebaseAuth.instance.currentUser != null`

### 5. Idempotent Operations
- `addToFavorites()` kiểm tra document đã tồn tại trước khi thêm
- Tránh duplicate entries

---

## Các Component Liên Quan

### 1. `_FavoriteButton` (lib/components/my_food_tile.dart:268)
- Widget riêng biệt để hiển thị nút yêu thích
- Sử dụng StreamBuilder để theo dõi trạng thái
- Tự quản lý state loading

### 2. `FoodPage` (lib/pages/food_page.dart)
- Có nút yêu thích trên AppBar
- Sử dụng cùng FavoriteService
- Có state riêng `_isTogglingFavorite`

### 3. `FavoritesPage` (lib/pages/favorites_page.dart)
- Hiển thị danh sách món yêu thích
- Sử dụng `getFavoriteFoodsStream()` để real-time updates
- Tự động cập nhật khi có thay đổi

---

## Security Rules (Firestore)

```javascript
match /user_favorites/{userId}/favorites/{foodId} {
  // User chỉ có thể đọc/ghi favorites của chính mình
  allow read, write: if request.auth != null && 
                        request.auth.uid == userId;
}
```

---

## Data Flow Diagram

```
┌─────────────┐
│   UI Layer  │
│ (FoodTile/  │
│  FoodPage)  │
└──────┬──────┘
       │ User Action
       ↓
┌──────────────────┐
│ FavoriteService  │
│  - toggleFavorite │
│  - addToFavorites │
│  - removeFrom...  │
└──────┬───────────┘
       │
       ↓
┌──────────────────┐
│   Firestore      │
│ user_favorites/   │
│  {userId}/        │
│  favorites/       │
│   {foodId}        │
└──────┬───────────┘
       │
       ↓ (Stream)
┌──────────────────┐
│ StreamBuilder     │
│  - isFavoriteStream│
│  - Auto Update UI │
└───────────────────┘
```

---

## Lưu Ý Kỹ Thuật

1. **State Management**: Sử dụng local state (`setState`) kết hợp với StreamBuilder
2. **Async Operations**: Tất cả operations đều async, có error handling
3. **Real-time Sync**: Firestore snapshots đảm bảo đồng bộ real-time
4. **User Experience**: Loading states, snackbars, và tooltips
5. **Performance**: Chỉ query document cần thiết, không load toàn bộ collection






