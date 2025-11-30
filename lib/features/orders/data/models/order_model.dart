class Order {
  final String? id;
  final String? customerId;
  final DateTime orderDate;
  final double totalAmount;
  final double taxAmount;
  final double discountAmount;
  final String? paymentMethod; // Ana ödeme yöntemi (uyumluluk için)
  final String status;
  final String? customerName;
  final List<PaymentDetail> payments;
  final String? cashierName;
  final String? cashierId;
  final String? branchId;
  final List<OrderItem> items; // Denormalized items

  Order({
    this.id,
    this.customerId,
    required this.orderDate,
    required this.totalAmount,
    required this.taxAmount,
    this.discountAmount = 0,
    this.paymentMethod,
    this.status = 'pending',
    this.customerName,
    this.payments = const [],
    this.cashierName,
    this.cashierId,
    this.branchId,
    this.items = const [],
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id']?.toString(),
      customerId: json['customerId'],
      orderDate: json['orderDate'] is String
          ? DateTime.parse(json['orderDate'])
          : (json['orderDate'] as dynamic).toDate(),
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      taxAmount: (json['taxAmount'] ?? 0).toDouble(),
      discountAmount: (json['discountAmount'] ?? 0).toDouble(),
      paymentMethod: json['paymentMethod'],
      status: json['status'] ?? 'pending',
      customerName: json['customerName'],
      payments: (json['payments'] as List<dynamic>?)
              ?.map((e) => PaymentDetail.fromJson(e))
              .toList() ??
          [],
      cashierName: json['cashierName'],
      cashierId: json['cashierId'],
      branchId: json['branchId'],
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => OrderItem.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'customerId': customerId,
      'orderDate': orderDate.toIso8601String(),
      'totalAmount': totalAmount,
      'taxAmount': taxAmount,
      'discountAmount': discountAmount,
      'paymentMethod': paymentMethod,
      'status': status,
      'customerName': customerName,
      'payments': payments.map((e) => e.toJson()).toList(),
      'cashierName': cashierName,
      'cashierId': cashierId,
      'branchId': branchId,
      'items': items.map((e) => e.toJson()).toList(),
    };
  }

  Map<String, dynamic> toMap() {
    return toJson();
  }
  Order copyWith({
    String? id,
    String? customerId,
    DateTime? orderDate,
    double? totalAmount,
    double? taxAmount,
    double? discountAmount,
    String? paymentMethod,
    String? status,
    String? customerName,
    List<PaymentDetail>? payments,
    String? cashierName,
    String? cashierId,
    String? branchId,
    List<OrderItem>? items,
  }) {
    return Order(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      orderDate: orderDate ?? this.orderDate,
      totalAmount: totalAmount ?? this.totalAmount,
      taxAmount: taxAmount ?? this.taxAmount,
      discountAmount: discountAmount ?? this.discountAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      customerName: customerName ?? this.customerName,
      payments: payments ?? this.payments,
      cashierName: cashierName ?? this.cashierName,
      cashierId: cashierId ?? this.cashierId,
      branchId: branchId ?? this.branchId,
      items: items ?? this.items,
    );
  }
}

class OrderItem {
  final String? id;
  final String orderId;
  final String productId;
  final int quantity;
  final double unitPrice;
  final double taxRate;
  final String? productName;
  final int refundedQuantity; // İade edilen miktar

  OrderItem({
    this.id,
    required this.orderId,
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    required this.taxRate,
    this.productName,
    this.refundedQuantity = 0,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id']?.toString(),
      orderId: json['orderId']?.toString() ?? '',
      productId: json['productId']?.toString() ?? '',
      quantity: (json['quantity'] as int?) ?? 1,
      unitPrice: (json['unitPrice'] ?? 0).toDouble(),
      taxRate: (json['taxRate'] ?? 0).toDouble(),
      productName: json['productName']?.toString(),
      refundedQuantity: (json['refundedQuantity'] as int?) ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'orderId': orderId,
      'productId': productId,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'taxRate': taxRate,
      'productName': productName,
      'refundedQuantity': refundedQuantity,
    };
  }

  double get totalPrice => unitPrice * quantity;
  double get totalTax => totalPrice * taxRate;
  double get total => totalPrice + totalTax;
}

class PaymentDetail {
  final String method; // 'cash', 'card', 'other'
  final double amount;

  PaymentDetail({required this.method, required this.amount});

  factory PaymentDetail.fromJson(Map<String, dynamic> json) {
    return PaymentDetail(
      method: json['method'] ?? 'cash',
      amount: (json['amount'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'method': method,
      'amount': amount,
    };
  }
}