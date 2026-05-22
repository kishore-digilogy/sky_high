import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:sky_high/pages/other/no_internet_page.dart';

class ConnectivityWrapper extends StatefulWidget {
  final Widget child;
  const ConnectivityWrapper({super.key, required this.child});

  @override
  State<ConnectivityWrapper> createState() => _ConnectivityWrapperState();
}

class _ConnectivityWrapperState extends State<ConnectivityWrapper> {
  List<ConnectivityResult> _connectivityResults = [ConnectivityResult.wifi];
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _checkInitialConnectivity();
    try {
      _subscription = Connectivity().onConnectivityChanged.listen(
        (List<ConnectivityResult> results) {
          setState(() {
            _connectivityResults = results;
          });
        },
        onError: (error) {
          debugPrint("ConnectivityWrapper: Stream error: $error");
        },
      );
    } catch (e) {
      debugPrint("ConnectivityWrapper: Error subscribing to stream: $e");
    }
  }

  Future<void> _checkInitialConnectivity() async {
    try {
      final results = await Connectivity().checkConnectivity();
      setState(() {
        _connectivityResults = results;
      });
    } catch (e) {
      debugPrint("ConnectivityWrapper: Failed to check connectivity: $e");
      // Optimistic fallback to avoid locking user out if native plugin fails to initialize
      setState(() {
        _connectivityResults = [ConnectivityResult.wifi];
      });
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  bool get _isConnected {
    if (_connectivityResults.isEmpty) return false;
    if (_connectivityResults.contains(ConnectivityResult.none)) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    if (!_isConnected) {
      return ScaffoldMessenger(
        child: Builder(
          builder: (childContext) {
            return NoInternetPage(
              onTryAgain: () async {
                setState(() {
                  _isChecking = true;
                });

                // Smooth delay for premium user interaction feel
                await Future.delayed(const Duration(milliseconds: 1200));

                List<ConnectivityResult> results = [ConnectivityResult.none];
                try {
                  results = await Connectivity().checkConnectivity();
                } catch (e) {
                  debugPrint("ConnectivityWrapper: Error checking connectivity on retry: $e");
                }

                bool actuallyConnected = false;

                if (results.isNotEmpty && !results.contains(ConnectivityResult.none)) {
                  try {
                    // Double check with a quick lookup to verify real internet access
                    final lookup = await InternetAddress.lookup('google.com')
                        .timeout(const Duration(seconds: 4));
                    if (lookup.isNotEmpty && lookup[0].rawAddress.isNotEmpty) {
                      actuallyConnected = true;
                    }
                  } catch (_) {
                    actuallyConnected = false;
                  }
                }

                if (mounted) {
                  setState(() {
                    _isChecking = false;
                    if (actuallyConnected) {
                      _connectivityResults = results;
                    } else {
                      _connectivityResults = [ConnectivityResult.none];
                      
                      // Show attractive floating notification on retry failure
                      ScaffoldMessenger.of(childContext).showSnackBar(
                        SnackBar(
                          content: const Text(
                            'Still no internet connection. Please verify your data/Wi-Fi and try again.',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                          backgroundColor: const Color(0xFFEF4444),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                        ),
                      );
                    }
                  });
                }
              },
              isChecking: _isChecking,
            );
          },
        ),
      );
    }
    return widget.child;
  }
}
