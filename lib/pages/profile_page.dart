import 'package:flutter/material.dart';
import 'package:food_delivery_fbase/services/auth/auth_service.dart';
import 'package:food_delivery_fbase/models/user.dart';
import 'package:food_delivery_fbase/components/my_textfield.dart';
import 'package:food_delivery_fbase/components/my_button.dart';
import 'package:food_delivery_fbase/pages/location_selection_page.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  
  // Controllers for form fields
  final _displayNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  UserModel? _currentUser;
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isChangingPassword = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }
  
  @override
  void dispose() {
    _displayNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
  
  Future<void> _loadUserData() async {
    try {
      final userData = await _authService.getCurrentUserData();
      setState(() {
        _currentUser = userData;
        _isLoading = false;
      });
      
      if (userData != null) {
        _displayNameController.text = userData.displayName ?? '';
        _phoneController.text = userData.phoneNumber ?? '';
        _addressController.text = userData.address ?? '';
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Lỗi tải thông tin người dùng: $e');
    }
  }
  
  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    try {
      await _authService.updateUserProfile(
        displayName: _displayNameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        address: _addressController.text.trim(),
      );
      
      setState(() {
        _isEditing = false;
      });
      
      _showSuccessSnackBar('Cập nhật thông tin thành công!');
      _loadUserData(); // Reload user data
    } catch (e) {
      _showErrorSnackBar('Lỗi cập nhật thông tin: $e');
    }
  }
  
  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showErrorSnackBar('Mật khẩu mới và xác nhận mật khẩu không khớp!');
      return;
    }
    
    try {
      // Reauthenticate user first
      await _authService.reauthenticateUser(
        _currentUser!.email,
        _currentPasswordController.text,
      );
      
      // Update password
      await _authService.updatePassword(_newPasswordController.text);
      
      setState(() {
        _isChangingPassword = false;
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      });
      
      _showSuccessSnackBar('Đổi mật khẩu thành công!');
    } catch (e) {
      _showErrorSnackBar('Lỗi đổi mật khẩu: $e');
    }
  }
  
  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      
      if (image != null) {
        // Here you would typically upload the image to Firebase Storage
        // and get the download URL, then update the user's profileImageUrl
        _showInfoSnackBar('Chức năng upload ảnh sẽ được thêm sau');
      }
    } catch (e) {
      _showErrorSnackBar('Lỗi chọn ảnh: $e');
    }
  }
  
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
  
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }
  
  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Hồ sơ cá nhân"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (!_isEditing && !_isChangingPassword)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentUser == null
              ? const Center(child: Text('Không thể tải thông tin người dùng'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Profile Picture Section
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 60,
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              backgroundImage: _currentUser!.profileImageUrl != null
                                  ? NetworkImage(_currentUser!.profileImageUrl!)
                                  : null,
                              child: _currentUser!.profileImageUrl == null
                                  ? Icon(
                                      Icons.person,
                                      size: 60,
                                      color: Theme.of(context).colorScheme.onPrimary,
                                    )
                                  : null,
                            ),
                            if (_isEditing)
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: _pickImage,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.camera_alt,
                                      color: Theme.of(context).colorScheme.onPrimary,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        
                        // User Info
                        Text(
                          _currentUser!.displayNameOrEmail,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        Text(
                          _currentUser!.email,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (_currentUser!.isAdmin)
                          Container(
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'ADMIN',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        const SizedBox(height: 30),
                        
                        // Profile Information Form
                        if (_isEditing) ...[
                          MyTextField(
                            controller: _displayNameController,
                            hintText: "Tên hiển thị",
                            obscureText: false,
                            icon: Icon(Icons.person),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Vui lòng nhập tên hiển thị';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          MyTextField(
                            controller: _phoneController,
                            hintText: "Số điện thoại",
                            obscureText: false,
                            icon: Icon(Icons.phone),
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 16),
                          MyTextField(
                            controller: _addressController,
                            hintText: "Địa chỉ",
                            obscureText: false,
                            icon: Icon(Icons.location_on),
                            maxLines: 3,
                          ),
                          const SizedBox(height: 20),
                          
                          // Action Buttons
                          Row(
                            children: [
                              Expanded(
                                child: MyButton(
                                  text: "Hủy",
                                  onTap: () {
                                    setState(() {
                                      _isEditing = false;
                                    });
                                    _loadUserData(); // Reset form
                                  },
                                  backgroundColor: Colors.grey,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: MyButton(
                                  text: "Lưu",
                                  onTap: _updateProfile,
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          // Display Mode
                          _buildInfoCard(
                            icon: Icons.person,
                            title: "Tên hiển thị",
                            value: _currentUser!.displayName ?? "Chưa cập nhật",
                          ),
                          _buildInfoCard(
                            icon: Icons.phone,
                            title: "Số điện thoại",
                            value: _currentUser!.phoneNumber ?? "Chưa cập nhật",
                          ),
                          _buildLocationCard(
                            address: _currentUser!.address ?? "Chưa cập nhật",
                          ),
                          _buildInfoCard(
                            icon: Icons.email,
                            title: "Email",
                            value: _currentUser!.email,
                          ),
                          _buildInfoCard(
                            icon: Icons.calendar_today,
                            title: "Ngày tạo tài khoản",
                            value: "${_currentUser!.createdAt.day}/${_currentUser!.createdAt.month}/${_currentUser!.createdAt.year}",
                          ),
                        ],
                        
                        const SizedBox(height: 30),
                        
                        // Change Password Section
                        if (_isChangingPassword) ...[
                          const Divider(),
                          const SizedBox(height: 20),
                          Text(
                            "Đổi mật khẩu",
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          MyTextField(
                            controller: _currentPasswordController,
                            hintText: "Mật khẩu hiện tại",
                            obscureText: _obscureCurrentPassword,
                            icon: Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(_obscureCurrentPassword ? Icons.visibility : Icons.visibility_off),
                              onPressed: () {
                                setState(() {
                                  _obscureCurrentPassword = !_obscureCurrentPassword;
                                });
                              },
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Vui lòng nhập mật khẩu hiện tại';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          MyTextField(
                            controller: _newPasswordController,
                            hintText: "Mật khẩu mới",
                            obscureText: _obscureNewPassword,
                            icon: Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(_obscureNewPassword ? Icons.visibility : Icons.visibility_off),
                              onPressed: () {
                                setState(() {
                                  _obscureNewPassword = !_obscureNewPassword;
                                });
                              },
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Vui lòng nhập mật khẩu mới';
                              }
                              if (value.length < 6) {
                                return 'Mật khẩu phải có ít nhất 6 ký tự';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          MyTextField(
                            controller: _confirmPasswordController,
                            hintText: "Xác nhận mật khẩu mới",
                            obscureText: _obscureConfirmPassword,
                            icon: Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword = !_obscureConfirmPassword;
                                });
                              },
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Vui lòng xác nhận mật khẩu mới';
                              }
                              if (value != _newPasswordController.text) {
                                return 'Mật khẩu xác nhận không khớp';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          
                          // Password Action Buttons
                          Row(
                            children: [
                              Expanded(
                                child: MyButton(
                                  text: "Hủy",
                                  onTap: () {
                                    setState(() {
                                      _isChangingPassword = false;
                                      _currentPasswordController.clear();
                                      _newPasswordController.clear();
                                      _confirmPasswordController.clear();
                                    });
                                  },
                                  backgroundColor: Colors.grey,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: MyButton(
                                  text: "Đổi mật khẩu",
                                  onTap: _changePassword,
                                ),
                              ),
                            ],
                          ),
                        ] else if (!_isEditing) ...[
                          // Change Password Button
                          MyButton(
                            text: "Đổi mật khẩu",
                            onTap: () {
                              setState(() {
                                _isChangingPassword = true;
                              });
                            },
                            backgroundColor: Colors.orange,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
    );
  }
  
  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: Theme.of(context).colorScheme.onSurface,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard({
    required String address,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.location_on,
                color: Theme.of(context).colorScheme.onSurface,
                size: 24,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Địa chỉ",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      address,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const LocationSelectionPage(
                      allowBack: true,
                    ),
                  ),
                ).then((_) {
                  // Reload user data after returning from location selection
                  _loadUserData();
                });
              },
              icon: const Icon(Icons.map),
              label: const Text('Xác định vị trí trên bản đồ'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}