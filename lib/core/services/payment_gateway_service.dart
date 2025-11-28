import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// POS Terminal Provider Interface
abstract class POSProvider {
  Future<PaymentResponse> processPayment(PaymentRequest request);
  Future<bool> refund(String transactionId, double amount);
  Future<TransactionStatus> checkStatus(String transactionId);
}

/// İyzico Payment Provider
class IyzicoProvider implements POSProvider {
  final String apiKey;
  final String secretKey;
  final String baseUrl;

  IyzicoProvider({
    required this.apiKey,
    required this.secretKey,
    this.baseUrl = 'https://api.iyzipay.com',
  });

  @override
  Future<PaymentResponse> processPayment(PaymentRequest request) async {
    try {
      final url = Uri.parse('$baseUrl/payment/auth');
      
      final body = {
        'locale': 'tr',
        'conversationId': request.conversationId,
        'price': request.amount.toString(),
        'paidPrice': request.amount.toString(),
        'currency': 'TRY',
        'installment': '1',
        'basketId': request.orderId,
        'paymentChannel': 'WEB',
        'paymentGroup': 'PRODUCT',
        'paymentCard': {
          'cardHolderName': request.cardHolderName,
          'cardNumber': request.cardNumber,
          'expireMonth': request.expireMonth,
          'expireYear': request.expireYear,
          'cvc': request.cvc,
        },
        'buyer': {
          'id': request.customerId,
          'name': request.customerName.split(' ').first,
          'surname': request.customerName.split(' ').last,
          'email': request.email,
          'identityNumber': '11111111111', // Müşteri TC/Vergi No
          'registrationAddress': request.address,
          'city': request.city,
          'country': 'Turkey',
          'ip': request.ip,
        },
        'shippingAddress': {
          'contactName': request.customerName,
          'city': request.city,
          'country': 'Turkey',
          'address': request.address,
        },
        'billingAddress': {
          'contactName': request.customerName,
          'city': request.city,
          'country': 'Turkey',
          'address': request.address,
        },
        'basketItems': request.items.map((item) => {
          'id': item.id,
          'name': item.name,
          'category1': item.category,
          'itemType': 'PHYSICAL',
          'price': item.price.toString(),
        }).toList(),
      };

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': _generateAuthToken(),
        },
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);

      if (data['status'] == 'success') {
        return PaymentResponse(
          success: true,
          transactionId: data['paymentId'],
          authCode: data['authCode'],
          message: 'Ödeme başarılı',
        );
      } else {
        return PaymentResponse(
          success: false,
          message: data['errorMessage'] ?? 'Ödeme başarısız',
        );
      }
    } catch (e) {
      return PaymentResponse(
        success: false,
        message: 'Bağlantı hatası: $e',
      );
    }
  }

  @override
  Future<bool> refund(String transactionId, double amount) async {
    try {
      final url = Uri.parse('$baseUrl/payment/refund');
      
      final body = {
        'paymentTransactionId': transactionId,
        'price': amount.toString(),
        'currency': 'TRY',
      };

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': _generateAuthToken(),
        },
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);
      return data['status'] == 'success';
    } catch (e) {
      debugPrint('İade hatası: $e');
      return false;
    }
  }

  @override
  Future<TransactionStatus> checkStatus(String transactionId) async {
    // İyzico transaction status check
    return TransactionStatus.success;
  }

  String _generateAuthToken() {
    // İyzico authorization token generation
    final random = DateTime.now().millisecondsSinceEpoch.toString();
    final hashStr = '$apiKey$random$secretKey';
    // Base64 encode - gerçek implementasyonda HMAC-SHA256 kullanılmalı
    return 'IYZWS $apiKey:${base64Encode(utf8.encode(hashStr))}';
  }
}

/// PayTR Payment Provider
class PayTRProvider implements POSProvider {
  final String merchantId;
  final String merchantKey;
  final String merchantSalt;

  PayTRProvider({
    required this.merchantId,
    required this.merchantKey,
    required this.merchantSalt,
  });

  @override
  Future<PaymentResponse> processPayment(PaymentRequest request) async {
    // PayTR implementasyonu
    return PaymentResponse(success: false, message: 'PayTR yakında eklenecek');
  }

  @override
  Future<bool> refund(String transactionId, double amount) async {
    return false;
  }

  @override
  Future<TransactionStatus> checkStatus(String transactionId) async {
    return TransactionStatus.pending;
  }
}

/// Payment Request Model
class PaymentRequest {
  final String conversationId;
  final String orderId;
  final double amount;
  final String cardHolderName;
  final String cardNumber;
  final String expireMonth;
  final String expireYear;
  final String cvc;
  final String customerId;
  final String customerName;
  final String email;
  final String address;
  final String city;
  final String ip;
  final List<BasketItem> items;

  PaymentRequest({
    required this.conversationId,
    required this.orderId,
    required this.amount,
    required this.cardHolderName,
    required this.cardNumber,
    required this.expireMonth,
    required this.expireYear,
    required this.cvc,
    required this.customerId,
    required this.customerName,
    required this.email,
    required this.address,
    required this.city,
    required this.ip,
    required this.items,
  });
}

class BasketItem {
  final String id;
  final String name;
  final String category;
  final double price;

  BasketItem({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
  });
}

/// Payment Response Model
class PaymentResponse {
  final bool success;
  final String? transactionId;
  final String? authCode;
  final String message;

  PaymentResponse({
    required this.success,
    this.transactionId,
    this.authCode,
    required this.message,
  });
}

enum TransactionStatus {
  success,
  pending,
  failed,
  refunded,
}
