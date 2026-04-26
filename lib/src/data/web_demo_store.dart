import '../models/category.dart';
import '../models/product.dart';
import '../models/report_models.dart';
import '../models/sale.dart';
import '../models/sale_item.dart';
import 'sale_dao.dart';
import 'seed_data.dart';

class WebDemoStore {
  WebDemoStore() : _state = _buildInitialState();

  WebDemoState _state;

  List<Category> fetchCategories() => _state.categories;

  List<Product> fetchProducts({
    int? categoryId,
    String searchQuery = '',
    bool activeOnly = true,
  }) {
    final query = searchQuery.trim().toLowerCase();
    final items = _state.products.where((product) {
      if (activeOnly && !product.isActive) {
        return false;
      }
      if (categoryId != null && product.categoryId != categoryId) {
        return false;
      }
      if (query.isEmpty) {
        return true;
      }
      final sku = product.sku?.toLowerCase() ?? '';
      return product.name.toLowerCase().contains(query) || sku.contains(query);
    }).toList();

    items.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return items;
  }

  List<Product> fetchLowStockProducts() {
    final items = _state.products.where((product) {
      return product.isActive &&
          product.stockQuantity <= product.lowStockThreshold;
    }).toList();
    items.sort((a, b) => a.stockQuantity.compareTo(b.stockQuantity));
    return items;
  }

  DailySalesSummary fetchDailySummary() {
    final sales = _todaysSales();
    return DailySalesSummary(
      totalRevenue: sales.fold<double>(
        0,
        (sum, record) => sum + record.sale.totalAmount,
      ),
      saleCount: sales.length,
    );
  }

  List<TopSellingProduct> fetchTopSellingProducts() {
    final totals = <int, _TopSellingAccumulator>{};

    for (final record in _todaysSales()) {
      for (final item in record.items) {
        final product = _state.products.firstWhere(
          (entry) => entry.id == item.productId,
        );
        final bucket = totals.putIfAbsent(
          item.productId,
          () => _TopSellingAccumulator(name: product.name),
        );
        bucket.quantitySold += item.quantity;
        bucket.revenue += item.lineTotal;
      }
    }

    final rows = totals.values
        .map(
          (entry) => TopSellingProduct(
            name: entry.name,
            quantitySold: entry.quantitySold,
            revenue: entry.revenue,
          ),
        )
        .toList();

    rows.sort((a, b) {
      final quantityCompare = b.quantitySold.compareTo(a.quantitySold);
      if (quantityCompare != 0) {
        return quantityCompare;
      }
      return b.revenue.compareTo(a.revenue);
    });

    return rows.take(10).toList();
  }

  List<HourlySalesPoint> fetchHourlyBreakdown() {
    final totals = <int, double>{};

    for (final record in _todaysSales()) {
      final hour = (record.sale.timestamp ?? DateTime.now()).hour;
      totals[hour] = (totals[hour] ?? 0) + record.sale.totalAmount;
    }

    final rows = totals.entries
        .map((entry) => HourlySalesPoint(hour: entry.key, revenue: entry.value))
        .toList();
    rows.sort((a, b) => a.hour.compareTo(b.hour));
    return rows;
  }

  Future<void> processSale(Sale sale, List<SaleItem> items) async {
    final updatedProducts = [..._state.products];

    for (final item in items) {
      final index = updatedProducts.indexWhere(
        (product) => product.id == item.productId,
      );
      if (index == -1) {
        throw InsufficientStockException(item.productId);
      }
      final product = updatedProducts[index];
      if (product.stockQuantity < item.quantity) {
        throw InsufficientStockException(item.productId);
      }
      updatedProducts[index] = product.copyWith(
        stockQuantity: product.stockQuantity - item.quantity,
        updatedAt: DateTime.now(),
      );
    }

    final saleId = _state.nextSaleId;
    var saleItemId = _state.nextSaleItemId;
    final normalizedItems = items.map((item) {
      final normalized = item.copyWith(id: saleItemId, saleId: saleId);
      saleItemId += 1;
      return normalized;
    }).toList();

    _state = _state.copyWith(
      products: updatedProducts,
      sales: [
        ..._state.sales,
        DemoSaleRecord(
          sale: sale.copyWith(id: saleId),
          items: normalizedItems,
        ),
      ],
      nextSaleId: saleId + 1,
      nextSaleItemId: saleItemId,
    );
  }

  Future<int> upsertCategory(Category category) async {
    if (category.id == null) {
      final saved = category.copyWith(
        id: _state.nextCategoryId,
        createdAt: DateTime.now(),
      );
      _state = _state.copyWith(
        categories: [..._state.categories, saved],
        nextCategoryId: _state.nextCategoryId + 1,
      );
      return saved.id!;
    }

    _state = _state.copyWith(
      categories: _state.categories
          .map((entry) => entry.id == category.id ? category : entry)
          .toList(),
    );
    return category.id!;
  }

  Future<void> deleteCategory(int id) async {
    _state = _state.copyWith(
      categories: _state.categories
          .where((category) => category.id != id)
          .toList(),
      products: _state.products
          .map(
            (product) => product.categoryId == id
                ? product.copyWith(categoryId: null)
                : product,
          )
          .toList(),
    );
  }

  Future<int> upsertProduct(Product product) async {
    if (product.id == null) {
      final saved = product.copyWith(
        id: _state.nextProductId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      _state = _state.copyWith(
        products: [..._state.products, saved],
        nextProductId: _state.nextProductId + 1,
      );
      return saved.id!;
    }

    _state = _state.copyWith(
      products: _state.products
          .map(
            (entry) => entry.id == product.id
                ? product.copyWith(updatedAt: DateTime.now())
                : entry,
          )
          .toList(),
    );
    return product.id!;
  }

  Future<void> softDeleteProduct(int id) async {
    _state = _state.copyWith(
      products: _state.products
          .map(
            (product) => product.id == id
                ? product.copyWith(isActive: false, updatedAt: DateTime.now())
                : product,
          )
          .toList(),
    );
  }

  Future<String> exportDailyReportCsv() async {
    return 'Web demo mode: CSV export is mocked only.';
  }

  List<DemoSaleRecord> _todaysSales() {
    final today = DateTime.now();
    return _state.sales.where((record) {
      final timestamp = record.sale.timestamp ?? today;
      return timestamp.year == today.year &&
          timestamp.month == today.month &&
          timestamp.day == today.day;
    }).toList();
  }

  static WebDemoState _buildInitialState() {
    var nextCategoryId = 1;
    final categories = SeedData.demoCategories.map((category) {
      final saved = category.copyWith(
        id: nextCategoryId,
        createdAt: DateTime.now(),
      );
      nextCategoryId += 1;
      return saved;
    }).toList();

    var nextProductId = 1;
    final products = SeedData.buildProducts(categories).map((product) {
      final saved = product.copyWith(
        id: nextProductId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      nextProductId += 1;
      return saved;
    }).toList();

    return WebDemoState(
      categories: categories,
      products: products,
      sales: const [],
      nextCategoryId: nextCategoryId,
      nextProductId: nextProductId,
      nextSaleId: 1,
      nextSaleItemId: 1,
    );
  }
}

class WebDemoState {
  const WebDemoState({
    required this.categories,
    required this.products,
    required this.sales,
    required this.nextCategoryId,
    required this.nextProductId,
    required this.nextSaleId,
    required this.nextSaleItemId,
  });

  final List<Category> categories;
  final List<Product> products;
  final List<DemoSaleRecord> sales;
  final int nextCategoryId;
  final int nextProductId;
  final int nextSaleId;
  final int nextSaleItemId;

  WebDemoState copyWith({
    List<Category>? categories,
    List<Product>? products,
    List<DemoSaleRecord>? sales,
    int? nextCategoryId,
    int? nextProductId,
    int? nextSaleId,
    int? nextSaleItemId,
  }) {
    return WebDemoState(
      categories: categories ?? this.categories,
      products: products ?? this.products,
      sales: sales ?? this.sales,
      nextCategoryId: nextCategoryId ?? this.nextCategoryId,
      nextProductId: nextProductId ?? this.nextProductId,
      nextSaleId: nextSaleId ?? this.nextSaleId,
      nextSaleItemId: nextSaleItemId ?? this.nextSaleItemId,
    );
  }
}

class DemoSaleRecord {
  const DemoSaleRecord({required this.sale, required this.items});

  final Sale sale;
  final List<SaleItem> items;
}

class _TopSellingAccumulator {
  _TopSellingAccumulator({required this.name});

  final String name;
  int quantitySold = 0;
  double revenue = 0;
}
