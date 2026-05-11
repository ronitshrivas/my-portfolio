import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:innovator/Innovator/constant/app_colors.dart';
import 'package:innovator/Innovator/screens/Blocked/BlockedUser.dart';
import 'package:innovator/Innovator/screens/Profile/Edit_Profile.dart';
import 'package:innovator/Innovator/screens/chatrrom/screen/chatlistscreen.dart';
import 'package:innovator/Innovator/widget/CustomizeFAB.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:innovator/Innovator/Authorization/change_pwd.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final Color primaryColor = const Color.fromRGBO(244, 135, 6, 1);

  bool pushNotifications = true;
  bool emailNotifications = false;
  bool privateAccount = false;
  bool allowTagging = true;
  bool showOnlineStatus = true;
  bool darkMode = false;
  bool autoPlayVideos = true;
  bool saveToGallery = false;
  String selectedLanguage = 'English';

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      setState(() {
        pushNotifications = prefs.getBool('pushNotifications') ?? true;
        emailNotifications = prefs.getBool('emailNotifications') ?? false;
        privateAccount = prefs.getBool('privateAccount') ?? false;
        allowTagging = prefs.getBool('allowTagging') ?? true;
        showOnlineStatus = prefs.getBool('showOnlineStatus') ?? true;
        darkMode = prefs.getBool('darkMode') ?? false;
        autoPlayVideos = prefs.getBool('autoPlayVideos') ?? true;
        saveToGallery = prefs.getBool('saveToGallery') ?? false;
        selectedLanguage = prefs.getString('selectedLanguage') ?? 'English';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      Get.snackbar(
        'Failed',
        'Failed to Load Settings',
        backgroundColor: Colors.red,
        colorText: AppColors.whitecolor,
      );
    }
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (value is bool) {
        await prefs.setBool(key, value);
      } else if (value is String) {
        await prefs.setString(key, value);
      } else if (value is int) {
        await prefs.setInt(key, value);
      } else if (value is double) {
        await prefs.setDouble(key, value);
      }

      Get.snackbar(
        'Saved',
        'All Settings Saved Successfully',
        backgroundColor: Colors.green,
        colorText: AppColors.whitecolor,
      );
    } catch (e) {
      Get.snackbar(
        'Failed',
        'Failed to Save Settings',
        backgroundColor: Colors.red,
        colorText: AppColors.whitecolor,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = ref.watch(chatUnreadCountProvider);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          scrolledUnderElevation: 0,
          title: const Text(
            'Settings',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],

      appBar: AppBar(
        scrolledUnderElevation: 0,
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Section
            _buildSectionCard(
              title: 'Account',
              icon: Icons.person,
              children: [
                _buildSettingsTile(
                  icon: Icons.edit,
                  title: 'Edit Profile',
                  subtitle: 'Update your profile information',
                  onTap:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => EditProfileScreen()),
                      ),
                ),
                _buildSettingsTile(
                  icon: Icons.lock,
                  title: 'Change Password',
                  subtitle: 'Update your account password',
                  onTap:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChangePasswordScreen(),
                        ),
                      ),
                ),
                _buildSwitchTile(
                  icon: Icons.privacy_tip,
                  title: 'Private Account',
                  subtitle: 'Only followers can see your posts',
                  value: privateAccount,
                  onChanged: (value) {
                    setState(() => privateAccount = value);
                    _saveSetting('privateAccount', value);
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Privacy & Security Section
            _buildSectionCard(
              title: 'Privacy & Security',
              icon: Icons.security,
              children: [
                _buildSwitchTile(
                  icon: Icons.visibility,
                  title: 'Show Online Status',
                  subtitle: 'Let others see when you\'re active',
                  value: showOnlineStatus,
                  onChanged: (value) {
                    setState(() => showOnlineStatus = value);
                    _saveSetting('showOnlineStatus', value);
                  },
                ),
                _buildSwitchTile(
                  icon: Icons.local_offer,
                  title: 'Allow Tagging',
                  subtitle: 'Others can tag you in posts',
                  value: allowTagging,
                  onChanged: (value) {
                    setState(() => allowTagging = value);
                    _saveSetting('allowTagging', value);
                  },
                ),
                _buildSettingsTile(
                  icon: Icons.block,
                  title: 'Blocked Users',
                  subtitle: 'Manage blocked accounts',
                  onTap:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => BlockedUsersScreen()),
                      ),
                ),
              ],
            ),

            const SizedBox(height: 16),
          ],
        ),
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
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: primaryColor, size: 24),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: Colors.grey[600]),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
          trailing: Icon(
            Icons.arrow_forward_ios,
            color: Colors.grey[400],
            size: 16,
          ),
          onTap: onTap,
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[600]),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.grey[600], fontSize: 12),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: primaryColor,
        inactiveThumbColor: Colors.black,
      ),
      contentPadding: EdgeInsets.zero,
    );
  }
}
