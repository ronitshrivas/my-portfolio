import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Shows the first frame of a local video file as a still thumbnail (paused at
/// 0:00). Uses video_player (already a dependency) so no extra package is
/// needed. While the frame loads it shows a dark placeholder.
class VideoThumbnailView extends StatefulWidget {
  const VideoThumbnailView({super.key, required this.path});

  final String path;

  @override
  State<VideoThumbnailView> createState() => VideoThumbnailViewState();
}

class VideoThumbnailViewState extends State<VideoThumbnailView> {
  VideoPlayerController? _controller;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final controller = VideoPlayerController.file(File(widget.path));
      await controller.initialize();
      // Seek to the first frame and keep it paused as a static thumbnail.
      await controller.seekTo(Duration.zero);
      await controller.setVolume(0);
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _ready = true;
      });
    } catch (_) {
      // Leave the placeholder if the frame can't be decoded.
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (!_ready || controller == null) {
      return const ColoredBox(color: Color(0xFF1B1E28));
    }
    return FittedBox(
      fit: BoxFit.cover,
      clipBehavior: Clip.hardEdge,
      child: SizedBox(
        width: controller.value.size.width,
        height: controller.value.size.height,
        child: VideoPlayer(controller),
      ),
    );
  }
}
