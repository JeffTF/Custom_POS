enum PaymentMethod { cash, card, mobile, other }

class Sale {
  const Sale({
    this.id,
    required this.totalAmount,
    this.taxAmount = 0,
    this.discountAmount = 0,
    required this.paymentMethod,
    this.timestamp,
    this.isCompleted = true,
  });

  final int? id;
  final double totalAmount;
  final double taxAmount;
  final double discountAmount;
  final PaymentMethod paymentMethod;
  final DateTime? timestamp;
  final bool isCompleted;

  Sale copyWith({
    int? id,
    double? totalAmount,
    double? taxAmount,
    double? discountAmount,
    PaymentMethod? paymentMethod,
    DateTime? timestamp,
    bool? isCompleted,
  }) {
    return Sale(
      id: id ?? this.id,
      totalAmount: totalAmount ?? this.totalAmount,
      taxAmount: taxAmount ?? this.taxAmount,
      discountAmount: discountAmount ?? this.discountAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      timestamp: timestamp ?? this.timestamp,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  factory Sale.fromMap(Map<String, Object?> map) {
    return Sale(
      id: map['id'] as int?,
      totalAmount: (map['total_amount'] as num).toDouble(),
      taxAmount: (map['tax_amount'] as num?)?.toDouble() ?? 0,
      discountAmount: (map['discount_amount'] as num?)?.toDouble() ?? 0,
      paymentMethod: PaymentMethod.values.byName(
        map['payment_method'] as String,
      ),
      timestamp: _readDate(map['timestamp']),
      isCompleted: (map['is_completed'] as int? ?? 1) == 1,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'total_amount': totalAmount,
      'tax_amount': taxAmount,
      'discount_amount': discountAmount,
      'payment_method': paymentMethod.name,
      'timestamp': timestamp?.toIso8601String(),
      'is_completed': isCompleted ? 1 : 0,
    };
  }

  static DateTime? _readDate(Object? value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
