import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../data/category_dao.dart';
import '../data/database_helper.dart';
import '../data/product_dao.dart';
import '../data/sale_dao.dart';
import '../data/web_demo_store.dart';
import '../models/cart_item.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../models/report_models.dart';
import '../models/sale.dart';
import '../services/image_service.dart';

final databaseHelperProvider = Provider<DatabaseHelper>((ref) {
  return DatabaseHelper();
});

final categoryDaoProvider = Provider<CategoryDao>((ref) {
  final db = ref.watch(databaseHelperProvider).database;
  return CategoryDao(db);
});

final productDaoProvider = Provider<ProductDao>((ref) {
  final db = ref.watch(databaseHelperProvider).database;
  return ProductDao(db);
});

final saleDaoProvider = Provider<SaleDao>((ref) {
  final db = ref.watch(databaseHelperProvider).database;
  return SaleDao(db);
});

final imageServiceProvider = Provider<ImageService>((ref) {
  return ImageService(ImagePicker());
});

final webDemoStoreProvider = Provider<WebDemoStore>((ref) {
  return WebDemoStore();
});

final productFilterProvider =
    StateNotifierProvider<ProductFilterController, ProductFilterState>((ref) {
      return ProductFilterController();
    });

final appModeProvider = StateProvider<AppMode>((ref) => AppMode.staff);
final taxRateProvider = StateProvider<double>((ref) => 0.07);

final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  if (kIsWeb) {
    return ref.watch(webDemoStoreProvider).fetchCategories();
  }
  return ref.watch(categoryDaoProvider).fetchCategories();
});

final productsProvider = FutureProvider<List<Product>>((ref) async {
  final filter = ref.watch(productFilterProvider);
  if (kIsWeb) {
    return ref
        .watch(webDemoStoreProvider)
        .fetchProducts(
          categoryId: filter.categoryId,
          searchQuery: filter.searchQuery,
        );
  }
  return ref
      .watch(productDaoProvider)
      .fetchProducts(
        categoryId: filter.categoryId,
        searchQuery: filter.searchQuery,
      );
});

final lowStockProductsProvider = FutureProvider<List<Product>>((ref) async {
  if (kIsWeb) {
    return ref.watch(webDemoStoreProvider).fetchLowStockProducts();
  }
  return ref.watch(productDaoProvider).fetchLowStockProducts();
});

final dailySummaryProvider = FutureProvider<DailySalesSummary>((ref) async {
  if (kIsWeb) {
    return ref.watch(webDemoStoreProvider).fetchDailySummary();
  }
  return ref.watch(saleDaoProvider).fetchDailySummary();
});

final topSellingProductsProvider = FutureProvider<List<TopSellingProduct>>((
  ref,
) async {
  if (kIsWeb) {
    return ref.watch(webDemoStoreProvider).fetchTopSellingProducts();
  }
  return ref.watch(saleDaoProvider).fetchTopSellingProducts();
});

final hourlySalesProvider = FutureProvider<List<HourlySalesPoint>>((ref) async {
  if (kIsWeb) {
    return ref.watch(webDemoStoreProvider).fetchHourlyBreakdown();
  }
  return ref.watch(saleDaoProvider).fetchHourlyBreakdown();
});

enum AppMode { staff, admin }

class ProductFilterState {
  const ProductFilterState({this.categoryId, this.searchQuery = ''});

  final int? categoryId;
  final String searchQuery;

  ProductFilterState copyWith({
    int? categoryId,
    bool clearCategory = false,
    String? searchQuery,
  }) {
    return ProductFilterState(
      categoryId: clearCategory ? null : categoryId ?? this.categoryId,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class ProductFilterController extends StateNotifier<ProductFilterState> {
  ProductFilterController() : super(const ProductFilterState());

  void selectCategory(int? categoryId) {
    state = state.copyWith(
      categoryId: categoryId,
      clearCategory: categoryId == null,
    );
  }

  void setSearchQuery(String value) {
    state = state.copyWith(searchQuery: value);
  }
}

class CartState {
  const CartState({
    required this.items,
    this.discount = 0,
    this.isProcessing = false,
    this.lastReceiptMessage,
  });

  final List<CartItem> items;
  final double discount;
  final bool isProcessing;
  final String? lastReceiptMessage;

  double subtotal() {
    return items.fold<double>(0, (sum, item) => sum + item.lineTotal);
  }

  double tax(double rate) => subtotal() * rate;
  double total(double rate) => subtotal() + tax(rate) - discount;

  CartState copyWith({
    List<CartItem>? items,
    double? discount,
    bool? isProcessing,
    String? lastReceiptMessage,
    bool clearReceipt = false,
  }) {
    return CartState(
      items: items ?? this.items,
      discount: discount ?? this.discount,
      isProcessing: isProcessing ?? this.isProcessing,
      lastReceiptMessage: clearReceipt
          ? null
          : lastReceiptMessage ?? this.lastReceiptMessage,
    );
  }
}

final cartProvider = StateNotifierProvider<CartController, CartState>((ref) {
  return CartController(ref);
});

class CartController extends StateNotifier<CartState> {
  CartController(this._ref) : super(const CartState(items: <CartItem>[]));

  final Ref _ref;

  void addProduct(Product product) {
    if (product.isOutOfStock || product.id == null) {
      return;
    }

    final existingIndex = state.items.indexWhere(
      (item) => item.product.id == product.id,
    );
    if (existingIndex == -1) {
      state = state.copyWith(
        items: <CartItem>[
          ...state.items,
          CartItem(product: product, quantity: 1),
        ],
        clearReceipt: true,
      );
      return;
    }

    final current = state.items[existingIndex];
    if (current.quantity >= current.product.stockQuantity) {
      return;
    }

    final updated = [...state.items];
    updated[existingIndex] = current.copyWith(quantity: current.quantity + 1);
    state = state.copyWith(items: updated, clearReceipt: true);
  }

  void updateQuantity(int productId, int quantity) {
    final updated = <CartItem>[];
    for (final item in state.items) {
      if (item.product.id != productId) {
        updated.add(item);
        continue;
      }
      if (quantity <= 0) {
        continue;
      }
      updated.add(
        item.copyWith(quantity: quantity.clamp(1, item.product.stockQuantity)),
      );
    }
    state = state.copyWith(items: updated, clearReceipt: true);
  }

  void removeProduct(int productId) {
    state = state.copyWith(
      items: state.items.where((item) => item.product.id != productId).toList(),
      clearReceipt: true,
    );
  }

  void clearCart() {
    state = state.copyWith(items: const <CartItem>[], clearReceipt: true);
  }

  Future<String> processSale(PaymentMethod method) async {
    if (state.items.isEmpty) {
      return 'Cart is empty';
    }

    state = state.copyWith(isProcessing: true);
    final taxRate = _ref.read(taxRateProvider);
    final sale = Sale(
      totalAmount: state.total(taxRate),
      taxAmount: state.tax(taxRate),
      discountAmount: state.discount,
      paymentMethod: method,
      timestamp: DateTime.now(),
    );

    try {
      final saleItems = state.items.map((item) => item.toSaleItem()).toList();
      if (kIsWeb) {
        await _ref.read(webDemoStoreProvider).processSale(sale, saleItems);
      } else {
        await _ref.read(saleDaoProvider).processSale(sale, saleItems);
      }
      state = const CartState(
        items: <CartItem>[],
        lastReceiptMessage: 'Sale completed successfully.',
      );
      _invalidateReadModels();
      return 'Sale completed successfully.';
    } on InsufficientStockException catch (error) {
      state = state.copyWith(isProcessing: false);
      return 'Insufficient stock for product #${error.productId}.';
    } catch (_) {
      state = state.copyWith(isProcessing: false);
      return 'Sale could not be processed.';
    }
  }

  void _invalidateReadModels() {
    _ref.invalidate(productsProvider);
    _ref.invalidate(lowStockProductsProvider);
    _ref.invalidate(dailySummaryProvider);
    _ref.invalidate(topSellingProductsProvider);
    _ref.invalidate(hourlySalesProvider);
  }
}

final adminActionsProvider = Provider<AdminActions>((ref) {
  return AdminActions(ref);
});

class AdminActions {
  const AdminActions(this._ref);

  final Ref _ref;

  Future<void> saveProduct(Product product) async {
    if (kIsWeb) {
      await _ref.read(webDemoStoreProvider).upsertProduct(product);
    } else {
      await _ref.read(productDaoProvider).upsert(product);
    }
    _ref.invalidate(productsProvider);
    _ref.invalidate(lowStockProductsProvider);
  }

  Future<void> deleteProduct(Product product) async {
    if (product.id == null) {
      return;
    }
    if (kIsWeb) {
      await _ref.read(webDemoStoreProvider).softDeleteProduct(product.id!);
    } else {
      await _ref.read(productDaoProvider).softDelete(product.id!);
    }
    _ref.invalidate(productsProvider);
    _ref.invalidate(lowStockProductsProvider);
  }

  Future<void> saveCategory(Category category) async {
    if (kIsWeb) {
      await _ref.read(webDemoStoreProvider).upsertCategory(category);
    } else {
      await _ref.read(categoryDaoProvider).upsert(category);
    }
    _ref.invalidate(categoriesProvider);
    _ref.invalidate(productsProvider);
  }

  Future<void> deleteCategory(Category category) async {
    if (category.id == null) {
      return;
    }
    if (kIsWeb) {
      await _ref.read(webDemoStoreProvider).deleteCategory(category.id!);
    } else {
      await _ref.read(categoryDaoProvider).delete(category.id!);
    }
    _ref.invalidate(categoriesProvider);
    _ref.invalidate(productsProvider);
  }

  Future<String> exportReportCsv() async {
    if (kIsWeb) {
      return _ref.read(webDemoStoreProvider).exportDailyReportCsv();
    }
    return _ref.read(saleDaoProvider).exportDailyReportCsv();
  }
}
