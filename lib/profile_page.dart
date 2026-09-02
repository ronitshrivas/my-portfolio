import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:innovator/innovator/providers/innovator_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models/api_response.dart';
import 'package:innovator/innovator/data/models/feed_models.dart';
import 'package:innovator/innovator/data/models/profile_models.dart';
import 'package:innovator/innovator/data/sources/auth_api.dart';
import 'package:innovator/innovator/data/sources/chat_api.dart';
import 'package:innovator/innovator/data/sources/feed_api.dart';
import 'package:innovator/innovator/data/sources/profile_api.dart';
import 'chat_page.dart';
import 'services/auth_session.dart';
import 'services/sound_player.dart';
import 'theme/brand_colors.dart';
import 'widgets/animated_blob_background.dart';
import 'widgets/cached_feed_image.dart';
import 'widgets/fast_glass.dart';
import 'widgets/liquid_pressable.dart';
import 'widgets/news_feed_section.dart' show FeedCard;
import 'widgets/wave_fill_painter.dart';

const _ink = BrandColors.ink;
const _muted = BrandColors.muted;
const _defaultCover = 'Assets/feed/post_07.jpg';

class _LearnerInfo {
  const _LearnerInfo({
    required this.displayName,
    required this.fullName,
    required this.bio,
    this.educations = const [],
    this.occupations = const [],
    this.links = const [],
    required this.email,
    required this.phone,
    required this.dateOfBirth,
    required this.gender,
    required this.city,
    required this.country,
    required this.permanentAddress,
    required this.temporaryAddress,
    required this.zipCode,
    required this.school,
    required this.faculty,
    required this.educationLevel,
    required this.degree,
    required this.major,
    required this.yearLevel,
    required this.studentId,
    required this.enrollmentYear,
    required this.skills,
    required this.hobby,
    required this.learningGoals,
    required this.language,
    required this.portfolio,
    required this.facebook,
    required this.linkedin,
    required this.instagram,
    required this.github,
  });
  final String displayName;
  final String fullName;
  final String bio;
  final List<String> educations;
  final List<String> occupations;
  final List<ProfileLink> links;
  final String email;
  final String phone;
  final String dateOfBirth;
  final String gender;
  final String city;
  final String country;
  final String permanentAddress;
  final String temporaryAddress;
  final String zipCode;
  final String school;
  final String faculty;
  final String educationLevel;
  final String degree;
  final String major;
  final String yearLevel;
  final String studentId;
  final String enrollmentYear;
  final String skills;
  final String hobby;
  final String learningGoals;
  final String language;
  final String portfolio;
  final String facebook;
  final String linkedin;
  final String instagram;
  final String github;

  _LearnerInfo copyWith({
    String? displayName,
    String? fullName,
    String? bio,
    List<String>? educations,
    List<String>? occupations,
    List<ProfileLink>? links,
    String? email,
    String? phone,
    String? dateOfBirth,
    String? gender,
    String? city,
    String? country,
    String? permanentAddress,
    String? temporaryAddress,
    String? zipCode,
    String? school,
    String? faculty,
    String? educationLevel,
    String? degree,
    String? major,
    String? yearLevel,
    String? studentId,
    String? enrollmentYear,
    String? skills,
    String? hobby,
    String? learningGoals,
    String? language,
    String? portfolio,
    String? facebook,
    String? linkedin,
    String? instagram,
    String? github,
  }) {
    return _LearnerInfo(
      displayName: displayName ?? this.displayName,
      fullName: fullName ?? this.fullName,
      bio: bio ?? this.bio,
      educations: educations ?? this.educations,
      occupations: occupations ?? this.occupations,
      links: links ?? this.links,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      city: city ?? this.city,
      country: country ?? this.country,
      permanentAddress: permanentAddress ?? this.permanentAddress,
      temporaryAddress: temporaryAddress ?? this.temporaryAddress,
      zipCode: zipCode ?? this.zipCode,
      school: school ?? this.school,
      faculty: faculty ?? this.faculty,
      educationLevel: educationLevel ?? this.educationLevel,
      degree: degree ?? this.degree,
      major: major ?? this.major,
      yearLevel: yearLevel ?? this.yearLevel,
      studentId: studentId ?? this.studentId,
      enrollmentYear: enrollmentYear ?? this.enrollmentYear,
      skills: skills ?? this.skills,
      hobby: hobby ?? this.hobby,
      learningGoals: learningGoals ?? this.learningGoals,
      language: language ?? this.language,
      portfolio: portfolio ?? this.portfolio,
      facebook: facebook ?? this.facebook,
      linkedin: linkedin ?? this.linkedin,
      instagram: instagram ?? this.instagram,
      github: github ?? this.github,
    );
  }
}

_LearnerInfo _emptyLearnerInfo(String name) => _LearnerInfo(
  displayName: name,
  fullName: name,
  bio: '',
  email: '',
  phone: '',
  dateOfBirth: '',
  gender: '',
  city: '',
  country: '',
  permanentAddress: '',
  temporaryAddress: '',
  zipCode: '',
  school: '',
  faculty: '',
  educationLevel: '',
  degree: '',
  major: '',
  yearLevel: '',
  studentId: '',
  enrollmentYear: '',
  skills: '',
  hobby: '',
  learningGoals: '',
  language: '',
  portfolio: '',
  facebook: '',
  linkedin: '',
  instagram: '',
  github: '',
);

_LearnerInfo _learnerFromProfile(UserProfile profile, {_LearnerInfo? keep}) {
  final base = keep ?? _emptyLearnerInfo(profile.displayName);
  return base.copyWith(
    displayName: profile.displayName,
    fullName: (profile.fullName?.trim().isNotEmpty ?? false)
        ? profile.fullName!.trim()
        : profile.displayName,
    bio: profile.bio ?? '',
    email: profile.email ?? '',
    phone: profile.phone ?? '',
    dateOfBirth: profile.dateOfBirth ?? '',
    gender: profile.gender ?? '',
    permanentAddress: profile.address ?? base.permanentAddress,
    educationLevel: profile.education ?? base.educationLevel,
    major: profile.occupation ?? base.major,
    skills: profile.interests.isEmpty
        ? base.skills
        : profile.interests.join(', '),
    // New multi-value backend fields (merged singular + plural).
    educations: profile.allEducations,
    occupations: profile.allOccupations,
    links: profile.links,
  );
}

UpdateProfileRequest _toUpdateRequest(_LearnerInfo info) {
  final interests = <String>[
    ...info.skills.split(RegExp(r'[,/|]')),
    ...info.hobby.split(RegExp(r'[,/|]')),
  ].map((e) => e.trim()).where((e) => e.isNotEmpty).toSet().toList();

  final address = [
    info.permanentAddress,
    info.temporaryAddress,
    [info.city, info.country].where((e) => e.trim().isNotEmpty).join(', '),
    if (info.zipCode.trim().isNotEmpty) 'ZIP ${info.zipCode.trim()}',
  ].where((e) => e.trim().isNotEmpty).join(' · ');

  // Multi-value lists come straight from the edit form's dynamic rows. These
  // are the source of truth for education / occupation.
  final educations = info.educations
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toSet() // de-dupe repeated entries
      .toList();
  final occupations = info.occupations
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toSet()
      .toList();

  // Collapse the lists into the single legacy string (deduped, joined once).
  // Fall back to the scalar form fields only when no list rows were entered.
  final education = educations.isNotEmpty
      ? educations.join(' · ')
      : [
          info.educationLevel,
          info.school,
          info.faculty,
          info.degree,
          info.yearLevel,
        ]
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toSet()
            .join(' · ');

  final occupation = occupations.isNotEmpty
      ? occupations.first
      : (info.major.trim().isNotEmpty
          ? info.major.trim()
          : (info.learningGoals.trim().isNotEmpty
              ? info.learningGoals.trim()
              : info.degree.trim()));
  final links = [
    ...info.links.where((l) => (l.url ?? '').trim().isNotEmpty),
    ..._linksFromInfo(info),
  ];

  return UpdateProfileRequest(
    fullName: info.fullName.trim().isEmpty ? info.displayName : info.fullName,
    bio: info.bio,
    dateOfBirth: info.dateOfBirth,
    phone: info.phone,
    gender: info.gender,
    // Send an empty string (not null) for cleared fields so the backend
    // actually clears them — null means "leave unchanged" on the server.
    address: address,
    education: education,
    occupation: occupation,
    interests: interests,
    // Always send the lists (even when empty) so clearing all rows persists.
    educations: educations.isNotEmpty
        ? educations
        : (education.isEmpty ? <String>[] : [education]),
    occupations: occupations.isNotEmpty
        ? occupations
        : (occupation.isEmpty ? <String>[] : [occupation]),
    links: links,
  );
}

/// Maps the learner's legacy social fields into profile links (used as a
/// fallback when the dynamic links list is empty).
List<ProfileLink> _linksFromInfo(_LearnerInfo info) {
  final entries = <String, String>{
    'LinkedIn': info.linkedin,
    'GitHub': info.github,
    'Portfolio': info.portfolio,
    'Facebook': info.facebook,
    'Instagram': info.instagram,
  };
  final out = <ProfileLink>[];
  entries.forEach((label, url) {
    final u = url.trim();
    if (u.isNotEmpty) out.add(ProfileLink(label: label, url: u));
  });
  return out;
}

class _Person {
  const _Person({
    required this.name,
    required this.colors,
    this.username,
    this.occupation,
    this.authUserId,
    this.avatarUrl,
    this.isFollowed = false,
  });

  final String name;
  final String? username;
  final String? occupation;
  final List<Color> colors;
  final String? authUserId;
  final String? avatarUrl;
  final bool isFollowed;

  factory _Person.fromListUser(ProfileListUser user) {
    final seed = user.id.isNotEmpty ? user.id : user.displayName;
    final palettes = const [
      [Color(0xFF4C1D95), Color(0xFF7C3AED)],
      [Color(0xFF1E3A8A), Color(0xFF2563EB)],
      [Color(0xFF0F766E), Color(0xFF14B8A6)],
      [Color(0xFF9F1239), Color(0xFFE11D48)],
      [Color(0xFF0369A1), Color(0xFF38BDF8)],
    ];
    final colors = palettes[seed.hashCode.abs() % palettes.length];
    return _Person(
      name: user.displayName,
      username: user.username?.trim(),
      occupation: user.occupation?.trim(),
      colors: colors,
      authUserId: user.id,
      avatarUrl: user.avatar,
      isFollowed: user.isFollowed,
    );
  }
}

class _TitleBadge {
  const _TitleBadge({
    required this.label,
    required this.icon,
    required this.colors,
  });
  final String label;
  final IconData icon;
  final List<Color> colors;
}

const _titles = [
  _TitleBadge(
    label: 'Innovator',
    icon: Icons.auto_awesome_rounded,
    colors: [Color(0xFFE0A800), BrandColors.accent],
  ),
  _TitleBadge(
    label: 'Creator',
    icon: Icons.palette_rounded,
    colors: [BrandColors.secondarySurface, Color(0xFF14304A)],
  ),
  _TitleBadge(
    label: 'Developer',
    icon: Icons.code_rounded,
    colors: [BrandColors.secondarySurface, Color(0xFF0F2A44)],
  ),
  _TitleBadge(
    label: 'Programmer',
    icon: Icons.terminal_rounded,
    colors: [Color(0xFF0A1C30), BrandColors.secondarySurface],
  ),
];

/// Full-screen view of another member's profile (opened from feed, etc.).
class AuthorProfilePage extends StatelessWidget {
  const AuthorProfilePage({
    super.key,
    required this.name,
    this.authUserId,
    this.username,
  });

  final String name;
  final String? authUserId;
  final String? username;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const AnimatedBlobBackground(),
          ProfileSection(
            name: name,
            authUserId: authUserId,
            username: username,
            contentPadding: EdgeInsets.fromLTRB(0, top, 0, 24),
            onBack: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

/// Profile with cover banner, overlapping avatar, identity row, stats, and
/// innovations feed.
class ProfileSection extends ConsumerStatefulWidget {
  const ProfileSection({
    super.key,
    required this.name,
    this.authUserId,
    this.username,
    this.contentPadding = EdgeInsets.zero,
    this.onBack,
  });

  final String name;
  final String? authUserId;
  final String? username;
  final EdgeInsets contentPadding;

  /// When set, this is treated as another person's profile: back replaces
  /// the options menu, and cover/avatar cameras are hidden.
  final VoidCallback? onBack;

  @override
  ConsumerState<ProfileSection> createState() => _ProfileSectionState();
}

class _ProfileSectionState extends ConsumerState<ProfileSection>
    with TickerProviderStateMixin {
  final _profileApi = ProfileApi();
  final _feedApi = FeedApi();

  int _titleIndex = 0;
  Uint8List? _avatarBytes;
  Uint8List? _coverBytes;
  String? _avatarUrl;
  String? _coverUrl;
  bool _coverUploading = false;
  String? _cvFileName;
  late _LearnerInfo _info = _emptyLearnerInfo(widget.name);

  UserProfile? _profile;
  bool _loading = true;
  bool _followBusy = false;

  /// Follow state for private accounts: none | pending | accepted.
  String _followStatus = 'none';
  String? _error;
  int _collaborators = 0;
  int _collaborating = 0;
  int _innovationCount = 0;
  static const _avatarSize = 92.0;
  static const _coverHeight = 230.0;

  bool get _isOwnProfile => widget.onBack == null;

  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  late final AnimationController _wave = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _entrance.dispose();
    _wave.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final UserProfile profile;
      if (_isOwnProfile) {
        profile = await _profileApi.getMe();
      } else if (widget.authUserId != null && widget.authUserId!.isNotEmpty) {
        profile = await _profileApi.getByAuthUserId(widget.authUserId!);
      } else if (widget.username != null && widget.username!.isNotEmpty) {
        profile = await _profileApi.getByUsername(widget.username!);
      } else {
        profile = await _profileApi.getByUsername(widget.name);
      }
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _followStatus = profile.isFollowed ? 'accepted' : 'none';
        _info = _learnerFromProfile(profile, keep: _info);
        _avatarUrl =
            (profile.avatar != null && profile.avatar!.trim().isNotEmpty)
            ? profile.avatar!.trim()
            : null;
        _coverUrl =
            (profile.coverImage != null && profile.coverImage!.trim().isNotEmpty)
            ? profile.coverImage!.trim()
            : null;
        _collaborators = profile.followersCount;
        _collaborating = profile.followingCount;
        _loading = false;
      });
      // Seed the shared current-user state so the cover Consumer, drawer and
      // composer all reflect the loaded profile (own profile only).
      if (_isOwnProfile) {
        ProviderScope.containerOf(context, listen: false)
            .read(currentUserProvider.notifier)
            .set(profile);
      }
      // Real innovation (post) count from the dedicated endpoint.
      unawaited(_loadInnovationCount(profile.authUserId));
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load profile';
      });
    }
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(behavior: SnackBarBehavior.floating, content: Text(message)),
    );
  }

  Future<void> _openPeopleSheet(
    BuildContext context, {
    required String title,
    required String subtitle,
    required Future<List<ProfileListUser>> Function() loader,
  }) async {
    HapticFeedback.mediumImpact();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: _ink.withValues(alpha: .28),
      builder: (_) =>
          _PeopleSheet(title: title, subtitle: subtitle, loader: loader),
    );
  }

  Widget _stagger({required int index, required Widget child}) {
    final start = (index * .1).clamp(0.0, .6);
    final animation = CurvedAnimation(
      parent: _entrance,
      curve: Interval(
        start,
        (start + .45).clamp(0.0, 1.0),
        curve: Curves.easeOutCubic,
      ),
    );
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, .06),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }

  Future<Uint8List?> _pickImage() async {
    try {
      // image_picker returns a real readable file (reliable bytes) for gallery
      // / WhatsApp images, unlike file_picker which often yields null bytes on
      // Android — that empty upload is why the cover never appeared.
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );
      if (picked == null) return null;
      final bytes = await picked.readAsBytes();
      if (bytes.isEmpty) {
        if (mounted) _toast('That image could not be read. Try another.');
        return null;
      }
      return bytes;
    } catch (_) {
      if (!mounted) return null;
      _toast('Could not open the photo picker');
      return null;
    }
  }

  /// Picks an image for the avatar and returns its bytes. Uses image_picker
  /// (reliable readable bytes for gallery / WhatsApp images on Android, any
  /// format) — file_picker often returns null bytes and the upload then fails.
  Future<Uint8List?> _pickAnyFile() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );
      if (picked == null) return null;
      final bytes = await picked.readAsBytes();
      if (bytes.isEmpty) {
        if (mounted) _toast('That image could not be read. Try another.');
        return null;
      }
      return bytes;
    } catch (_) {
      if (!mounted) return null;
      _toast('Could not open the photo picker');
      return null;
    }
  }

  /// Pushes the new avatar into the shared current-user provider so the drawer
  /// and any other screen watching it update instantly. Own profile only.
  void _broadcastAvatar(String url) {
    if (!_isOwnProfile) return;
    ProviderScope.containerOf(context, listen: false)
        .read(currentUserProvider.notifier)
        .setAvatar(url);
  }

  void _broadcastCover(String url) {
    if (!_isOwnProfile) return;
    ProviderScope.containerOf(context, listen: false)
        .read(currentUserProvider.notifier)
        .setCover(url);
  }

  Future<void> _changePhoto() async {
    HapticFeedback.mediumImpact();
    final raw = await _pickAnyFile();
    if (raw == null || !mounted) return;
    // Send the picker's original JPEG bytes — the backend re-encodes any format
    // and persists it, so a client PNG re-encode (which can bloat and 500) is
    // unnecessary.
    final bytes = raw;
    if (!mounted) return;
    setState(() => _avatarBytes = bytes);
    try {
      final url = await _profileApi.uploadAvatar(bytes, filename: 'avatar.jpg');
      if (!mounted) return;
      setState(() {
        _avatarUrl = url;
        _avatarBytes = null;
      });
      // Broadcast so the drawer / header / anywhere watching updates instantly.
      _broadcastAvatar(url);
      _toast('Avatar updated');
      await _loadProfile();
    } on ApiException catch (e) {
      if (mounted) _toast(e.message);
    } catch (_) {
      if (mounted) _toast('Could not upload avatar');
    }
  }

  Future<void> _changeCover() async {
    if (_coverUploading) return;
    HapticFeedback.mediumImpact();
    final raw = await _pickImage();
    if (raw == null || !mounted) return;
    // Send original bytes; backend converts + persists (avoids PNG bloat/500).
    final bytes = raw;
    if (!mounted) return;
    // Optimistically show the picked cover while it uploads.
    setState(() {
      _coverBytes = bytes;
      _coverUploading = true;
    });
    try {
      final url = await _profileApi.uploadCover(bytes, filename: 'cover.jpg');
      if (!mounted) return;
      // Update the cover in place only — no full-screen reload. The local
      // _coverUrl repaints just the banner, and _broadcastCover pushes the new
      // URL into the shared provider so the drawer / composer update too.
      setState(() {
        _coverUrl = url;
        _coverBytes = null;
        _coverUploading = false;
      });
      _broadcastCover(url);
      _toast('Cover updated');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _coverBytes = null;
        _coverUploading = false;
      });
      _toast(e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _coverBytes = null;
        _coverUploading = false;
      });
      _toast('Could not upload cover');
    }
  }

  Future<void> _manageCv() async {
    HapticFeedback.mediumImpact();
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'doc', 'docx'],
        withData: false,
      );
      final file = result?.files.single;
      if (file == null || !mounted) return;
      setState(() => _cvFileName = file.name);
      _toast('CV selected · ${file.name} (upload endpoint not in profile API)');
    } catch (_) {
      if (mounted) _toast('Could not open the CV picker');
    }
  }

  void _cycleTitle() {
    HapticFeedback.selectionClick();
    setState(() => _titleIndex = (_titleIndex + 1) % _titles.length);
  }

  bool _messageBusy = false;

  /// Creates/opens a chat with the viewed user, then opens the chat screen.
  Future<void> _openChatWithUser() async {
    final target = _profile?.authUserId;
    if (target == null || target.isEmpty || _messageBusy) return;
    setState(() => _messageBusy = true);
    HapticFeedback.selectionClick();
    try {
      await ChatApi().createConversation(
        participantUserId: target,
        participantUsername: _profile?.username,
        participantAvatar: _profile?.avatar,
      );
      if (!mounted) return;
      setState(() => _messageBusy = false);
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(
            body: SafeArea(child: ChatSection()),
          ),
        ),
      );
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _messageBusy = false);
        _toast(e.message);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _messageBusy = false);
        _toast('Could not start chat');
      }
    }
  }

  Future<void> _loadInnovationCount(String authorId) async {
    if (authorId.isEmpty) return;
    try {
      final count = await _feedApi.postsCountByAuthor(authorId);
      if (!mounted) return;
      // Only trust the endpoint when it returns a real value; a 0 (broken or
      // empty endpoint) must not wipe the count derived from the loaded posts.
      if (count > 0) setState(() => _innovationCount = count);
    } catch (_) {
      // Keep the current value on failure.
    }
  }

  Future<void> _toggleFollow() async {
    final target = _profile?.authUserId;
    if (target == null || target.isEmpty || _followBusy) return;
    SoundPlayer.instance.follow();
    setState(() => _followBusy = true);
    try {
      final result = await _profileApi.toggleFollow(target);
      if (!mounted) return;
      setState(() {
        _followBusy = false;
        final current = _profile;
        if (current != null) {
          _profile = UserProfile(
            id: current.id,
            authUserId: current.authUserId,
            username: current.username,
            fullName: current.fullName,
            email: current.email,
            role: current.role,
            bio: current.bio,
            avatar: current.avatar,
            dateOfBirth: current.dateOfBirth,
            phone: current.phone,
            gender: current.gender,
            address: current.address,
            education: current.education,
            occupation: current.occupation,
            interests: current.interests,
            followersCount: result.isFollowing
                ? current.followersCount + 1
                : (current.followersCount > 0 ? current.followersCount - 1 : 0),
            followingCount: current.followingCount,
            isFollowed: result.isFollowing,
            createdAt: current.createdAt,
          );
          _collaborators = _profile!.followersCount;
        }
        _followStatus = result.status;
      });
      _toast(
        result.message ?? (result.isFollowing ? 'Following' : 'Unfollowed'),
      );
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _followBusy = false);
        _toast(e.message);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _followBusy = false);
        _toast('Could not update follow');
      }
    }
  }

  Future<void> _blockUser() async {
    final target = _profile?.authUserId;
    if (target == null || target.isEmpty) return;
    try {
      final result = await _profileApi.block(target);
      if (!mounted) return;
      _toast(result.message ?? 'Blocked');
    } on ApiException catch (e) {
      if (mounted) _toast(e.message);
    }
  }

  void _openProfileMenu() {
    HapticFeedback.selectionClick();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: _ink.withValues(alpha: .28),
      builder: (ctx) => _ProfileMenuSheet(
        cvFileName: _cvFileName,
        onEditInfo: () {
          Navigator.of(ctx).pop();
          _openEditProfile();
        },
        onChangeCover: () {
          Navigator.of(ctx).pop();
          _changeCover();
        },
        onChangePhoto: () {
          Navigator.of(ctx).pop();
          _changePhoto();
        },
        onManageCv: () {
          Navigator.of(ctx).pop();
          _manageCv();
        },
      ),
    );
  }

  Future<void> _openEditProfile() async {
    HapticFeedback.mediumImpact();
    final updated = await Navigator.of(context).push<_LearnerInfo>(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 380),
        reverseTransitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (_, animation, __) => FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          ),
          child: _EditProfilePage(info: _info),
        ),
      ),
    );
    if (updated == null || !mounted) return;
    setState(() => _info = updated);
    try {
      final request = _toUpdateRequest(updated);
      debugPrint('[Profile] PUT /api/profile body=${request.toJson()}');
      final saved = await _profileApi.updateProfile(request);
      debugPrint('[Profile] server returned fullName="${saved.fullName}" '
          'occupation="${saved.occupation}" bio="${saved.bio}"');
      if (!mounted) return;
      setState(() {
        _profile = saved;
        _info = _learnerFromProfile(saved, keep: updated);
        _collaborators = saved.followersCount;
        _collaborating = saved.followingCount;
      });
      debugPrint('[Profile] after setState — _info.fullName="${_info.fullName}" '
          '_info.major="${_info.major}" _info.bio="${_info.bio}" '
          '_info.educationLevel="${_info.educationLevel}"');
      // Push the saved profile into shared state so the drawer, feed author
      // cards, composer and every other widget watching currentUserProvider
      // update instantly — not just this page.
      if (_isOwnProfile) {
        ProviderScope.containerOf(context, listen: false)
            .read(currentUserProvider.notifier)
            .set(saved);
      }
      _toast('Profile saved');
    } on ApiException catch (e) {
      if (mounted) _toast(e.message);
    } catch (_) {
      if (mounted) _toast('Could not save profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    final padding = widget.contentPadding;
    final title = _titles[_titleIndex];
    final overlap = _avatarSize * .55;
    // For the signed-in user's own profile, drive the header from shared
    // current-user state so a profile edit reflects here instantly (and
    // everywhere else that watches it). Other users' profiles use their loaded
    // values only. Falls back to local _info until the provider hydrates.
    final live = _isOwnProfile ? ref.watch(currentUserProvider) : null;

    final liveName = live?.fullName;
    final displayName = (liveName != null && liveName.trim().isNotEmpty)
        ? liveName.trim()
        : (_info.displayName.isEmpty ? widget.name : _info.displayName);

    // Occupation / education / bio, reactive from shared state when available.
    final headlineOccupation = (live?.occupation?.trim().isNotEmpty ?? false)
        ? live!.occupation!.trim()
        : _info.major;
    final headlineEducation = (live?.education?.trim().isNotEmpty ?? false)
        ? live!.education!.trim()
        : _info.educationLevel;
    final headlineBio = (live?.bio?.trim().isNotEmpty ?? false)
        ? live!.bio!.trim()
        : _info.bio;

    final targetAuthId = _profile?.authUserId;

    if (_loading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2.4));
    }

    if (_error != null && _profile == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: _muted),
              ),
              const SizedBox(height: 12),
              TextButton(onPressed: _loadProfile, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    return ListView(
      physics: const SlipperyScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: EdgeInsets.only(bottom: padding.bottom + 6),
      children: [
        _stagger(
          index: 0,
          child: _CoverHeader(
            coverHeight: _coverHeight,
            avatarSize: _avatarSize,
            topInset: padding.top,
            overlap: overlap,
            coverBytes: _coverBytes,
            coverUrl: _coverUrl,
            coverUploading: _coverUploading,
            avatarBytes: _avatarBytes,
            avatarUrl: _avatarUrl,
            name: displayName,
            accent: title.colors,
            wave: _wave,
            onChangeCover: widget.onBack == null ? _changeCover : null,
            onChangeAvatar: widget.onBack == null ? _changePhoto : null,
            onMenu: widget.onBack == null ? _openProfileMenu : null,
            onBack: widget.onBack,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Column(
            children: [
              _stagger(
                index: 1,
                child: Column(
                  children: [
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: _ink,
                        letterSpacing: -.4,
                        height: 1.1,
                      ),
                    ),
                    if (_profile?.username != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '@${_profile!.username}',
                        style: TextStyle(
                          fontSize: 13,
                          color: _ink.withValues(alpha: .45),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    _TitleBadgeChip(
                      badge: title,
                      wave: _wave,
                      onTap: _cycleTitle,
                      verified: _isOwnProfile
                          ? (live?.isVerified ?? _profile?.isVerified ?? false)
                          : (_profile?.isVerified ?? false),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      [
                            if (headlineEducation.trim().isNotEmpty)
                              headlineEducation,
                            if (_info.school.trim().isNotEmpty) _info.school,
                            if (headlineOccupation.trim().isNotEmpty)
                              headlineOccupation,
                          ].join(' · ').trim().isEmpty
                          ? 'Innovator member'
                          : [
                              if (headlineEducation.trim().isNotEmpty)
                                headlineEducation,
                              if (_info.school.trim().isNotEmpty) _info.school,
                              if (headlineOccupation.trim().isNotEmpty)
                                headlineOccupation,
                            ].join(' · '),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: _ink.withValues(alpha: .48),
                      ),
                    ),
                    if (headlineBio.trim().isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        headlineBio,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13.5,
                          height: 1.45,
                          color: _ink.withValues(alpha: .72),
                        ),
                      ),
                    ],
                    if (!_isOwnProfile) ...[
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Message button — shown once you follow this person
                          // (mutual/one-way follow enables chatting).
                          if (_profile?.isFollowed ?? false) ...[
                            LiquidPressable(
                              onTap: _messageBusy ? () {} : _openChatWithUser,
                              borderRadius: BorderRadius.circular(999),
                              rippleColor: Colors.white,
                              intensity: .8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(999),
                                  color: BrandColors.secondarySurface,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _messageBusy
                                          ? Icons.hourglass_top_rounded
                                          : Icons.chat_bubble_outline_rounded,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 6),
                                    const Text(
                                      'Message',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          LiquidPressable(
                            onTap: _followBusy ? () {} : _toggleFollow,
                            borderRadius: BorderRadius.circular(999),
                            rippleColor: Colors.white,
                            intensity: .8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(999),
                                color: ((_profile?.isFollowed ?? false) ||
                                        _followStatus == 'pending')
                                    ? Colors.white.withValues(alpha: .7)
                                    : BrandColors.secondarySurface,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: .85),
                                ),
                              ),
                              child: Text(
                                _followBusy
                                    ? '…'
                                    : (_followStatus == 'pending'
                                          ? 'Requested'
                                          : ((_profile?.isFollowed ?? false)
                                                ? 'Following'
                                                : 'Follow')),
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: ((_profile?.isFollowed ?? false) ||
                                          _followStatus == 'pending')
                                      ? _ink
                                      : Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          LiquidPressable(
                            onTap: _blockUser,
                            borderRadius: BorderRadius.circular(999),
                            rippleColor: _ink,
                            intensity: .7,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(999),
                                color: Colors.white.withValues(alpha: .55),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: .9),
                                ),
                              ),
                              child: Text(
                                'Block',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: _ink.withValues(alpha: .75),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _stagger(
                index: 2,
                child: _StatsRow(
                  collaborators: _collaborators,
                  collaborating: _collaborating,
                  innovations: _innovationCount,
                  onCollaborators: () => _openPeopleSheet(
                    context,
                    title: 'Collaborators',
                    subtitle: 'People following this profile',
                    loader: () => _profileApi.followers(
                      authUserId: _isOwnProfile ? null : targetAuthId,
                    ),
                  ),
                  onCollaborating: () => _openPeopleSheet(
                    context,
                    title: 'Collaborating',
                    subtitle: 'People this profile follows',
                    loader: () => _profileApi.following(
                      authUserId: _isOwnProfile ? null : targetAuthId,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              _stagger(
                index: 3,
                child: const Center(
                  child: Text(
                    'Innovations',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _ink,
                      letterSpacing: -.2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _stagger(
                index: 4,
                child: _InnovationsFeed(
                  wave: _wave,
                  authorId: _isOwnProfile
                      ? (targetAuthId ?? AuthSession.instance.userId)
                      : targetAuthId,
                  onCount: (n) {
                    // Frontend truth: the actual number of loaded posts. Use it
                    // when the count endpoint returned 0 / hasn't answered.
                    if (mounted && n != _innovationCount) {
                      setState(() => _innovationCount = n);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ----------------------------------------------------------------- cover

class _CoverHeader extends StatelessWidget {
  const _CoverHeader({
    required this.coverHeight,
    required this.avatarSize,
    required this.topInset,
    required this.overlap,
    required this.coverBytes,
    this.coverUrl,
    this.coverUploading = false,
    required this.avatarBytes,
    this.avatarUrl,
    required this.name,
    required this.accent,
    required this.wave,
    this.onChangeCover,
    this.onChangeAvatar,
    this.onMenu,
    this.onBack,
  });

  final double coverHeight;
  final double avatarSize;
  final double topInset;
  final double overlap;
  final Uint8List? coverBytes;
  final String? coverUrl;
  final bool coverUploading;
  final Uint8List? avatarBytes;
  final String? avatarUrl;
  final String name;
  final List<Color> accent;
  final AnimationController wave;
  final VoidCallback? onChangeCover;
  final VoidCallback? onChangeAvatar;
  final VoidCallback? onMenu;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final totalHeight = coverHeight + (avatarSize - overlap);

    return SizedBox(
      height: totalHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: coverHeight,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Only this Consumer rebuilds when the shared cover changes —
                // not the whole profile screen. Priority: freshly-picked bytes
                // (optimistic) → shared provider cover → passed url → default.
                if (coverBytes != null)
                  Image.memory(coverBytes!, fit: BoxFit.cover)
                else
                  Consumer(
                    builder: (context, ref, _) {
                      // Only the OWN profile (where the cover can be changed)
                      // watches the shared current-user cover — otherwise every
                      // other user's profile would show the signed-in user's
                      // cover. Other profiles use only their own [coverUrl].
                      final ownProfile = onChangeCover != null;
                      final liveCover = ownProfile
                          ? ref.watch(
                              currentUserProvider.select((u) => u?.coverImage),
                            )
                          : null;
                      final url = (liveCover != null && liveCover.isNotEmpty)
                          ? liveCover
                          : coverUrl;
                      if (url != null && url.isNotEmpty) {
                        return CachedFeedImage(
                          url: url,
                          fit: BoxFit.cover,
                          errorWidget: const FastAssetImage(
                            asset: _defaultCover,
                            fit: BoxFit.cover,
                          ),
                        );
                      }
                      return const FastAssetImage(
                        asset: _defaultCover,
                        fit: BoxFit.cover,
                      );
                    },
                  ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x33071323),
                        Color(0x00071323),
                        Color(0x66071323),
                      ],
                      stops: [0, .45, 1],
                    ),
                  ),
                ),
                if (coverUploading)
                  const Positioned.fill(
                    child: ColoredBox(
                      color: Color(0x66000000),
                      child: Center(
                        child: SizedBox(
                          width: 26,
                          height: 26,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  top: topInset + 10,
                  left: 16,
                  child: _GlassIconButton(
                    icon: onBack != null
                        ? Icons.arrow_back_rounded
                        : Icons.more_horiz_rounded,
                    tooltip: onBack != null ? 'Back' : 'Profile options',
                    onTap: onBack ?? onMenu ?? () {},
                  ),
                ),
                if (onChangeCover != null)
                  Positioned(
                    top: topInset + 10,
                    right: 16,
                    child: 
                    _GlassIconButton(
                      icon: Icons.photo_camera_outlined,
                      tooltip: 'Change cover',
                      onTap: onChangeCover!,
                   ),
                ),
              ],
            ),
          ), 
          Positioned(
            left: 0,
            right: 0,
            top: coverHeight - overlap,
            child: Center(
              child: _AvatarBadge(
                size: avatarSize,
                name: name,
                bytes: avatarBytes,
                imageUrl: avatarUrl,
                wave: wave,
                accent: accent,
                onCamera: onChangeAvatar,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({
    required this.icon,
    required this.onTap,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final button = LiquidPressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      rippleColor: Colors.white,
      intensity: 1.1,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: .22),
          border: Border.all(color: Colors.white.withValues(alpha: .65)),
        ),
        child: Icon(icon, size: 18, color: Colors.white),
      ),
    );
    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}

// ----------------------------------------------------------- profile menu

class _ProfileMenuSheet extends StatelessWidget {
  const _ProfileMenuSheet({
    required this.onEditInfo,
    required this.onChangeCover,
    required this.onChangePhoto,
    required this.onManageCv,
    this.cvFileName,
  });

  final VoidCallback onEditInfo;
  final VoidCallback onChangeCover;
  final VoidCallback onChangePhoto;
  final VoidCallback onManageCv;
  final String? cvFileName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 18),
      child: FastGlass(
        borderRadius: BorderRadius.circular(28),
        opacity: .94,
        padding: const EdgeInsets.fromLTRB(10, 12, 10, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 4.5,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: _ink.withValues(alpha: .18),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Profile',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: _ink,
                letterSpacing: -.2,
              ),
            ),
            const SizedBox(height: 10),
            _MenuRow(
              icon: Icons.edit_outlined,
              title: 'Edit profile & personal information',
              subtitle: 'Student details, bio, school, and more',
              onTap: onEditInfo,
            ),
            _MenuRow(
              icon: Icons.photo_camera_outlined,
              title: 'Change cover photo',
              subtitle: 'Update your banner image',
              onTap: onChangeCover,
            ),
            _MenuRow(
              icon: Icons.account_circle_outlined,
              title: 'Change profile photo',
              subtitle: 'Update your avatar',
              onTap: onChangePhoto,
            ),
            _MenuRow(
              icon: Icons.description_outlined,
              title: 'My CV',
              subtitle: cvFileName == null
                  ? 'Upload or update your CV (PDF, DOC)'
                  : 'Current · $cvFileName',
              onTap: onManageCv,
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FastTap(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: BrandColors.accent.withValues(alpha: .16),
              ),
              child: Icon(icon, size: 20, color: BrandColors.accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: _ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: _ink.withValues(alpha: .48),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: _ink.withValues(alpha: .3),
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------- edit profile

class _EditProfilePage extends StatefulWidget {
  const _EditProfilePage({required this.info});

  final _LearnerInfo info;

  @override
  State<_EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<_EditProfilePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _wave = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  )..repeat();

  late final _displayName = TextEditingController(
    text: widget.info.displayName,
  );

  // Username availability check for the display name (debounced). The original
  // value is allowed (it's the user's current username).
  late final String _originalUsername = widget.info.displayName.trim();
  final _authApi = AuthApi();
  Timer? _usernameDebounce;
  bool _checkingUsername = false;
  bool? _usernameAvailable;
  List<String> _usernameSuggestions = const [];

  void _onUsernameChanged(String value) {
    final name = value.trim();
    _usernameDebounce?.cancel();
    setState(() {
      _usernameAvailable = null;
      _usernameSuggestions = const [];
      _checkingUsername = false;
    });
    if (name.isEmpty || name == _originalUsername) return;
    if (name.length < 3) return;
    _usernameDebounce = Timer(const Duration(milliseconds: 450), () async {
      setState(() => _checkingUsername = true);
      try {
        final result = await _authApi.checkUsername(name);
        if (!mounted || _displayName.text.trim() != name) return;
        setState(() {
          _usernameAvailable = result.available;
          _usernameSuggestions = result.suggestions;
          _checkingUsername = false;
        });
      } catch (_) {
        if (mounted) setState(() => _checkingUsername = false);
      }
    });
  }

  void _applyUsernameSuggestion(String suggestion) {
    _displayName.text = suggestion;
    _displayName.selection = TextSelection.fromPosition(
      TextPosition(offset: suggestion.length),
    );
    _onUsernameChanged(suggestion);
  }
  late final _fullName = TextEditingController(text: widget.info.fullName);
  late final _bio = TextEditingController(text: widget.info.bio);
  late final _email = TextEditingController(text: widget.info.email);
  late final _phone = TextEditingController(text: widget.info.phone);
  late final _dob = TextEditingController(text: widget.info.dateOfBirth);
  late final _gender = TextEditingController(text: widget.info.gender);
  late final _city = TextEditingController(text: widget.info.city);
  late final _country = TextEditingController(text: widget.info.country);
  late final _permanentAddress = TextEditingController(
    text: widget.info.permanentAddress,
  );
  late final _temporaryAddress = TextEditingController(
    text: widget.info.temporaryAddress,
  );
  late final _zipCode = TextEditingController(text: widget.info.zipCode);
  late final _school = TextEditingController(text: widget.info.school);
  late final _faculty = TextEditingController(text: widget.info.faculty);
  late final _degree = TextEditingController(text: widget.info.degree);
  late final _major = TextEditingController(text: widget.info.major);
  late final _yearLevel = TextEditingController(text: widget.info.yearLevel);
  late final _studentId = TextEditingController(text: widget.info.studentId);
  late final _enrollmentYear = TextEditingController(
    text: widget.info.enrollmentYear,
  );
  late final _skills = TextEditingController(text: widget.info.skills);
  late final _hobby = TextEditingController(text: widget.info.hobby);
  late final _goals = TextEditingController(text: widget.info.learningGoals);
  late final _language = TextEditingController(text: widget.info.language);
  late final _portfolio = TextEditingController(text: widget.info.portfolio);
  late final _facebook = TextEditingController(text: widget.info.facebook);
  late final _linkedin = TextEditingController(text: widget.info.linkedin);
  late final _instagram = TextEditingController(text: widget.info.instagram);
  late final _github = TextEditingController(text: widget.info.github);
  late String _educationLevel = widget.info.educationLevel;

  // Dynamic multi-value rows, each backed by its own controller(s).
  late final List<TextEditingController> _educationRows = _seedRows(
    widget.info.educations,
  );
  late final List<TextEditingController> _occupationRows = _seedRows(
    widget.info.occupations,
  );
  late final List<({TextEditingController label, TextEditingController url})>
      _linkRows = _seedLinkRows(widget.info.links);

  List<TextEditingController> _seedRows(List<String> values) {
    final list = values
        .where((v) => v.trim().isNotEmpty)
        .map((v) => TextEditingController(text: v))
        .toList();
    if (list.isEmpty) list.add(TextEditingController());
    return list;
  }

  List<({TextEditingController label, TextEditingController url})> _seedLinkRows(
    List<ProfileLink> values,
  ) {
    final list = values
        .where((l) => (l.url ?? '').trim().isNotEmpty)
        .map((l) => (
              label: TextEditingController(text: l.label ?? ''),
              url: TextEditingController(text: l.url ?? ''),
            ))
        .toList();
    if (list.isEmpty) {
      list.add((label: TextEditingController(), url: TextEditingController()));
    }
    return list;
  }

  @override
  void dispose() {
    _usernameDebounce?.cancel();
    _wave.dispose();
    for (final c in [
      _displayName,
      _fullName,
      _bio,
      _email,
      _phone,
      _dob,
      _gender,
      _city,
      _country,
      _permanentAddress,
      _temporaryAddress,
      _zipCode,
      _school,
      _faculty,
      _degree,
      _major,
      _yearLevel,
      _studentId,
      _enrollmentYear,
      _skills,
      _hobby,
      _goals,
      _language,
      _portfolio,
      _facebook,
      _linkedin,
      _instagram,
      _github,
    ]) {
      c.dispose();
    }
    for (final c in [..._educationRows, ..._occupationRows]) {
      c.dispose();
    }
    for (final r in _linkRows) {
      r.label.dispose();
      r.url.dispose();
    }
    super.dispose();
  }

  void _save() {
    // Block save if the chosen username is taken (unchanged username is fine).
    final username = _displayName.text.trim();
    if (username != _originalUsername && _usernameAvailable == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('That username is taken. Pick another.'),
        ),
      );
      return;
    }
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop(
      _LearnerInfo(
        displayName: _displayName.text.trim(),
        fullName: _fullName.text.trim(),
        bio: _bio.text.trim(),
        educations: _educationRows
            .map((c) => c.text.trim())
            .where((t) => t.isNotEmpty)
            .toList(),
        occupations: _occupationRows
            .map((c) => c.text.trim())
            .where((t) => t.isNotEmpty)
            .toList(),
        links: _linkRows
            .where((r) => r.url.text.trim().isNotEmpty)
            .map((r) => ProfileLink(
                  label: r.label.text.trim().isEmpty
                      ? null
                      : r.label.text.trim(),
                  url: r.url.text.trim(),
                ))
            .toList(),
        email: _email.text.trim(),
        phone: _phone.text.trim(),
        dateOfBirth: _dob.text.trim(),
        gender: _gender.text.trim(),
        city: _city.text.trim(),
        country: _country.text.trim(),
        permanentAddress: _permanentAddress.text.trim(),
        temporaryAddress: _temporaryAddress.text.trim(),
        zipCode: _zipCode.text.trim(),
        school: _school.text.trim(),
        faculty: _faculty.text.trim(),
        educationLevel: _educationLevel,
        degree: _degree.text.trim(),
        major: _major.text.trim(),
        yearLevel: _yearLevel.text.trim(),
        studentId: _studentId.text.trim(),
        enrollmentYear: _enrollmentYear.text.trim(),
        skills: _skills.text.trim(),
        hobby: _hobby.text.trim(),
        learningGoals: _goals.text.trim(),
        language: _language.text.trim(),
        portfolio: _portfolio.text.trim(),
        facebook: _facebook.text.trim(),
        linkedin: _linkedin.text.trim(),
        instagram: _instagram.text.trim(),
        github: _github.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: BrandColors.canvas,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const AnimatedBlobBackground(),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 16, 8),
                  child: Row(
                    children: [
                      FastTap(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          Navigator.of(context).pop();
                        },
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: .7),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: .95),
                            ),
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            size: 20,
                            color: _ink.withValues(alpha: .85),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Edit information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: _ink,
                            letterSpacing: -.3,
                          ),
                        ),
                      ),
                      FastTap(
                        onTap: _save,
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color: BrandColors.secondarySurface,
                          ),
                          child: const Text(
                            'Save',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(20, 4, 20, 28 + bottom),
                    children: [
                      const _FormSectionTitle('Profile'),
                      _FormField(
                        label: 'Username',
                        controller: _displayName,
                        hint: 'How you appear on Innovator',
                        wave: _wave,
                        onChanged: _onUsernameChanged,
                      ),
                      _EditUsernameStatus(
                        checking: _checkingUsername,
                        available: _usernameAvailable,
                        suggestions: _usernameSuggestions,
                        onPick: _applyUsernameSuggestion,
                      ),
                      _FormField(
                        label: 'Full name',
                        controller: _fullName,
                        hint: 'Legal / official name',
                        wave: _wave,
                      ),
                      _FormField(
                        label: 'Bio',
                        controller: _bio,
                        hint: 'A short intro about you',
                        maxLines: 4,
                        wave: _wave,
                      ),
                      const SizedBox(height: 18),
                      _MultiEntrySection(
                        title: 'Education',
                        addLabel: 'Add education',
                        rows: _educationRows,
                        hint: 'e.g. BSc CSIT — Tribhuvan University',
                        wave: _wave,
                        onAdd: () => setState(
                          () => _educationRows.add(TextEditingController()),
                        ),
                        onRemove: (i) => setState(() {
                          _educationRows.removeAt(i).dispose();
                          if (_educationRows.isEmpty) {
                            _educationRows.add(TextEditingController());
                          }
                        }),
                      ),
                      const SizedBox(height: 18),
                      _MultiEntrySection(
                        title: 'Occupation',
                        addLabel: 'Add occupation',
                        rows: _occupationRows,
                        hint: 'e.g. Founder @ Meta Tronix',
                        wave: _wave,
                        onAdd: () => setState(
                          () => _occupationRows.add(TextEditingController()),
                        ),
                        onRemove: (i) => setState(() {
                          _occupationRows.removeAt(i).dispose();
                          if (_occupationRows.isEmpty) {
                            _occupationRows.add(TextEditingController());
                          }
                        }),
                      ),
                      const SizedBox(height: 18),
                      _LinksSection(
                        rows: _linkRows,
                        wave: _wave,
                        onAdd: () => setState(() => _linkRows.add((
                              label: TextEditingController(),
                              url: TextEditingController(),
                            ))),
                        onRemove: (i) => setState(() {
                          final r = _linkRows.removeAt(i);
                          r.label.dispose();
                          r.url.dispose();
                          if (_linkRows.isEmpty) {
                            _linkRows.add((
                              label: TextEditingController(),
                              url: TextEditingController(),
                            ));
                          }
                        }),
                      ),
                      const SizedBox(height: 18),
                      const _FormSectionTitle('Personal'),
                      _FormField(
                        label: 'Email',
                        controller: _email,
                        hint: 'student@school.edu',
                        keyboard: TextInputType.emailAddress,
                        wave: _wave,
                      ),
                      _FormField(
                        label: 'Phone',
                        controller: _phone,
                        hint: '+977 …',
                        keyboard: TextInputType.phone,
                        wave: _wave,
                      ),
                      _FormField(
                        label: 'Date of birth',
                        controller: _dob,
                        hint: 'DD Mon YYYY',
                        wave: _wave,
                      ),
                      _FormField(
                        label: 'Gender',
                        controller: _gender,
                        hint: 'Optional',
                        wave: _wave,
                      ),
                      _FormField(
                        label: 'City',
                        controller: _city,
                        hint: 'Where you study / live',
                        wave: _wave,
                      ),
                      _FormField(
                        label: 'Country',
                        controller: _country,
                        hint: 'Country',
                        wave: _wave,
                      ),
                      _FormField(
                        label: 'Permanent address',
                        controller: _permanentAddress,
                        hint: 'Full permanent address',
                        maxLines: 2,
                        wave: _wave,
                      ),
                      _FormField(
                        label: 'Temporary address',
                        controller: _temporaryAddress,
                        hint: 'Current / temporary address',
                        maxLines: 2,
                        wave: _wave,
                      ),
                      _FormField(
                        label: 'Zip code',
                        controller: _zipCode,
                        hint: 'Postal / ZIP code',
                        keyboard: TextInputType.number,
                        wave: _wave,
                      ),
                      const SizedBox(height: 18),
                      const _FormSectionTitle('Student / learner'),
                      _EducationLevelPicker(
                        value: _educationLevel,
                        wave: _wave,
                        onChanged: (level) =>
                            setState(() => _educationLevel = level),
                      ),
                      const SizedBox(height: 12),
                      _FormField(
                        label: 'School / University',
                        controller: _school,
                        hint: 'Institution name',
                        wave: _wave,
                      ),
                      _FormField(
                        label: 'Faculty / Department',
                        controller: _faculty,
                        hint: 'e.g. School of Technology',
                        wave: _wave,
                      ),
                      _FormField(
                        label: 'Degree / Program',
                        controller: _degree,
                        hint: 'Bachelor, Master, Diploma…',
                        wave: _wave,
                      ),
                      _FormField(
                        label: 'Major / Field of study',
                        controller: _major,
                        hint: 'e.g. Computer Science',
                        wave: _wave,
                      ),
                      _FormField(
                        label: 'Year level',
                        controller: _yearLevel,
                        hint: '1st Year, 2nd Year, Graduate…',
                        wave: _wave,
                      ),
                      _FormField(
                        label: 'Student ID',
                        controller: _studentId,
                        hint: 'Campus ID number',
                        wave: _wave,
                      ),
                      _FormField(
                        label: 'Enrollment year',
                        controller: _enrollmentYear,
                        hint: 'YYYY',
                        keyboard: TextInputType.number,
                        wave: _wave,
                      ),
                      const SizedBox(height: 18),
                      const _FormSectionTitle('Learning'),
                      _FormField(
                        label: 'Skills & interests',
                        controller: _skills,
                        hint: 'Comma-separated skills',
                        maxLines: 2,
                        wave: _wave,
                      ),
                      _FormField(
                        label: 'Hobby',
                        controller: _hobby,
                        hint: 'What you enjoy outside class',
                        maxLines: 2,
                        wave: _wave,
                      ),
                      _FormField(
                        label: 'Learning goals',
                        controller: _goals,
                        hint: 'What you want to achieve',
                        maxLines: 3,
                        wave: _wave,
                      ),
                      _FormField(
                        label: 'Languages',
                        controller: _language,
                        hint: 'Languages you speak',
                        wave: _wave,
                      ),
                      _FormField(
                        label: 'Portfolio',
                        controller: _portfolio,
                        hint: 'https://…',
                        keyboard: TextInputType.url,
                        wave: _wave,
                      ),
                      const SizedBox(height: 18),
                      const _FormSectionTitle('Social links'),
                      _FormField(
                        label: 'Facebook profile link',
                        controller: _facebook,
                        hint: 'https://facebook.com/…',
                        keyboard: TextInputType.url,
                        wave: _wave,
                      ),
                      _FormField(
                        label: 'LinkedIn profile link',
                        controller: _linkedin,
                        hint: 'https://linkedin.com/in/…',
                        keyboard: TextInputType.url,
                        wave: _wave,
                      ),
                      _FormField(
                        label: 'Instagram profile link',
                        controller: _instagram,
                        hint: 'https://instagram.com/…',
                        keyboard: TextInputType.url,
                        wave: _wave,
                      ),
                      _FormField(
                        label: 'GitHub profile link',
                        controller: _github,
                        hint: 'https://github.com/…',
                        keyboard: TextInputType.url,
                        wave: _wave,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FormSectionTitle extends StatelessWidget {
  const _FormSectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: _ink,
          letterSpacing: -.2,
        ),
      ),
    );
  }
}

/// Section with dynamically addable single-value rows (education/occupation).
class _MultiEntrySection extends StatelessWidget {
  const _MultiEntrySection({
    required this.title,
    required this.addLabel,
    required this.rows,
    required this.hint,
    required this.wave,
    required this.onAdd,
    required this.onRemove,
  });

  final String title;
  final String addLabel;
  final List<TextEditingController> rows;
  final String hint;
  final AnimationController wave;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FormSectionTitle(title),
        for (var i = 0; i < rows.length; i++)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: _FormField(
                  label: '$title ${i + 1}',
                  controller: rows[i],
                  hint: hint,
                  wave: wave,
                ),
              ),
              if (rows.length > 1)
                IconButton(
                  onPressed: () => onRemove(i),
                  icon: Icon(
                    Icons.remove_circle_outline_rounded,
                    color: _ink.withValues(alpha: .4),
                  ),
                ),
            ],
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text(addLabel),
          ),
        ),
      ],
    );
  }
}

/// Section for arbitrary profile links (label + url) with add/remove.
class _LinksSection extends StatelessWidget {
  const _LinksSection({
    required this.rows,
    required this.wave,
    required this.onAdd,
    required this.onRemove,
  });

  final List<({TextEditingController label, TextEditingController url})> rows;
  final AnimationController wave;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FormSectionTitle('Links'),
        for (var i = 0; i < rows.length; i++)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 4,
                child: _FormField(
                  label: 'Label',
                  controller: rows[i].label,
                  hint: 'LinkedIn',
                  wave: wave,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 6,
                child: _FormField(
                  label: 'URL',
                  controller: rows[i].url,
                  hint: 'https://…',
                  keyboard: TextInputType.url,
                  wave: wave,
                ),
              ),
              if (rows.length > 1)
                IconButton(
                  onPressed: () => onRemove(i),
                  icon: Icon(
                    Icons.remove_circle_outline_rounded,
                    color: _ink.withValues(alpha: .4),
                  ),
                ),
            ],
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Add link'),
          ),
        ),
      ],
    );
  }
}

/// Liquid chip row for picking education level.
class _EducationLevelPicker extends StatelessWidget {
  const _EducationLevelPicker({
    required this.value,
    required this.wave,
    required this.onChanged,
  });

  static const options = [
    'School level',
    '+2 level',
    'Bachelor level',
    'Master level',
    'PhD',
    'ECA courses',
  ];

  final String value;
  final AnimationController wave;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 8),
          child: Text(
            'Education level',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: .2,
              color: _ink.withValues(alpha: .48),
            ),
          ),
        ),
        AnimatedBuilder(
          animation: wave,
          builder: (context, _) {
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final option in options)
                  _EducationChip(
                    label: option,
                    selected: value == option,
                    wave: wave,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onChanged(option);
                    },
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _EducationChip extends StatelessWidget {
  const _EducationChip({
    required this.label,
    required this.selected,
    required this.wave,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final AnimationController wave;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(999);

    return LiquidPressable(
      onTap: onTap,
      borderRadius: radius,
      rippleColor: selected ? Colors.white : _ink,
      intensity: .9,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          borderRadius: radius,
          border: Border.all(
            color: selected
                ? BrandColors.accent.withValues(alpha: .45)
                : Colors.white.withValues(alpha: .75),
            width: selected ? 1.3 : 1.05,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: BrandColors.secondarySurface.withValues(alpha: .2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Stack(
              children: [
                Positioned.fill(
                  child: ColoredBox(
                    color: Colors.white.withValues(alpha: selected ? .2 : .16),
                  ),
                ),
                if (selected)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: WaveFillPainter(
                        phase: wave.value * 2 * pi,
                        fill: 1.15,
                        color: BrandColors.secondarySurface.withValues(
                          alpha: .92,
                        ),
                        amplitude: 2.4,
                        frequency: 1.4,
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -.1,
                      color: selected
                          ? Colors.white
                          : _ink.withValues(alpha: .72),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FormField extends StatefulWidget {
  const _FormField({
    required this.label,
    required this.controller,
    required this.hint,
    required this.wave,
    this.maxLines = 1,
    this.keyboard = TextInputType.text,
    this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final AnimationController wave;
  final int maxLines;
  final TextInputType keyboard;
  final ValueChanged<String>? onChanged;

  @override
  State<_FormField> createState() => _FormFieldState();
}

class _FormFieldState extends State<_FormField> {
  final _focus = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      final next = _focus.hasFocus;
      if (next != _focused) setState(() => _focused = next);
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(20);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AnimatedBuilder(
        animation: widget.wave,
        builder: (context, _) {
          final fill = _focused ? .42 : .18;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(
                color: _focused
                    ? BrandColors.accent.withValues(alpha: .55)
                    : Colors.white.withValues(alpha: .72),
                width: _focused ? 1.4 : 1.1,
              ),
              boxShadow: [
                if (_focused)
                  BoxShadow(
                    color: BrandColors.accent.withValues(alpha: .16),
                    blurRadius: 22,
                    offset: const Offset(0, 8),
                  )
                else
                  BoxShadow(
                    color: _ink.withValues(alpha: .05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: ClipRRect(
              borderRadius: radius,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withValues(
                                alpha: _focused ? .38 : .22,
                              ),
                              Colors.white.withValues(
                                alpha: _focused ? .16 : .08,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: CustomPaint(
                        painter: WaveFillPainter(
                          phase:
                              widget.wave.value * 2 * pi +
                              widget.label.hashCode * .01,
                          fill: fill,
                          color: _ink.withValues(alpha: _focused ? .10 : .05),
                          amplitude: _focused ? 3.6 : 2.2,
                          frequency: 1.45,
                        ),
                      ),
                    ),
                    if (_focused)
                      Positioned.fill(
                        child: CustomPaint(
                          painter: WaveFillPainter(
                            phase: widget.wave.value * 2 * pi + 1.4,
                            fill: .28,
                            color: BrandColors.accent.withValues(alpha: .10),
                            amplitude: 2.8,
                            frequency: 1.2,
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.label,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: .2,
                              color: _focused
                                  ? BrandColors.accent.withValues(alpha: .85)
                                  : _ink.withValues(alpha: .48),
                            ),
                          ),
                          const SizedBox(height: 4),
                          TextField(
                            controller: widget.controller,
                            focusNode: _focus,
                            maxLines: widget.maxLines,
                            keyboardType: widget.keyboard,
                            onChanged: widget.onChanged,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              color: _ink,
                            ),
                            cursorColor: BrandColors.accent,
                            decoration: InputDecoration(
                              isDense: true,
                              border: InputBorder.none,
                              hintText: widget.hint,
                              hintStyle: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: _ink.withValues(alpha: .32),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Username availability status shown under the Username field on the edit
/// profile form: spinner while checking, green/red result, tappable suggestions.
class _EditUsernameStatus extends StatelessWidget {
  const _EditUsernameStatus({
    required this.checking,
    required this.available,
    required this.suggestions,
    required this.onPick,
  });

  final bool checking;
  final bool? available;
  final List<String> suggestions;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    if (!checking && available == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 4, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (checking)
            Row(
              children: [
                const SizedBox(
                  width: 13,
                  height: 13,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 8),
                Text(
                  'Checking…',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: _ink.withValues(alpha: .55),
                  ),
                ),
              ],
            )
          else if (available == true)
            const Row(
              children: [
                Icon(Icons.check_circle_rounded,
                    size: 15, color: Color(0xFF17A275)),
                SizedBox(width: 6),
                Text(
                  'Available',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF17A275),
                  ),
                ),
              ],
            )
          else if (available == false) ...[
            const Row(
              children: [
                Icon(Icons.cancel_rounded, size: 15, color: Color(0xFFC0392B)),
                SizedBox(width: 6),
                Text(
                  'Taken',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFC0392B),
                  ),
                ),
              ],
            ),
            if (suggestions.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final s in suggestions)
                    GestureDetector(
                      onTap: () => onPick(s),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: Colors.white.withValues(alpha: .6),
                          border:
                              Border.all(color: _ink.withValues(alpha: .15)),
                        ),
                        child: Text(
                          s,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: _ink,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------- avatar

class _AvatarBadge extends StatelessWidget {
  const _AvatarBadge({
    required this.size,
    required this.name,
    required this.bytes,
    this.imageUrl,
    required this.wave,
    required this.accent,
    this.onCamera,
  });

  final double size;
  final String name;
  final Uint8List? bytes;
  final String? imageUrl;
  final AnimationController wave;
  final List<Color> accent;
  final VoidCallback? onCamera;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3.5),
              boxShadow: [
                BoxShadow(
                  color: _ink.withValues(alpha: .18),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipOval(
              child: SizedBox(
                width: size,
                height: size,
                child: bytes != null
                    ? Image.memory(bytes!, fit: BoxFit.cover)
                    : (imageUrl != null && imageUrl!.trim().isNotEmpty)
                    // Use the same cached, auth-header-aware loader as the feed
                    // so a cached copy shows even if the server file 404s, and
                    // headers are sent when the media path requires them.
                    ? CachedFeedImage(
                        url: imageUrl!,
                        fit: BoxFit.cover,
                        width: size,
                        height: size,
                        memCacheWidth: (size * 3).round(),
                        errorWidget: Stack(
                          fit: StackFit.expand,
                          children: [
                            DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    accent.first.withValues(alpha: .9),
                                    accent.last,
                                  ],
                                ),
                              ),
                            ),
                            Center(
                              child: Text(
                                name.isEmpty ? '?' : name[0].toUpperCase(),
                                style: TextStyle(
                                  fontSize: size * .38,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : Stack(
                        fit: StackFit.expand,
                        children: [
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  accent.first.withValues(alpha: .9),
                                  accent.last,
                                ],
                              ),
                            ),
                          ),
                          AnimatedBuilder(
                            animation: wave,
                            builder: (context, _) => CustomPaint(
                              painter: WaveFillPainter(
                                phase: wave.value * 2 * pi,
                                fill: .3,
                                color: Colors.white.withValues(alpha: .12),
                                amplitude: 4,
                                frequency: 1.3,
                              ),
                            ),
                          ),
                          Center(
                            child: Text(
                              name.isEmpty ? '?' : name[0].toUpperCase(),
                              style: TextStyle(
                                fontSize: size * .38,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
          if (onCamera != null)
            Positioned(
              right: -2,
              bottom: -2,
              child: LiquidPressable(
                onTap: onCamera!,
                borderRadius: BorderRadius.circular(16),
                rippleColor: Colors.white,
                intensity: 1.2,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: BrandColors.secondarySurface,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------- badge

class _TitleBadgeChip extends StatelessWidget {
  const _TitleBadgeChip({
    required this.badge,
    required this.wave,
    required this.onTap,
    this.verified = false,
  });

  final _TitleBadge badge;
  final AnimationController wave;
  final VoidCallback onTap;
  final bool verified;

  @override
  Widget build(BuildContext context) {
    return LiquidPressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      rippleColor: Colors.white,
      intensity: 1.1,
      child: AnimatedBuilder(
        animation: wave,
        builder: (context, _) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: badge.colors,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: WaveFillPainter(
                        phase: wave.value * 2 * pi,
                        fill: .28,
                        color: Colors.white.withValues(alpha: .12),
                        amplitude: 2.5,
                        frequency: 1.4,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(badge.icon, size: 14, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(
                        badge.label,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: .2,
                        ),
                      ),
                      if (verified) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.verified_rounded,
                          size: 13,
                          color: Colors.white.withValues(alpha: .9),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ------------------------------------------------------------------ stats

/// Open premium metrics — no card, no border. Editorial numbers with soft
/// hairline separators and a gold accent mark under each value.
class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.collaborators,
    required this.collaborating,
    required this.innovations,
    required this.onCollaborators,
    required this.onCollaborating,
  });

  final int collaborators;
  final int collaborating;
  final int innovations;
  final VoidCallback onCollaborators;
  final VoidCallback onCollaborating;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: _StatCell(
              value: collaborators,
              label: 'Collaborators',
              onTap: onCollaborators,
            ),
          ),
          _StatDivider(),
          Expanded(
            child: _StatCell(
              value: collaborating,
              label: 'Collaborating',
              onTap: onCollaborating,
            ),
          ),
          _StatDivider(),
          Expanded(
            child: _StatCell(value: innovations, label: 'Innovation'),
          ),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 28,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _ink.withValues(alpha: 0),
            _ink.withValues(alpha: .14),
            _ink.withValues(alpha: 0),
          ],
        ),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.value, required this.label, this.onTap});

  final int value;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return FastTap(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap?.call();
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Column(
          children: [
            Text(
              '$value',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: _ink,
                letterSpacing: -.6,
                height: 1,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: 18,
              height: 2.5,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: BrandColors.accent,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: .2,
                color: _ink.withValues(alpha: .48),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------------- people sheet

class _PeopleSheet extends StatefulWidget {
  const _PeopleSheet({
    required this.title,
    required this.subtitle,
    required this.loader,
  });

  final String title;
  final String subtitle;
  final Future<List<ProfileListUser>> Function() loader;

  @override
  State<_PeopleSheet> createState() => _PeopleSheetState();
}

class _PeopleSheetState extends State<_PeopleSheet> {
  bool _loading = true;
  String? _error;
  List<_Person> _people = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final users = await widget.loader();
      if (!mounted) return;
      setState(() {
        _people = users.map(_Person.fromListUser).toList();
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load people';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.sizeOf(context).height * .78;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxH),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            child: FastGlass(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(32),
              ),
              opacity: .94,
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 42,
                      height: 4.5,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: _ink.withValues(alpha: .18),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 16, 22, 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.title,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: _ink,
                                    letterSpacing: -.3,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  _loading
                                      ? widget.subtitle
                                      : '${widget.subtitle} · ${_people.length} shown',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: _ink.withValues(alpha: .48),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          FastTap(
                            onTap: () => Navigator.of(context).pop(),
                            borderRadius: BorderRadius.circular(999),
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: .55),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: .95),
                                ),
                              ),
                              child: Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: _ink.withValues(alpha: .75),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Flexible(
                      child: _loading
                          ? const Padding(
                              padding: EdgeInsets.all(36),
                              child: Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                ),
                              ),
                            )
                          : _error != null
                          ? Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                children: [
                                  Text(
                                    _error!,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(color: _muted),
                                  ),
                                  TextButton(
                                    onPressed: _load,
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            )
                          : _people.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(28),
                              child: Text(
                                'No people here yet',
                                style: TextStyle(color: _muted),
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              padding: const EdgeInsets.fromLTRB(14, 8, 14, 18),
                              itemCount: _people.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                return _PersonTile(person: _people[index]);
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PersonTile extends StatefulWidget {
  const _PersonTile({required this.person});

  final _Person person;

  @override
  State<_PersonTile> createState() => _PersonTileState();
}

class _PersonTileState extends State<_PersonTile> {
  final _profileApi = ProfileApi();
  late bool _following = widget.person.isFollowed;
  bool _busy = false;

  _Person get person => widget.person;

  bool get _isMe {
    final me = AuthSession.instance.userId;
    return me != null && me.isNotEmpty && me == person.authUserId;
  }

  void _openProfile() {
    HapticFeedback.selectionClick();
    final id = person.authUserId;
    if (id == null || id.isEmpty) return;
    final nav = Navigator.of(context);
    nav.pop();
    nav.push(
      MaterialPageRoute<void>(
        builder: (_) => AuthorProfilePage(name: person.name, authUserId: id),
      ),
    );
  }

  Future<void> _toggleFollow() async {
    final id = person.authUserId;
    if (_busy || id == null || id.isEmpty) return;
    HapticFeedback.selectionClick();
    SoundPlayer.instance.follow();
    final next = !_following;
    setState(() {
      _following = next;
      _busy = true;
    });
    try {
      final result = await _profileApi.toggleFollow(id);
      if (mounted) setState(() => _following = result.isFollowing);
    } catch (_) {
      if (mounted) setState(() => _following = !next);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final letter = person.name.isEmpty ? '?' : person.name[0].toUpperCase();
    final avatarUrl = person.avatarUrl?.trim();
    final fallback = Center(
      child: Text(
        letter,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );

    return FastTap(
      onTap: _openProfile,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: person.colors,
                ),
              ),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: person.colors,
                  ),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                clipBehavior: Clip.antiAlias,
                child: avatarUrl != null && avatarUrl.isNotEmpty
                    ? CachedFeedImage(
                        url: avatarUrl,
                        fit: BoxFit.cover,
                        width: 44,
                        height: 44,
                        memCacheWidth: 100,
                        errorWidget: fallback,
                      )
                    : fallback,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    person.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: _ink,
                      letterSpacing: -.2,
                    ),
                  ),
                  if ((person.username ?? '').isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      '@${person.username}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: _ink.withValues(alpha: .48),
                      ),
                    ),
                  ],
                  if ((person.occupation ?? '').isNotEmpty) ...[
                    const SizedBox(height: 1),
                    Text(
                      person.occupation!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: _ink.withValues(alpha: .58),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (!_isMe)
              _PersonFollowButton(
                following: _following,
                busy: _busy,
                onTap: _toggleFollow,
              ),
          ],
        ),
      ),
    );
  }
}

/// Compact follow / following pill used in the people sheet.
class _PersonFollowButton extends StatelessWidget {
  const _PersonFollowButton({
    required this.following,
    required this.busy,
    required this.onTap,
  });

  final bool following;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FastTap(
      onTap: busy ? () {} : onTap,
      borderRadius: BorderRadius.circular(999),
      child: Opacity(
        opacity: busy ? .6 : 1,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: following
                ? Colors.white.withValues(alpha: .7)
                : BrandColors.secondarySurface,
            border: Border.all(
              color: following
                  ? _ink.withValues(alpha: .18)
                  : Colors.white.withValues(alpha: .85),
            ),
          ),
          child: Text(
            following ? 'Following' : 'Follow',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: following ? _ink : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------ innovations

/// The signed-in / viewed member's own posts, pulled from the feed service
/// (`/api/users/{authorId}/posts`). Falls back to an empty state when the
/// member hasn't posted yet.
class _InnovationsFeed extends StatefulWidget {
  const _InnovationsFeed({required this.wave, this.authorId, this.onCount});

  final AnimationController wave;
  final String? authorId;

  /// Reports the number of loaded posts so the profile can show the real count.
  final ValueChanged<int>? onCount;

  @override
  State<_InnovationsFeed> createState() => _InnovationsFeedState();
}

class _InnovationsFeedState extends State<_InnovationsFeed> {
  final _feedApi = FeedApi();
  List<FeedPostDto> _items = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant _InnovationsFeed oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.authorId != widget.authorId) _load();
  }

  Future<void> _load() async {
    final id = widget.authorId?.trim();
    if (id == null || id.isEmpty) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    setState(() => _loading = true);
    try {
      final page = await _feedApi.postsByAuthor(id, pageSize: 50);
      if (!mounted) return;
      setState(() {
        _items = page.results;
        _loading = false;
      });
      widget.onCount?.call(_items.length);
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _replacePost(FeedPostDto updated) {
    final idx = _items.indexWhere((p) => p.id == updated.id);
    if (idx < 0) return;
    setState(() {
      final next = List<FeedPostDto>.from(_items);
      next[idx] = updated;
      _items = next;
    });
  }

  void _removePost(String id) {
    setState(() => _items = _items.where((p) => p.id != id).toList());
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2.4)),
      );
    }
    if (_items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Center(
          child: Text(
            'No posts yet.',
            style: TextStyle(color: _ink.withValues(alpha: .5)),
          ),
        ),
      );
    }
    // Reuse the real news-feed card so profile posts get every feature —
    // see-more captions, live reactions, comments, share and delete.
    return Column(
      children: [
        for (var i = 0; i < _items.length; i++) ...[
          if (i > 0) const SizedBox(height: 14),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: 380 + i * 60),
            curve: Curves.easeOutCubic,
            builder: (context, t, child) => Transform.translate(
              offset: Offset(0, 14 * (1 - t.clamp(0, 1))),
              child: Opacity(opacity: t.clamp(0, 1), child: child),
            ),
            child: RepaintBoundary(
              child: FeedCard(
                key: ValueKey('profile-post-${_items[i].id}'),
                post: _items[i],
                onChanged: _replacePost,
                onDeleted: _removePost,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
