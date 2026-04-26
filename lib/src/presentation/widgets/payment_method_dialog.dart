import 'package:flutter/material.dart';

import '../../models/sale.dart';

class PaymentMethodDialog extends StatelessWidget {
  const PaymentMethodDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select payment method'),
      content: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: PaymentMethod.values.map((method) {
          return SizedBox(
            width: 130,
            child: FilledButton.tonalIcon(
              onPressed: () => Navigator.of(context).pop(method),
              icon: Icon(_iconFor(method)),
              label: Text(_labelFor(method)),
            ),
          );
        }).toList(),
      ),
    );
  }

  static IconData _iconFor(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return Icons.payments_outlined;
      case PaymentMethod.card:
        return Icons.credit_card_outlined;
      case PaymentMethod.mobile:
        return Icons.phone_iphone_outlined;
      case PaymentMethod.other:
        return Icons.point_of_sale_outlined;
    }
  }

  static String _labelFor(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.card:
        return 'Card';
      case PaymentMethod.mobile:
        return 'Mobile';
      case PaymentMethod.other:
        return 'Other';
    }
  }
}
