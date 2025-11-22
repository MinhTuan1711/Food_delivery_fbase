import 'package:flutter/material.dart';
import 'package:food_delivery_fbase/components/my_button.dart';
import 'package:food_delivery_fbase/components/my_textfield.dart';
import 'package:food_delivery_fbase/services/auth/auth_service.dart';
import 'package:food_delivery_fbase/utils/admin_setup.dart';

class AdminSetupPage extends StatefulWidget {
  const AdminSetupPage({super.key});

  @override
  State<AdminSetupPage> createState() => _AdminSetupPageState();
}

class _AdminSetupPageState extends State<AdminSetupPage> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _isSettingUpRestaurantConfig = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _setupAdmin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await AdminSetup.setupFirstAdmin(_emailController.text.trim());
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thiết lập admin thành công!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _setupRestaurantConfig() async {
    setState(() {
      _isSettingUpRestaurantConfig = true;
    });

    try {
      final success = await AdminSetup.setupRestaurantConfig();
      
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Thiết lập cấu hình nhà hàng thành công!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Thiết lập cấu hình nhà hàng thất bại. Vui lòng thử lại.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSettingUpRestaurantConfig = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thiết lập Admin'),
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.admin_panel_settings,
                size: 80,
                color: Colors.blue,
              ),
              const SizedBox(height: 24),
              
              const Text(
                'Thiết lập Admin',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              const Text(
                'Nhập email của user muốn thiết lập làm admin. User này phải đã đăng ký trong hệ thống.',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 32),
              
              MyTextField(
                controller: _emailController,
                hintText: 'Email của admin',
                obscureText: false,
                icon: const Icon(Icons.email),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập email';
                  }
                  if (!value.contains('@')) {
                    return 'Email không hợp lệ';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 24),
              
              MyButton(
                text: _isLoading ? 'Đang thiết lập...' : 'Thiết lập Admin',
                onTap: _isLoading ? null : _setupAdmin,
              ),
              
              const SizedBox(height: 32),
              
              const Divider(),
              
              const SizedBox(height: 16),
              
              const Text(
                'Cấu hình nhà hàng',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 8),
              
              const Text(
                'Thiết lập phạm vi giao hàng (quốc gia)',
                style: TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              MyButton(
                text: _isSettingUpRestaurantConfig 
                    ? 'Đang thiết lập...' 
                    : 'Thiết lập cấu hình nhà hàng',
                onTap: _isSettingUpRestaurantConfig ? null : _setupRestaurantConfig,
              ),
              
              const SizedBox(height: 16),
              
              const Text(
                'Lưu ý: Chỉ có thể thiết lập admin cho user đã tồn tại trong hệ thống.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}


