import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _isFirstTimeKey = 'is_first_time';
  static const String _tokenKey = 'auth_token';
  static const String _userDataKey = 'user_data';
  static const String _recentStudyKey = 'recent_study';
  static const String _studyGuideShownKey = 'study_guide_shown';
  static const String _languageKey = 'selected_language';

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

  List<Map<String, dynamic>> getRecentStudies() {
    final dataStr = _prefs.getString(_recentStudyKey);
    if (dataStr != null) {
      try {
        final decoded = json.decode(dataStr);
        if (decoded is List) {
          return decoded.map((e) => e as Map<String, dynamic>).toList();
        } else if (decoded is Map<String, dynamic>) {
          return [decoded];
        }
      } catch (e) {
        return [];
      }
    }
    return [];
  }

  Future<void> addRecentStudy(Map<String, dynamic> data) async {
    final List<Map<String, dynamic>> studies = getRecentStudies();
    
    // Remove existing entry for the same company to move it to front
    studies.removeWhere((s) => s['company']['id'] == data['company']['id']);
    
    // Add new study to the beginning
    studies.insert(0, data);
    
    // Keep only top 5
    if (studies.length > 5) {
      studies.removeRange(5, studies.length);
    }
    
    await _prefs.setString(_recentStudyKey, json.encode(studies));
  }

  Future<void> clearRecentStudies() async {
    await _prefs.remove(_recentStudyKey);
  }

  Future<void> removeRecentStudy(int companyId) async {
    final List<Map<String, dynamic>> studies = getRecentStudies();
    studies.removeWhere((s) => s['company']['id'] == companyId);
    await _prefs.setString(_recentStudyKey, json.encode(studies));
  }

  bool get isStudyGuideShown => _prefs.getBool(_studyGuideShownKey) ?? false;

  Future<void> setStudyGuideShown(bool value) async {
    await _prefs.setBool(_studyGuideShownKey, value);
  }

  String getSelectedLanguage() {
    return _prefs.getString(_languageKey) ?? 'English';
  }

  Future<void> setSelectedLanguage(String language) async {
    await _prefs.setString(_languageKey, language);
  }

  Future<void> clearUserRelatedData() async {
    await _prefs.remove(_tokenKey);
    await _prefs.remove(_userDataKey);
    await _prefs.remove(_recentStudyKey);
    
    // Also clear any company-specific last studied keys
    final keys = _prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith('last_studied_')) {
        await _prefs.remove(key);
      }
    }
  }

  Future<void> clearAll() async {
    await _prefs.clear();
  }
}
