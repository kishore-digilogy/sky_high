import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:screen_protector/screen_protector.dart';
import 'dart:io';

class VideoViewerPage extends StatefulWidget {
  final String videoUrl;
  final String title;

  const VideoViewerPage({
    super.key,
    required this.videoUrl,
    required this.title,
  });

  static void open(BuildContext context, String url, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoViewerPage(videoUrl: url, title: title),
      ),
    );
  }

  @override
  State<VideoViewerPage> createState() => _VideoViewerPageState();
}

class _VideoViewerPageState extends State<VideoViewerPage>
    with WidgetsBindingObserver {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _isError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _enableSecureMode();
    _setupScreenshotListener();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      // ignore: deprecated_member_use
      _videoPlayerController = VideoPlayerController.network(widget.videoUrl);
      await _videoPlayerController.initialize();
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        autoPlay: true,
        looping: false,
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Text(
              errorMessage,
              style: const TextStyle(color: Colors.white),
            ),
          );
        },
      );
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isError = true;
          _errorMessage = e.toString();
        });
        _showTrendyErrorDialog(context, _errorMessage);
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disableSecureMode();
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  void _setupScreenshotListener() {
    ScreenProtector.addListener(
      () {
        if (mounted) {
          _showSecurityAlertDialog(
            context,
            'Screenshot Detected',
            'Screenshots are restricted to protect intellectual property.',
          );
        }
      },
      (isRecording) {
        if (isRecording && mounted) {
          _showSecurityAlertDialog(
            context,
            'Recording Detected',
            'Screen recording is restricted for security reasons.',
          );
        }
      },
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _enableSecureMode();
      _chewieController?.pause();
    } else if (state == AppLifecycleState.resumed) {
      _enableSecureMode();
    }
  }

  Future<void> _enableSecureMode() async {
    try {
      await ScreenProtector.preventScreenshotOn();
      if (Platform.isAndroid) {
        await ScreenProtector.protectDataLeakageOn();
      }
      if (Platform.isIOS) {
        await ScreenProtector.protectDataLeakageWithBlur();
      }
    } catch (e) {
      debugPrint('Error enabling secure mode: $e');
    }
  }

  Future<void> _disableSecureMode() async {
    try {
      await ScreenProtector.preventScreenshotOff();
      await ScreenProtector.protectDataLeakageOff();
      if (Platform.isIOS) {
        await ScreenProtector.protectDataLeakageWithBlurOff();
      }
    } catch (e) {
      debugPrint('Error disabling secure mode: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // trendy light blue-grey bg
      appBar: AppBar(
        title: Text(
          widget.title,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: const Color(0xFF0F172A),
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: SafeArea(
        child: _isError
            ? const Center(child: Text('Failed to load video.'))
            : _chewieController != null &&
                    _chewieController!.videoPlayerController.value.isInitialized
                ? Chewie(controller: _chewieController!)
                : const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  void _showTrendyErrorDialog(BuildContext context, String error) {
    _showDialogBase(
      context: context,
      title: 'Unable to Load Video',
      message: 'The video could not be fetched. Please check your connection.',
      icon: Icons.error_outline_rounded,
      iconBgColor: const Color(0xFFFFEDD5),
      iconColor: const Color(0xFFF97316),
      buttonText: 'Got it',
      buttonColor: const Color(0xFF1E293B),
      onPressed: () {
        Navigator.pop(context);
        Navigator.pop(context);
      },
    );
  }

  void _showSecurityAlertDialog(
    BuildContext context,
    String title,
    String message,
  ) {
    _showDialogBase(
      context: context,
      title: title,
      message: message,
      icon: Icons.security_rounded,
      iconBgColor: const Color(0xFFFEE2E2),
      iconColor: const Color(0xFFEF4444),
      buttonText: 'I Understand',
      buttonColor: const Color(0xFFEF4444),
      onPressed: () => Navigator.pop(context),
    );
  }

  void _showDialogBase({
    required BuildContext context,
    required String title,
    required String message,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String buttonText,
    required Color buttonColor,
    required VoidCallback onPressed,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    // ignore: deprecated_member_use
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: iconBgColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: iconColor, size: 32),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFF64748B),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: buttonColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        buttonText,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
