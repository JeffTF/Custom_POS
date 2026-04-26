import 'package:flutter/material.dart';

class Category {
  const Category({
    this.id,
    required this.name,
    required this.color,
    this.sortOrder = 0,
    this.createdAt,
  });

  final int? id;
  final String name;
  final String color;
  final int sortOrder;
  final DateTime? createdAt;

  Color get chipColor {
    final hex = color.replaceFirst('#', '');
    final value = int.tryParse(hex, radix: 16);
    if (value == null) {
      return const Color(0xFF0F766E);
    }
    return Color(int.parse('FF$hex', radix: 16));
  }

  Category copyWith({
    int? id,
    String? name,
    String? color,
    int? sortOrder,
    DateTime? createdAt,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory Category.fromMap(Map<String, Object?> map) {
    return Category(
      id: map['id'] as int?,
      name: map['name'] as String,
      color: (map['color'] as String?) ?? '#0F766E',
      sortOrder: (map['sort_order'] as int?) ?? 0,
      createdAt: _readDate(map['created_at']),
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'name': name,
      'color': color,
      'sort_order': sortOrder,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  static DateTime? _readDate(Object? value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
