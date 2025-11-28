import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_constants.dart';

class Payment {
  final String? id;
  final String orderId;
  final double amount;
  final String paymentMethod;
  final DateTime paymentDate;
  final String? transactionId;
  final String? orderNumber;
  final String? customerName;

  Payment({
    this.id,
    required this.orderId,
    required this.amount,
    required this.paymentMethod,
    required this.paymentDate,
    this.transactionId,
    this.orderNumber,
    this.customerName,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'],
      orderId: json['orderId'],
      amount: json['amount'].toDouble(),
      paymentMethod: json['paymentMethod'],
      paymentDate: json['paymentDate'] is String
          ? DateTime.parse(json['paymentDate'])
          : (json['paymentDate'] as Timestamp).toDate(),
      transactionId: json['transactionId'],
      orderNumber: json['orderNumber'],
      customerName: json['customerName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderId': orderId,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'paymentDate': paymentDate.toIso8601String(),
      'transactionId': transactionId,
      'orderNumber': orderNumber,
      'customerName': customerName,
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'orderId': orderId,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'paymentDate': DateFormat(AppConstants.dateFormat).format(paymentDate),
      'transactionId': transactionId,
      'orderNumber': orderNumber,
      'customerName': customerName,
    };
  }
}