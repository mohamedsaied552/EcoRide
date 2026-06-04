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
      idVerificationStatus: idVerificationStatus ?? this.idVerificationStatus,
      phoneVerified: phoneVerified ?? this.phoneVerified,
      role: role ?? this.role,
    );
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    // Some endpoints wrap the payload as { data: { ... } } or { user: { ... } }.
    // Unwrap so callers can pass either the raw body or the wrapper.
    Map<String, dynamic> source = json;
    final nested = json['user'] ?? json['data'];
    if (nested is Map) {
      source = Map<String, dynamic>.from(nested);
    }

    final email = _readString(source, const ['email', 'Email']);
    final roleRaw = source['role'] ?? source['Role'];
    return AppUser(
      id: _readString(source, const ['id', 'userId', 'Id', 'ID']),
      name: _readString(source, const ['fullName', 'name', 'FullName', 'Name']),
      email: email,
      phone: _readString(source, const [
        'phoneNumber',
        'phone',
        'PhoneNumber',
        'Phone',
      ]),
      walletBalance: _readDouble(source, const [
        'walletBalance',
        'WalletBalance',
      ]),
      ridesCount: _readInt(source, const ['ridesCount', 'RidesCount']),
      rating: _readDouble(source, const ['rating', 'Rating']),
      avatarUrl: _sanitizeAvatarUrl(
        _readNullableString(source, const ['avatarUrl', 'AvatarUrl']),
      ),
      accountStatus: _readNullableString(source, const [
        'accountStatus',
        'AccountStatus',
      ]),
      idVerificationStatus: _readNullableString(source, const [
        'idVerificationStatus',
        'IdVerificationStatus',
      ]),
      phoneVerified: _readBool(source, const [
        'phoneVerified',
        'PhoneVerified',
      ]),
      role: _roleFromString(
        roleRaw is String ? roleRaw : _inferRoleFromEmail(email),
      ),
    );
  }

  static String _readString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is String) return value;
      if (value != null) return value.toString();
    }
    return '';
  }

  static String? _readNullableString(
    Map<String, dynamic> json,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = json[key];
      if (value == null) continue;
      if (value is String) return value;
      return value.toString();
    }
    return null;
  }

  static double _readDouble(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is num) return value.toDouble();
      if (value is String) {
        final parsed = double.tryParse(value);
        if (parsed != null) return parsed;
      }
    }
    return 0;
  }

  static int _readInt(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is num) return value.toInt();
      if (value is String) {
        final parsed = int.tryParse(value);
        if (parsed != null) return parsed;
      }
    }
    return 0;
  }

  static bool _readBool(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is bool) return value;
      if (value is num) return value != 0;
      if (value is String) {
        final lower = value.toLowerCase();
        if (lower == 'true') return true;
        if (lower == 'false') return false;
      }
    }
    return false;
  }

  static String _inferRoleFromEmail(String email) {
    return email.toLowerCase().contains('admin') ? 'admin' : 'user';
  }

  static String? _sanitizeAvatarUrl(String? url) {
    if (url == null || url.trim().isEmpty) return null;
    const ngrokBase = 'https://releasable-unrecessive-adam.ngrok-free.dev';
    final normalized = url.trim();
    if (normalized.contains('localhost:5001')) {
      return normalized.replaceFirst(
        RegExp(r'https?://localhost:5001'),
        ngrokBase,
      );
    }
    return normalized;
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
