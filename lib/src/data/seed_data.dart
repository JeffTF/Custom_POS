import '../models/category.dart';
import '../models/product.dart';

class SeedData {
  static const demoCategories = <Category>[
    Category(name: 'Beverages', color: '#0F766E', sortOrder: 1),
    Category(name: 'Snacks', color: '#C2410C', sortOrder: 2),
    Category(name: 'Dairy', color: '#1D4ED8', sortOrder: 3),
    Category(name: 'Bakery', color: '#B45309', sortOrder: 4),
    Category(name: 'Household', color: '#475569', sortOrder: 5),
    Category(name: 'Personal Care', color: '#BE185D', sortOrder: 6),
  ];

  static List<Product> buildProducts(List<Category> categories) {
    final ids = <String, int>{
      for (final category in categories) category.name: category.id!,
    };

    const items = <_SeedProduct>[
      _SeedProduct('Cola Can', 1.99, 45, 'Beverages', 8),
      _SeedProduct('Orange Juice', 3.49, 20, 'Beverages', 5),
      _SeedProduct('Mineral Water', 0.99, 80, 'Beverages', 12),
      _SeedProduct('Iced Coffee', 2.79, 18, 'Beverages', 6),
      _SeedProduct('Green Tea', 2.25, 22, 'Beverages', 5),
      _SeedProduct('Energy Drink', 3.99, 12, 'Beverages', 4),
      _SeedProduct('Potato Chips', 2.49, 32, 'Snacks', 7),
      _SeedProduct('Trail Mix', 4.99, 16, 'Snacks', 4),
      _SeedProduct('Chocolate Bar', 1.49, 40, 'Snacks', 6),
      _SeedProduct('Salted Peanuts', 3.25, 19, 'Snacks', 5),
      _SeedProduct('Granola Bites', 3.79, 14, 'Snacks', 4),
      _SeedProduct('Rice Crackers', 2.95, 17, 'Snacks', 4),
      _SeedProduct('Whole Milk', 2.89, 11, 'Dairy', 4),
      _SeedProduct('Greek Yogurt', 1.79, 15, 'Dairy', 5),
      _SeedProduct('Cheddar Cheese', 4.59, 10, 'Dairy', 3),
      _SeedProduct('Butter Block', 3.69, 9, 'Dairy', 3),
      _SeedProduct('Chocolate Milk', 2.49, 13, 'Dairy', 4),
      _SeedProduct('Cream Cheese', 2.99, 8, 'Dairy', 3),
      _SeedProduct('Sourdough Loaf', 3.49, 7, 'Bakery', 3),
      _SeedProduct('Croissant', 1.99, 18, 'Bakery', 5),
      _SeedProduct('Blueberry Muffin', 2.29, 16, 'Bakery', 5),
      _SeedProduct('Bagel Pack', 4.89, 10, 'Bakery', 3),
      _SeedProduct('Cinnamon Roll', 2.79, 12, 'Bakery', 4),
      _SeedProduct('Baguette', 2.59, 9, 'Bakery', 3),
      _SeedProduct('Dish Soap', 5.99, 14, 'Household', 4),
      _SeedProduct('Laundry Detergent', 12.99, 9, 'Household', 3),
      _SeedProduct('Paper Towels', 8.49, 11, 'Household', 4),
      _SeedProduct('Trash Bags', 6.79, 13, 'Household', 4),
      _SeedProduct('Glass Cleaner', 4.29, 10, 'Household', 3),
      _SeedProduct('Sponges', 3.49, 21, 'Household', 5),
      _SeedProduct('Shampoo', 7.99, 15, 'Personal Care', 4),
      _SeedProduct('Conditioner', 7.99, 12, 'Personal Care', 4),
      _SeedProduct('Toothpaste', 3.59, 25, 'Personal Care', 6),
      _SeedProduct('Body Wash', 6.49, 14, 'Personal Care', 4),
      _SeedProduct('Hand Soap', 2.99, 18, 'Personal Care', 5),
      _SeedProduct('Face Tissue', 2.49, 24, 'Personal Care', 6),
      _SeedProduct('Sparkling Water', 1.29, 35, 'Beverages', 8),
      _SeedProduct('Protein Shake', 4.49, 10, 'Beverages', 3),
      _SeedProduct('Pretzel Sticks', 2.19, 22, 'Snacks', 5),
      _SeedProduct('Fruit Gummies', 1.69, 28, 'Snacks', 6),
      _SeedProduct('String Cheese', 4.19, 14, 'Dairy', 4),
      _SeedProduct('Vanilla Yogurt', 1.89, 17, 'Dairy', 4),
      _SeedProduct('Donut Box', 5.99, 8, 'Bakery', 3),
      _SeedProduct('Banana Bread', 4.79, 6, 'Bakery', 2),
      _SeedProduct('Air Freshener', 3.99, 12, 'Household', 4),
      _SeedProduct('Floor Cleaner', 9.49, 7, 'Household', 3),
      _SeedProduct('Dental Floss', 2.89, 20, 'Personal Care', 5),
      _SeedProduct('Deodorant', 5.49, 11, 'Personal Care', 3),
      _SeedProduct('Lip Balm', 2.19, 26, 'Personal Care', 6),
      _SeedProduct('Herbal Tea', 3.15, 18, 'Beverages', 4),
      _SeedProduct('Nuts Mix Tub', 8.99, 9, 'Snacks', 3),
      _SeedProduct('Whipped Cream', 3.39, 7, 'Dairy', 2),
      _SeedProduct('Sandwich Bread', 2.99, 12, 'Bakery', 4),
      _SeedProduct('Storage Bags', 4.69, 16, 'Household', 4),
    ];

    return items.map((item) {
      final categoryId = ids[item.category]!;
      final sku = item.name.toUpperCase().replaceAll(' ', '-');
      return Product(
        name: item.name,
        price: item.price,
        stockQuantity: item.stock,
        categoryId: categoryId,
        sku: sku,
        lowStockThreshold: item.lowStock,
      );
    }).toList();
  }
}

class _SeedProduct {
  const _SeedProduct(
    this.name,
    this.price,
    this.stock,
    this.category,
    this.lowStock,
  );

  final String name;
  final double price;
  final int stock;
  final String category;
  final int lowStock;
}
