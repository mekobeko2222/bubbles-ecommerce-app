import 'package:flutter/material.dart'; // For ChangeNotifier and Locale
import 'package:shared_preferences/shared_preferences.dart'; // For persistence

class LocaleProvider extends ChangeNotifier {
  Locale? _locale; // Nullable to indicate no specific locale is set initially

  // Key for storing the locale in SharedPreferences
  static const String _localeKey = 'app_locale';

  Locale? get locale => _locale;

  LocaleProvider() {
    _loadLocale(); // Load the saved locale when the provider is instantiated
  }

  // Loads the previously saved locale from SharedPreferences
  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final String? languageCode = prefs.getString(_localeKey);

    if (languageCode != null) {
      _locale = Locale(languageCode);
    } else {
      // Default to English if no locale is saved (or use device locale logic if preferred)
      _locale = const Locale('en'); // Set a default initial locale if nothing found
    }
    notifyListeners(); // Notify listeners once the locale is loaded
  }

  // Sets the new locale and saves it to SharedPreferences
  Future<void> setLocale(Locale newLocale) async {
    if (_locale == newLocale) return; // No change needed

    _locale = newLocale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, newLocale.languageCode);
    notifyListeners(); // Notify listeners of the change
  }

  // Helper method to toggle between English and Arabic (for simplicity)
  void toggleLocale() {
    if (_locale?.languageCode == 'en') {
      setLocale(const Locale('ar'));
    } else {
      setLocale(const Locale('en'));
    }
  }
}
