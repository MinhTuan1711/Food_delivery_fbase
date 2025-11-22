import 'package:flutter/material.dart';

ThemeData lightMode = ThemeData(
  brightness: Brightness.light,
  colorScheme: ColorScheme.light(
    background: Colors.white, // Nền trắng
    primary: Color(0xFF83C5BE).withOpacity(0.3), // Màu chủ đạo #83C5BE với opacity 30%
    secondary: Color(0xFF83C5BE).withOpacity(0.2), // Màu phụ nhạt
    tertiary: Colors.grey.shade200, // Màu bậc 3
    inversePrimary: Colors.grey.shade900, // Màu chữ tối trên nền sáng
    onBackground: Colors.grey.shade900, // Chữ trên nền background
    onPrimary: Colors.grey.shade900, // Chữ trên primary (tối vì nền trắng)
    onSecondary: Colors.grey.shade900, // Chữ trên secondary
    surface: Colors.white, // Bề mặt sáng
    onSurface: Colors.grey.shade900, // Chữ trên surface
    onSurfaceVariant: Colors.grey.shade700, // Chữ variant
    error: Colors.red.shade600, // Màu lỗi
    onError: Colors.white, // Chữ trên error
  ),
  scaffoldBackgroundColor: Colors.white,
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.white,
    foregroundColor: Colors.grey.shade900,
    elevation: 0,
  ),
);
