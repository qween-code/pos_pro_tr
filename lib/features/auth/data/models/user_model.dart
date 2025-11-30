class UserModel {
  final String id;
  final String name;
  final String email;
  final String role; // 'admin', 'cashier', 'manager' gibi roller
  final String? region; // Şube bilgisi (Ana Şube, İstanbul, Ankara, İzmir)

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.region,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      role: json['role'],
      region: json['region'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      if (region != null) 'region': region,
    };
  }

  // Kullanıcının belirli bir yetkiye sahip olup olmadığını kontrol et
  bool hasPermission(String permission) {
    // Basit bir yetki kontrolü
    // Gerçek uygulamada daha karmaşık bir yetki sistemi kullanılabilir
    switch (role) {
      case 'admin':
        return true;
      case 'manager':
        return permission != 'delete_user';
      case 'cashier':
        return permission == 'create_order' || permission == 'view_products';
      default:
        return false;
    }
  }
}