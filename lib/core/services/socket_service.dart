import 'dart:async';
import 'package:get_it/get_it.dart';
import 'package:sky_high/core/services/api_service.dart';
import 'package:sky_high/core/services/storage_service.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;

  IO.Socket? socket;

  final _subscriptionStatusController = StreamController<String>.broadcast();
  Stream<String> get onSubscriptionStatusChanged =>
      _subscriptionStatusController.stream;

  final _connectionStatusController = StreamController<bool>.broadcast();
  Stream<bool> get onConnectionStatusChanged =>
      _connectionStatusController.stream;

  bool get isConnected => socket?.connected ?? false;

  SocketService._internal();

  void init() {
    if (socket != null) return;

    final String socketUrl = getSocketUrl();
    print('SocketService: Initializing connection to $socketUrl');

    socket = IO.io(
      socketUrl,
      IO.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .enableReconnection()
          .setReconnectionAttempts(5)
          .setReconnectionDelay(1000)
          .build(),
    );

    socket!.onConnect((_) {
      print('SocketService: Connected to Socket.IO server successfully!');
      _connectionStatusController.add(true);
    });

    socket!.onDisconnect((_) {
      print('SocketService: Disconnected from Socket.IO server.');
      _connectionStatusController.add(false);
    });

    socket!.onConnectError((err) {
      print('SocketService: Connection error: $err');
      _connectionStatusController.add(false);
    });

    // Listen to subscription status updates
    socket!.on('subscription:status_update', (data) async {
      print('SocketService: subscription:status_update event received: $data');
      if (data == null) return;

      try {
        final int? eventUserId = data['user_id'] is int
            ? data['user_id'] as int
            : int.tryParse(data['user_id']?.toString() ?? '');
        final String? subscriptionStatus =
            data['subscription_status'] as String?;

        if (eventUserId != null && subscriptionStatus != null) {
          final storage = GetIt.I<StorageService>();
          final currentUser = storage.getUserData();

          if (currentUser != null) {
            final int? currentUserId = currentUser['id'] is int
                ? currentUser['id'] as int
                : int.tryParse(currentUser['id']?.toString() ?? '');

            if (currentUserId == eventUserId) {
              print(
                'SocketService: Matching user found! Updating local subscription status to: $subscriptionStatus',
              );

              currentUser['subscription_status'] = subscriptionStatus;
              currentUser['is_paid'] = subscriptionStatus == 'paid';

              await storage.setUserData(currentUser);

              // Broadcast the status update
              _subscriptionStatusController.add(subscriptionStatus);
            }
          }
        }
      } catch (e) {
        print('SocketService: Error processing subscription:status_update: $e');
      }
    });

    socket!.on('payment:status_update', (data) {
      print('SocketService: payment:status_update event received: $data');
    });
  }

  String getSocketUrl() {
    try {
      final apiUri = Uri.parse(ApiService.baseUrl);
      if (apiUri.host == 'localhost' ||
          apiUri.host == '127.0.0.1' ||
          apiUri.host == '10.0.2.2') {
        return 'http://localhost:5000';
      }
      String hostUrl = '${apiUri.scheme}://${apiUri.host}';
      if (apiUri.hasPort) {
        hostUrl += ':${apiUri.port}';
      }
      return hostUrl;
    } catch (e) {
      print(
        'SocketService: Error parsing ApiService.baseUrl, fallback to http://localhost:5000',
      );
      return 'http://localhost:5000';
    }
  }

  void disconnect() {
    socket?.disconnect();
    socket = null;
  }
}
