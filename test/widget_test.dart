import 'package:flutter_test/flutter_test.dart';
import 'package:pos_demo/src/data/sale_dao.dart';
import 'package:pos_demo/src/models/product.dart';
import 'package:pos_demo/src/models/sale.dart';
import 'package:pos_demo/src/models/sale_item.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Database database;
  late SaleDao saleDao;

  setUp(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    database = await openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE products (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            price REAL NOT NULL,
            stock_quantity INTEGER NOT NULL,
            category_id INTEGER,
            image_path TEXT,
            sku TEXT UNIQUE,
            low_stock_threshold INTEGER DEFAULT 5,
            is_active INTEGER DEFAULT 1,
            created_at TEXT,
            updated_at TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE sales (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            total_amount REAL NOT NULL,
            tax_amount REAL DEFAULT 0,
            discount_amount REAL DEFAULT 0,
            payment_method TEXT NOT NULL,
            timestamp TEXT NOT NULL,
            is_completed INTEGER DEFAULT 1
          )
        ''');
        await db.execute('''
          CREATE TABLE sale_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            sale_id INTEGER NOT NULL,
            product_id INTEGER NOT NULL,
            quantity INTEGER NOT NULL,
            unit_price REAL NOT NULL
          )
        ''');
      },
    );
    saleDao = SaleDao(Future<Database>.value(database));
  });

  tearDown(() async {
    await database.close();
  });

  test(
    'processSale decrements stock and records sale items atomically',
    () async {
      final productId = await database.insert(
        'products',
        const Product(name: 'Coffee', price: 4.5, stockQuantity: 5).toMap()
          ..remove('id'),
      );

      await saleDao.processSale(
        Sale(
          totalAmount: 9,
          taxAmount: 0.63,
          paymentMethod: PaymentMethod.cash,
          timestamp: DateTime(2026, 4, 26, 10),
        ),
        [SaleItem(productId: productId, quantity: 2, unitPrice: 4.5)],
      );

      final products = await database.query(
        'products',
        where: 'id = ?',
        whereArgs: [productId],
      );
      final sales = await database.query('sales');
      final items = await database.query('sale_items');

      expect(products.single['stock_quantity'], 3);
      expect(sales, hasLength(1));
      expect(items, hasLength(1));
    },
  );

  test('processSale rolls back when stock is insufficient', () async {
    final productId = await database.insert(
      'products',
      const Product(name: 'Tea', price: 3.0, stockQuantity: 1).toMap()
        ..remove('id'),
    );

    expect(
      () => saleDao.processSale(
        Sale(
          totalAmount: 6,
          taxAmount: 0.42,
          paymentMethod: PaymentMethod.card,
          timestamp: DateTime(2026, 4, 26, 11),
        ),
        [SaleItem(productId: productId, quantity: 2, unitPrice: 3)],
      ),
      throwsA(isA<InsufficientStockException>()),
    );

    final products = await database.query(
      'products',
      where: 'id = ?',
      whereArgs: [productId],
    );
    final sales = await database.query('sales');
    final items = await database.query('sale_items');

    expect(products.single['stock_quantity'], 1);
    expect(sales, isEmpty);
    expect(items, isEmpty);
  });
}
