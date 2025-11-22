import 'package:flutter/material.dart';
import 'package:food_delivery_fbase/models/user.dart';
import 'package:food_delivery_fbase/services/user_service.dart';
import 'package:food_delivery_fbase/services/auth/auth_service.dart';
import 'package:intl/intl.dart';

class AdminUserManagementPage extends StatefulWidget {
  const AdminUserManagementPage({super.key});

  @override
  State<AdminUserManagementPage> createState() => _AdminUserManagementPageState();
}

class _AdminUserManagementPageState extends State<AdminUserManagementPage> {
  final UserService _userService = UserService();
  final AuthService _authService = AuthService();
  List<UserModel> _users = [];
  bool _isLoading = true;
  String _searchQuery = '';
  bool _showAdminsOnly = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final users = await _userService.getAllUsers();
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi tải danh sách người dùng: $e')),
        );
      }
    }
  }

  List<UserModel> get _filteredUsers {
    var filtered = _users.where((user) {
      final matchesSearch = _searchQuery.isEmpty ||
          user.displayNameOrEmail.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          user.email.toLowerCase().contains(_searchQuery.toLowerCase());
      
      final matchesAdminFilter = !_showAdminsOnly || user.isAdmin;
      
      return matchesSearch && matchesAdminFilter;
    }).toList();

    // Sort by admin status first, then by creation date
    filtered.sort((a, b) {
      if (a.isAdmin != b.isAdmin) {
        return b.isAdmin ? 1 : -1;
      }
      return b.createdAt.compareTo(a.createdAt);
    });

    return filtered;
  }

  Future<void> _toggleAdminStatus(UserModel user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(user.isAdmin ? 'Thu hồi quyền admin' : 'Cấp quyền admin'),
        content: Text(
          user.isAdmin
              ? 'Bạn có chắc chắn muốn thu hồi quyền admin của "${user.displayNameOrEmail}"?'
              : 'Bạn có chắc chắn muốn cấp quyền admin cho "${user.displayNameOrEmail}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
    foregroundColor: Theme.of(context).colorScheme.inversePrimary,
  ),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              user.isAdmin ? 'Thu hồi' : 'Cấp quyền',
              style: TextStyle(
                color: user.isAdmin ? Colors.red : Colors.green,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _userService.updateUserAdminStatus(user.uid, !user.isAdmin);
        await _loadUsers();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                user.isAdmin
                    ? 'Đã thu hồi quyền admin thành công'
                    : 'Đã cấp quyền admin thành công',
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi khi cập nhật quyền: $e')),
          );
        }
      }
    }
  }

  Future<void> _deleteUser(UserModel user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa người dùng'),
        content: Text(
          'Bạn có chắc chắn muốn xóa người dùng "${user.displayNameOrEmail}"?\n\nHành động này không thể hoàn tác!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _userService.deleteUser(user.uid);
        await _loadUsers();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã xóa người dùng thành công')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi khi xóa người dùng: $e')),
          );
        }
      }
    }
  }

  void _showUserDetails(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Thông tin người dùng'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInfoRow('Email', user.email),
              _buildInfoRow('Tên hiển thị', user.displayName ?? 'Chưa cập nhật'),
              _buildInfoRow('Số điện thoại', user.phoneNumber ?? 'Chưa cập nhật'),
              _buildInfoRow('Địa chỉ', user.address ?? 'Chưa cập nhật'),
              _buildInfoRow('Tên giao hàng', user.deliveryName ?? 'Chưa cập nhật'),
              _buildInfoRow('SĐT giao hàng', user.deliveryPhone ?? 'Chưa cập nhật'),
              _buildInfoRow('Địa chỉ giao hàng', user.deliveryAddress ?? 'Chưa cập nhật'),
              _buildInfoRow('Quyền admin', user.isAdmin ? 'Có' : 'Không'),
              _buildInfoRow('Ngày tạo', DateFormat('dd/MM/yyyy HH:mm').format(user.createdAt)),
              if (user.updatedAt != null)
                _buildInfoRow('Cập nhật lần cuối', DateFormat('dd/MM/yyyy HH:mm').format(user.updatedAt!)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
    foregroundColor: Theme.of(context).colorScheme.inversePrimary,
  ),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý người dùng'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: _loadUsers,
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and filter section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  enableIMEPersonalizedLearning: true,
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm người dùng...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                            icon: const Icon(Icons.clear),
                          )
                        : null,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    FilterChip(
                      label: const Text('Chỉ hiển thị Admin'),
                      selected: _showAdminsOnly,
                      onSelected: (selected) {
                        setState(() {
                          _showAdminsOnly = selected;
                        });
                      },
                    ),
                    const Spacer(),
                    Text(
                      'Tổng: ${_filteredUsers.length} người dùng',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Users list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredUsers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.people_outline, size: 64),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isNotEmpty || _showAdminsOnly
                                  ? 'Không tìm thấy người dùng nào'
                                  : 'Chưa có người dùng nào',
                              style: const TextStyle(fontSize: 18),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user = _filteredUsers[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: user.isAdmin
                                    ? Colors.red.withOpacity(0.1)
                                    : Colors.blue.withOpacity(0.1),
                                child: Icon(
                                  user.isAdmin ? Icons.admin_panel_settings : Icons.person,
                                  color: user.isAdmin ? Colors.red : Colors.blue,
                                ),
                              ),
                              title: Text(
                                user.displayNameOrEmail,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(user.email),
                                  if (user.isAdmin)
                                    Container(
                                      margin: const EdgeInsets.only(top: 4),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text(
                                        'ADMIN',
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              trailing: PopupMenuButton<String>(
                                onSelected: (value) {
                                  switch (value) {
                                    case 'view':
                                      _showUserDetails(user);
                                      break;
                                    case 'admin':
                                      _toggleAdminStatus(user);
                                      break;
                                    case 'delete':
                                      _deleteUser(user);
                                      break;
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'view',
                                    child: Row(
                                      children: [
                                        Icon(Icons.visibility),
                                        SizedBox(width: 8),
                                        Text('Xem chi tiết'),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'admin',
                                    child: Row(
                                      children: [
                                        Icon(
                                          user.isAdmin ? Icons.remove_moderator : Icons.admin_panel_settings,
                                          color: user.isAdmin ? Colors.red : Colors.green,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          user.isAdmin ? 'Thu hồi quyền admin' : 'Cấp quyền admin',
                                          style: TextStyle(
                                            color: user.isAdmin ? Colors.red : Colors.green,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text('Xóa', style: TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
