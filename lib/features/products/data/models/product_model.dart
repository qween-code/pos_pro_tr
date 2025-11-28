class Product {
  final String? id;  // Firestore için String ID
  final String name;
  final double price;
  final int stock;
  final String? category;
  final String? barcode;
  final double taxRate;

  Product({
    this.id,
    required this.name,
    required this.price,
    required this.stock,
    this.category,
    this.barcode,
    this.taxRate = 0.10,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id']?.toString(),  // String'e çevir
      name: json['name'],
      price: (json['price'] ?? 0).toDouble(),
      stock: json['stock'] ?? 0,
      category: json['category'],
      barcode: json['barcode'],
      taxRate: (json['taxRate'] ?? 0.10).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'price': price,
      'stock': stock,
      'category': category,
      'barcode': barcode,
      'taxRate': taxRate,
    };
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'price': price,
      'stock': stock,
      'category': category,
      'barcode': barcode,
      'taxRate': taxRate,
    };
  }
}