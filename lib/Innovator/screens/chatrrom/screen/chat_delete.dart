import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:innovator/Innovator/App_data/App_data.dart';
import 'package:innovator/Innovator/constant/api_constants.dart';
import 'package:innovator/Innovator/constant/app_colors.dart';
import 'package:innovator/Innovator/provider/chat_preference_provider.dart';

const _orange = Color.fromRGBO(244, 135, 6, 1);

class ChatDeleteScreen extends ConsumerStatefulWidget {
  final String chatPartnerId;

  const ChatDeleteScreen({super.key, required this.chatPartnerId});

  @override
  ConsumerState<ChatDeleteScreen> createState() => _ChatDeleteScreenState();
}

class _ChatDeleteScreenState extends ConsumerState<ChatDeleteScreen> {
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(chatPreferenceProvider.notifier)
          .fetchPreference(widget.chatPartnerId);
    });
  }

  Future<void> _updatePreference(String? preference) async {
    if (preference == null) return;

    final notifier = ref.read(chatPreferenceProvider.notifier);
    final previousPreference =
        ref.read(chatPreferenceProvider)[widget.chatPartnerId] ?? '24_hours';

    notifier.setPreference(widget.chatPartnerId, preference);
    setState(() => _isSaving = true);

    try {
      final token = AppData().accessToken ?? '';
      final response = await http
          .post(
            Uri.parse(ApiConstants.chatPreferences),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: json.encode({
              'chat_partner': widget.chatPartnerId,
              'deletion_preference': preference,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200 && response.statusCode != 201) {
        notifier.setPreference(widget.chatPartnerId, previousPreference);
        if (mounted) _showErrorSnackbar('Failed to update. Please try again.');
      }
    } catch (_) {
      notifier.setPreference(widget.chatPartnerId, previousPreference);
      if (mounted) {
        _showErrorSnackbar('Something went wrong. Check your connection.');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.systemRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final preferences = ref.watch(chatPreferenceProvider);
    final currentPreference = preferences[widget.chatPartnerId] ?? '24_hours';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.black12,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: Colors.black87,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Message Deletion',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.grey.shade100),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'AUTO-DELETE MESSAGES',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade500,
                letterSpacing: 0.6,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: RadioGroup<String>(
              groupValue: currentPreference,
              onChanged: (String? value) {
                if (!_isSaving && value != null) {
                  _updatePreference(value);
                }
              },
              child: Column(
                children: [
                  PreferenceOption(
                    label: 'After 24 hours',
                    description: 'Messages will be automatically removed',
                    value: '24_hours',
                    selectedValue: currentPreference,
                    isFirst: true,
                    isLast: false,
                  ),
                  Divider(height: 1, indent: 56, color: Colors.grey.shade100),
                  PreferenceOption(
                    label: 'Never',
                    description: 'Messages will always be kept',
                    value: 'never',
                    selectedValue: currentPreference,
                    isFirst: false,
                    isLast: true,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              currentPreference == 'never'
                  ? 'Your messages in this chat will never be deleted automatically.'
                  : 'Messages in this chat older than 24 hours will be deleted automatically.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PreferenceOption extends StatelessWidget {
  final String label;
  final String description;
  final String value;
  final String selectedValue;
  final bool isFirst;
  final bool isLast;

  const PreferenceOption({
    super.key,
    required this.label,
    required this.description,
    required this.value,
    required this.selectedValue,
    required this.isFirst,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selectedValue;

    return ClipRRect(
      borderRadius: BorderRadius.vertical(
        top: isFirst ? const Radius.circular(14) : Radius.zero,
        bottom: isLast ? const Radius.circular(14) : Radius.zero,
      ),
      child: Material(
        color: Colors.white,
        child: InkWell(
          onTap:
              () => RadioGroup.maybeOf<String>(context)?.onChanged?.call(value),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Radio<String>(value: value),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.black87 : Colors.black54,
                        ),
                      ),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: _orange,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
