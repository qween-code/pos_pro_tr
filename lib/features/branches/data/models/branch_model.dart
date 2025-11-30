class Branch {
  final String? id;
  final String name;
  final String address;
  final String? phone;
  final String? email;
  final bool isActive;
  final DateTime createdAt;

  Branch({
    this.id,
    required this.name,
    required this.address,
    this.phone,
    this.email,
    this.isActive = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Branch.fromJson(Map<String, dynamic> json) {
    return Branch(
      id: json['id']?.toString(),
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      phone: json['phone'],
      email: json['email'],
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] is String
          ? DateTime.parse(json['createdAt'])
          : (json['createdAt'] as dynamic).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'address': address,
      'phone': phone,
      'email': email,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Branch copyWith({
    String? id,
    String? name,
    String? address,
    String? phone,
    String? email,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return Branch(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
