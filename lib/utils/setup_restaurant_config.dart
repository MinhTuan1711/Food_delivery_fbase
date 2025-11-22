/// Script setup restaurant_config cho Firebase Firestore
/// 
/// Script này sẽ tạo document restaurant_config/delivery_range
/// với cấu hình phạm vi giao hàng mặc định (Vietnam)
/// 
/// Cách sử dụng:
/// 1. Import và gọi function trong main.dart hoặc một page nào đó
/// 2. Hoặc chạy trong debug console
/// 
/// Ví dụ:
/// ```dart
/// import 'package:food_delivery_fbase/utils/setup_restaurant_config.dart';
/// 
/// // Trong initState hoặc một function nào đó
/// await setupRestaurantConfig();
/// ```

import 'package:food_delivery_fbase/utils/admin_setup.dart';

/// Setup restaurant config với quốc gia mặc định (Vietnam)
/// 
/// [country] - Tên quốc gia (mặc định: "Vietnam")
/// 
/// Returns: true nếu setup thành công
Future<bool> setupRestaurantConfig({String country = 'Vietnam'}) async {
  print('🚀 Bắt đầu setup restaurant config...');
  print('   Country: $country');
  
  // Kiểm tra xem đã setup chưa
  final isSetup = await AdminSetup.isRestaurantConfigSetup();
  if (isSetup) {
    print('⚠️  Restaurant config đã được setup trước đó.');
    final currentConfig = await AdminSetup.getRestaurantConfig();
    if (currentConfig != null) {
      print('   Current country: ${currentConfig['country']}');
    }
    print('   Đang cập nhật với country mới: $country');
  }
  
  // Thực hiện setup
  final success = await AdminSetup.setupRestaurantConfig(country: country);
  
  if (success) {
    print('✅ Setup restaurant config thành công!');
    print('');
    print('📋 Thông tin đã setup:');
    print('   Collection: restaurant_config');
    print('   Document: delivery_range');
    print('   Country: $country');
    print('');
    print('💡 Bạn có thể kiểm tra trong Firebase Console:');
    print('   Firestore Database > restaurant_config > delivery_range');
  } else {
    print('❌ Setup restaurant config thất bại!');
    print('   Vui lòng kiểm tra:');
    print('   1. Firebase đã được khởi tạo chưa');
    print('   2. User đã đăng nhập và có quyền admin chưa');
    print('   3. Security rules đã được deploy chưa');
  }
  
  return success;
}

/// Kiểm tra và hiển thị thông tin restaurant config hiện tại
Future<void> checkRestaurantConfig() async {
  print('🔍 Kiểm tra restaurant config...');
  
  final isSetup = await AdminSetup.isRestaurantConfigSetup();
  if (!isSetup) {
    print('❌ Restaurant config chưa được setup.');
    print('   Chạy setupRestaurantConfig() để thiết lập.');
    return;
  }
  
  final config = await AdminSetup.getRestaurantConfig();
  if (config != null) {
    print('✅ Restaurant config đã được setup:');
    print('   Country: ${config['country'] ?? 'N/A'}');
    print('   Created At: ${config['createdAt'] ?? 'N/A'}');
    print('   Updated At: ${config['updatedAt'] ?? 'N/A'}');
  } else {
    print('❌ Không thể lấy thông tin restaurant config.');
  }
}


































