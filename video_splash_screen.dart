import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Video Splash Screen
/// 
/// Displays a fullscreen video then automatically navigates
/// to the home screen when the video ends or after a timeout
class VideoSplashScreen extends StatefulWidget {
  const VideoSplashScreen({Key? key}) : super(key: key);

  @override
  _VideoSplashScreenState createState() => _VideoSplashScreenState();
}

class _VideoSplashScreenState extends State<VideoSplashScreen> {
  /// Video player controller
  late VideoPlayerController _controller;

  /// Prevents multiple navigations if video ends or timeout occurs
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();

    /// Fallback timeout: if video gets stuck for any reason, navigate after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      _navigateToHome();
    });
  }

  /// Initialize video and setup listeners
  void _initializeVideo() {
    _controller = VideoPlayerController.asset("assets/videos/splash.mp4")
      // Set volume (0.0 = muted, 1.0 = full volume)
      ..setVolume(0.0)
      
      // Initialize video
      ..initialize().then((_) {
        if (mounted) {
          setState(() {});
          _controller.play();
        }
      })
      // Error handling: if video fails to load, navigate to home
      .catchError((error) {
        debugPrint("Video Error: $error");
        _navigateToHome();
      });

    // Add listener to monitor video progress
    _controller.addListener(_videoListener);
  }

  /// Video listener: monitors video completion
  /// 
  /// We use >= instead of == because position and duration are Duration types
  /// Direct comparison might fail due to microsecond differences
  void _videoListener() {
    if (!_controller.value.isInitialized) return;

    final position = _controller.value.position;
    final duration = _controller.value.duration;

    if (position >= duration) {
      _navigateToHome();
    }
  }

  /// Navigate to home screen
  /// 
  /// - Checks mounted (is the Widget still in the tree?)
  /// - Checks _hasNavigated (did we navigate before?)
  /// - Uses pushReplacementNamed so user can't go back to splash
  void _navigateToHome() {
    if (!mounted || _hasNavigated) return;
    _hasNavigated = true;

    // Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  void dispose() {
    // Clean up resources: remove listener then dispose controller
    _controller.removeListener(_videoListener);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Black background prevents white flicker
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Video
          if (_controller.value.isInitialized)
            SizedBox.expand(
              child: FittedBox(
                // BoxFit.cover: fills entire screen while maintaining aspect ratio
                // May crop parts of the video in some aspect ratios
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              ),
            )
          else
            // Loading indicator (shown while video initializes)
            const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
        ],
      ),
    );
  }
}
