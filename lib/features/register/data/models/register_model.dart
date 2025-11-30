import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterModel {
  final String? id;
  final String userId;
  final String userName;
  final DateTime openingTime;
  final DateTime? closingTime;
  final double openingBalance;
  final double? closingBalance;
  final double totalCashSales;
  final double totalCardSales;
  final double totalOtherSales;
  final String status; // 'open', 'closed'
  final String? notes;

  RegisterModel({
    this.id,
    required this.userId,
    required this.userName,
    required this.openingTime,
    this.closingTime,
    required this.openingBalance,
    this.closingBalance,
    this.totalCashSales = 0.0,
    this.totalCardSales = 0.0,
    this.totalOtherSales = 0.0,
    this.status = 'open',
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'openingTime': Timestamp.fromDate(openingTime),
      'closingTime': closingTime != null ? Timestamp.fromDate(closingTime!) : null,
      'openingBalance': openingBalance,
      'closingBalance': closingBalance,
      'totalCashSales': totalCashSales,
      'totalCardSales': totalCardSales,
      'totalOtherSales': totalOtherSales,
      'status': status,
      'notes': notes,
    };
  }

  factory RegisterModel.fromJson(Map<String, dynamic> json) {
    return RegisterModel(
      id: json['id'],
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      openingTime: (json['openingTime'] as Timestamp).toDate(),
      closingTime: json['closingTime'] != null ? (json['closingTime'] as Timestamp).toDate() : null,
      openingBalance: (json['openingBalance'] ?? 0.0).toDouble(),
      closingBalance: json['closingBalance']?.toDouble(),
      totalCashSales: (json['totalCashSales'] ?? json['cashSales'] ?? 0.0).toDouble(),
      totalCardSales: (json['totalCardSales'] ?? json['cardSales'] ?? 0.0).toDouble(),
      totalOtherSales: (json['totalOtherSales'] ?? json['otherSales'] ?? 0.0).toDouble(),
      status: json['status'] ?? 'open',
      notes: json['notes'],
    );
  }

  RegisterModel copyWith({
    String? id,
    String? userId,
    String? userName,
    DateTime? openingTime,
    DateTime? closingTime,
    double? openingBalance,
    double? closingBalance,
    double? totalCashSales,
    double? totalCardSales,
    double? totalOtherSales,
    String? status,
    String? notes,
  }) {
    return RegisterModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      openingTime: openingTime ?? this.openingTime,
      closingTime: closingTime ?? this.closingTime,
      openingBalance: openingBalance ?? this.openingBalance,
      closingBalance: closingBalance ?? this.closingBalance,
      totalCashSales: totalCashSales ?? this.totalCashSales,
      totalCardSales: totalCardSales ?? this.totalCardSales,
      totalOtherSales: totalOtherSales ?? this.totalOtherSales,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }
}
