enum UserRole { user, admin }

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.walletBalance,
    required this.ridesCount,
    required this.rating,
    this.avatarUrl,
    this.accountStatus,
    this.idVerificationStatus,
    this.phoneVerified = false,
    this.role = UserRole.user,
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final double walletBalance;
  final int ridesCount;
  final double rating;
  final String? avatarUrl;
  final String? accountStatus;
  final String? idVerificationStatus;
  final bool phoneVerified;
  final UserRole role;

  bool get isAdmin => role == UserRole.admin;

  AppUser copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    double? walletBalance,
    int? ridesCount,
    double? rating,
    String? avatarUrl,
    String? accountStatus,
    String? idVerificationStatus,
    bool? phoneVerified,
    UserRole? role,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      walletBalance: walletBalance ?? this.walletBalance,
      ridesCount: ridesCount ?? this.ridesCount,
      rating: rating ?? this.rating,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      accountStatus: accountStatus ?? this.accountStatus,
      idVerificationStatus:
          idVerificationStatus ?? this.idVerificationStatus,
      phoneVerified: phoneVerified ?? this.phoneVerified,
      role: role ?? this.role,
    );
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    final email = (json['email'] ?? '') as String;
    return AppUser(
      id: json['id'] as String,
      name: (json['name'] ?? json['fullName'] ?? '') as String,
      email: email,
      phone: (json['phone'] ?? json['phoneNumber'] ?? '') as String,
      walletBalance: ((json['walletBalance'] ?? 0) as num).toDouble(),
      ridesCount: (json['ridesCount'] ?? 0) as int,
      rating: ((json['rating'] ?? 0) as num).toDouble(),
      avatarUrl: json['avatarUrl'] as String?,
      accountStatus: json['accountStatus'] as String?,
      idVerificationStatus: json['idVerificationStatus'] as String?,
      phoneVerified: (json['phoneVerified'] ?? false) as bool,
      role: _roleFromString((json['role'] ?? _inferRoleFromEmail(email)) as String),
    );
  }

  static String _inferRoleFromEmail(String email) {
    return email.toLowerCase().contains('admin') ? 'admin' : 'user';
  }

  static UserRole _roleFromString(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.user;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'fullName': name,
      'email': email,
      'phone': phone,
      'phoneNumber': phone,
      'walletBalance': walletBalance,
      'ridesCount': ridesCount,
      'rating': rating,
      'avatarUrl': avatarUrl,
      'accountStatus': accountStatus,
      'idVerificationStatus': idVerificationStatus,
      'phoneVerified': phoneVerified,
      'role': role.name,
    };
  }
}
