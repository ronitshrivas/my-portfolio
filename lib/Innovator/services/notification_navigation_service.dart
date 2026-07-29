// lib/Innovator/services/notification_navigation_service.dart
//
// A static helper that navigates from notification tap data using the
// GetX navigatorKey — works from main.dart (background/killed) and from
// any local-notification payload handler.

import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:innovator/Innovator/App_data/App_data.dart';
import 'package:innovator/Innovator/screens/Feed/post_detail_screen.dart';
import 'package:innovator/Innovator/screens/chatrrom/screen/chatscreen.dart';
import 'package:innovator/Innovator/screens/show_Specific_Profile/Show_Specific_Profile.dart';
import 'package:innovator/ecommerce/screens/Shop/Product_detail_Page.dart';
import 'package:innovator/elearning/model/course_list_model.dart';
import 'package:innovator/elearning/screens/course_details_screen.dart';
import 'package:innovator/elearning/screens/course_list_screen.dart';

class NotificationNavigationService {
  // ─── single entry-point called for every notification tap ────────────────

  static Future<void> handlePayload(Map<String, dynamic> data) async {
    final type = (data['type'] ?? '').toString().toLowerCase();
    developer.log('[NavService] handling type=$type data=$data');

    switch (type) {
      // ── Innovator social ─────────────────────────────────────────────────
      case 'like':
      case 'reaction':
      case 'comment':
      case 'share':
      case 'mention':
        final postId =
            data['relatedPostId']?.toString() ??
            data['related_post_id']?.toString() ??
            data['postId']?.toString() ??
            data['post_id']?.toString();
        if (postId != null && postId.isNotEmpty) {
          _push(
            NewFeedPostDetailScreen(
              postId: postId,
              highlightAction: type,
            ),
          );
        }
        break;

      // ── Chat / Message ───────────────────────────────────────────────────
      case 'chat':
      case 'message':
      case 'chat_message':
      case 'new_message':
        final senderId =
            data['senderId']?.toString() ??
            data['sender_id']?.toString() ??
            data['chatId']?.toString();
        final senderName =
            data['senderName']?.toString() ??
            data['sender_username']?.toString() ??
            'User';
        final senderAvatar =
            data['senderAvatar']?.toString() ??
            data['sender_avatar']?.toString() ??
            '';
        if (senderId != null && senderId.isNotEmpty) {
          _push(
            ChatScreen(
              otherUserId: senderId,
              otherUserName: senderName,
              otherUserAvatar: senderAvatar,
              isOnline: false,
            ),
          );
        }
        break;

      // ── Follow / Friend-request ──────────────────────────────────────────
      case 'follow':
      case 'friend_request':
        final userId =
            data['senderId']?.toString() ??
            data['sender_id']?.toString() ??
            data['userId']?.toString();
        if (userId != null && userId.isNotEmpty) {
          _push(SpecificUserProfilePage(userId: userId));
        }
        break;

      // ── E-learning ──────────────────────────────────────────────────────
      case 'elearning':
      case 'enrollment':
      case 'course':
      case 'course_announcement':
        final courseId =
            data['courseId']?.toString() ??
            data['course_id']?.toString();
        if (courseId != null && courseId.isNotEmpty) {
          await _navigateToCourse(courseId);
        } else {
          _push(const CourseListScreen());
        }
        break;

      // ── E-commerce ──────────────────────────────────────────────────────
      case 'ecommerce':
      case 'product':
      case 'shop':
      case 'order':
        final productId =
            data['productId']?.toString() ??
            data['product_id']?.toString();
        if (productId != null && productId.isNotEmpty) {
          _push(ProductDetailPage(productId: productId));
        }
        break;

      default:
        developer.log('[NavService] unhandled type: $type');
    }

    // Mark the Innovator-side notification as read if we have an id
    final notifId = data['id']?.toString() ?? data['notificationId']?.toString();
    if (notifId != null && notifId.isNotEmpty) {
      _markInnovatorNotificationRead(notifId);
    }
  }

  // ─── helpers ─────────────────────────────────────────────────────────────

  /// Push a route using the GetX navigator key so it works from any context.
  static void _push(Widget screen) {
    final state = Get.key.currentState;
    if (state == null) {
      developer.log('[NavService] navigator not ready yet, retrying in 500ms');
      Future.delayed(const Duration(milliseconds: 500), () => _push(screen));
      return;
    }
    state.push(MaterialPageRoute(builder: (_) => screen));
  }

  /// Fetch course list, find the matching course by ID, then navigate.
  /// Falls back to course-list screen when the course cannot be found.
  static Future<void> _navigateToCourse(String courseId) async {
    try {
      developer.log('[NavService] fetching course $courseId');
      final token = AppData().accessToken;
      if (token == null || token.isEmpty) {
        _push(const CourseListScreen());
        return;
      }

      final response = await http
          .get(
            Uri.parse('http://36.253.137.34:8003/api/courses/'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body) as List<dynamic>;
        final courseJson = list
            .cast<Map<String, dynamic>>()
            .where((c) => c['id']?.toString() == courseId)
            .firstOrNull;

        if (courseJson != null) {
          final course = CourseListModel.fromJson(courseJson);
          _push(CourseDetailScreen(course: course));
          return;
        }
      }
    } catch (e) {
      developer.log('[NavService] course fetch error: $e');
    }
    // fallback
    _push(const CourseListScreen());
  }

  /// Call the Innovator mark-as-read API in the background (fire-and-forget).
  static void _markInnovatorNotificationRead(String notificationId) async {
    try {
      final token = AppData().accessToken;
      if (token == null || token.isEmpty) return;
      await http.post(
        Uri.parse(
          'http://36.253.137.34:8012/api/notifications/$notificationId/mark-as-read',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      developer.log('[NavService] marked notification $notificationId as read');
    } catch (e) {
      developer.log('[NavService] markAsRead error: $e');
    }
  }
}