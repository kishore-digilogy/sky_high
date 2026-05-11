import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:screen_protector/screen_protector.dart';
import 'dart:io';
import 'package:google_fonts/google_fonts.dart';

class PdfViewerPage extends StatefulWidget {
  final String pdfUrl;
  final String title;

  const PdfViewerPage({super.key, required this.pdfUrl, required this.title});

  static void open(BuildContext context, String url, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfViewerPage(pdfUrl: url, title: title),
      ),
    );
  }

  @override
  State<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage>
    with WidgetsBindingObserver {
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _enableSecureMode();
    _setupScreenshotListener();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disableSecureMode();
    super.dispose();
  }

  void _setupScreenshotListener() {
    // Note: Screenshot detection listener is primary supported on iOS
    // Android prevention is handled by the system level FLAG_SECURE
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
    } else if (state == AppLifecycleState.resumed) {
      _enableSecureMode();
    }
  }

  Future<void> _enableSecureMode() async {
    try {
      // Prevent screenshots and screen recordings
      await ScreenProtector.preventScreenshotOn();

      // Android specific data leakage protection
      if (Platform.isAndroid) {
        await ScreenProtector.protectDataLeakageOn();
      }

      // Hide content in the background/multitasking view (iOS specific)
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
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded, size: 22),
            onPressed: () {
              // Show info or help
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SfPdfViewer.network(
        widget.pdfUrl,
        key: _pdfViewerKey,
        enableTextSelection: false,
        canShowPaginationDialog: true,
        canShowScrollHead: true,
        canShowScrollStatus: true,
        // backgroundColor: const Color(0xFFF1F5F9),
        onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
          _showTrendyErrorDialog(context, details.error);
        },
      ),
    );
  }

  void _showTrendyErrorDialog(BuildContext context, String error) {
    _showDialogBase(
      context: context,
      title: 'Unable to Load PDF',
      message:
          'The document could not be fetched from the server. Please check your connection.',
      icon: Icons.error_outline_rounded,
      iconBgColor: const Color(0xFFFFEDD5),
      iconColor: const Color(0xFFF97316),
      buttonText: 'Got it',
      buttonColor: const Color(0xFF1E293B),
      onPressed: () {
        Navigator.pop(context); // Close dialog
        Navigator.pop(context); // Close PdfViewerPage
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
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
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
        );
      },
    );
  }
}
