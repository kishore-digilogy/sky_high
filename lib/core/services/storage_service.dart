import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _isFirstTimeKey = 'is_first_time';
  static const String _tokenKey = 'auth_token';
  static const String _userDataKey = 'user_data';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  bool getIsFirstTime() {
    return _prefs.getBool(_isFirstTimeKey) ?? true;
  }

  Future<void> setIsFirstTime(bool value) async {
    await _prefs.setBool(_isFirstTimeKey, value);
  }

  String? getToken() {
    return _prefs.getString(_tokenKey);
  }

  Future<void> setToken(String? token) async {
    if (token == null) {
      await _prefs.remove(_tokenKey);
    } else {
      await _prefs.setString(_tokenKey, token);
    }
  }

  Map<String, dynamic>? getUserData() {
    final dataStr = _prefs.getString(_userDataKey);
    if (dataStr != null) {
      return json.decode(dataStr) as Map<String, dynamic>;
    }
    return null;
  }

  Future<void> setUserData(Map<String, dynamic>? data) async {
    if (data == null) {
      await _prefs.remove(_userDataKey);
    } else {
      await _prefs.setString(_userDataKey, json.encode(data));
    }
  }

  Future<void> clearAll() async {
    await _prefs.clear();
  }
}
