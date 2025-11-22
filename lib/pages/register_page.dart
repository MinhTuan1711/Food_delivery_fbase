import 'package:flutter/material.dart';
import 'package:food_delivery_fbase/components/auth_widgets.dart';
import 'package:food_delivery_fbase/components/my_button.dart';
import 'package:food_delivery_fbase/components/my_textfield.dart';
import 'package:food_delivery_fbase/pages/home_page.dart';
import 'package:food_delivery_fbase/services/auth/auth_service.dart';
import 'package:food_delivery_fbase/utils/auth_helpers.dart';

class RegisterPage extends StatefulWidget {
  final void Function()? onTap;
  const RegisterPage({super.key, required this.onTap});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  //text editting controller
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  //register method
  void register() async {
    if (!mounted) return;
    
    final _authService = AuthService();

    //check if password match -> create user
    if (passwordController.text != confirmPasswordController.text.trim()) {
      AuthHelpers.showErrorDialog(
        context,
        title: "Mật khẩu không khớp!",
        message: "Vui lòng đảm bảo cả hai mật khẩu giống nhau.",
      );
      return;
    }

    try {
      AuthHelpers.showLoadingDialog(context);
      await _authService.signUpWithEmailPassword(
        emailController.text.trim(),
        passwordController.text.trim(),
      );
      
      if (!mounted) return;
      AuthHelpers.closeDialog(context);
      
      // Clear form data
      emailController.clear();
      passwordController.clear();
      confirmPasswordController.clear();
      
      // Show success dialog and navigate to home page
      AuthHelpers.showSuccessDialog(
        context,
        title: "Đăng ký thành công!",
        message: "Tài khoản của bạn đã được tạo thành công. Bạn sẽ được chuyển đến trang chủ.",
        onOk: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      AuthHelpers.closeDialog(context);
      AuthHelpers.showErrorDialog(
        context,
        title: "Đăng ký thất bại",
        message: AuthHelpers.extractErrorMessage(e),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              //logo
              Icon(
                //Icons.lock_open_rounded,
                Icons.delivery_dining,
                size: 100,
                color: Theme.of(context).colorScheme.inversePrimary,
              ),

              //message, app slogan
              Text(
                "Hãy tạo tài khoản cho bạn",
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),
              ),
              const SizedBox(height: 25),

              //email textfield
              MyTextField(
                controller: emailController,
                hintText: "Email",
                obscureText: false,
                keyboardType: TextInputType.emailAddress,
                icon: Icon(
                  Icons.email,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              SizedBox(
                height: 25,
              ),

              //password textfield
              MyTextField(
                controller: passwordController,
                hintText: "Mật khẩu",
                obscureText: true,
                icon: Icon(
                  Icons.password,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              SizedBox(
                height: 25,
              ),

              //confirm password textfield
              MyTextField(
                controller: confirmPasswordController,
                hintText: "Xác nhận mật khẩu",
                obscureText: true,
                icon: Icon(
                  Icons.password,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              SizedBox(
                height: 25,
              ),

              //sign up button
              MyButton(
                text: "Đăng ký",
                onTap: register,
              ),

              SizedBox(
                height: 25,
              ),
              AuthNavigationLink(
                prefixText: "Đã có tài khoản?",
                linkText: "Đăng nhập ngay",
                onTap: widget.onTap,
              )
            ],
          ),
        ));
  }
}