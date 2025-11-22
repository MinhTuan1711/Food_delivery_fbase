import 'package:food_delivery_fbase/models/food.dart';
import 'package:food_delivery_fbase/services/food_service.dart';
import 'package:food_delivery_fbase/utils/image_placeholders.dart';

class DataMigration {
  static final FoodService _foodService = FoodService();

  /// Migrate hardcoded data to Firestore
  /// Chỉ chạy một lần để chuyển dữ liệu từ code sang database
  static Future<void> migrateHardcodedDataToFirestore() async {
    try {
      // Danh sách sản phẩm mẫu để migrate
      final List<Food> sampleFoods = [
        // Burgers
        Food(
          name: "Classic Cheeseburger",
          description:
              "A juicy beef patty with melted cheddar, lettuce, tomato, and a hint of onion and pickle.",
          imagePath: generatePlaceholderImage("classic-cheeseburger"),
          price: 0.99,
          availableAddons: [
            Addon(name: "Extra Cheese", price: 0.99),
            Addon(name: "Bacon", price: 1.99),
            Addon(name: "Avocado", price: 2.99)
          ],
          category: FoodCategory.bac,
          quantity: 10,
        ),
        Food(
          name: "Mushroom Black Bean Burger",
          description: "Vegetarian Friendly, Vegan Options",
          imagePath: generatePlaceholderImage("mushroom-black-bean-burger"),
          price: 4.99,
          availableAddons: [
            Addon(name: "Extra Cheese", price: 4.99),
            Addon(name: "Bacon", price: 6.55),
            Addon(name: "Avocado", price: 8.85)
          ],
          category: FoodCategory.bac,
          quantity: 10,
        ),

        // Salads
        Food(
          name: "Superfoods Salad",
          description:
              "A healthy mix of superfoods with fresh vegetables and nuts.",
          imagePath: generatePlaceholderImage("superfoods-salad"),
          price: 5.59,
          availableAddons: [
            Addon(name: "Extra Cheese", price: 5.59),
            Addon(name: "Bacon", price: 6.55),
            Addon(name: "Avocado", price: 8.85)
          ],
          category: FoodCategory.trung,
          quantity: 10,
        ),
        Food(
          name: "Italian Chopped Salad",
          description:
              "This chopped salad is so flavorful that even salad skeptics will pile their plates with seconds!",
          imagePath: generatePlaceholderImage("italian-chopped-salad"),
          price: 3.99,
          availableAddons: [
            Addon(name: "Extra Cheese", price: 3.99),
            Addon(name: "Bacon", price: 6.55),
            Addon(name: "Avocado", price: 8.55)
          ],
          category: FoodCategory.trung,
          quantity: 10,
        ),

        // Desserts
        Food(
          name: "Cherry Delight Dessert",
          description:
              "We believe the best kind of brownie recipe is the one that results the fudgy kind of brownies.",
          imagePath: generatePlaceholderImage("cherry-delight-dessert"),
          price: 2.99,
          availableAddons: [
            Addon(name: "Extra Cheese", price: 2.99),
            Addon(name: "Bacon", price: 5.55),
            Addon(name: "Avocado", price: 11.55)
          ],
          category: FoodCategory.nam,
          quantity: 10,
        ),
        Food(
          name: "Chocolate Sandwich Cupcakes",
          description:
              "Every cook needs a moist banana cake recipe that they keep coming back to.",
          imagePath: generatePlaceholderImage("chocolate-sandwich-cupcakes"),
          price: 1.19,
          availableAddons: [
            Addon(name: "Extra Cheese", price: 1.19),
            Addon(name: "Bacon", price: 5.55),
            Addon(name: "Avocado", price: 8.85)
          ],
          category: FoodCategory.nam,
          quantity: 10,
        ),

        // Drinks
        Food(
          name: "Blue Drink - Silver Factory",
          description:
              "Cool down with this fresh peach fizz served with mint leaves and juicy raspberries.",
          imagePath: generatePlaceholderImage("blue-drink-silver-factory"),
          price: 1.21,
          availableAddons: [
            Addon(name: "Extra Cheese", price: 1.21),
            Addon(name: "Bacon", price: 3.11),
            Addon(name: "Avocado", price: 4.55)
          ],
          category: FoodCategory.bac,
          quantity: 10,
        ),
        Food(
          name: "Frozen Apple Margarita",
          description:
              "To make this frozen drink into a mocktail, swap the tequila for an extra cup of sparkling apple juice.",
          imagePath: generatePlaceholderImage("frozen-apple-margarita"),
          price: 2.21,
          availableAddons: [
            Addon(name: "Extra Cheese", price: 2.21),
            Addon(name: "Bacon", price: 3.52),
            Addon(name: "Avocado", price: 4.54)
          ],
          category: FoodCategory.bac,
          quantity: 10,
        ),
      ];

      print('Bắt đầu migrate dữ liệu...');

      for (final food in sampleFoods) {
        try {
          await _foodService.addFood(food);
          print('✓ Đã thêm: ${food.name}');
        } catch (e) {
          print('✗ Lỗi khi thêm ${food.name}: $e');
        }
      }

      print('Hoàn thành migrate dữ liệu!');
    } catch (e) {
      print('Lỗi trong quá trình migrate: $e');
    }
  }

  /// Kiểm tra xem đã có dữ liệu trong Firestore chưa
  static Future<bool> hasDataInFirestore() async {
    try {
      final foods = await _foodService.getFoods().first;
      return foods.isNotEmpty;
    } catch (e) {
      print('Lỗi khi kiểm tra dữ liệu: $e');
      return false;
    }
  }
}
