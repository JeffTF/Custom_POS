import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../models/product.dart';
import '../../models/report_models.dart';
import '../utils/formatters.dart';

class ReportPanel extends StatelessWidget {
  const ReportPanel({
    super.key,
    required this.summary,
    required this.lowStockProducts,
    required this.topSelling,
    required this.hourlySales,
    required this.onExport,
  });

  final DailySalesSummary summary;
  final List<Product> lowStockProducts;
  final List<TopSellingProduct> topSelling;
  final List<HourlySalesPoint> hourlySales;
  final Future<void> Function() onExport;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _StatTile(
              label: 'Revenue Today',
              value: currencyFormatter.format(summary.totalRevenue),
            ),
            const SizedBox(width: 12),
            _StatTile(label: 'Transactions', value: '${summary.saleCount}'),
            const Spacer(),
            FilledButton.icon(
              onPressed: onExport,
              icon: const Icon(Icons.download_outlined),
              label: const Text('Export CSV'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hourly revenue',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 16),
                        Expanded(child: _HourlyChart(points: hourlySales)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Low stock alerts',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 12),
                              Expanded(
                                child: lowStockProducts.isEmpty
                                    ? const Center(
                                        child: Text(
                                          'No low-stock products today.',
                                        ),
                                      )
                                    : ListView.separated(
                                        itemCount: lowStockProducts.length,
                                        separatorBuilder: (context, index) =>
                                            const Divider(height: 12),
                                        itemBuilder: (context, index) {
                                          final item = lowStockProducts[index];
                                          return Row(
                                            children: [
                                              Expanded(child: Text(item.name)),
                                              Text(
                                                'Stock ${item.stockQuantity}',
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Top sellers',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 12),
                              Expanded(
                                child: topSelling.isEmpty
                                    ? const Center(
                                        child: Text('No completed sales yet.'),
                                      )
                                    : ListView.separated(
                                        itemCount: topSelling.length,
                                        separatorBuilder: (context, index) =>
                                            const Divider(height: 12),
                                        itemBuilder: (context, index) {
                                          final item = topSelling[index];
                                          return Row(
                                            children: [
                                              Expanded(child: Text(item.name)),
                                              Text('${item.quantitySold} sold'),
                                            ],
                                          );
                                        },
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

class _HourlyChart extends StatelessWidget {
  const _HourlyChart({required this.points});

  final List<HourlySalesPoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const Center(child: Text('No revenue yet today.'));
    }

    return BarChart(
      BarChartData(
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 54,
              getTitlesWidget: (value, meta) {
                return Text('\$${value.toInt()}');
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text('${value.toInt()}:00');
              },
            ),
          ),
        ),
        barGroups: points.map((point) {
          return BarChartGroupData(
            x: point.hour,
            barRods: [
              BarChartRodData(
                toY: point.revenue,
                width: 18,
                borderRadius: BorderRadius.circular(4),
                color: const Color(0xFF0F766E),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
