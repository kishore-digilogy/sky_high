import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:sky_high/core/services/deeplink_service.dart';
import 'package:sky_high/core/services/api_service.dart';

class StorageService {
  static const String _isFirstTimeKey = 'is_first_time';
  static const String _tokenKey = 'auth_token';
  static const String _userDataKey = 'user_data';
  static const String _recentStudyKey = 'recent_study';
  static const String _studyGuideShownKey = 'study_guide_shown';
  static const String _languageKey = 'selected_language';
  static const String _savedEmailsKey = 'saved_emails';
  static const String _pendingPaymentKey = 'pending_payment';

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

  static void initOneSignal([String? userId]) async {
    try {
      print('StorageService: Initializing OneSignal...');
      OneSignal.Debug.setLogLevel(OSLogLevel.debug);
      OneSignal.initialize("8a517530-af11-446d-ae13-4ec77e3f99c9");
      final granted = await OneSignal.Notifications.requestPermission(true);
      print('StorageService: Notification permission granted: $granted');

      // Register click listener for deep linking
      OneSignal.Notifications.addClickListener((event) {
        final additionalData = event.notification.additionalData;
        print('====================================================');
        print('🔔 STORAGE_SERVICE: NOTIFICATION CLICKED EVENT!');
        print('🔔 Title: ${event.notification.title}');
        print('🔔 Body: ${event.notification.body}');
        print('🔔 Custom Payload (additionalData): $additionalData');
        print('====================================================');

        if (additionalData != null) {
          DeeplinkService().onNotificationClicked(additionalData);
        } else {
          print('🔔 STORAGE_SERVICE: Warning! Custom payload is null.');
        }
      });

      if (userId != null) {
        print('StorageService: Logging into OneSignal with user ID: $userId');
        OneSignal.login(userId);

        if (granted) {
          // Poll briefly to ensure the subscription ID is registered and retrieved
          String? subscriptionId = OneSignal.User.pushSubscription.id;
          int attempts = 0;
          while ((subscriptionId == null || subscriptionId.isEmpty) &&
              attempts < 10) {
            await Future.delayed(const Duration(milliseconds: 500));
            subscriptionId = OneSignal.User.pushSubscription.id;
            attempts++;
          }

          if (subscriptionId != null && subscriptionId.isNotEmpty) {
            print(
              'StorageService: OneSignal subscription ID obtained: $subscriptionId',
            );
            _sendOneSignalIdToBackend(subscriptionId);
          } else {
            print(
              'StorageService: Failed to retrieve OneSignal subscription ID after several attempts.',
            );
          }
        }
      }
    } catch (e) {
      print('StorageService: OneSignal init error: $e');
    }
  }

  static Future<void> _sendOneSignalIdToBackend(String onesignalId) async {
    try {
      print('StorageService: Sending OneSignal ID to backend: $onesignalId');
      final dio = ApiService().dio;
      final response = await dio.post(
        '${ApiService.baseUrl}/auth/update-onesignal',
        data: {'onesignal_id': onesignalId},
      );
      print(
        'StorageService: Backend response for OneSignal ID update: ${response.data}',
      );
    } catch (e) {
      print('StorageService: Error sending OneSignal ID to backend: $e');
    }
  }

  Future<void> setUserData(Map<String, dynamic>? data) async {
    if (data == null) {
      await _prefs.remove(_userDataKey);
      try {
        print('StorageService: Logging out of OneSignal...');
        await OneSignal.logout();
      } catch (e) {
        print('StorageService: OneSignal logout error: $e');
      }
    } else {
      await _prefs.setString(_userDataKey, json.encode(data));
      final userId = data['id']?.toString();
      initOneSignal(userId);
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

  List<String> getSavedEmails() {
    final list = _prefs.getStringList(_savedEmailsKey);
    return list != null ? List<String>.from(list) : [];
  }

  Future<void> saveEmail(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty) return;

    final List<String> emails = getSavedEmails();
    // Remove if already exists so we can move it to the top/first position
    emails.remove(cleanEmail);
    emails.insert(0, cleanEmail);

    // Keep only the top 5 most recent
    if (emails.length > 5) {
      emails.removeRange(5, emails.length);
    }

    await _prefs.setStringList(_savedEmailsKey, emails);
  }

  Future<void> clearUserRelatedData() async {
    await _prefs.remove(_tokenKey);
    await _prefs.remove(_userDataKey);
    await _prefs.remove(_recentStudyKey);

    try {
      print('StorageService: Logging out of OneSignal...');
      await OneSignal.logout();
    } catch (e) {
      print('StorageService: OneSignal logout error: $e');
    }

    // Also clear any company-specific last studied keys
    final keys = _prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith('last_studied_')) {
        await _prefs.remove(key);
      }
    }
  }

  Map<String, dynamic>? getPendingPayment() {
    final dataStr = _prefs.getString(_pendingPaymentKey);
    if (dataStr != null) {
      try {
        return json.decode(dataStr) as Map<String, dynamic>;
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  Future<void> setPendingPayment(Map<String, dynamic>? data) async {
    if (data == null) {
      await _prefs.remove(_pendingPaymentKey);
    } else {
      await _prefs.setString(_pendingPaymentKey, json.encode(data));
    }
  }

  Future<void> clearAll() async {
    await _prefs.clear();
  }
}
