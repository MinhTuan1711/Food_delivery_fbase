import 'package:flutter/material.dart';
import 'package:food_delivery_fbase/components/auth_widgets.dart';
import 'package:food_delivery_fbase/components/my_button.dart';
import 'package:food_delivery_fbase/components/my_textfield.dart';
import 'package:food_delivery_fbase/pages/user/home_page.dart';
import 'package:food_delivery_fbase/services/auth/auth_service.dart';
import 'package:food_delivery_fbase/utils/auth_helpers.dart';

class LoginPage extends StatefulWidget {
  final void Function()? onTap;

  const LoginPage({super.key, required this.onTap});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  //text editting controller
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  //login method
  void login() async {
    if (!mounted) return;

    final _authService = AuthService();

    try {
      AuthHelpers.showLoadingDialog(context);
      await _authService.signInWithEmailPassword(
        emailController.text.trim(),
        passwordController.text.trim(),
      );

      if (!mounted) return;
      AuthHelpers.closeDialog(context);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );

      emailController.clear();
      passwordController.clear();
    } catch (e) {
      if (!mounted) return;
      AuthHelpers.closeDialog(context);
      AuthHelpers.showErrorDialog(
        context,
        title: "Đăng nhập thất bại",
        message: AuthHelpers.extractErrorMessage(e),
      );
    }
  }

  //forgot password method
  void forgotPassword() async {
    if (!mounted) return;

    final resetEmailController = TextEditingController();
    final _authService = AuthService();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.background,
        title: Text(
          "Quên mật khẩu",
          style: TextStyle(
            color: Theme.of(context).colorScheme.inversePrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Nhập email của bạn để nhận link đặt lại mật khẩu",
              style: TextStyle(
                color: Theme.of(context).colorScheme.inversePrimary,
              ),
            ),
            const SizedBox(height: 20),
            MyTextField(
              controller: resetEmailController,
              hintText: 'Email',
              obscureText: false,
              keyboardType: TextInputType.emailAddress,
              icon: Icon(
                Icons.email,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy"),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.inversePrimary,
            ),
          ),
          TextButton(
            onPressed: () async {
              if (resetEmailController.text.trim().isEmpty) {
                AuthHelpers.showSnackBar(context,
                    message: "Vui lòng nhập email");
                return;
              }

              try {
                await _authService
                    .resetPassword(resetEmailController.text.trim());
                if (!context.mounted) return;
                Navigator.pop(context);
                AuthHelpers.showSnackBar(
                  context,
                  message:
                      "Email đặt lại mật khẩu đã được gửi. Vui lòng kiểm tra hộp thư của bạn.",
                  backgroundColor: Colors.green,
                );
              } catch (e) {
                if (!context.mounted) return;
                AuthHelpers.showSnackBar(
                  context,
                  message: AuthHelpers.extractErrorMessage(e),
                  backgroundColor: Colors.red,
                );
              }
            },
            child: const Text("Gửi"),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.inversePrimary,
            ),
          ),
        ],
      ),
    );
  }

  //google sign in method
  void signInWithGoogle() async {
    if (!mounted) return;

    final _authService = AuthService();

    try {
      AuthHelpers.showLoadingDialog(context);
      await _authService.signInWithGoogle();

      if (!mounted) return;
      AuthHelpers.closeDialog(context);

      // Navigate to HomePage after successful Google sign in
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } catch (e) {
      if (mounted) {
        AuthHelpers.closeDialog(context);
        AuthHelpers.showErrorDialog(
          context,
          title: "Đăng nhập thất bại",
          message: AuthHelpers.extractErrorMessage(e),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              //logo
              Icon(
                Icons.lock_open_rounded,
                size: 72,
                color: Theme.of(context).colorScheme.inversePrimary,
              ),
              const SizedBox(
                height: 25,
              ),
              //message,app slogan
              Text(
                "Ứng dụng giao đồ ăn",
                style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.inversePrimary),
              ),
              const SizedBox(
                height: 25,
              ),
              //email textfield
              MyTextField(
                controller: emailController,
                hintText: 'Email',
                obscureText: false,
                keyboardType: TextInputType.emailAddress,
                icon: Icon(
                  Icons.email,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              //password textfield
              MyTextField(
                controller: passwordController,
                hintText: 'Mật khẩu',
                obscureText: true,
                icon: Icon(
                  Icons.password,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              //forgot password link
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: GestureDetector(
                    onTap: forgotPassword,
                    child: Text(
                      "Quên mật khẩu?",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              //sign it button
              MyButton(
                text: "Đăng nhập",
                onTap: login,
              ),
              const SizedBox(height: 20),
              const AuthDivider(),
              const SizedBox(height: 20),
              GoogleSignInButton(
                onPressed: signInWithGoogle,
                text: "Đăng nhập với Google",
              ),
              const SizedBox(height: 25),
              AuthNavigationLink(
                prefixText: "Chưa có tài khoản?",
                linkText: "Đăng ký ngay",
                onTap: widget.onTap,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
