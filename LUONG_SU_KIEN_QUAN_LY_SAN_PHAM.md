# Luồng Sự Kiện Quản Lý Sản Phẩm (Admin)

## Tổng Quan
Ứng dụng cho phép admin quản lý sản phẩm với các tính năng:
1. **Xem danh sách sản phẩm** (real-time updates)
2. **Tìm kiếm sản phẩm** (theo tên, mô tả)
3. **Lọc theo danh mục** (Miền Bắc / Miền Trung / Miền Nam)
4. **Thêm sản phẩm mới** (với upload ảnh, quản lý add-ons)
5. **Sửa sản phẩm** (cập nhật thông tin, thay đổi ảnh, quản lý add-ons)
6. **Xóa sản phẩm**
7. **Quản lý add-ons** (thêm, sửa, xóa)

## Kiến Trúc

### 1. Service Layer: `FoodService`
**File:** `lib/services/food_service.dart`

#### Cấu trúc dữ liệu Firestore:
```
foods/
  └── {foodId}/
      ├── name: string
      ├── description: string
      ├── imagePath: string (URL từ Firebase Storage)
      ├── price: number
      ├── category: string (bac/trung/nam)
      ├── availableAddons: array<Addon>
      ├── quantity: number
      ├── createdAt: timestamp
      └── updatedAt: timestamp?
```

#### Các phương thức chính:

**a) `getFoods()`**
- Trả về `Stream<List<Food>>` để theo dõi real-time
- Query: `collection('foods').orderBy('createdAt', descending: true)`
- Tự động cập nhật khi có thay đổi trong Firestore

**b) `addFood(Food food)`**
- Thêm sản phẩm mới vào Firestore
- Trả về `Future<String>` (document ID)

**c) `updateFood(Food food)`**
- Cập nhật thông tin sản phẩm
- Update `updatedAt` timestamp

**d) `deleteFood(String foodId)`**
- Xóa sản phẩm khỏi Firestore

**e) `updateFoodQuantity(String foodId, int quantityChange)`**
- Cập nhật số lượng sản phẩm (tăng/giảm)

### 2. Service Layer: `ImageService`
**File:** `lib/services/image_service.dart`

#### Các phương thức chính:

**a) `pickImageFromGallery()`**
- Chọn ảnh từ thư viện
- Resize: max 1024x1024, quality 80%

**b) `pickImageFromCamera()`**
- Chụp ảnh từ camera
- Resize: max 1024x1024, quality 80%

**c) `uploadImageToFirebase(File imageFile, String fileName)`**
- Upload ảnh lên Firebase Storage
- Path: `food_images/{fileName}`
- Trả về download URL

**d) `deleteImageFromFirebase(String imageUrl)`**
- Xóa ảnh khỏi Firebase Storage

**e) `generateUniqueFileName(String originalName)`**
- Tạo tên file duy nhất: `food_{timestamp}.{extension}`

---

## Luồng Sự Kiện Chi Tiết

### Luồng 1: Mở Trang Quản Lý Sản Phẩm

```
┌─────────────────────────────────────────────────────────────┐
│ 1. Admin mở AdminProductManagementPage                       │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. build() - StreamBuilder                                    │
│    - Stream: FoodService.getFoods()                           │
│    - Hiển thị loading indicator khi đang fetch              │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 3. FoodService.getFoods()                                     │
│    - Query Firestore: collection('foods')                    │
│    - orderBy('createdAt', descending: true)                   │
│    - Trả về Stream<List<Food>>                                │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 4. UI Render với StreamBuilder                                │
│    - Hiển thị SearchBar + FilterChip (danh mục)              │
│    - Hiển thị danh sách sản phẩm                              │
│    - Mỗi sản phẩm hiển thị:                                   │
│      • Ảnh, tên, giá, số lượng (còn/hết hàng)                │
│      • Danh mục, mô tả                                        │
│      • PopupMenu: Sửa / Xóa                                   │
└─────────────────────────────────────────────────────────────┘
```

### Luồng 2: Tìm Kiếm & Lọc Sản Phẩm

```
┌─────────────────────────────────────────────────────────────┐
│ 1. Admin nhập từ khóa vào SearchBar                         │
│    HOẶC chọn FilterChip danh mục                              │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. onChanged() / onSelected()                                │
│    - setState(_searchQuery = value)                           │
│    - HOẶC setState(_selectedCategory = category)             │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 3. filteredFoods (trong StreamBuilder)                        │
│    - Lọc foods theo:                                          │
│      • matchesSearch: tên/mô tả chứa _searchQuery            │
│      • matchesCategory: category == _selectedCategory        │
│    - Trả về List<Food> đã lọc                                 │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 4. UI tự động rebuild với danh sách đã lọc                    │
│    - Hiển thị "Không tìm thấy sản phẩm nào" nếu rỗng        │
└─────────────────────────────────────────────────────────────┘
```

### Luồng 3: Thêm Sản Phẩm Mới

```
┌─────────────────────────────────────────────────────────────┐
│ 1. Admin click IconButton "Thêm" trên AppBar                 │
│    HOẶC click "Thêm sản phẩm" khi danh sách rỗng            │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. Navigator.push(AdminAddFoodPage)                           │
│    - Khởi tạo form với các trường trống                       │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 3. Admin điền form:                                           │
│    - Chọn ảnh (từ thư viện/camera)                            │
│    - Nhập tên, mô tả, giá, số lượng                           │
│    - Chọn danh mục                                             │
│    - Thêm add-ons (nếu có)                                     │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 4. Admin click "Thêm sản phẩm"                                │
│    - _addFood() được gọi                                       │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 5. Validate form                                              │
│    - Kiểm tra tất cả trường bắt buộc                          │
│    - Kiểm tra _selectedImage != null                          │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 6. Upload ảnh lên Firebase Storage                            │
│    - ImageService.generateUniqueFileName()                    │
│    - ImageService.uploadImageToFirebase()                     │
│    - Nhận về imageUrl                                         │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 7. Tạo Food object                                            │
│    - Food(name, description, imageUrl, price, ...)            │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 8. FoodService.addFood(food)                                   │
│    - Thêm document vào Firestore: collection('foods')         │
│    - createdAt = FieldValue.serverTimestamp()                 │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 9. Firestore Stream tự động cập nhật                           │
│    - getFoods() emit data mới                                 │
│    - AdminProductManagementPage tự động hiển thị sản phẩm mới │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 10. Navigator.pop() - Quay về trang quản lý                   │
│     - Hiển thị SnackBar: "Thêm sản phẩm thành công!"         │
└─────────────────────────────────────────────────────────────┘
```

### Luồng 4: Chọn Ảnh Sản Phẩm

```
┌─────────────────────────────────────────────────────────────┐
│ 1. Admin click "Chọn hình ảnh" / "Thay đổi hình ảnh"        │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. _pickImage() - showModalBottomSheet                        │
│    - Hiển thị 2 options:                                      │
│      • "Chọn từ thư viện"                                     │
│      • "Chụp ảnh"                                             │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 3a. Chọn từ thư viện:                                         │
│     - ImageService.pickImageFromGallery()                     │
│     - Resize: max 1024x1024, quality 80%                      │
│     - Trả về File?                                             │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 3b. Chụp ảnh:                                                 │
│     - ImageService.pickImageFromCamera()                      │
│     - Resize: max 1024x1024, quality 80%                      │
│     - Trả về File?                                             │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 4. setState(_selectedImage = image)                          │
│    - UI hiển thị ảnh preview                                  │
└─────────────────────────────────────────────────────────────┘
```

### Luồng 5: Quản Lý Add-ons (Thêm)

```
┌─────────────────────────────────────────────────────────────┐
│ 1. Admin click "Thêm" add-on                                  │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. _addAddon() - showDialog(_AddonDialog)                      │
│    - Hiển thị form: Tên add-on, Giá add-on                    │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 3. Admin điền form và click "Thêm"                            │
│    - Validate: tên và giá không được trống                   │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 4. Tạo Addon object                                           │
│    - Addon(name, price)                                       │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 5. setState(_addons.add(addon))                               │
│    - UI hiển thị add-on mới trong danh sách                   │
└─────────────────────────────────────────────────────────────┘
```

### Luồng 6: Sửa Sản Phẩm

```
┌─────────────────────────────────────────────────────────────┐
│ 1. Admin click PopupMenu → "Sửa"                              │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. _navigateToEditFood(food)                                   │
│    - Navigator.push(AdminEditFoodPage(food: food))            │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 3. AdminEditFoodPage.initState()                               │
│    - Khởi tạo controllers với giá trị hiện tại                │
│    - _selectedCategory = food.category                         │
│    - _addons = List.from(food.availableAddons)                │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 4. Admin chỉnh sửa thông tin                                   │
│    - Có thể thay đổi ảnh (chọn ảnh mới)                        │
│    - Có thể thêm/sửa/xóa add-ons                              │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 5. Admin click "Cập nhật sản phẩm"                            │
│    - _updateFood() được gọi                                    │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 6. Validate form                                              │
│    - Kiểm tra tất cả trường bắt buộc                          │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 7. Nếu có ảnh mới (_selectedImage != null):                   │
│    - Upload ảnh mới lên Firebase Storage                       │
│    - Xóa ảnh cũ (nếu là URL từ Firebase)                      │
│    - Cập nhật imagePath = imageUrl mới                        │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 8. Tạo updatedFood object                                     │
│    - food.copyWith(updated fields)                            │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 9. FoodService.updateFood(updatedFood)                         │
│    - Update Firestore document                                │
│    - updatedAt = FieldValue.serverTimestamp()                 │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 10. Firestore Stream tự động cập nhật                          │
│     - getFoods() emit data mới                                │
│     - AdminProductManagementPage tự động refresh              │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 11. Navigator.pop() - Quay về trang quản lý                   │
│     - Hiển thị SnackBar: "Cập nhật sản phẩm thành công!"      │
└─────────────────────────────────────────────────────────────┘
```

### Luồng 7: Xóa Sản Phẩm

```
┌─────────────────────────────────────────────────────────────┐
│ 1. Admin click PopupMenu → "Xóa"                              │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. _deleteFood(foodId, foodName)                               │
│    - showDialog(AlertDialog xác nhận)                         │
│    - "Bạn có chắc chắn muốn xóa "{foodName}"?"                │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 3. Admin xác nhận "Xóa"                                       │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 4. FoodService.deleteFood(foodId)                              │
│    - Xóa document: collection('foods').doc(foodId).delete()   │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 5. Firestore Stream tự động cập nhật                           │
│    - getFoods() emit data mới (không còn sản phẩm đã xóa)     │
│    - AdminProductManagementPage tự động refresh                │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 6. Hiển thị SnackBar                                          │
│    - "Đã xóa sản phẩm thành công"                             │
└─────────────────────────────────────────────────────────────┘
```

### Luồng 8: Real-time Updates

```
┌─────────────────────────────────────────────────────────────┐
│ 1. Admin khác cập nhật/xóa/thêm sản phẩm                      │
│    HOẶC admin hiện tại thực hiện thao tác                     │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. Firestore tự động emit change event                        │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 3. StreamBuilder trong AdminProductManagementPage             │
│    - Nhận data mới từ getFoods() stream                       │
│    - Tự động rebuild UI                                       │
│    - Cập nhật danh sách sản phẩm                              │
└─────────────────────────────────────────────────────────────┘
```

---

## Các Component Chính

### 1. AdminProductManagementPage
- **File:** `lib/pages/admin_product_management_page.dart`
- **Chức năng:**
  - Hiển thị danh sách sản phẩm (real-time)
  - Tìm kiếm và lọc sản phẩm
  - Navigate to AdminAddFoodPage / AdminEditFoodPage
  - Xóa sản phẩm

### 2. AdminAddFoodPage
- **File:** `lib/pages/admin_add_food_page.dart`
- **Chức năng:**
  - Form thêm sản phẩm mới
  - Chọn ảnh (thư viện/camera)
  - Quản lý add-ons
  - Upload ảnh và lưu sản phẩm

### 3. AdminEditFoodPage
- **File:** `lib/pages/admin_edit_food_page.dart`
- **Chức năng:**
  - Form sửa sản phẩm
  - Thay đổi ảnh (upload mới, xóa ảnh cũ)
  - Quản lý add-ons (thêm, sửa, xóa)
  - Cập nhật sản phẩm

### 4. FoodService
- **File:** `lib/services/food_service.dart`
- **Chức năng:**
  - Stream foods real-time
  - Thêm, sửa, xóa sản phẩm
  - Cập nhật số lượng

### 5. ImageService
- **File:** `lib/services/image_service.dart`
- **Chức năng:**
  - Chọn ảnh từ thư viện/camera
  - Upload ảnh lên Firebase Storage
  - Xóa ảnh khỏi Firebase Storage

### 6. Food Model
- **File:** `lib/models/food.dart`
- **Chức năng:**
  - Model đại diện cho sản phẩm
  - Chứa: name, description, imagePath, price, category, addons, quantity
  - `isInStock` getter: kiểm tra còn hàng (quantity > 0)

---

## Lưu Ý

- Danh sách sản phẩm được cập nhật real-time qua Firestore Stream
- Ảnh được upload lên Firebase Storage, path: `food_images/{fileName}`
- Khi sửa sản phẩm và thay đổi ảnh, ảnh cũ sẽ được xóa tự động
- Add-ons có thể được thêm, sửa, xóa trong form thêm/sửa sản phẩm
- Sản phẩm được sắp xếp theo `createdAt` (mới nhất trước)
- Tìm kiếm không phân biệt hoa thường, tìm theo tên hoặc mô tả
- Số lượng sản phẩm: `quantity > 0` = còn hàng, `quantity = 0` = hết hàng
- Danh mục: Miền Bắc (bac), Miền Trung (trung), Miền Nam (nam)

