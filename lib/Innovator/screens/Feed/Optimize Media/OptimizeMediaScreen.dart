import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:innovator/Innovator/constant/app_colors.dart';
import 'package:innovator/Innovator/screens/Feed/Inner_Homepage.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:video_player/video_player.dart';

class OptimizedMediaGalleryScreen extends StatefulWidget {
  final List<String> mediaUrls;
  final int initialIndex;

  const OptimizedMediaGalleryScreen({
    required this.mediaUrls,
    required this.initialIndex,
    Key? key,
  }) : super(key: key);

  @override
  _OptimizedMediaGalleryScreenState createState() =>
      _OptimizedMediaGalleryScreenState();
}

class _OptimizedMediaGalleryScreenState
    extends State<OptimizedMediaGalleryScreen> {
  late PageController _pageController;
  late int _currentIndex;
  bool _isFullScreen = false;
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _pdfLoadFailed = false;
  bool _isLoadingVideo = false;

  // Keep track of loaded items to improve memory usage
  final Set<int> _loadedIndices = {};

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Load current media
    _loadMedia(_currentIndex);

    // Preload adjacent media for smoother experience
    if (_currentIndex > 0) {
      _preloadMedia(_currentIndex - 1);
    }

    if (_currentIndex < widget.mediaUrls.length - 1) {
      _preloadMedia(_currentIndex + 1);
    }
  }

  // Preload media without showing it
  void _preloadMedia(int index) {
    if (index < 0 || index >= widget.mediaUrls.length) return;
    if (_loadedIndices.contains(index)) return;

    _loadedIndices.add(index);
    final url = widget.mediaUrls[index];

    if (FileTypeHelper.isImage(url)) {
      precacheImage(NetworkImage(url), context);
    }
  }

  Future<void> _loadMedia(int index) async {
    if (index < 0 || index >= widget.mediaUrls.length) return;

    _loadedIndices.add(index);
    final url = widget.mediaUrls[index];

    if (FileTypeHelper.isVideo(url)) {
      await _initializeVideo(url);
    }
  }

  Future<void> _initializeVideo(String url) async {
    if (_isLoadingVideo) return;

    setState(() => _isLoadingVideo = true);

    try {
      // Clean up previous controllers
      await _disposeVideoControllers();

      debugPrint('🎥 Initializing video: $url');

      _videoController = VideoPlayerController.networkUrl(Uri.parse(url));

      await _videoController!.initialize();

      debugPrint('Video initialized successfully');

      if (mounted) {
        setState(() {
          _chewieController = ChewieController(
            videoPlayerController: _videoController!,
            autoPlay: true, // Auto-play when initialized
            looping: true,
            allowFullScreen: true,
            aspectRatio: _videoController!.value.aspectRatio,
            autoInitialize: true,
            errorBuilder: (context, errorMessage) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppColors.whitecolor,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      errorMessage,
                      style: const TextStyle(color: AppColors.whitecolor),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            },
          );
          _isLoadingVideo = false;
        });

        // Ensure video starts playing
        if (_videoController != null && _videoController!.value.isInitialized) {
          _videoController!.play();
          debugPrint('▶️ Video started playing');
        }
      }
    } catch (e) {
      debugPrint(' Video initialization error: $e');
      if (mounted) {
        setState(() => _isLoadingVideo = false);
      }
    }
  }

  Future<void> _disposeVideoControllers() async {
    if (_videoController != null) {
      await _videoController!.pause();
      await _videoController!.dispose();
      _videoController = null;
    }

    if (_chewieController != null) {
      _chewieController!.dispose();
      _chewieController = null;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _disposeVideoControllers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar:
          _isFullScreen
              ? null
              : AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    color: AppColors.whitecolor,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text(
                  '${_currentIndex + 1}/${widget.mediaUrls.length}',
                  style: const TextStyle(color: AppColors.whitecolor),
                ),
                centerTitle: true,
                actions: [
                  IconButton(
                    icon: const Icon(
                      Icons.fullscreen,
                      color: AppColors.whitecolor,
                    ),
                    onPressed: _toggleFullScreen,
                  ),
                ],
              ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.mediaUrls.length,
        onPageChanged: (index) async {
          debugPrint('📄 Page changed to index: $index');

          // Pause current video if it's playing
          if (_videoController != null && _videoController!.value.isPlaying) {
            await _videoController!.pause();
          }

          setState(() {
            _currentIndex = index;
            _pdfLoadFailed = false;
          });

          // Load the current page media
          await _loadMedia(index);

          // Try to preload the next page if it exists
          if (index < widget.mediaUrls.length - 1) {
            _preloadMedia(index + 1);
          }

          // Preload the previous page if it exists
          if (index > 0) {
            _preloadMedia(index - 1);
          }
        },
        itemBuilder: (context, index) {
          final url = widget.mediaUrls[index];

          if (index != _currentIndex) {
            // Just show a placeholder for non-visible pages
            return Container(
              color: Colors.black,
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: AppColors.whitecolor.withOpacity(0.3),
                  ),
                ),
              ),
            );
          }

          return GestureDetector(
            onTap: () {
              // Don't toggle fullscreen on tap, let Chewie handle video controls
              if (!FileTypeHelper.isVideo(url)) {
                _toggleFullScreen();
              }
            },
            child: _buildMediaViewer(url),
          );
        },
      ),
    );
  }

  Widget _buildMediaViewer(String url) {
    if (FileTypeHelper.isImage(url)) {
      return _buildImageViewer(url);
    } else if (FileTypeHelper.isVideo(url)) {
      return _buildVideoViewer();
    } else if (FileTypeHelper.isPdf(url)) {
      return _buildPdfViewer(url);
    } else {
      return _buildUnsupportedViewer(url);
    }
  }

  Widget _buildImageViewer(String url) {
    return InteractiveViewer(
      panEnabled: true,
      minScale: 1.0,
      maxScale: 3.0,
      child: Center(
        child: CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.contain,
          placeholder:
              (context, url) => const Center(
                child: CircularProgressIndicator(color: AppColors.whitecolor),
              ),
          errorWidget:
              (context, url, error) => const Center(
                child: Icon(Icons.error, color: AppColors.whitecolor, size: 48),
              ),
        ),
      ),
    );
  }

  Widget _buildVideoViewer() {
    if (_isLoadingVideo) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.whitecolor),
            const SizedBox(height: 16),
            const Text(
              'Loading video...',
              style: TextStyle(color: AppColors.whitecolor),
            ),
          ],
        ),
      );
    }

    if (_chewieController == null || _videoController == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: AppColors.whitecolor,
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              'Error loading video',
              style: TextStyle(color: AppColors.whitecolor),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.whitecolor,
                foregroundColor: Colors.black,
              ),
              onPressed: () {
                final url = widget.mediaUrls[_currentIndex];
                _initializeVideo(url); // Retry initialization
              },
              child: const Text('Retry'),
            ),
            const SizedBox(height: 8),
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: AppColors.whitecolor.withOpacity(0.2),
                foregroundColor: AppColors.whitecolor,
              ),
              onPressed: () {
                final url = widget.mediaUrls[_currentIndex];
                _downloadAndOpenFile(url, 'video.mp4');
              },
              child: const Text('Download and Open'),
            ),
          ],
        ),
      );
    }

    if (_videoController!.value.hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: AppColors.whitecolor,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Video error: ${_videoController!.value.errorDescription ?? "Unknown error"}',
              style: const TextStyle(color: AppColors.whitecolor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.whitecolor,
                foregroundColor: Colors.black,
              ),
              onPressed: () {
                final url = widget.mediaUrls[_currentIndex];
                _initializeVideo(url); // Retry initialization
              },
              child: const Text('Retry'),
            ),
            const SizedBox(height: 8),
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: AppColors.whitecolor.withOpacity(0.2),
                foregroundColor: AppColors.whitecolor,
              ),
              onPressed: () {
                final url = widget.mediaUrls[_currentIndex];
                _downloadAndOpenFile(url, 'video.mp4');
              },
              child: const Text('Download and Open'),
            ),
          ],
        ),
      );
    }

    return Center(
      child: AspectRatio(
        aspectRatio: _videoController!.value.aspectRatio,
        child: Chewie(controller: _chewieController!),
      ),
    );
  }

  Widget _buildPdfViewer(String url) {
    if (_pdfLoadFailed) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: AppColors.whitecolor,
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              'Failed to load PDF',
              style: TextStyle(color: AppColors.whitecolor),
            ),
            const SizedBox(height: 16),
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: AppColors.whitecolor,
                foregroundColor: Colors.black,
              ),
              onPressed: () => _downloadAndOpenFile(url, 'document.pdf'),
              child: const Text('Download and Open'),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        SfPdfViewer.network(
          url,
          onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
            setState(() {
              _pdfLoadFailed = true;
            });
          },
          canShowScrollHead: false,
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            backgroundColor: AppColors.whitecolor,
            foregroundColor: Colors.black,
            child: const Icon(Icons.download),
            onPressed: () => _downloadAndOpenFile(url, 'document.pdf'),
          ),
        ),
      ],
    );
  }

  Widget _buildUnsupportedViewer(String url) {
    // Get filename from URL
    final fileName = url.split('/').last;
    final fileExtension = fileName.split('.').last.toLowerCase();

    IconData icon;
    String fileType;

    if (fileExtension == 'doc' || fileExtension == 'docx') {
      icon = Icons.description;
      fileType = 'Word Document';
    } else {
      icon = Icons.insert_drive_file;
      fileType = 'Document';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.whitecolor, size: 64),
          const SizedBox(height: 16),
          Text(
            fileType,
            style: const TextStyle(color: AppColors.whitecolor, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            fileName,
            style: const TextStyle(color: AppColors.whitecolor, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => _downloadAndOpenFile(url, fileName),
            child: const Text('Download and Open'),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadAndOpenFile(String url, String fileName) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => const AlertDialog(
              content: Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 16),
                  Text('Downloading file...'),
                ],
              ),
            ),
      );

      // Download file
      final response = await http.get(Uri.parse(url));

      // Get temporary directory
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/$fileName';

      // Write to file
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Open file
      final result = await OpenFile.open(filePath);

      if (result.type != ResultType.done) {
        throw Exception('Could not open file: ${result.message}');
      }
    } catch (e) {
      // Close loading dialog if it's still open
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      // Show error
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
    });
  }
}
