class DailySalesSummary {
  const DailySalesSummary({
    required this.totalRevenue,
    required this.saleCount,
  });

  final double totalRevenue;
  final int saleCount;
}

class TopSellingProduct {
  const TopSellingProduct({
    required this.name,
    required this.quantitySold,
    required this.revenue,
  });

  final String name;
  final int quantitySold;
  final double revenue;
}

class HourlySalesPoint {
  const HourlySalesPoint({required this.hour, required this.revenue});

  final int hour;
  final double revenue;
}
