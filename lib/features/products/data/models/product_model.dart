class Product {
  final String? id;
  final String name;
  final String? description;
  final double price;
  final int stock;
  final String category;
  final String? imageUrl;
  final String? barcode;
  final double taxRate;
  final bool isFavorite;
  final int criticalStockLevel; // Kritik stok seviyesi

  Product({
    this.id,
    required this.name,
    this.description,
    required this.price,
    required this.stock,
    required this.category,
    this.imageUrl,
    this.barcode,
    this.taxRate = 18.0,
    this.isFavorite = false,
    this.criticalStockLevel = 10,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id']?.toString(),
      name: json['name'] ?? '',
      description: json['description'],
      price: (json['price'] ?? 0.0).toDouble(),
      stock: (json['stock'] ?? 0).toInt(),
      category: json['category'] ?? 'Genel',
      imageUrl: json['imageUrl'],
      barcode: json['barcode'],
      taxRate: (json['taxRate'] ?? 18.0).toDouble(),
      isFavorite: json['isFavorite'] ?? false,
      criticalStockLevel: (json['criticalStockLevel'] ?? 10).toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'stock': stock,
      'category': category,
      'imageUrl': imageUrl,
      'barcode': barcode,
      'taxRate': taxRate,
      'isFavorite': isFavorite,
      'criticalStockLevel': criticalStockLevel,
    };
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'description': description,
      'price': price,
      'stock': stock,
      'category': category,
      'imageUrl': imageUrl,
      'barcode': barcode,
      'taxRate': taxRate,
      'isFavorite': isFavorite,
      'criticalStockLevel': criticalStockLevel,
    };
  }

  Product copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    int? stock,
    String? category,
    String? imageUrl,
    String? barcode,
    double? taxRate,
    bool? isFavorite,
    int? criticalStockLevel,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      barcode: barcode ?? this.barcode,
      taxRate: taxRate ?? this.taxRate,
      isFavorite: isFavorite ?? this.isFavorite,
      criticalStockLevel: criticalStockLevel ?? this.criticalStockLevel,
    );
  }
}