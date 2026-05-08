class AuthToken {
  const AuthToken({
    required this.accessToken,
    required this.expiresAt,
    required this.refreshToken,
    required this.refreshTokenExpiration,
  });

  final String accessToken;
  final DateTime expiresAt;
  final String refreshToken;
  final DateTime refreshTokenExpiration;

  factory AuthToken.fromJson(Map<String, dynamic> json) {
    return AuthToken(
      accessToken: (json['accessToken'] ?? '') as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      refreshToken: (json['refreshToken'] ?? '') as String,
      refreshTokenExpiration: DateTime.parse(
        json['refreshTokenExpiration'] as String,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'expiresAt': expiresAt.toIso8601String(),
      'refreshToken': refreshToken,
      'refreshTokenExpiration': refreshTokenExpiration.toIso8601String(),
    };
  }
}
