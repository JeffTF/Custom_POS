import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/report_models.dart';
import '../models/sale.dart';
import '../models/sale_item.dart';

class InsufficientStockException implements Exception {
  const InsufficientStockException(this.productId);

  final int productId;

  @override
  String toString() => 'InsufficientStockException(productId: $productId)';
}

class SaleDao {
  const SaleDao(this._dbFuture);

  final Future<Database> _dbFuture;

  Future<void> processSale(Sale sale, List<SaleItem> items) async {
    final db = await _dbFuture;
    await db.transaction((txn) async {
      final saleId = await txn.insert('sales', sale.toMap()..remove('id'));

      for (final item in items) {
        await txn.insert(
          'sale_items',
          item.toMap()
            ..remove('id')
            ..['sale_id'] = saleId,
        );

        final updated = await txn.rawUpdate(
          '''
          UPDATE products
          SET stock_quantity = stock_quantity - ?, updated_at = ?
          WHERE id = ? AND stock_quantity >= ?
          ''',
          <Object?>[
            item.quantity,
            DateTime.now().toIso8601String(),
            item.productId,
            item.quantity,
          ],
        );

        if (updated == 0) {
          throw InsufficientStockException(item.productId);
        }
      }
    });
  }

  Future<DailySalesSummary> fetchDailySummary() async {
    final db = await _dbFuture;
    final rows = await db.rawQuery('''
      SELECT COALESCE(SUM(total_amount), 0) AS total_amount, COUNT(*) AS sale_count
      FROM sales
      WHERE date(timestamp) = date('now','localtime')
    ''');
    final row = rows.single;
    return DailySalesSummary(
      totalRevenue: (row['total_amount'] as num?)?.toDouble() ?? 0,
      saleCount: (row['sale_count'] as num?)?.toInt() ?? 0,
    );
  }

  Future<List<TopSellingProduct>> fetchTopSellingProducts() async {
    final db = await _dbFuture;
    final rows = await db.rawQuery('''
      SELECT p.name AS product_name,
             SUM(si.quantity) AS quantity_sold,
             SUM(si.quantity * si.unit_price) AS revenue
      FROM sale_items si
      INNER JOIN sales s ON s.id = si.sale_id
      INNER JOIN products p ON p.id = si.product_id
      WHERE date(s.timestamp) = date('now','localtime')
      GROUP BY si.product_id, p.name
      ORDER BY quantity_sold DESC, revenue DESC
      LIMIT 10
    ''');

    return rows.map((row) {
      return TopSellingProduct(
        name: row['product_name'] as String,
        quantitySold: (row['quantity_sold'] as num).toInt(),
        revenue: (row['revenue'] as num).toDouble(),
      );
    }).toList();
  }

  Future<List<HourlySalesPoint>> fetchHourlyBreakdown() async {
    final db = await _dbFuture;
    final rows = await db.rawQuery('''
      SELECT CAST(strftime('%H', timestamp) AS INTEGER) AS sale_hour,
             SUM(total_amount) AS revenue
      FROM sales
      WHERE date(timestamp) = date('now','localtime')
      GROUP BY sale_hour
      ORDER BY sale_hour ASC
    ''');

    return rows.map((row) {
      return HourlySalesPoint(
        hour: (row['sale_hour'] as num).toInt(),
        revenue: (row['revenue'] as num).toDouble(),
      );
    }).toList();
  }

  Future<String> exportDailyReportCsv() async {
    final db = await _dbFuture;
    final rows = await db.rawQuery('''
      SELECT s.id,
             s.timestamp,
             s.payment_method,
             s.total_amount,
             s.tax_amount,
             s.discount_amount
      FROM sales s
      WHERE date(s.timestamp) = date('now','localtime')
      ORDER BY s.timestamp DESC
    ''');

    final dir = await getApplicationDocumentsDirectory();
    final file = File(
      p.join(
        dir.path,
        'daily_report_${DateTime.now().millisecondsSinceEpoch}.csv',
      ),
    );

    final lines = <String>[
      'sale_id,timestamp,payment_method,total_amount,tax_amount,discount_amount',
      ...rows.map((row) {
        return [
          row['id'],
          row['timestamp'],
          row['payment_method'],
          row['total_amount'],
          row['tax_amount'],
          row['discount_amount'],
        ].join(',');
      }),
    ];

    await file.writeAsString(lines.join('\n'));
    return file.path;
  }

 
}
