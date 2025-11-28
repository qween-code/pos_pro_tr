class Order {
  final String? id;  // Firestore için String ID
  final String? customerId;
  final DateTime orderDate;
  final double totalAmount;
  final double taxAmount;
  final double discountAmount;
  final String? paymentMethod;
  final String status;
  final String? customerName;

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
    };
  }

  Map<String, dynamic> toMap() {
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
    };
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

  OrderItem({
    this.id,
    required this.orderId,
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    required this.taxRate,
    this.productName,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id']?.toString(),
      orderId: json['orderId'],
      productId: json['productId'],
      quantity: json['quantity'],
      unitPrice: (json['unitPrice'] ?? 0).toDouble(),
      taxRate: (json['taxRate'] ?? 0).toDouble(),
      productName: json['productName'],
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
    };
  }

  double get totalPrice => unitPrice * quantity;
  double get totalTax => totalPrice * taxRate;
  double get total => totalPrice + totalTax;
}