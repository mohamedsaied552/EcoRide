import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleCubit extends Cubit<Locale> {
  LocaleCubit() : super(const Locale('en'));

  static const _languageCodeKey = 'language_code';

  Future<void> loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_languageCodeKey);
    switch (languageCode) {
      case 'ar':
        emit(const Locale('ar'));
      case 'en':
        emit(const Locale('en'));
    }
  }

  Future<void> toggleLanguage() async {
    final nextLocale = state.languageCode == 'en'
        ? const Locale('ar')
        : const Locale('en');
    emit(nextLocale);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageCodeKey, nextLocale.languageCode);
  }

  String languageLabel() {
    return state.languageCode == 'en' ? 'English' : 'العربية';
  }
}
