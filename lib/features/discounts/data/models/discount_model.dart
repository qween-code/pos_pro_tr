import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_constants.dart';

class Discount {
  final String? id;
  final String name;
  final String discountType; // 'percentage' veya 'fixed'
  final double discountValue;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;

  Discount({
    this.id,
    required this.name,
    required this.discountType,
    required this.discountValue,
    required this.startDate,
    required this.endDate,
    this.isActive = true,
  });

  factory Discount.fromJson(Map<String, dynamic> json) {
    return Discount(
      id: json['id'],
      name: json['name'],
      discountType: json['discountType'],
      discountValue: json['discountValue'].toDouble(),
      startDate: json['startDate'] is String
          ? DateTime.parse(json['startDate'])
          : (json['startDate'] as Timestamp).toDate(),
      endDate: json['endDate'] is String
          ? DateTime.parse(json['endDate'])
          : (json['endDate'] as Timestamp).toDate(),
      isActive: json['isActive'] is bool
          ? json['isActive']
          : json['isActive'] == 1 || json['isActive'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'discountType': discountType,
      'discountValue': discountValue,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'isActive': isActive,
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'discountType': discountType,
      'discountValue': discountValue,
      'startDate': DateFormat(AppConstants.dateFormat).format(startDate),
      'endDate': DateFormat(AppConstants.dateFormat).format(endDate),
      'isActive': isActive ? 1 : 0,
    };
  }

  String get displayValue {
    if (discountType == 'percentage') {
      return '%${(discountValue * 100).toStringAsFixed(0)}';
    } else {
      return '${discountValue.toStringAsFixed(2)} ₺';
    }
  }

  bool get isValid {
    final now = DateTime.now();
    return isActive && startDate.isBefore(now) && endDate.isAfter(now);
  }
}