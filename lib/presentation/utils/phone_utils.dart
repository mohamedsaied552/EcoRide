class PhoneUtils {
  PhoneUtils._();

  static const int egyptLocalDigits = 10;

  static String digitsOnly(String input) {
    return input.replaceAll(RegExp(r'\D'), '');
  }

  /// Builds E.164-style international number, e.g. `+201004832172`.
  static String toInternational({
    required String dialCode,
    required String localNumber,
  }) {
    final dial = dialCode.trim().startsWith('+')
        ? dialCode.trim()
        : '+${dialCode.trim()}';
    final local = digitsOnly(localNumber);
    return '$dial$local';
  }

  /// Validates Egypt local numbers (10 digits after country code).
  static String? validateEgyptLocalNumber(String localNumber) {
    final digits = digitsOnly(localNumber);
    if (digits.isEmpty) {
      return 'empty';
    }
    if (digits.length != egyptLocalDigits) {
      return 'invalidLength';
    }
    if (!RegExp(r'^1\d{9}$').hasMatch(digits)) {
      return 'invalidFormat';
    }
    return null;
  }
}

class CountryDialCode {
  const CountryDialCode({
    required this.name,
    required this.dialCode,
    required this.flag,
    this.localDigits = PhoneUtils.egyptLocalDigits,
  });

  final String name;
  final String dialCode;
  final String flag;
  final int localDigits;

  static const CountryDialCode egypt = CountryDialCode(
    name: 'Egypt',
    dialCode: '+20',
    flag: '🇪🇬',
  );

  static const List<CountryDialCode> supported = <CountryDialCode>[
    egypt,
    CountryDialCode(name: 'Saudi Arabia', dialCode: '+966', flag: '🇸🇦', localDigits: 9),
    CountryDialCode(name: 'UAE', dialCode: '+971', flag: '🇦🇪', localDigits: 9),
  ];
}
