import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:innovator/research/provider/research_provider.dart';

const _kBlue = Color(0xFF185FA5);
const _kBlueMid = Color(0xFF378ADD);
const _kBlueSoft = Color(0xFFE6F1FB);
const _kBlueBorder = Color(0xFFB5D4F4);

const _kRed = Color(0xFFA32D2D);
const _kRedSoft = Color(0xFFFCEBEB);
const _kRedBorder = Color(0xFFF7C1C1);

const _kGreen = Color(0xFF3B6D11);

const _kText = Color(0xFF1C1C1E);
const _kTextSub = Color(0xFF555555);
const _kTextMuted = Color(0xFF8A8A8E);
const _kTextHint = Color(0xFFBBBBBB);
const _kSurface = Color(0xFFF7F8FA);
const _kBorder = Color(0xFFE2E4E8);
const _kCard = Color(0xFFFFFFFF);

const double _kMaxFileSizeBytes = 10 * 1024 * 1024;

class UploadResearchPaperSheet extends ConsumerStatefulWidget {
  const UploadResearchPaperSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const UploadResearchPaperSheet(),
    );
  }

  @override
  ConsumerState<UploadResearchPaperSheet> createState() =>
      _UploadResearchPaperSheetState();
}

class _UploadResearchPaperSheetState
    extends ConsumerState<UploadResearchPaperSheet> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _researcherNamesCtrl = TextEditingController();

  String _type = 'free';
  PlatformFile? _paperFile;
  PlatformFile? _researcherFile;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _researcherNamesCtrl.dispose();
    super.dispose(); // No ref.read here - this fixes the crash
  }

  Future<void> _pickPaperFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      if (file.size > _kMaxFileSizeBytes) {
        _snack('File too large. Please select a PDF under 10 MB.');
        return;
      }
      setState(() => _paperFile = file);
    }
  }

  Future<void> _pickResearcherFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      if (file.size > _kMaxFileSizeBytes) {
        _snack('File too large. Please select a file under 10 MB.');
        return;
      }
      setState(() => _researcherFile = file);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_paperFile == null) {
      _snack('Please attach a paper file (PDF).');
      return;
    }
    if (_paperFile!.size > _kMaxFileSizeBytes) {
      _snack('File is too large. Please upload a PDF under 10 MB.');
      return;
    }

    final names =
        _researcherNamesCtrl.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => ProviderScope(
            parent: ProviderScope.containerOf(context),
            child: _UploadProgressDialog(fileName: _paperFile!.name),
          ),
    );

    final ok = await ref
        .read(uploadResearchPaperProvider.notifier)
        .upload(
          email: _emailCtrl.text.trim(),
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          type: _type,
          price:
              _type == 'paid' ? double.tryParse(_priceCtrl.text.trim()) : null,
          researcherNames: names.isEmpty ? null : names,
          paperFile: _paperFile!,
          researcherFile: _researcherFile,
        );

    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop(); // close progress dialog

      if (ok) {
        ref.read(uploadResearchPaperProvider.notifier).reset(); // safe reset
        Navigator.of(context).pop(); // close bottom sheet
        _snack('Research paper uploaded successfully!', isError: false);
      }
    }
  }

  void _snack(String msg, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: isError ? _kRed : _kGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uploadState = ref.watch(uploadResearchPaperProvider);

    return Container(
      decoration: const BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 14),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: _kBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 4),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 12, 10),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: _kBlueSoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.upload_file_rounded,
                    color: _kBlue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Upload Research Paper',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _kText,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    ref.read(uploadResearchPaperProvider.notifier).reset();
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _kSurface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _kBorder),
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: _kTextMuted,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),

          const Divider(height: 1, color: _kBorder),

          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FieldLabel('Email', required: true),
                    _AppField(
                      controller: _emailCtrl,
                      hint: 'researcher@example.com',
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: Icon(Icons.mail_outline_rounded),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty)
                          return 'Email is required';
                        if (!v.contains('@')) return 'Enter a valid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    _FieldLabel('Title', required: true),
                    _AppField(
                      controller: _titleCtrl,
                      hint: 'Research paper title',
                      prefixIcon: Icon(Icons.title_rounded),
                      validator:
                          (v) =>
                              (v == null || v.trim().isEmpty)
                                  ? 'Title is required'
                                  : null,
                    ),
                    const SizedBox(height: 16),

                    _FieldLabel('Description'),
                    _AppField(
                      controller: _descCtrl,
                      hint: 'Brief description of the paper...',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),

                    _FieldLabel('Type', required: true),
                    _TypeSelector(
                      selected: _type,
                      onChanged:
                          (v) => setState(() {
                            _type = v;
                            if (v == 'free') _priceCtrl.clear();
                          }),
                    ),
                    const SizedBox(height: 16),

                    if (_type == 'paid') ...[
                      _FieldLabel('Price (NPR)', required: true),
                      _AppField(
                        controller: _priceCtrl,
                        hint: 'e.g. 8000',
                        keyboardType: TextInputType.number,
                        prefixIcon: Image.asset(
                          'assets/icon/npr.png',
                          width: 20,
                          color: _kTextMuted,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator:
                            (v) =>
                                (v == null || v.trim().isEmpty)
                                    ? 'Price is required for paid papers'
                                    : null,
                      ),
                      const SizedBox(height: 16),
                    ],

                    _FieldLabel('Researcher Names'),
                    _AppField(
                      controller: _researcherNamesCtrl,
                      hint: 'e.g. Ram, Shyam, Hari',
                      prefixIcon: Icon(Icons.people_outline_rounded),
                    ),
                    const SizedBox(height: 6),
                    const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 13,
                          color: _kTextHint,
                        ),
                        SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            'For multiple researchers, separate names with a comma.',
                            style: TextStyle(fontSize: 12, color: _kTextMuted),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    _FieldLabel('Paper File', required: true),
                    const SizedBox(height: 2),
                    const Text(
                      'PDF only · max 10 MB',
                      style: TextStyle(fontSize: 12, color: _kTextHint),
                    ),
                    const SizedBox(height: 6),
                    _FilePickerTile(
                      file: _paperFile,
                      emptyHint: 'Tap to select PDF',
                      icon: Icons.picture_as_pdf_rounded,
                      accent: const Color(0xFF993C1D),
                      accentSoft: const Color(0xFFFAECE7),
                      onTap: _pickPaperFile,
                    ),
                    const SizedBox(height: 16),

                    _FieldLabel('Researcher File'),
                    const SizedBox(height: 2),
                    const Text(
                      'Optional · any format · max 10 MB',
                      style: TextStyle(fontSize: 12, color: _kTextHint),
                    ),
                    const SizedBox(height: 6),
                    _FilePickerTile(
                      file: _researcherFile,
                      emptyHint: 'Tap to select file',
                      icon: Icons.attach_file_rounded,
                      accent: _kBlue,
                      accentSoft: _kBlueSoft,
                      onTap: _pickResearcherFile,
                    ),

                    const SizedBox(height: 28),

                    if (uploadState.error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _kRedSoft,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _kRedBorder),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: _kRed,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _friendlyError(uploadState.error!),
                                style: const TextStyle(
                                  color: _kRed,
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: uploadState.isUploading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kBlue,
                          disabledBackgroundColor: _kBlueBorder,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.cloud_upload_rounded,
                              size: 20,
                              color: Colors.white,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Upload Paper',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _friendlyError(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('413') || lower.contains('payload too large')) {
      return 'File is too large for the server. Please compress your PDF or upload a file under 5 MB.';
    }
    if (lower.contains('network') ||
        lower.contains('socket') ||
        lower.contains('connection')) {
      return 'Network error. Please check your connection and try again.';
    }
    if (lower.contains('timeout'))
      return 'The request timed out. Please try again.';
    if (lower.contains('unauthorized') ||
        lower.contains('403') ||
        lower.contains('401')) {
      return 'You are not authorized to perform this action.';
    }
    if (raw.length > 120) return 'Something went wrong. Please try again.';
    return raw;
  }
}

// ====================== Supporting Widgets ======================

class _UploadProgressDialog extends ConsumerWidget {
  final String fileName;
  const _UploadProgressDialog({required this.fileName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(uploadResearchPaperProvider);
    final pct = (state.progress * 100).round();

    return PopScope(
      canPop: false,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: _kCard,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _AnimatedProgressRing(progress: state.progress, color: _kBlue),
              const SizedBox(height: 22),
              Text(
                state.progress == 0 ? 'Preparing upload…' : 'Uploading — $pct%',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _kText,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Please wait, do not close this window',
                style: TextStyle(fontSize: 12, color: _kTextMuted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: state.progress == 0 ? null : state.progress,
                  minHeight: 6,
                  backgroundColor: _kBlueSoft,
                  valueColor: const AlwaysStoppedAnimation<Color>(_kBlue),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                fileName,
                style: const TextStyle(fontSize: 11, color: _kTextHint),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedProgressRing extends StatefulWidget {
  final double progress;
  final Color color;
  const _AnimatedProgressRing({required this.progress, required this.color});

  @override
  State<_AnimatedProgressRing> createState() => _AnimatedProgressRingState();
}

class _AnimatedProgressRingState extends State<_AnimatedProgressRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(
      begin: 0.93,
      end: 1.07,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pct = (widget.progress * 100).round();
    return AnimatedBuilder(
      animation: _pulseAnim,
      builder:
          (_, child) => Transform.scale(
            scale: widget.progress == 0 ? _pulseAnim.value : 1.0,
            child: child,
          ),
      child: SizedBox(
        width: 110,
        height: 110,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: widget.progress),
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOut,
                builder:
                    (_, value, __) => CircularProgressIndicator(
                      value: widget.progress == 0 ? null : value,
                      strokeWidth: 9,
                      backgroundColor: _kBlueSoft,
                      valueColor: AlwaysStoppedAnimation<Color>(widget.color),
                      strokeCap: StrokeCap.round,
                    ),
              ),
            ),
            SizedBox(
              width: 80,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      widget.progress == 0 ? '···' : '$pct%',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: widget.color,
                        height: 1,
                      ),
                    ),
                  ),
                  if (widget.progress > 0) ...[
                    const SizedBox(height: 2),
                    const Text(
                      'uploaded',
                      style: TextStyle(fontSize: 10, color: _kTextMuted),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  final bool required;
  const _FieldLabel(this.text, {this.required = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _kText,
            ),
          ),
          if (required)
            const Text(
              ' *',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _kRed,
              ),
            ),
        ],
      ),
    );
  }
}

class _AppField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? prefixIcon;

  const _AppField({
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.maxLines = 1,
    this.validator,
    this.inputFormatters,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      inputFormatters: inputFormatters,
      style: const TextStyle(fontSize: 14, color: _kText),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 14, color: _kTextHint),
        prefixIcon:
            prefixIcon != null
                ? SizedBox(width: 48, child: Center(child: prefixIcon))
                : null,
        filled: true,
        fillColor: _kSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _kBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _kBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _kBlueMid, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _kRed),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _kRed, width: 1.5),
        ),
      ),
    );
  }
}

class _TypeSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  const _TypeSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _TypeTile(
          label: 'Free',
          subtitle: 'Open access',
          icon: Icons.lock_open_rounded,
          selected: selected == 'free',
          onTap: () => onChanged('free'),
        ),
        const SizedBox(width: 12),
        _TypeTile(
          label: 'Paid',
          subtitle: 'Restricted access',
          icon: Icons.paid_rounded,
          selected: selected == 'paid',
          onTap: () => onChanged('paid'),
        ),
      ],
    );
  }
}

class _TypeTile extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _TypeTile({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? _kBlueSoft : _kSurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? _kBlueMid : _kBorder,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Image.asset(
                'assets/icon/npr.png',
                width: 20,
                color: selected ? _kBlue : _kTextMuted,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: selected ? _kBlue : _kText,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                      style: TextStyle(
                        fontSize: 11,
                        color: selected ? _kBlueMid : _kTextMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? _kBlue : Colors.transparent,
                  border: Border.all(
                    color: selected ? _kBlue : _kBorder,
                    width: 2,
                  ),
                ),
                child:
                    selected
                        ? const Icon(Icons.check, size: 11, color: Colors.white)
                        : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilePickerTile extends StatelessWidget {
  final PlatformFile? file;
  final String emptyHint;
  final IconData icon;
  final Color accent;
  final Color accentSoft;
  final VoidCallback onTap;

  const _FilePickerTile({
    required this.file,
    required this.emptyHint,
    required this.icon,
    required this.accent,
    required this.accentSoft,
    required this.onTap,
  });

  String _fmt(int bytes) {
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final has = file != null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: has ? accentSoft : _kSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: has ? accent.withValues(alpha: 0.35) : _kBorder,
            width: has ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color:
                    has
                        ? accent.withValues(alpha: 0.12)
                        : const Color(0xFFEEEEEE),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 19, color: has ? accent : _kTextMuted),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    has ? file!.name : emptyHint,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: has ? FontWeight.w600 : FontWeight.w400,
                      color: has ? _kText : _kTextMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    has ? _fmt(file!.size) : 'No file selected',
                    style: TextStyle(
                      fontSize: 11,
                      color: has ? _kTextSub : _kTextHint,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              has
                  ? Icons.check_circle_rounded
                  : Icons.add_circle_outline_rounded,
              color: has ? accent : _kTextHint,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
