import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:innovator/Innovator/constant/api_constants.dart';
import 'package:innovator/Innovator/constant/app_colors.dart';
import 'package:innovator/Innovator/ui/ui.dart';
import 'package:innovator/Innovator/provider/upload_provider.dart';
import 'package:innovator/Innovator/screens/CreatePost/reels_camera_screen.dart';
import 'package:innovator/Innovator/screens/CreatePost/reels_preview_screen.dart';
import 'package:innovator/Innovator/screens/Profile/profile_page.dart';
import 'package:innovator/Innovator/screens/chatrrom/screen/chatlistscreen.dart';
import 'package:innovator/Innovator/utils/Drawer/custom_drawer.dart';
import 'package:innovator/Innovator/widget/CustomizeFAB.dart';
import 'package:innovator/innovator_home.dart';
import 'dart:convert';
import 'dart:io';
import 'package:mime/mime.dart';
import 'package:innovator/Innovator/App_data/App_data.dart';
import 'package:path/path.dart' as path;
import 'package:image_picker/image_picker.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isLoading = true;
  Map<String, dynamic>? _userData;
  String? _errorMessage;

  List<PlatformFile> _selectedFiles = [];
  List<XFile> _selectedImages = [];

  bool _isUploading = false;
  bool _isCreatingPost = false;
  bool _isProcessingAI = false;
  final TextEditingController _descriptionController = TextEditingController();
  final AppData _appData = AppData();
  late AnimationController _animationController;
  late Animation<double> _animation;
  final ImagePicker _picker = ImagePicker();

  static const String _groqApiUrl =
      'https://api.groq.com/openai/v1/chat/completions';
  static const String _groqApiKey =
      'REVOKED_GROQ_KEY';

  List<Map<String, dynamic>> _categories = [];
  bool _categoriesLoading = true;
  String? _selectedCategoryId;

  final Color _primaryColor = const Color.fromRGBO(244, 135, 6, 1);
  final Color _facebookBlue = const Color(0xFF1877F2);
  final Color _backgroundColor = const Color(0xFFF0F2F5);
  final Color _cardColor = AppColors.whitecolor;
  final Color _textColor = const Color(0xFF333333);

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
    _fetchUserProfile();
    _fetchCategories();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _descriptionController.addListener(_updateButtonState);
  }

  void _updateButtonState() {
    if (_isPostButtonEnabled) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
    setState(() {});
  }

  void _checkAuthStatus() => debugPrint('Auth: ${_appData.isAuthenticated}');

  @override
  void dispose() {
    _descriptionController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  bool get _isPostButtonEnabled =>
      (_descriptionController.text.isNotEmpty || _selectedFiles.isNotEmpty) &&
      !_isCreatingPost &&
      !_isProcessingAI;

  Future<void> _fetchCategories() async {
    try {
      setState(() => _categoriesLoading = true);
      final response = await http
          .get(
            Uri.parse(ApiConstants.fetchcategories),
            headers: {
              'Content-Type': 'application/json',
              if (_appData.accessToken != null)
                'Authorization': 'Bearer ${_appData.accessToken}',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        // FeedService wraps the list: { success, message, data: [...] }.
        final decoded = json.decode(response.body);
        final List<dynamic> data =
            decoded is List
                ? decoded
                : (decoded is Map<String, dynamic>
                    ? (decoded['data'] as List<dynamic>? ?? [])
                    : []);
        setState(() {
          _categories = data.whereType<Map<String, dynamic>>().toList();
          _categoriesLoading = false;
        });
      } else {
        setState(() => _categoriesLoading = false);
      }
    } catch (e) {
      setState(() => _categoriesLoading = false);
      debugPrint('Categories error: $e');
    }
  }

  void _showCategoryPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (_) => Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            decoration: const BoxDecoration(
              color: AppColors.whitecolor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 4),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Select Category',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _textColor,
                        ),
                      ),
                      const Spacer(),
                      if (_selectedCategoryId != null)
                        TextButton(
                          onPressed: () {
                            setState(() => _selectedCategoryId = null);
                            Navigator.pop(context);
                          },
                          child: Text(
                            'Clear',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                if (_categoriesLoading)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  )
                else
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final cat = _categories[index];
                        final id = cat['id']?.toString() ?? '';
                        final name = cat['name']?.toString() ?? '';
                        final isSelected = _selectedCategoryId == id;

                        return ListTile(
                          onTap: () {
                            setState(() {
                              _selectedCategoryId = isSelected ? null : id;
                            });
                            Navigator.pop(context);
                          },
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 4,
                          ),
                          leading: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color:
                                  isSelected
                                      ? _primaryColor.withAlpha(12)
                                      : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _categoryIcon(name),
                              color:
                                  isSelected
                                      ? _primaryColor
                                      : Colors.grey.shade500,
                              size: 22,
                            ),
                          ),
                          title: Text(
                            _capitalize(name),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight:
                                  isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                              color: isSelected ? _primaryColor : _textColor,
                            ),
                          ),
                          trailing:
                              isSelected
                                  ? Icon(
                                    Icons.check_circle_rounded,
                                    color: _primaryColor,
                                    size: 22,
                                  )
                                  : Icon(
                                    Icons.radio_button_unchecked,
                                    color: Colors.grey.shade300,
                                    size: 22,
                                  ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 16),
              ],
            ),
          ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  IconData _categoryIcon(String name) {
    switch (name.toLowerCase()) {
      case 'fun':
        return Icons.emoji_emotions_rounded;
      case 'innovation':
        return Icons.lightbulb_rounded;
      case 'technology':
        return Icons.computer_rounded;
      case 'idea':
        return Icons.tips_and_updates_rounded;
      case 'project':
        return Icons.folder_rounded;
      case 'announcement':
        return Icons.campaign_rounded;
      case 'question':
        return Icons.help_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  Future<void> _captureImage() async {
    try {
      final XFile? captured = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (captured != null) {
        setState(() {
          _selectedImages.add(captured);
          _selectedFiles.add(
            PlatformFile(
              name: captured.name,
              path: captured.path,
              size: File(captured.path).lengthSync(),
            ),
          );
        });
        _updateButtonState();
      }
    } catch (e) {
      _showError('Error capturing image ');
    }
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile>? picked = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (picked != null && picked.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(picked);
          _selectedFiles.addAll(
            picked.map(
              (x) => PlatformFile(
                name: x.name,
                path: x.path,
                size: File(x.path).lengthSync(),
              ),
            ),
          );
        });
        _updateButtonState();
      }
    } catch (e) {
      _showError('Error picking images');
    }
  }

  static const Set<String> _videoExtensions = {
    'mp4',
    'mov',
    'avi',
    'mkv',
    'wmv',
    'flv',
    'webm',
    '3gp',
  };

  Future<void> _pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
      );
      if (result == null) return;

      final List<PlatformFile> videoFiles = [];
      final List<PlatformFile> otherFiles = [];

      for (final file in result.files) {
        final ext = file.extension?.toLowerCase() ?? '';
        if (_videoExtensions.contains(ext)) {
          videoFiles.add(file);
        } else {
          otherFiles.add(file);
        }
      }

      if (otherFiles.isNotEmpty) {
        setState(() => _selectedFiles.addAll(otherFiles));
        _updateButtonState();
      }

      for (final vf in videoFiles) {
        if (vf.path != null) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ReelsPreviewScreen(videoPath: vf.path!),
            ),
          );
        }
      }
    } catch (e) {
      _showError('Error picking files');
    }
  }

  Future<void> _takeVideo() async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(minutes: 5),
      );
      if (video != null && mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ReelsPreviewScreen(videoPath: video.path),
          ),
        );
      }
    } catch (e) {
      _showError('Error recording video');
    }
  }

  Future<String> _callGroqAPI(String message) async {
    final response = await http
        .post(
          Uri.parse(_groqApiUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_groqApiKey',
          },
          body: jsonEncode({
            'model': 'llama-3.1-8b-instant',
            'messages': [
              {
                'role': 'system',
                'content':
                    'You are ELIZA, an AI assistant created by Innovator. '
                    'Always respond as ELIZA and never mention Groq, Llama, Meta, Google, Gemini, '
                    'or any other AI system. Enhance the user\'s input to create a polished, '
                    'engaging post for an innovation platform. Keep to exactly 50 words or less. '
                    'Never wrap your response in quotation marks.',
              },
              {'role': 'user', 'content': message},
            ],
            'temperature': 0.7,
            'max_tokens': 150,
            'top_p': 1,
            'stream': false,
          }),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['choices'][0]['message']['content'];
    }
    throw Exception('Groq API Error ${response.statusCode}: ${response.body}');
  }

  String _validateWordCount(String r) {
    final words = r.trim().split(RegExp(r'\s+'));
    if (words.length <= 50) return r;
    final trimmed = words.take(50).join(' ');
    return trimmed.endsWith('.') ||
            trimmed.endsWith('!') ||
            trimmed.endsWith('?')
        ? trimmed
        : '$trimmed...';
  }

  String _processElizaResponse(String r) {
    String result = r.trim();
    result =
        result
            .replaceAll(
              RegExp(
                r'^["\u201C\u2018'
                "'"
                r']+',
              ),
              '',
            )
            .replaceAll(
              RegExp(
                r'["\u201D\u2019'
                "'"
                r']+$',
              ),
              '',
            )
            .trim();
    result = result
        .replaceAll(RegExp(r'\bGemini\b', caseSensitive: false), 'ELIZA')
        .replaceAll(RegExp(r'\bGoogle\b', caseSensitive: false), 'Innovator')
        .replaceAll(RegExp(r'\bBard\b', caseSensitive: false), 'ELIZA')
        .replaceAll(RegExp(r'\bGroq\b', caseSensitive: false), 'Innovator')
        .replaceAll(RegExp(r'\bLlama\b', caseSensitive: false), 'ELIZA')
        .replaceAll(RegExp(r'\bMeta\b', caseSensitive: false), 'Innovator');
    return _validateWordCount(result);
  }

  Future<void> _enhancePostWithAI() async {
    if (_descriptionController.text.trim().isEmpty || _isProcessingAI) {
      _showError('Please enter some text to enhance');
      return;
    }
    setState(() => _isProcessingAI = true);
    try {
      final processed = _processElizaResponse(
        await _callGroqAPI(_descriptionController.text.trim()),
      );
      setState(() {
        _descriptionController.text = processed;
        _isProcessingAI = false;
      });
      _showSuccess('Post enhanced by ELIZA AI)');
      _updateButtonState();
    } catch (e) {
      _showError('ELIZA enhancement failed');
      setState(() => _isProcessingAI = false);
    }
  }

  Future<void> _fetchUserProfile() async {
    try {
      if (AppData().accessToken?.isEmpty ?? true) {
        setState(() {
          _errorMessage = 'Authentication token not found';
          _isLoading = false;
        });
        return;
      }
      setState(() {
        _userData = AppData().currentUser;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error';
        _isLoading = false;
      });
    }
  }

  // Future<void> _createPost() async {
  //   if (_descriptionController.text.trim().isEmpty && _selectedFiles.isEmpty) {
  //     _showError('Please enter a description or select a file');
  //     return;
  //   }

  //   setState(() => _isCreatingPost = true);

  //   try {
  //     final uri = Uri.parse(ApiConstants.createpost);
  //     final request = http.MultipartRequest('POST', uri);

  //     if (_appData.accessToken != null) {
  //       request.headers['Authorization'] = 'Bearer ${_appData.accessToken}';
  //     }

  //     request.fields['content'] = _descriptionController.text.trim();

  //     if (_selectedCategoryId != null) {
  //       request.fields['category_ids'] = _selectedCategoryId!;
  //     }

  //     for (final file in _selectedFiles) {
  //       if (file.path == null) continue;
  //       final mimeType =
  //           lookupMimeType(file.path!) ?? 'application/octet-stream';
  //       request.files.add(
  //         await http.MultipartFile.fromPath(
  //           'uploaded_media',
  //           file.path!,
  //           contentType: MediaType.parse(mimeType),
  //           filename: path.basename(file.path!),
  //         ),
  //       );
  //     }

  //     final streamed = await request.send().timeout(
  //       const Duration(seconds: 60),
  //     );
  //     final response = await http.Response.fromStream(streamed);

  //     if (response.statusCode == 200 || response.statusCode == 201) {
  //       _showSuccess('Post published successfully!');
  //       _clearForm();
  //       Navigator.pushAndRemoveUntil(
  //         context,
  //         MaterialPageRoute(builder: (_) => Homepage()),
  //         (route) => false,
  //       );
  //     } else if (response.statusCode == 401) {
  //       _showError('Authentication failed. Please log in again.');
  //     } else {
  //       Map<String, dynamic> body = {};
  //       try {
  //         body = json.decode(response.body) as Map<String, dynamic>;
  //       } catch (_) {}
  //       final msg =
  //           body['detail']?.toString() ??
  //           body['message']?.toString() ??
  //           'Failed to create post (${response.statusCode})';
  //       _showError(msg);
  //     }
  //   } catch (e) {
  //     _showError('Error creating post: $e');
  //   } finally {
  //     setState(() => _isCreatingPost = false);
  //   }
  // }

  Future<void> _createPost() async {
    if (_descriptionController.text.trim().isEmpty && _selectedFiles.isEmpty) {
      _showError('Please enter a description or select a file');
      return;
    }

    // Capture everything BEFORE navigating (widget will be disposed)
    final String content = _descriptionController.text.trim();
    final String? categoryId = _selectedCategoryId;
    final List<PlatformFile> filesToUpload = List.from(_selectedFiles);
    final String? accessToken = _appData.accessToken;

    // Get the ProviderContainer — survives navigation
    final container = ProviderScope.containerOf(context);

    // Set uploading true BEFORE navigating
    container.read(postUploadingProvider.notifier).state = true;
    container.read(postUploadMessageProvider.notifier).state = null;

    // Navigate immediately
    _clearForm();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const Homepage()),
      (route) => false,
    );

    // Upload runs after navigation using container (not ref)
    try {
      // Backend route is /api/posts (no trailing slash).
      final createUrl = ApiConstants.createpost.replaceAll(RegExp(r'/+$'), '');
      final uri = Uri.parse(createUrl);
      final request = http.MultipartRequest('POST', uri);

      if (accessToken != null) {
        request.headers['Authorization'] = 'Bearer $accessToken';
      }

      // FeedService POST /api/posts expects: content, categoryIds (repeated),
      // sharedPostId, media (repeated file field).
      request.fields['content'] = content;

      if (categoryId != null && categoryId.isNotEmpty) {
        request.fields['categoryIds'] = categoryId;
      }

      for (final file in filesToUpload) {
        if (file.path == null) continue;
        final mimeType =
            lookupMimeType(file.path!) ?? 'application/octet-stream';
        request.files.add(
          await http.MultipartFile.fromPath(
            'media',
            file.path!,
            contentType: MediaType.parse(mimeType),
            filename: path.basename(file.path!),
          ),
        );
      }

      final streamed = await request.send().timeout(
        const Duration(seconds: 60),
      );
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200 || response.statusCode == 201) {
        container.read(postUploadingProvider.notifier).state = false;
        container.read(postUploadMessageProvider.notifier).state =
            'Post published successfully! 🎉';
      } else if (response.statusCode == 401) {
        container.read(postUploadingProvider.notifier).state = false;
        container.read(postUploadMessageProvider.notifier).state =
            'Authentication failed. Please log in again.';
      } else {
        // Surface the real server error to the log to diagnose 400s.
        developer.log(
          '[CreatePost] ${response.statusCode} body: ${response.body}',
        );
        Map<String, dynamic> body = {};
        try {
          body = json.decode(response.body) as Map<String, dynamic>;
        } catch (_) {}
        final msg =
            body['detail']?.toString() ??
            body['message']?.toString() ??
            (body['errors'] != null
                ? body['errors'].toString()
                : 'Failed to create post (${response.statusCode})');
        container.read(postUploadingProvider.notifier).state = false;
        container.read(postUploadMessageProvider.notifier).state = msg;
      }
    } catch (e) {
      container.read(postUploadingProvider.notifier).state = false;
      container.read(postUploadMessageProvider.notifier).state =
          'Error uploading post: $e';
    }
  }

  void _clearForm() {
    setState(() {
      _descriptionController.clear();
      _selectedFiles = [];
      _selectedImages = [];
      _selectedCategoryId = null;
    });
  }

  void _showError(String message) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      duration: Duration(seconds: 1),
      backgroundColor: Colors.red.shade700,
      behavior: SnackBarBehavior.fixed,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        duration: Duration(seconds: 1),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.fixed,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(drawerProfileProvider);

    final String? resolvedPictureUrl = () {
      final pic = profile.picture;
      if (pic == null || pic.isEmpty) return null;
      final base =
          pic.startsWith('http') ? pic : '${ApiConstants.userBase}$pic';
      return profile.imageVersion > 0
          ? '$base?v=${profile.imageVersion}'
          : base;
    }();

    final userData = AppData().currentUser ?? _userData;
    final String displayName =
        profile.name != 'User'
            ? profile.name
            : userData?['full_name']?.toString() ??
                userData?['username']?.toString() ??
                userData?['name']?.toString() ??
                'User';
    final unreadCount = ref.watch(chatUnreadCountProvider);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _backgroundColor,
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),

                Container(
                  constraints: const BoxConstraints(minHeight: 400),
                  color: _cardColor,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap:
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => UserProfileScreen(
                                          userId: AppData().currentUserId ?? '',
                                        ),
                                  ),
                                ),
                            child: CircleAvatar(
                              radius: 40,
                              backgroundColor: Colors.grey[200],
                              backgroundImage:
                                  resolvedPictureUrl != null
                                      ? NetworkImage(resolvedPictureUrl)
                                      : null,
                              child:
                                  resolvedPictureUrl == null
                                      ? const Icon(
                                        Icons.person,
                                        size: 40,
                                        color: Colors.grey,
                                      )
                                      : null,
                            ),
                          ),
                          const SizedBox(width: 12),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName.toUpperCase(),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: _textColor,
                                  ),
                                ),
                                const SizedBox(height: 8),

                                GestureDetector(
                                  onTap: _showCategoryPicker,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 7,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          _selectedCategoryId != null
                                              ? _primaryColor.withAlpha(10)
                                              : Colors.grey.shade100,
                                      border: Border.all(
                                        color:
                                            _selectedCategoryId != null
                                                ? _primaryColor.withAlpha(50)
                                                : Colors.grey.shade300,
                                        width: 1.2,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          _selectedCategoryId != null
                                              ? _categoryIcon(
                                                _categories
                                                        .firstWhere(
                                                          (c) =>
                                                              c['id']
                                                                  ?.toString() ==
                                                              _selectedCategoryId,
                                                          orElse: () => {},
                                                        )['name']
                                                        ?.toString() ??
                                                    '',
                                              )
                                              : Icons.add_circle_outline,
                                          size: 16,
                                          color:
                                              _selectedCategoryId != null
                                                  ? _primaryColor
                                                  : Colors.grey.shade500,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          _selectedCategoryId != null
                                              ? _capitalize(
                                                _categories
                                                        .firstWhere(
                                                          (c) =>
                                                              c['id']
                                                                  ?.toString() ==
                                                              _selectedCategoryId,
                                                          orElse: () => {},
                                                        )['name']
                                                        ?.toString() ??
                                                    'Category',
                                              )
                                              : 'Add Category',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight:
                                                _selectedCategoryId != null
                                                    ? FontWeight.w600
                                                    : FontWeight.w400,
                                            color:
                                                _selectedCategoryId != null
                                                    ? _primaryColor
                                                    : Colors.grey.shade600,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(
                                          Icons.keyboard_arrow_down_rounded,
                                          size: 18,
                                          color:
                                              _selectedCategoryId != null
                                                  ? _primaryColor
                                                  : Colors.grey.shade400,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          IconButton(
                            onPressed:
                                _isProcessingAI ? null : _enhancePostWithAI,
                            icon:
                                _isProcessingAI
                                    ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.blue,
                                        strokeWidth: 2,
                                      ),
                                    )
                                    : Image.asset(
                                      'animation/AI.gif',
                                      width: 50,
                                    ),
                            tooltip: 'Enhance with ELIZA AI',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Text field
                      TextField(
                        controller: _descriptionController,
                        style: TextStyle(color: _textColor, fontSize: 18),
                        maxLines: 8,
                        minLines: 3,
                        decoration: InputDecoration(
                          hintText: "Describe your Learnings in Brief ? ",
                          hintStyle: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 18,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),
                Container(
                  color: _cardColor,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add to your post',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: _textColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: [
                            _mediaButton(
                              icon: Icons.camera_alt,
                              color: Colors.purple,
                              label: 'Camera',
                              onTap: _captureImage,
                            ),
                            _mediaButton(
                              icon: Icons.videocam,
                              color: Colors.red,
                              label: 'Video',
                              onTap: _takeVideo,
                            ),
                            _mediaButton(
                              icon: Icons.photo_library,
                              color: Colors.green,
                              label: 'Photos',
                              onTap: _pickImages,
                            ),
                            _mediaButton(
                              icon: Icons.attach_file,
                              color: Colors.blue,
                              label: 'Files',
                              onTap: _pickFiles,
                            ),
                            _mediaButton(
                              icon: Icons.play_circle_fill_rounded,
                              color: Colors.orange,
                              label: 'Reels',
                              onTap:
                                  () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const ReelsCameraScreen(),
                                    ),
                                  ),
                            ),
                          ],
                        ),
                      ),

                      if (_selectedFiles.isNotEmpty && _isUploading) ...[
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: _facebookBlue,
                                strokeWidth: 2,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Uploading files...',
                              style: TextStyle(
                                color: _facebookBlue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],

                      if (_selectedFiles.isNotEmpty && !_isUploading) ...[
                        const SizedBox(height: 20),
                        Text(
                          'Selected Files (${_selectedFiles.length})',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _textColor,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 100,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _selectedFiles.length,
                            itemBuilder: (context, index) {
                              final file = _selectedFiles[index];
                              final isImage =
                                  file.path != null &&
                                  [
                                    'jpg',
                                    'jpeg',
                                    'png',
                                    'gif',
                                    'webp',
                                  ].contains(file.extension?.toLowerCase());
                              return Container(
                                width: 100,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                child: Stack(
                                  children: [
                                    if (isImage && file.path != null)
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.file(
                                          File(file.path!),
                                          width: 100,
                                          height: 100,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    else
                                      Center(
                                        child: Icon(
                                          _getFileIcon(file.extension),
                                          size: 36,
                                          color: _facebookBlue,
                                        ),
                                      ),
                                    Positioned(
                                      right: 0,
                                      top: 0,
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _selectedFiles.removeAt(index);
                                            if (index <
                                                _selectedImages.length) {
                                              _selectedImages.removeAt(index);
                                            }
                                          });
                                          _updateButtonState();
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withAlpha(50),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            color: AppColors.whitecolor,
                                            size: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isPostButtonEnabled ? _createPost : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _facebookBlue,
                    foregroundColor: AppColors.whitecolor,
                    disabledBackgroundColor: Colors.grey.shade300,
                    disabledForegroundColor: Colors.grey.shade500,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child:
                      _isCreatingPost
                          ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  color: AppColors.whitecolor,
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Publishing...',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          )
                          : const Text(
                            'Publish',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                ),
              ],
            ),
          ),
        ],
      ),
      // bottomNavigationBar: Container(
      //   padding: EdgeInsets.only(
      //     top: 40,
      //     left: 16,
      //     right: 16,
      //     bottom: MediaQuery.of(context).padding.bottom + 12,
      //   ),
      //   decoration: BoxDecoration(
      //     color: AppColors.whitecolor,
      //     boxShadow: [
      //       BoxShadow(
      //         color: Colors.black.withAlpha(10),
      //         blurRadius: 4,
      //         offset: const Offset(0, -1),
      //       ),
      //     ],
      //   ),
      //   child:
      // ),
      floatingActionButton: CountBadgeFAB(
        count: unreadCount,
        gifAsset: 'animation/chaticon.gif',
        backgroundColor: Colors.transparent,
        onPressed: () {
          ref.read(mutualFriendsProvider.notifier).refresh();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ChatListScreen()),
          ).then((_) {
            ref.invalidate(mutualFriendsProvider);
          });
        },
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
          child: LiquidNavBar(
            dock: NavDock.bottom,
            leading: const [
              LiquidNavItem(icon: Icons.home_rounded, label: 'Feed'),
              LiquidNavItem(icon: Icons.search_rounded, label: 'Search'),
              LiquidNavItem(
                icon: Icons.chat_bubble_outline_rounded,
                label: 'Chat',
              ),
            ],
            trailing: const [
              LiquidNavItem(icon: Icons.add_a_photo_rounded, label: 'Post'),
              LiquidNavItem(icon: Icons.storefront_outlined, label: 'Shop'),
              LiquidNavItem(
                icon: Icons.menu_rounded,
                label: 'Menu',
                pinBottom: true,
              ),
            ],
            // Post is the current screen; other taps return to the shell.
            selectedIndex: 3,
            onSelect: (_) {
              if (Navigator.of(context).canPop()) Navigator.of(context).pop();
            },
            onLogoTap: () {
              if (Navigator.of(context).canPop()) Navigator.of(context).pop();
            },
          ),
        ),
      ),
    );
  }

  Widget _mediaButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withAlpha(10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
        ],
      ),
    ),
  );

  IconData _getFileIcon(String? ext) {
    switch (ext?.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        return Icons.image;
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'mp3':
      case 'wav':
        return Icons.music_note;
      case 'mp4':
      case 'mov':
      case 'avi':
        return Icons.video_file;
      case 'zip':
      case 'rar':
        return Icons.folder_zip;
      default:
        return Icons.insert_drive_file;
    }
  }
}
