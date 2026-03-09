class AppUser {
  final String id;
  final String name;
  final String email;
  final String phone;
  final double walletBalance;
  final int ridesCount;
  final double rating;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.walletBalance,
    required this.ridesCount,
    required this.rating,
  });

  AppUser copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    double? walletBalance,
    int? ridesCount,
    double? rating,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      walletBalance: walletBalance ?? this.walletBalance,
      ridesCount: ridesCount ?? this.ridesCount,
      rating: rating ?? this.rating,
    );
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      walletBalance: (json['walletBalance'] as num).toDouble(),
      ridesCount: json['ridesCount'] as int,
      rating: (json['rating'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'walletBalance': walletBalance,
      'ridesCount': ridesCount,
      'rating': rating,
    };
  }
}
