import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:sky_high/core/services/storage_service.dart';
import 'package:sky_high/core/services/api_service.dart';

class PaymentService {
  static final PaymentService _instance = PaymentService._internal();

  factory PaymentService() => _instance;

  PaymentService._internal();

  // Save pending payment payload
  Future<void> savePendingPayment(Map<String, dynamic> payload) async {
    final storage = GetIt.I<StorageService>();
    await storage.setPendingPayment(payload);
    debugPrint("💾 PaymentService: Saved pending payment details locally: $payload");
  }

  // Get pending payment payload
  Map<String, dynamic>? getPendingPayment() {
    final storage = GetIt.I<StorageService>();
    return storage.getPendingPayment();
  }

  // Clear pending payment details
  Future<void> clearPendingPayment() async {
    final storage = GetIt.I<StorageService>();
    await storage.setPendingPayment(null);
    debugPrint("🧹 PaymentService: Cleared pending payment details from storage.");
  }

  // Verify payment status with the backend
  Future<bool> verifyPayment(Map<String, dynamic> payload) async {
    final dio = ApiService().dio;
    final token = GetIt.I<StorageService>().getToken();

    if (token == null || token.isEmpty) {
      debugPrint("⚠️ PaymentService: Cannot verify payment because auth token is null or empty.");
      return false;
    }

    try {
      final response = await dio.post(
        '${ApiService.baseUrl}/payment/verify',
        data: payload,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      debugPrint("PaymentService: Verify response status: ${response.statusCode}");
      debugPrint("PaymentService: Verify response data: ${response.data}");

      if (response.statusCode == 200 && response.data['success'] == true) {
        // Refresh local user data subscription status to paid
        final storage = GetIt.I<StorageService>();
        final userData = storage.getUserData();
        if (userData != null) {
          userData['subscription_status'] = 'paid';
          await storage.setUserData(userData);
        }
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("PaymentService: Error in payment verification request: $e");
      // Rethrow to allow callers to distinguish network issues from verification rejection
      rethrow;
    }
  }

  // Background check and retry verification
  bool _isVerifying = false;

  Future<void> checkAndVerifyPendingPayment() async {
    if (_isVerifying) return;
    final pending = getPendingPayment();
    if (pending == null) {
      debugPrint("PaymentService: No pending payments to verify.");
      return;
    }

    _isVerifying = true;
    debugPrint("🚀 PaymentService: Retrying verification for pending payment: $pending");

    try {
      final success = await verifyPayment(pending);
      if (success) {
        await clearPendingPayment();
        debugPrint("🎉 PaymentService: Successfully verified and cleared pending payment!");
      } else {
        debugPrint("❌ PaymentService: Verification request completed but failed status. Retaining for retry.");
      }
    } catch (e) {
      debugPrint("⚠️ PaymentService: Verification request failed due to error: $e. Retaining for next retry.");
    } finally {
      _isVerifying = false;
    }
  }
}
