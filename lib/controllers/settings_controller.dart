import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// GetX controller for theme and locale settings.
/// Persists to SharedPreferences so settings survive app restarts.
class SettingsController extends GetxController {
  static const _themeKey  = 'theme_mode';
  static const _localeKey = 'locale';

  late SharedPreferences _prefs;

  final Rx<ThemeMode> themeMode = ThemeMode.system.obs;
  final Rxn<Locale>   locale    = Rxn<Locale>();

  @override
  Future<void> onInit() async {
    super.onInit();
    _prefs = await SharedPreferences.getInstance();
    _load();
  }

  void _load() {
    // Theme
    switch (_prefs.getString(_themeKey)) {
      case 'light':  themeMode.value = ThemeMode.light;
      case 'dark':   themeMode.value = ThemeMode.dark;
      default:       themeMode.value = ThemeMode.system;
    }
    // Locale
    final code = _prefs.getString(_localeKey);
    if (code != null) locale.value = Locale(code);
  }

  void setTheme(ThemeMode mode) {
    themeMode.value = mode;
    _prefs.setString(_themeKey, mode.name);
    Get.changeThemeMode(mode);
  }

  void setLocale(Locale loc) {
    locale.value = loc;
    _prefs.setString(_localeKey, loc.languageCode);
    Get.updateLocale(loc);
  }
}
