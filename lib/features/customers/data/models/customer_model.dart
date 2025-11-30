class Customer {
  final String? id;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final String? note;
  final double balance; // Müşteri bakiyesi (Pozitif: Borçlu, Negatif: Alacaklı)
  final int loyaltyPoints; // Sadakat puanı

  Customer({
    this.id,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.note,
    this.balance = 0.0,
    this.loyaltyPoints = 0,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id']?.toString(),
      name: json['name'] ?? '',
      phone: json['phone'],
      email: json['email'],
      address: json['address'],
      note: json['note'],
      balance: (json['balance'] ?? 0.0).toDouble(),
      loyaltyPoints: (json['loyaltyPoints'] ?? 0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'note': note,
      'balance': balance,
      'loyaltyPoints': loyaltyPoints,
    };
  }

  Customer copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? address,
    String? note,
    double? balance,
    int? loyaltyPoints,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      note: note ?? this.note,
      balance: balance ?? this.balance,
      loyaltyPoints: loyaltyPoints ?? this.loyaltyPoints,
    );
  }
}