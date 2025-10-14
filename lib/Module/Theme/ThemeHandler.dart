import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ThemeHandler with ChangeNotifier {
  // 기본 색상
  Color _primaryColor;
  Color _lightPrimaryColor;
  Color _darkPrimaryColor;
  Color _desaturateColor;

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ThemeHandler()
      : _primaryColor = Colors.pink[200]!,
        _lightPrimaryColor = lightenColor(Colors.pink[200]!),
        _darkPrimaryColor = darkenColor(Colors.pink[200]!),
        _desaturateColor = desaturatenColor(Colors.pink[200]!) {
    loadColors(); // 생성자에서 색상을 불러오는 메서드 호출
  }

  // 각 색상에 대한 getter
  Color get primaryColor => _primaryColor;
  Color get lightPrimaryColor => _lightPrimaryColor;
  Color get darkPrimaryColor => _darkPrimaryColor;
  Color get desaturateColor => _desaturateColor;

  // 색상을 변경하고 저장하는 메서드
  void changePrimaryColor(Color primaryColor, String colorName) {
    _primaryColor = primaryColor;
    _lightPrimaryColor = lightenColor(primaryColor);
    _darkPrimaryColor = darkenColor(primaryColor);
    _desaturateColor = desaturatenColor(primaryColor);
    saveColor('primaryColor', primaryColor);
    saveColor('lightPrimaryColor', _lightPrimaryColor);
    saveColor('darkPrimaryColor', _darkPrimaryColor);
    saveColor('desaturateColor', _desaturateColor);

    FirebaseAnalytics.instance
        .logEvent(name: 'theme_color_change_to_$colorName');
    notifyListeners();
  }

  // 저장된 색상을 로드하는 메서드
  Future<void> loadColors() async {
    _primaryColor = await loadColor('primaryColor', Colors.pink[200]!);
    _lightPrimaryColor =
        await loadColor('lightPrimaryColor', lightenColor(Colors.pink[200]!));
    _darkPrimaryColor =
        await loadColor('darkPrimaryColor', darkenColor(Colors.pink[200]!));
    _desaturateColor =
        await loadColor('desaturateColor', desaturatenColor(Colors.pink[200]!));
    notifyListeners();
  }

  // 색상을 저장하는 메서드
  Future<void> saveColor(String key, Color color) async {
    await _storage.write(key: key, value: color.value.toRadixString(16));
  }

  // 색상을 불러오는 메서드
  Future<Color> loadColor(String key, Color defaultColor) async {
    final colorString = await _storage.read(key: key);
    if (colorString != null) {
      return Color(int.parse(colorString, radix: 16));
    }
    return defaultColor;
  }

  // 더 밝은 색상을 생성하는 메서드
  static Color lightenColor(Color color, {double amount = 0.2}) {
    assert(amount >= 0 && amount <= 1);
    final hslColor = HSLColor.fromColor(color);
    final lightenedHslColor = hslColor.withLightness(
      (hslColor.lightness + amount).clamp(0.0, 1.0),
    );
    return lightenedHslColor.toColor();
  }

  // 더 밝은 색상을 생성하는 메서드
  static Color darkenColor(Color color, {double amount = 0.2}) {
    assert(amount >= 0 && amount <= 1);
    final hslColor = HSLColor.fromColor(color);
    final lightenedHslColor = hslColor.withLightness(
      (hslColor.lightness - amount).clamp(0.0, 1.0),
    );
    return lightenedHslColor.toColor();
  }

  static Color desaturatenColor(Color color, {double amount = 0.5}) {
    assert(amount >= 0 && amount <= 1);
    return color.withOpacity(
      (color.opacity - amount).clamp(0.0, 1.0), // 투명도를 감소시킴
    );
  }
}
