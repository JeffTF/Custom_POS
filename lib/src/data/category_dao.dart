import 'package:sqflite/sqflite.dart';

import '../models/category.dart';

class CategoryDao {
  const CategoryDao(this._dbFuture);

  final Future<Database> _dbFuture;

  Future<List<Category>> fetchCategories() async {
    final db = await _dbFuture;
    final rows = await db.query(
      'categories',
      orderBy: 'sort_order ASC, name ASC',
    );
    return rows.map(Category.fromMap).toList();
  }

  Future<int> upsert(Category category) async {
    final db = await _dbFuture;
    final map = category.toMap()..remove('created_at');
    if (category.id == null) {
      map.remove('id');
      return db.insert('categories', map);
    }
    await db.update(
      'categories',
      map..remove('id'),
      where: 'id = ?',
      whereArgs: <Object?>[category.id],
    );
    return category.id!;
  }

  Future<void> delete(int id) async {
    final db = await _dbFuture;
    await db.delete('categories', where: 'id = ?', whereArgs: <Object?>[id]);
  }
}
