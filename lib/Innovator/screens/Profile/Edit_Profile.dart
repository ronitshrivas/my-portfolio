import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:innovator/Innovator/App_data/App_data.dart';
import 'package:innovator/Innovator/constant/api_constants.dart';
import 'package:innovator/Innovator/constant/app_colors.dart';
import 'package:innovator/Innovator/screens/chatrrom/screen/chatlistscreen.dart';
import 'package:innovator/Innovator/widget/CustomizeFAB.dart';
import 'package:innovator/innovator_home.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:developer' as developer;
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:get/get.dart';
import 'package:innovator/Innovator/controllers/user_controller.dart';
import 'package:path/path.dart' as path;
import 'package:http_parser/http_parser.dart';
import 'dart:async';

enum UsernameStatus { idle, checking, available, taken, error }

class UsernameCheckState {
  final UsernameStatus status;
  final List<String> suggestions;
  final String? errorMessage;

  const UsernameCheckState({
    this.status = UsernameStatus.idle,
    this.suggestions = const [],
    this.errorMessage,
  });

  UsernameCheckState copyWith({
    UsernameStatus? status,
    List<String>? suggestions,
    String? errorMessage,
  }) => UsernameCheckState(
    status: status ?? this.status,
    suggestions: suggestions ?? this.suggestions,
    errorMessage: errorMessage ?? this.errorMessage,
  );
}

class EditUsernameNotifier extends StateNotifier<UsernameCheckState> {
  EditUsernameNotifier() : super(const UsernameCheckState());

  Timer? _debounce;
  String? _originalUsername;

  void setOriginalUsername(String username) {
    _originalUsername = username;
  }

  void onUsernameChanged(String username) {
    _debounce?.cancel();

    if (username.isEmpty) {
      state = const UsernameCheckState();
      return;
    }

    if (username.trim() == _originalUsername) {
      state = state.copyWith(status: UsernameStatus.available, suggestions: []);
      return;
    }

    state = state.copyWith(status: UsernameStatus.checking, suggestions: []);

    _debounce = Timer(const Duration(milliseconds: 500), () {
      _checkUsername(username.trim());
    });
  }

  Future<void> _checkUsername(String username) async {
    if (username.length < 3) {
      state = state.copyWith(
        status: UsernameStatus.error,
        errorMessage: 'Username must be at least 3 characters',
        suggestions: [],
      );
      return;
    }

    try {
      final response = await http
          .get(
            Uri.parse('${ApiConstants.checkusername}?username=$username'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final isAvailable = data['is_available'] == true;
        final suggestions =
            (data['suggestions'] as List<dynamic>?)
                ?.map((s) => s.toString())
                .toList() ??
            [];

        state = state.copyWith(
          status: isAvailable ? UsernameStatus.available : UsernameStatus.taken,
          suggestions: isAvailable ? [] : suggestions,
          errorMessage: null,
        );
      } else {
        state = state.copyWith(
          status: UsernameStatus.error,
          errorMessage: 'Could not check username',
          suggestions: [],
        );
      }
    } catch (e) {
      developer.log('Username check error: $e');
      state = state.copyWith(
        status: UsernameStatus.error,
        errorMessage: 'Network error',
        suggestions: [],
      );
    }
  }

  void selectSuggestion(String suggestion) {
    state = state.copyWith(status: UsernameStatus.available, suggestions: []);
  }

  void reset() {
    _debounce?.cancel();
    state = const UsernameCheckState();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

final editUsernameProvider =
    StateNotifierProvider.autoDispose<EditUsernameNotifier, UsernameCheckState>(
      (ref) => EditUsernameNotifier(),
    );

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  EditProfileScreenState createState() => EditProfileScreenState();
}

class EditProfileScreenState extends ConsumerState<EditProfileScreen>
    with SingleTickerProviderStateMixin {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  late AnimationController animCtrl;
  late Animation<double> fadeAnim;
  late Animation<Offset> slideAnim;
  final formKey = GlobalKey<FormState>();

  late TextEditingController fullNameCtrl;
  late TextEditingController usernameCtrl;
  late TextEditingController emailCtrl;
  late TextEditingController phoneCtrl;
  late TextEditingController addressCtrl;
  late TextEditingController bioCtrl;
  late TextEditingController educationCtrl;
  late TextEditingController occupationCtrl;
  late TextEditingController hobbiesCtrl;

  String? selectedGender;
  DateTime? selectedDob;
  bool isLoading = false;
  bool isUploading = false;
  String? errorMessage;
  File? selectedImage;
  String? currentAvatarUrl;

  final UserController userController = Get.put(UserController());

  static const Color primary = Color.fromRGBO(244, 135, 6, 1);
  static const Color primaryLight = Color.fromRGBO(235, 111, 70, 0.10);
  static const Color bgColor = Color(0xFFF8F9FA);

  @override
  void initState() {
    super.initState();
    initControllers();
    loadUserData();

    animCtrl = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    fadeAnim = CurvedAnimation(parent: animCtrl, curve: Curves.easeInOut);
    slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: animCtrl, curve: Curves.easeOutCubic));
    animCtrl.forward();
  }

  @override
  void dispose() {
    animCtrl.dispose();
    fullNameCtrl.dispose();
    usernameCtrl.dispose();
    emailCtrl.dispose();
    phoneCtrl.dispose();
    addressCtrl.dispose();
    bioCtrl.dispose();
    educationCtrl.dispose();
    occupationCtrl.dispose();
    hobbiesCtrl.dispose();
    super.dispose();
  }

  void initControllers() {
    fullNameCtrl = TextEditingController();
    usernameCtrl = TextEditingController();
    emailCtrl = TextEditingController();
    phoneCtrl = TextEditingController();
    addressCtrl = TextEditingController();
    bioCtrl = TextEditingController();
    educationCtrl = TextEditingController();
    occupationCtrl = TextEditingController();
    hobbiesCtrl = TextEditingController();
  }

  Future<void> loadUserData() async {
    final appData = AppData();
    await appData.initialize();
    final u = appData.currentUser ?? {};
    final profile = u['profile'] as Map<String, dynamic>? ?? {};

    setState(() {
      fullNameCtrl.text = u['full_name']?.toString() ?? '';
      usernameCtrl.text = u['username']?.toString() ?? '';
      emailCtrl.text = u['email']?.toString() ?? '';
      phoneCtrl.text =
          profile['phone_number']?.toString() ??
          u['phone_number']?.toString() ??
          '';
      addressCtrl.text =
          profile['address']?.toString() ?? u['address']?.toString() ?? '';
      bioCtrl.text = profile['bio']?.toString() ?? u['bio']?.toString() ?? '';
      educationCtrl.text =
          profile['education']?.toString() ?? u['education']?.toString() ?? '';
      occupationCtrl.text =
          profile['occupation']?.toString() ??
          u['occupation']?.toString() ??
          '';
      hobbiesCtrl.text =
          profile['hobbies']?.toString() ?? u['hobbies']?.toString() ?? '';
      selectedGender =
          profile['gender']?.toString() ?? u['gender']?.toString();

      final dobRaw =
          profile['date_of_birth']?.toString() ??
          u['date_of_birth']?.toString();
      if (dobRaw != null && dobRaw.isNotEmpty) {
        try {
          selectedDob = DateTime.parse(dobRaw);
        } catch (_) {}
      }

      final avatarPath =
          appData.currentUserAvatar ??
          profile['avatar']?.toString() ??
          u['photo_url']?.toString();
      currentAvatarUrl = resolveUrl(avatarPath);
    });

    final originalUsername = u['username']?.toString() ?? '';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(editUsernameProvider.notifier).setOriginalUsername(originalUsername);
      if (originalUsername.isNotEmpty) {
        ref.read(editUsernameProvider.notifier).onUsernameChanged(originalUsername);
      }
    });
  }

  String? resolveUrl(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
    return '${ApiConstants.userBase}$raw';
  }

  Future<void> pickImage() async {
    try {
      final XFile? image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );
      if (image == null) return;
      setState(() => selectedImage = File(image.path));
    } catch (e) {
      showError('Failed to pick image: $e');
    }
  }

  Future<String> uploadAvatar(File imageFile) async {
    final token = AppData().accessToken ?? '';
    final filename = path.basename(imageFile.path);
    final mimeType =
        filename.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg';

    final request =
        http.MultipartRequest('POST', Uri.parse(ApiConstants.avatarurl))
          ..headers['Authorization'] = 'Bearer $token'
          ..files.add(
            http.MultipartFile(
              'avatar',
              http.ByteStream(imageFile.openRead()),
              await imageFile.length(),
              filename: filename,
              contentType: MediaType.parse(mimeType),
            ),
          );

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    developer.log('[EditProfile] Avatar upload ${response.statusCode}: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final avatarPath =
          data['avatar']?.toString() ??
          data['data']?['avatar']?.toString() ??
          data['data']?['photo_url']?.toString() ??
          '';
      if (avatarPath.isEmpty) throw Exception('No avatar URL in response');
      return avatarPath;
    }
    throw Exception('Avatar upload failed (${response.statusCode})');
  }

  Future<void> updateProfile() async {
    if (!formKey.currentState!.validate()) return;

    final usernameState = ref.read(editUsernameProvider);
    if (usernameState.status == UsernameStatus.taken) {
      showError('Username is already taken');
      return;
    }
    if (usernameState.status == UsernameStatus.checking) {
      showError('Please wait — checking username availability...');
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final appData = AppData();

      if (selectedImage != null) {
        setState(() => isUploading = true);
        try {
          final newAvatarPath = await uploadAvatar(selectedImage!);
          final fullUrl = resolveUrl(newAvatarPath)!;

          if (currentAvatarUrl != null) {
            imageCache.evict(NetworkImage(currentAvatarUrl!));
          }

          await appData.updateProfilePicture(newAvatarPath);
          userController.updateProfilePicture(newAvatarPath);
          userController.profilePictureVersion.value++;

          setState(() => currentAvatarUrl = fullUrl);
        } finally {
          setState(() => isUploading = false);
        }
      }

      String? valOrNull(String s) => s.isEmpty ? null : s;

      final body = <String, dynamic>{
        'full_name': fullNameCtrl.text.trim(),
      };

      if (usernameCtrl.text.trim().isNotEmpty) {
        body['username'] = usernameCtrl.text.trim();
      }

      void addIfFilled(String key, String value) {
        final v = valOrNull(value);
        if (v != null) body[key] = v;
      }

      addIfFilled('phone_number', phoneCtrl.text.trim());
      addIfFilled('address', addressCtrl.text.trim());
      addIfFilled('bio', bioCtrl.text.trim());
      addIfFilled('education', educationCtrl.text.trim());
      addIfFilled('occupation', occupationCtrl.text.trim());
      addIfFilled('hobbies', hobbiesCtrl.text.trim());
      addIfFilled('email', emailCtrl.text.trim());

      if (selectedGender != null) body['gender'] = selectedGender;
      if (selectedDob != null) {
        body['date_of_birth'] = DateFormat('yyyy-MM-dd').format(selectedDob!);
      }

      developer.log('[EditProfile] PATCH ${ApiConstants.profile}  body: $body');

      final response = await http.patch(
        Uri.parse(ApiConstants.profile),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${appData.accessToken}',
        },
        body: jsonEncode(body),
      );

      developer.log('[EditProfile] PATCH response ${response.statusCode}: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final updated = jsonDecode(response.body) as Map<String, dynamic>;
        await appData.setCurrentUser({
          ...?appData.currentUser,
          'full_name': fullNameCtrl.text.trim(),
          'username': usernameCtrl.text.trim(),
          'email': emailCtrl.text.trim(),
          'profile': {
            ...?appData.currentUser?['profile'] as Map<String, dynamic>?,
            ...updated,
          },
        });

        userController.updateUserName(fullNameCtrl.text.trim());

        showSuccess('Profile updated successfully');
        Navigator.push(context, MaterialPageRoute(builder: (_) => Homepage()));
      } else {
        final errBody = jsonDecode(response.body);
        final msg =
            errBody is Map
                ? (errBody.values.first is List
                    ? (errBody.values.first as List).first.toString()
                    : errBody.values.first.toString())
                : response.body;
        setState(() => errorMessage = msg);
      }
    } catch (e) {
      developer.log('[EditProfile] Error: $e');
      setState(() => errorMessage = 'Error: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: AppColors.whitecolor),
            const SizedBox(width: 8),
            Text(msg),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.whitecolor),
            const SizedBox(width: 8),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> selectDob(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDob ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: primary,
            onPrimary: AppColors.whitecolor,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => selectedDob = picked);
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = ref.watch(chatUnreadCountProvider);

    return WillPopScope(
      onWillPop: () async => true,
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: bgColor,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.whitecolor,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromRGBO(0, 0, 0, 0.08),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_back, color: primary),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Update Profile',
            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          actions: [
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => Homepage()),
                );
              },
              child: const Text('Skip', style: TextStyle(color: primary)),
            ),
          ],
        ),
        body: Stack(
          children: [
            FadeTransition(
              opacity: fadeAnim,
              child: SlideTransition(
                position: slideAnim,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: Column(
                    children: [
                      buildAvatarSection(),
                      if (errorMessage != null) buildErrorBanner(errorMessage!),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Form(
                          key: formKey,
                          child: Column(
                            children: [
                              buildSection('Personal Information', [
                                buildField(
                                  ctrl: fullNameCtrl,
                                  label: 'Full Name',
                                  icon: Icons.person,
                                  required: true,
                                  validator: (v) =>
                                      v == null || v.trim().isEmpty
                                          ? 'Enter your full name'
                                          : null,
                                ),
                                buildUsernameField(),
                                buildField(
                                  ctrl: emailCtrl,
                                  label: 'Email',
                                  icon: Icons.email_outlined,
                                  keyboard: TextInputType.emailAddress,
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) return 'Enter your email';
                                    if (!RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v.trim())) {
                                      return 'Enter a valid email address';
                                    }
                                    return null;
                                  },
                                ),
                                buildField(
                                  ctrl: phoneCtrl,
                                  label: 'Phone Number',
                                  icon: Icons.phone,
                                  keyboard: TextInputType.phone,
                                ),
                                buildGenderDropdown(),
                                buildDobPicker(),
                                buildField(
                                  ctrl: addressCtrl,
                                  label: 'Address',
                                  icon: Icons.location_on,
                                  hint: 'City, Country',
                                ),
                              ]),
                              buildSection('Professional Information', [
                                buildField(
                                  ctrl: educationCtrl,
                                  label: 'Education',
                                  icon: Icons.school,
                                  hint: 'e.g. Bsc. CSIT',
                                ),
                                buildField(
                                  ctrl: occupationCtrl,
                                  label: 'Occupation',
                                  icon: Icons.work,
                                  hint: 'e.g. Software Engineer',
                                ),
                              ]),
                              buildSection('About You', [
                                buildField(
                                  ctrl: bioCtrl,
                                  label: 'Bio',
                                  icon: Icons.edit,
                                  hint: 'Tell us about yourself…',
                                  maxLines: 4,
                                ),
                                buildField(
                                  ctrl: hobbiesCtrl,
                                  label: 'Hobbies',
                                  icon: Icons.interests,
                                  hint: 'e.g. Reading, Hiking, Coding',
                                ),
                              ]),
                              const SizedBox(height: 28),
                              buildSaveButton(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (isLoading)
              Container(
                color: const Color.fromRGBO(0, 0, 0, 0.26),
                child: const Center(
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: primary),
                          SizedBox(height: 16),
                          Text('Saving profile…'),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
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
      ),
    );
  }

  Widget buildAvatarSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color.fromRGBO(244, 135, 6, 0.25),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: primaryLight,
                  backgroundImage: selectedImage != null
                      ? FileImage(selectedImage!) as ImageProvider
                      : (currentAvatarUrl != null
                          ? NetworkImage(currentAvatarUrl!)
                          : null),
                  child: (selectedImage == null && currentAvatarUrl == null)
                      ? const Icon(Icons.person, size: 60, color: primary)
                      : null,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: isUploading ? null : pickImage,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.whitecolor, width: 3),
                    ),
                    child: isUploading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: AppColors.whitecolor,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.camera_alt, color: AppColors.whitecolor, size: 18),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Tap to change profile picture',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget buildErrorBanner(String msg) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade600),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              msg,
              style: TextStyle(color: Colors.red.shade700, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSection(String title, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.whitecolor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(0, 0, 0, 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: primary,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget buildUsernameField() {
    final state = ref.watch(editUsernameProvider);

    Color borderColor() {
      switch (state.status) {
        case UsernameStatus.available:
          return Colors.green.shade500;
        case UsernameStatus.taken:
          return Colors.red.shade400;
        case UsernameStatus.checking:
          return Colors.orange.shade300;
        default:
          return Colors.grey.shade300;
      }
    }

    Widget? suffixIcon() {
      switch (state.status) {
        case UsernameStatus.checking:
          return Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.orange.shade400,
              ),
            ),
          );
        case UsernameStatus.available:
          return Icon(Icons.check_circle_rounded, color: Colors.green.shade500, size: 22);
        case UsernameStatus.taken:
          return Icon(Icons.cancel_rounded, color: Colors.red.shade400, size: 22);
        default:
          return null;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: usernameCtrl,
            autocorrect: false,
            enableSuggestions: false,
            onChanged: (value) =>
                ref.read(editUsernameProvider.notifier).onUsernameChanged(value),
            decoration: InputDecoration(
              labelText: 'Username',
              prefixIcon: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.alternate_email, color: primary, size: 20),
              ),
              suffixIcon: suffixIcon(),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: borderColor()),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: borderColor(), width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: borderColor(), width: 1.8),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              labelStyle: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: buildUsernameStatusMessage(state),
          ),
          if (state.status == UsernameStatus.taken && state.suggestions.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Try one of these:',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: state.suggestions.map((suggestion) {
                return UsernameSuggestionChip(
                  label: suggestion,
                  onTap: () {
                    usernameCtrl.text = suggestion;
                    usernameCtrl.selection = TextSelection.fromPosition(
                      TextPosition(offset: suggestion.length),
                    );
                    ref.read(editUsernameProvider.notifier).selectSuggestion(suggestion);
                    ref.read(editUsernameProvider.notifier).onUsernameChanged(suggestion);
                  },
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget buildUsernameStatusMessage(UsernameCheckState state) {
    switch (state.status) {
      case UsernameStatus.available:
        return Padding(
          padding: const EdgeInsets.only(top: 6, left: 4),
          child: Row(
            children: [
              Icon(Icons.check_circle_outline, size: 14, color: Colors.green.shade500),
              const SizedBox(width: 4),
              Text(
                'Username is available!',
                style: TextStyle(fontSize: 12, color: Colors.green.shade600, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        );
      case UsernameStatus.taken:
        return Padding(
          padding: const EdgeInsets.only(top: 6, left: 4),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 14, color: Colors.red.shade400),
              const SizedBox(width: 4),
              Text(
                'Username already taken',
                style: TextStyle(fontSize: 12, color: Colors.red.shade500, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        );
      case UsernameStatus.error:
        return Padding(
          padding: const EdgeInsets.only(top: 6, left: 4),
          child: Text(
            state.errorMessage ?? 'Invalid username',
            style: TextStyle(fontSize: 12, color: Colors.orange.shade700),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget buildField({
    required TextEditingController ctrl,
    required String label,
    required IconData icon,
    String? hint,
    bool required = false,
    TextInputType? keyboard,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: ctrl,
        keyboardType: keyboard,
        maxLines: maxLines,
        validator: validator,
        decoration: InputDecoration(
          labelText: required ? '$label *' : label,
          hintText: hint,
          prefixIcon: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: primary, size: 20),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primary, width: 1.8),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          labelStyle: TextStyle(color: Colors.grey.shade600),
          hintStyle: TextStyle(color: Colors.grey.shade400),
        ),
      ),
    );
  }

  Widget buildGenderDropdown() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: selectedGender,
        decoration: InputDecoration(
          labelText: 'Gender',
          prefixIcon: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.person_outline, color: primary, size: 20),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primary, width: 1.8),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
        items: ['Male', 'Female', 'Other', 'Prefer not to say']
            .map((g) => DropdownMenuItem(value: g, child: Text(g)))
            .toList(),
        onChanged: (v) => setState(() => selectedGender = v),
      ),
    );
  }

  Widget buildDobPicker() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => selectDob(context),
        borderRadius: BorderRadius.circular(12),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: 'Date of Birth',
            prefixIcon: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.calendar_today, color: primary, size: 20),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          child: Text(
            selectedDob != null
                ? DateFormat('MMM dd, yyyy').format(selectedDob!)
                : 'Select date of birth',
            style: TextStyle(
              color: selectedDob != null ? Colors.black87 : Colors.grey.shade400,
            ),
          ),
        ),
      ),
    );
  }

  Widget buildSaveButton() {
    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [primary, Color.fromRGBO(255, 131, 90, 1)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(244, 135, 6, 0.35),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : updateProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.save, color: AppColors.whitecolor),
            SizedBox(width: 8),
            Text(
              'Save Changes',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.whitecolor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class UsernameSuggestionChip extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const UsernameSuggestionChip({
    Key? key,
    required this.label,
    required this.onTap,
  }) : super(key: key);

  @override
  State<UsernameSuggestionChip> createState() => UsernameSuggestionChipState();
}

class UsernameSuggestionChipState extends State<UsernameSuggestionChip> {
  bool pressed = false;

  static const Color primary = Color.fromRGBO(244, 135, 6, 1);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => pressed = true),
      onTapUp: (_) {
        setState(() => pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: pressed
              ? primary
              : const Color.fromRGBO(244, 135, 6, 0.08),
          border: Border.all(
            color: pressed
                ? primary
                : const Color.fromRGBO(244, 135, 6, 0.4),
            width: 1.2,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.alternate_email,
              size: 13,
              color: pressed ? AppColors.whitecolor : primary,
            ),
            const SizedBox(width: 4),
            Text(
              widget.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: pressed ? AppColors.whitecolor : primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}