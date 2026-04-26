import 'package:flutter/foundation.dart' hide Category;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import '../models/category.dart';
import 'seed_data.dart';

class DatabaseHelper {
  DatabaseHelper();

  static const _dbName = 'offline_pos.db';
  Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    _database = await _openDatabase();
    return _database!;
  }

  Future<Database> _openDatabase() async { 
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, _dbName);

    return openDatabase(
      path,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await _createSchema(db);
        await _seed(db);
      },
    );
  }

  Future<void> _createSchema(Database db) async {
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        color TEXT,
        sort_order INTEGER DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        price REAL NOT NULL CHECK(price >= 0),
        stock_quantity INTEGER NOT NULL DEFAULT 0 CHECK(stock_quantity >= 0),
        category_id INTEGER,
        image_path TEXT,
        sku TEXT UNIQUE,
        low_stock_threshold INTEGER DEFAULT 5,
        is_active INTEGER DEFAULT 1,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE SET NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_products_category ON products(category_id)',
    );
    await db.execute(
      'CREATE INDEX idx_products_name ON products(name COLLATE NOCASE)',
    );

    await db.execute('''
      CREATE TABLE sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        total_amount REAL NOT NULL,
        tax_amount REAL DEFAULT 0,
        discount_amount REAL DEFAULT 0,
        payment_method TEXT NOT NULL CHECK(payment_method IN ('cash', 'card', 'mobile', 'other')),
        timestamp TEXT NOT NULL DEFAULT (datetime('now','localtime')),
        is_completed INTEGER DEFAULT 1
      )
    ''');
    await db.execute('CREATE INDEX idx_sales_date ON sales(date(timestamp))');

    await db.execute('''
      CREATE TABLE sale_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sale_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        quantity INTEGER NOT NULL CHECK(quantity > 0),
        unit_price REAL NOT NULL,
        FOREIGN KEY (sale_id) REFERENCES sales(id) ON DELETE CASCADE,
        FOREIGN KEY (product_id) REFERENCES products(id)
      )
    ''');
    await db.execute('CREATE INDEX idx_sale_items_sale ON sale_items(sale_id)');
  }

  Future<void> _seed(Database db) async {
    final categoryBatch = db.batch();
    for (final category in SeedData.demoCategories) {
      categoryBatch.insert('categories', category.toMap()..remove('id'));
    }
    await categoryBatch.commit(noResult: true);

    final categoryRows = await db.query(
      'categories',
      orderBy: 'sort_order ASC',
    );
    final categories = categoryRows.map(Category.fromMap).toList();
    final productBatch = db.batch();
    for (final product in SeedData.buildProducts(categories)) {
      productBatch.insert('products', product.toMap()..remove('id'));
    }
    await productBatch.commit(noResult: true);
  }
}
