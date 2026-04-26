import 'package:sqflite/sqflite.dart';

import '../models/product.dart';

class ProductDao {
  const ProductDao(this._dbFuture);

  final Future<Database> _dbFuture;

  Future<List<Product>> fetchProducts({
    int? categoryId,
    String searchQuery = '',
    bool activeOnly = true,
  }) async {
    final db = await _dbFuture;
    final where = <String>[];
    final args = <Object?>[];

    if (activeOnly) {
      where.add('is_active = 1');
    }
    if (categoryId != null) {
      where.add('category_id = ?');
      args.add(categoryId);
    }
    if (searchQuery.trim().isNotEmpty) {
      where.add('(name LIKE ? COLLATE NOCASE OR sku LIKE ? COLLATE NOCASE)');
      final term = '%${searchQuery.trim()}%';
      args.addAll(<Object?>[term, term]);
    }

    final rows = await db.query(
      'products',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return rows.map(Product.fromMap).toList();
  }

  Future<int> upsert(Product product) async {
    final db = await _dbFuture;
    final map = product.toMap()
      ..remove('created_at')
      ..['updated_at'] = DateTime.now().toIso8601String();

    if (product.id == null) {
      map.remove('id');
      return db.insert('products', map);
    }

    await db.update(
      'products',
      map..remove('id'),
      where: 'id = ?',
      whereArgs: <Object?>[product.id],
    );
    return product.id!;
  }

  Future<void> softDelete(int id) async {
    final db = await _dbFuture;
    await db.update(
      'products',
      <String, Object?>{
        'is_active': 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  Future<List<Product>> fetchLowStockProducts() async {
    final db = await _dbFuture;
    final rows = await db.rawQuery('''
      SELECT * FROM products
      WHERE stock_quantity <= low_stock_threshold
        AND is_active = 1
      ORDER BY stock_quantity ASC, name COLLATE NOCASE ASC
    ''');
    return rows.map(Product.fromMap).toList();
  }
}
