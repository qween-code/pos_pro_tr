class Customer {
  final String? id;  // Firestore için String ID
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final int loyaltyPoints;

  Customer({
    this.id,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.loyaltyPoints = 0,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id']?.toString(),
      name: json['name'],
      phone: json['phone'],
      email: json['email'],
      address: json['address'],
      loyaltyPoints: json['loyaltyPoints'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'loyaltyPoints': loyaltyPoints,
    };
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'loyaltyPoints': loyaltyPoints,
    };
  }
}