import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:screen_protector/screen_protector.dart';
import 'dart:io';

class VideoPlayerPage extends StatefulWidget {
  final String videoUrl;
  final String title;

  const VideoPlayerPage({
    super.key,
    required this.videoUrl,
    required this.title,
  });

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage>
    with WidgetsBindingObserver {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializePlayer();
    _enableSecureMode();
  }

  Future<void> _initializePlayer() async {
    // debugPrint('🎥 VideoPlayer Initializing with URL: ${widget.videoUrl}');
    try {
      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
      );
      await _videoPlayerController.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        autoPlay: true,
        looping: false,
        aspectRatio: _videoPlayerController.value.aspectRatio,
        materialProgressColors: ChewieProgressColors(
          playedColor: const Color(0xFF6366F1),
          handleColor: const Color(0xFF6366F1),
          backgroundColor: Colors.grey.withOpacity(0.5),
          bufferedColor: Colors.white.withOpacity(0.3),
        ),
        placeholder: Container(
          color: Colors.black,
          child: const Center(
            child: CircularProgressIndicator(color: Color(0xFF6366F1)),
          ),
        ),
        autoInitialize: true,
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
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorDialog('Unable to load video. Please try again later.');
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    _disableSecureMode();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _enableSecureMode();
      _videoPlayerController.pause();
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

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator(color: Color(0xFF6366F1))
            : _chewieController != null &&
                  _chewieController!.videoPlayerController.value.isInitialized
            ? Chewie(controller: _chewieController!)
            : const Text(
                'Error initializing video player',
                style: TextStyle(color: Colors.white),
              ),
      ),
    );
  }
}
