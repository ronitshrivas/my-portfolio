import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:innovator/KMS/screens/dashboard/teacher_dashboard_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:innovator/KMS/core/constants/app_style.dart';
import 'package:innovator/KMS/provider/teacher_provider.dart';

class _KycFormData {
  File? idDoc;
  String bankAccountNumber = '';
  String bankName = '';
  String citizenship = '';
  File? photo;
  File? cv;
  String nIdNumber = '';

  bool get isComplete =>
      idDoc != null &&
      bankAccountNumber.trim().isNotEmpty &&
      bankName.trim().isNotEmpty &&
      citizenship.trim().isNotEmpty &&
      photo != null &&
      cv != null &&
      nIdNumber.trim().isNotEmpty;
}

class KycUploadScreen extends ConsumerStatefulWidget {
  const KycUploadScreen({super.key});

  @override
  ConsumerState<KycUploadScreen> createState() => _KycUploadScreenState();
}

class _KycUploadScreenState extends ConsumerState<KycUploadScreen>
    with SingleTickerProviderStateMixin {
  final _formData = _KycFormData();
  bool _isUploading = false;
  bool _uploadSuccess = false;
  final ImagePicker _picker = ImagePicker();

  final _bankAccountCtrl = TextEditingController();
  final _bankNameCtrl = TextEditingController();
  final _citizenshipCtrl = TextEditingController();
  final _nIdCtrl = TextEditingController();

  late AnimationController _successController;
  late Animation<double> successAnim;

  @override
  void initState() {
    super.initState();
    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    successAnim = CurvedAnimation(
      parent: _successController,
      curve: Curves.elasticOut,
    );

    void listener() => setState(() {});
    _bankAccountCtrl.addListener(listener);
    _bankNameCtrl.addListener(listener);
    _citizenshipCtrl.addListener(listener);
    _nIdCtrl.addListener(listener);
  }

  @override
  void dispose() {
    _successController.dispose();
    _bankAccountCtrl.dispose();
    _bankNameCtrl.dispose();
    _citizenshipCtrl.dispose();
    _nIdCtrl.dispose();
    super.dispose();
  }

  final _digitsOnly = FilteringTextInputFormatter.digitsOnly;

  Future<bool> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (status.isGranted) return true;
    if (status.isPermanentlyDenied && mounted) {
      _showPermissionDialog(
        title: 'Camera Permission Required',
        message:
            'Camera access is permanently denied. Please enable it from App Settings.',
      );
      return false;
    }
    if (mounted) _showSnack('Camera permission denied', isError: true);
    return false;
  }

  Future<bool> _requestGalleryPermission() async {
    final Permission perm =
        Platform.isAndroid
            ? (await _isAndroid13Plus()
                ? Permission.photos
                : Permission.storage)
            : Permission.photos;
    final status = await perm.request();
    if (status.isGranted || status.isLimited) return true;
    if (status.isPermanentlyDenied && mounted) {
      _showPermissionDialog(
        title: 'Gallery Permission Required',
        message:
            'Gallery access is permanently denied. Please enable it from App Settings.',
      );
      return false;
    }
    if (mounted) _showSnack('Gallery permission denied', isError: true);
    return false;
  }

  Future<bool> _isAndroid13Plus() async {
    try {
      return int.parse(Platform.operatingSystemVersion.split('.').first) >= 13;
    } catch (_) {
      return false;
    }
  }

  void _showImagePickerSheet(void Function(File) onPicked) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (_) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _sheetHandle(),
                const SizedBox(height: 20),
                const Text(
                  'Select Image Source',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  'Choose camera or gallery',
                  style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: _PickerOption(
                        icon: Icons.camera_alt_rounded,
                        label: 'Camera',
                        subtitle: 'Take a new photo',
                        onTap: () async {
                          Navigator.pop(context);
                          await _pickImageFromCamera(onPicked);
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _PickerOption(
                        icon: Icons.photo_library_rounded,
                        label: 'Gallery',
                        subtitle: 'Choose existing photo',
                        onTap: () async {
                          Navigator.pop(context);
                          await _pickImageFromGallery(onPicked);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _pickImageFromCamera(void Function(File) onPicked) async {
    if (!await _requestCameraPermission()) return;
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 82,
        maxWidth: 1600,
      );
      if (picked != null && mounted) onPicked(File(picked.path));
    } catch (_) {
      if (mounted) _showSnack('Could not capture photo', isError: true);
    }
  }

  Future<void> _pickImageFromGallery(void Function(File) onPicked) async {
    if (!await _requestGalleryPermission()) return;
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 82,
        maxWidth: 1600,
      );
      if (picked != null && mounted) onPicked(File(picked.path));
    } catch (_) {
      if (mounted) _showSnack('Could not pick image', isError: true);
    }
  }

  Future<void> _pickFile(void Function(File) onPicked) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
      );
      if (result?.files.single.path != null && mounted) {
        onPicked(File(result!.files.single.path!));
      }
    } catch (_) {
      if (mounted) _showSnack('Could not pick file', isError: true);
    }
  }

  void _showSnack(String message, {required bool isError}) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                isError ? Icons.error_outline : Icons.check_circle_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(message, style: const TextStyle(fontSize: 14)),
              ),
            ],
          ),
          backgroundColor:
              isError ? const Color(0xFFDC2626) : const Color(0xFF15803D),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          duration: const Duration(seconds: 4),
        ),
      );
  }

  void _showPermissionDialog({required String title, required String message}) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
            ),
            content: Text(message, style: const TextStyle(fontSize: 14)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  openAppSettings();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppStyle.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Open Settings',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }

  void _showResultDialog({
    required String title,
    required String message,
    bool isSuccess = false,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSuccess ? Colors.green.shade800 : Colors.red.shade800,
              ),
            ),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  if (isSuccess) {
                    ref.refresh(kycStatusProvider);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TeacherDashboardScreen(),
                      ),
                    );
                  }
                },
                child: Text(
                  'OK',
                  style: TextStyle(
                    color: isSuccess ? Colors.green.shade700 : Colors.black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _uploadKyc() async {
    if (!_formData.isComplete) {
      _showResultDialog(
        title: "Incomplete",
        message: "Please complete all fields and upload required documents.",
        isSuccess: false,
      );
      return;
    }

    HapticFeedback.lightImpact();
    setState(() => _isUploading = true);

    try {
      await ref.read(
        kycUploadProvider({
          'idDoc': _formData.idDoc!,
          'bankAccountNumber': _bankAccountCtrl.text.trim(),
          'bankName': _bankNameCtrl.text.trim(),
          'citizenship': _citizenshipCtrl.text.trim(),
          'photo': _formData.photo!,
          'cv': _formData.cv!,
          'nIdNumber': _nIdCtrl.text.trim(),
        }).future,
      );

      setState(() {
        _uploadSuccess = true;
        _isUploading = false;
      });

      await _successController.forward();
      HapticFeedback.heavyImpact();

      _showResultDialog(
        title: "Success",
        message:
            "KYC submitted successfully!\nYou will now be redirected to the dashboard.",
        isSuccess: true,
      );
    } catch (e) {
      setState(() => _isUploading = false);

      _showResultDialog(
        title: "Error",
        message: "Failed to submit KYC.\nPlease try again.\n\n$e",
        isSuccess: false,
      );
    }
  }

  Widget _sheetHandle() => Container(
    width: 42,
    height: 5,
    decoration: BoxDecoration(
      color: Colors.grey[300],
      borderRadius: BorderRadius.circular(4),
    ),
  );

  @override
  Widget build(BuildContext context) {
    _formData.bankAccountNumber = _bankAccountCtrl.text.trim();
    _formData.bankName = _bankNameCtrl.text.trim();
    _formData.citizenship = _citizenshipCtrl.text.trim();
    _formData.nIdNumber = _nIdCtrl.text.trim();

    final canSubmit = _formData.isComplete && !_isUploading && !_uploadSuccess;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
            style: IconButton.styleFrom(
              backgroundColor: Colors.grey[100],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: const Text(
          'KYC Verification',
          style: TextStyle(
            fontSize: 19,
            fontFamily: 'Inter',
            color: Colors.black,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 28),
              _buildAcceptedDocs(),
              const SizedBox(height: 36),

              _fieldSectionTitle('ID Document *'),
              const SizedBox(height: 12),
              _buildFileUploadZone(
                title: 'National ID / Passport / Driving License / Citizenship',
                file: _formData.idDoc,
                onTap:
                    () => _showImagePickerSheet(
                      (f) => setState(() => _formData.idDoc = f),
                    ),
                onRemove: () => setState(() => _formData.idDoc = null),
                isImage: true,
              ),

              const SizedBox(height: 32),
              _fieldSectionTitle('Personal Photo *'),
              const SizedBox(height: 12),
              _buildFileUploadZone(
                title: 'Clear passport-size or face photo',
                file: _formData.photo,
                onTap:
                    () => _showImagePickerSheet(
                      (f) => setState(() => _formData.photo = f),
                    ),
                onRemove: () => setState(() => _formData.photo = null),
                isImage: true,
              ),

              const SizedBox(height: 32),
              _fieldSectionTitle('CV / Resume *'),
              const SizedBox(height: 12),
              _buildFileUploadZone(
                title: 'PDF, DOC, DOCX, JPG or PNG',
                file: _formData.cv,
                onTap: () => _pickFile((f) => setState(() => _formData.cv = f)),
                onRemove: () => setState(() => _formData.cv = null),
                isImage: false,
              ),

              const SizedBox(height: 36),
              _fieldSectionTitle('Bank Details'),
              const SizedBox(height: 16),
              _modernTextField(
                controller: _bankNameCtrl,
                label: 'Bank Name',
                hint: 'e.g. Global IME Bank, Nabil Bank...',
                icon: Icons.account_balance_rounded,
              ),
              const SizedBox(height: 16),
              _modernTextField(
                controller: _bankAccountCtrl,
                label: 'Account Number',
                hint: 'Enter full account number',
                icon: Icons.credit_card_rounded,
                keyboardType: TextInputType.number,
                inputFormatters: [_digitsOnly],
              ),

              const SizedBox(height: 36),
              _fieldSectionTitle('Identity Numbers'),
              const SizedBox(height: 16),
              _modernTextField(
                controller: _citizenshipCtrl,
                label: 'Citizenship Number',
                hint: 'e.g. 123456789',
                icon: Icons.badge_rounded,
                inputFormatters: [_digitsOnly],
              ),
              const SizedBox(height: 16),
              _modernTextField(
                controller: _nIdCtrl,
                label: 'National ID Number',
                hint: 'Enter your NID number',
                icon: Icons.fingerprint_rounded,
                keyboardType: TextInputType.number,
                inputFormatters: [_digitsOnly],
              ),

              const SizedBox(height: 44),
              _buildTips(),
              const SizedBox(height: 44),
              _buildSubmitButton(canSubmit),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fieldSectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        color: Colors.black87,
      ),
    );
  }

  Widget _modernTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        prefixIcon: Icon(icon, size: 22, color: AppStyle.primaryColor),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFD1D5DB), width: 1.4),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFD1D5DB), width: 1.4),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppStyle.primaryColor, width: 2.2),
        ),
        labelStyle: const TextStyle(
          fontSize: 14.5,
          color: Colors.black54,
          fontWeight: FontWeight.w500,
        ),
        floatingLabelStyle: TextStyle(
          color: AppStyle.primaryColor,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
        hintStyle: const TextStyle(
          color: Color(0xFF9CA3AF),
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  Widget _buildFileUploadZone({
    required String title,
    required File? file,
    required VoidCallback onTap,
    required VoidCallback onRemove,
    required bool isImage,
  }) {
    final hasFile = file != null;

    return GestureDetector(
      onTap: hasFile || _isUploading || _uploadSuccess ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        height: isImage ? (hasFile ? 210 : 150) : 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: hasFile ? AppStyle.primaryColor : const Color(0xFFE5E7EB),
            width: 1.6,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 14,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child:
            hasFile
                ? isImage
                    ? _buildImagePreview(file!, onRemove)
                    : _buildFilePreview(file!, onRemove)
                : _buildEmptyUploadState(title, isImage),
      ),
    );
  }

  Widget _buildEmptyUploadState(String title, bool isImage) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Color.alphaBlend(Colors.white, AppStyle.primaryColor),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isImage ? Icons.add_a_photo_rounded : Icons.upload_file_rounded,
              color: AppStyle.primaryColor,
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            isImage ? 'Tap to upload photo' : 'Supported: PDF, DOC, JPG, PNG',
            style: const TextStyle(fontSize: 13.5, color: Color(0xFF6B7280)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview(File file, VoidCallback onRemove) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(file, fit: BoxFit.cover),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xCC000000), Color(0x00000000)],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.edit_rounded, color: Colors.white, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Tap to change',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: onRemove,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC2626),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Remove',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilePreview(File file, VoidCallback onRemove) {
    final name = file.path.split('/').last;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Color.alphaBlend(Colors.white, AppStyle.primaryColor),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.insert_drive_file_rounded,
              color: AppStyle.primaryColor,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFFEE2E2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                color: Color(0xFFDC2626),
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppStyle.primaryColor,
            Color.lerp(AppStyle.primaryColor, Colors.black, 0.18)!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x4D000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(56),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.verified_user_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Identity Verification',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Please provide accurate details and clear documents',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcceptedDocs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Accepted ID Documents',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: const [
            _DocChip(icon: Icons.credit_card_rounded, label: 'National ID'),
            _DocChip(icon: Icons.book, label: 'Passport'),
            _DocChip(
              icon: Icons.directions_car_rounded,
              label: 'Driving License',
            ),
            _DocChip(icon: Icons.badge_rounded, label: 'Citizenship'),
          ],
        ),
      ],
    );
  }

  Widget _buildTips() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_rounded, color: Colors.blue[700], size: 22),
              const SizedBox(width: 10),
              const Text(
                'Tips for Successful Submission',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E40AF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...[
            'Make sure all four corners of the document are visible',
            'Use good lighting — avoid shadows and glare',
            'Text should be sharp and clearly readable',
            'Double-check your bank account number',
          ].map(
            (tip) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle, color: Colors.blue[600], size: 18),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      tip,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF1E40AF),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(bool canSubmit) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton(
        onPressed: canSubmit && !_isUploading ? _uploadKyc : null,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              _uploadSuccess ? const Color(0xFF15803D) : AppStyle.primaryColor,
          disabledBackgroundColor: Colors.grey[400],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: canSubmit ? 6 : 0,
        ),
        child:
            _isUploading
                ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    ),
                    SizedBox(width: 14),
                    Text(
                      'Uploading...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                )
                : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _uploadSuccess
                          ? Icons.check_circle_rounded
                          : Icons.upload_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _uploadSuccess ? 'Submitted' : 'Submit KYC',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
      ),
    );
  }
}

class _PickerOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _PickerOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 14),
        decoration: BoxDecoration(
          color: Color.alphaBlend(Colors.white, AppStyle.primaryColor),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppStyle.primaryColor),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Color.alphaBlend(Colors.white, AppStyle.primaryColor),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppStyle.primaryColor, size: 32),
            ),
            const SizedBox(height: 14),
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppStyle.primaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 13, color: AppStyle.primaryColor),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _DocChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppStyle.primaryColor),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
