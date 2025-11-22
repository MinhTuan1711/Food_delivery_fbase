# Luồng Sự Kiện Quản Lý Người Dùng (Admin)

## Tổng Quan
Ứng dụng cho phép admin quản lý người dùng với các tính năng:
1. **Xem danh sách người dùng** (tất cả / chỉ admin)
2. **Tìm kiếm người dùng** (theo tên, email)
3. **Xem chi tiết người dùng**
4. **Cấp/Thu hồi quyền admin**
5. **Xóa người dùng** (kèm cleanup dữ liệu liên quan)
6. **Làm mới danh sách**

## Kiến Trúc

### 1. Service Layer: `UserService`
**File:** `lib/services/user_service.dart`

#### Cấu trúc dữ liệu Firestore:
```
users/
  └── {userId}/
      ├── uid: string
      ├── email: string
      ├── displayName: string?
      ├── phoneNumber: string?
      ├── address: string?
      ├── isAdmin: boolean
      ├── createdAt: timestamp
      ├── updatedAt: timestamp?
      ├── deliveryName: string?
      ├── deliveryPhone: string?
      ├── deliveryAddress: string?
      └── ...
```

#### Các phương thức chính:

**a) `getAllUsers()`**
- Lấy danh sách tất cả người dùng từ Firestore
- Query: `collection('users').get()`
- Trả về `Future<List<UserModel>>`

**b) `updateUserAdminStatus(String uid, bool isAdmin)`**
- Cập nhật quyền admin của người dùng
- Update Firestore: `isAdmin` và `updatedAt`

**c) `deleteUser(String uid)`**
- Xóa người dùng và cleanup dữ liệu liên quan:
  - Xóa cart items
  - Xóa cart document
  - Đánh dấu orders là `userDeleted: true`

---

## Luồng Sự Kiện Chi Tiết

### Luồng 1: Mở Trang Quản Lý Người Dùng

```
┌─────────────────────────────────────────────────────────────┐
│ 1. Admin mở AdminUserManagementPage                         │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. initState()                                               │
│    - Khởi tạo _users = []                                    │
│    - _isLoading = true                                       │
│    - _searchQuery = ''                                       │
│    - _showAdminsOnly = false                                 │
│    - Gọi _loadUsers()                                        │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 3. _loadUsers()                                              │
│    - setState(_isLoading = true)                             │
│    - Gọi UserService.getAllUsers()                           │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 4. UserService.getAllUsers()                                 │
│    - Query Firestore: collection('users').get()               │
│    - Map documents → List<UserModel>                         │
│    - Trả về List<UserModel>                                  │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 5. setState()                                                │
│    - _users = users                                          │
│    - _isLoading = false                                      │
│    - UI tự động rebuild                                      │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 6. UI Render                                                 │
│    - Hiển thị SearchBar + FilterChip                        │
│    - Hiển thị danh sách người dùng                           │
│    - Sắp xếp: Admin trước, sau đó theo createdAt (mới nhất) │
└─────────────────────────────────────────────────────────────┘
```

### Luồng 2: Tìm Kiếm & Lọc Người Dùng

```
┌─────────────────────────────────────────────────────────────┐
│ 1. Admin nhập từ khóa vào SearchBar                         │
│    HOẶC toggle FilterChip "Chỉ hiển thị Admin"              │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. onChanged() / onSelected()                                │
│    - setState(_searchQuery = value)                          │
│    - HOẶC setState(_showAdminsOnly = selected)               │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 3. _filteredUsers getter                                     │
│    - Lọc _users theo:                                        │
│      • matchesSearch: tên/email chứa _searchQuery           │
│      • matchesAdminFilter: isAdmin == true (nếu _showAdminsOnly) │
│    - Sắp xếp: Admin trước, sau đó theo createdAt            │
│    - Trả về List<UserModel> đã lọc                           │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 4. UI tự động rebuild với danh sách đã lọc                   │
│    - Cập nhật số lượng: "Tổng: X người dùng"                 │
└─────────────────────────────────────────────────────────────┘
```

### Luồng 3: Xem Chi Tiết Người Dùng

```
┌─────────────────────────────────────────────────────────────┐
│ 1. Admin click PopupMenu → "Xem chi tiết"                   │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. _showUserDetails(user)                                     │
│    - showDialog(AlertDialog)                                 │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 3. Hiển thị Dialog với thông tin:                            │
│    - Email, Tên hiển thị, SĐT, Địa chỉ                      │
│    - Tên giao hàng, SĐT giao hàng, Địa chỉ giao hàng        │
│    - Quyền admin (Có/Không)                                  │
│    - Ngày tạo, Cập nhật lần cuối                             │
└─────────────────────────────────────────────────────────────┘
```

### Luồng 4: Cấp/Thu Hồi Quyền Admin

```
┌─────────────────────────────────────────────────────────────┐
│ 1. Admin click PopupMenu → "Cấp quyền admin" /              │
│    "Thu hồi quyền admin"                                      │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. _toggleAdminStatus(user)                                   │
│    - showDialog(AlertDialog xác nhận)                        │
│    - "Bạn có chắc chắn muốn cấp/thu hồi quyền admin?"       │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 3. User xác nhận "Cấp quyền" / "Thu hồi"                    │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 4. UserService.updateUserAdminStatus(uid, !user.isAdmin)     │
│    - Update Firestore:                                       │
│      • isAdmin = !user.isAdmin                                │
│      • updatedAt = FieldValue.serverTimestamp()               │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 5. _loadUsers() - Reload danh sách                           │
│    - Lấy data mới từ Firestore                               │
│    - setState(_users = newUsers)                             │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 6. Hiển thị SnackBar                                         │
│    - "Đã cấp quyền admin thành công"                         │
│    - HOẶC "Đã thu hồi quyền admin thành công"                │
└─────────────────────────────────────────────────────────────┘
```

### Luồng 5: Xóa Người Dùng

```
┌─────────────────────────────────────────────────────────────┐
│ 1. Admin click PopupMenu → "Xóa"                             │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. _deleteUser(user)                                          │
│    - showDialog(AlertDialog xác nhận)                        │
│    - "Bạn có chắc chắn muốn xóa người dùng?                 │
│      Hành động này không thể hoàn tác!"                      │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 3. User xác nhận "Xóa"                                       │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 4. UserService.deleteUser(uid)                                │
│    - Gọi _cleanupUserData(uid)                               │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 5. _cleanupUserData(uid)                                      │
│    - Xóa cart items: user_carts/{uid}/items/*                │
│    - Xóa cart document: user_carts/{uid}                     │
│    - Update orders:                                          │
│      • userDeleted = true                                    │
│      • userEmail = '[Deleted User]'                          │
│      • updatedAt = FieldValue.serverTimestamp()              │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 6. Xóa user document: users/{uid}                            │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 7. _loadUsers() - Reload danh sách                           │
│    - Lấy data mới từ Firestore                               │
│    - setState(_users = newUsers)                             │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 8. Hiển thị SnackBar                                         │
│    - "Đã xóa người dùng thành công"                         │
└─────────────────────────────────────────────────────────────┘
```

### Luồng 6: Làm Mới Danh Sách

```
┌─────────────────────────────────────────────────────────────┐
│ 1. Admin click IconButton "Refresh" trên AppBar             │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. _loadUsers()                                               │
│    - setState(_isLoading = true)                             │
│    - Gọi UserService.getAllUsers()                           │
│    - setState(_users = users, _isLoading = false)             │
└─────────────────────────────────────────────────────────────┘
```

---

## Các Component Chính

### 1. AdminUserManagementPage
- **File:** `lib/pages/admin_user_management_page.dart`
- **Chức năng:**
  - Hiển thị danh sách người dùng
  - Tìm kiếm và lọc người dùng
  - Xem chi tiết, cấp/thu hồi quyền admin, xóa người dùng
  - Làm mới danh sách

### 2. UserService
- **File:** `lib/services/user_service.dart`
- **Chức năng:**
  - Lấy danh sách tất cả người dùng
  - Cập nhật quyền admin
  - Xóa người dùng và cleanup dữ liệu liên quan

### 3. UserModel
- **File:** `lib/models/user.dart`
- **Chức năng:**
  - Model đại diện cho người dùng
  - Chứa thông tin: email, displayName, isAdmin, delivery info, etc.

---

## Lưu Ý

- Chỉ admin mới có quyền truy cập trang này
- Xóa người dùng sẽ cleanup cart và đánh dấu orders là `userDeleted`
- Firebase Auth account deletion cần Firebase Admin SDK (backend)
- Danh sách được sắp xếp: Admin trước, sau đó theo ngày tạo (mới nhất)
- Tìm kiếm không phân biệt hoa thường, tìm theo tên hoặc email

