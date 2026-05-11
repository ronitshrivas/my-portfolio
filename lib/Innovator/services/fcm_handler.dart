import 'package:googleapis_auth/auth_io.dart';
import 'dart:convert';
import 'dart:developer' as developer;

class FCMHandler {
  static const String _fcmEndpoint =
      'https://fcm.googleapis.com/v1/projects/innovator-250f8/messages:send';
  static ServiceAccountCredentials? _credentials;
  static AuthClient? _authClient;
  static DateTime? _tokenExpiry;

  // Service account key - make sure this matches your Firebase project
  static const Map<String, dynamic> _serviceAccountKey = {
    "type": "service_account",
    "project_id": "innovator-250f8",
    "private_key_id": "face9754d7afcc85ee325f503cf8ec7c57b7db32",
    "private_key":
        "-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQDHB2mJxGw2FGT/\n5o+e1REaMqaixCKwzzf4RmO1dbKtbzJrbdR6Ad7C3I5YUNgJs/A04dMTpF1NPCxA\nHgJYCCTMhNrCx7jd8oESSWmzoNc5ZSi1s2S27qjkOy5TvpWzds4xYSErl/sqt8wi\nMUaKamLBpFmNUkZG4bphPGa9pmfzQ1ObJS9b9Zt4B/ZnXn5EsGCB6+BkdD3MU4Nk\nKaWtIAPe4IKDCTGNXhmaHXixYf8yopTZIwrkPhk7nSMtbs9c3NKFsm8gUfOjhDD5\ng0/8LCX/ZvyHqhGcjA0leT9tsbLcusnv9HcfuQSQfF21t0+bAz0f5KEsECtVJSfn\nQFgvu4PVAgMBAAECggEAFPkqJ8tBT1DxNGmdUIgJwCspQIq5pcyDDJCNA6YZA59t\nqUDO0g1DZmEWm6Y9SzHL33ln+bBpkpuDhZLZUrcyUDO0goUdwpRtAeUm6eJ0+7E2\nITD719ko3BAueW232cxsaGtgsvbWOsdZOsXa4KLbBaaQ4fcTEnd0DA4bkjhTHkvA\nu3rVYeBOoJfRBBygpoxRJK0pWAq0SsktsaRDquunHHghCnPGaIpTLNfU9QP7tXXF\n0Qnor9traQnKZEqcHWvfWSVbSW0AU/nDr7yL3oyF0UquWdN8f+WC9QUt1BcAKRp7\nGl0Bs2KyJ9NZ/nFCjym10FCQMKPbrrSnQNOWoQT5WwKBgQD2WLeyZ8dANNO5Wdva\ntG+l3ifYbs/Q1FshH+TSLKwuXfqe2kGYQQYEw5XsMtwAD7M98E+Oz5Aq2oFAaKQu\nNCNWywMEs/oFsM/P9p4I5Dd8k8+9aaGnv9ZmFdZbiCbgYGUVwaoeQWRUSyonQxup\nDygZ1RmCgj/+WAtmaiJaFb3j8wKBgQDO1ARquIZjL701Q9D18o8qKoqBqN88Ce/m\n8nEsUq4EiecjCwk9WEC9KLWuequn6R8Sv3F+Ddew6lpl4FbjHWT7dbZGnfrJMhgc\nhw3YVglrOGfbCFdxhvuE+b+i2a45vFJifoO5/dFo2ghl10tw2w+fDM0deDhc4n9x\nIazsansTFwKBgQDnnoShLmguGz1SkYVgPbSX3KfUHGQysec43tbzMeN1+RCyGP4B\nnGl/QzIMEcm+GQTrYK481TV0xVsvZvOvKYBsk5Yz7tBOV28c1oDCVWlCLWvuaIoA\nwiNgennAN+RtpNSGPz+nEM63XrC0l6lDLCgFGdLRXYuzpa6aTYIc90JCNwKBgFUO\nzGI3UM0prN5i7WS4RDhLFnsMQAIo9Ag+XFymA/rJ28yFlV8tFDK2s0D2IfID5UuI\nf9wfRTz0pAiRoin0xLrFRhj0j1Z+y3uv7vmxKF536/4gCBYgNQAS1cTbUNNdp2Pq\nM7IhuCUuxZVcXSIkdOAsG46rCkLowxB7kOoJQGQxAoGBAJ/z9uQKJJK2PhR8ZkP+\n7MP6Ets5a1gZeByvzIQl/2HIKRntc0JB/2jDz8kE51NpkUdCBns/5voCiHebtvce\nkOKqyU6wbiH0//2pcbDJFPoPZzAlXbHp4zGbUMM2vVfEs7E6BCyKS/W6bYDZPRfw\n4f8zChXbtQR2DNXZQgaYhe30\n-----END PRIVATE KEY-----\n",
    "client_email":
        "firebase-adminsdk-fbsvc@innovator-250f8.iam.gserviceaccount.com",
    "client_id": "110566247274362686947",
    "auth_uri": "https://accounts.google.com/o/oauth2/auth",
    "token_uri": "https://oauth2.googleapis.com/token",
    "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
    "client_x509_cert_url":
        "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-fbsvc%40innovator-250f8.iam.gserviceaccount.com",
    "universe_domain": "googleapis.com",
  };

  static Future<void> initialize() async {
    try {
      developer.log('🔥 Initializing FCMHandler...');

      _credentials = ServiceAccountCredentials.fromJson(_serviceAccountKey);
      const scopes = ['https://www.googleapis.com/auth/cloud-platform'];
      _authClient = await clientViaServiceAccount(_credentials!, scopes);
      _tokenExpiry = DateTime.now().add(const Duration(minutes: 50));

      developer.log('FCMHandler initialized successfully');
      await _testConnection();
    } catch (e) {
      developer.log(' Error initializing FCMHandler: $e');
      throw Exception('Failed to initialize FCMHandler: $e');
    }
  }

  static Future<void> _testConnection() async {
    try {
      developer.log(' Testing FCM connection...');

      final testPayload = {
        'validate_only': true,
        'message': {
          'topic': 'test-topic',
          'notification': {'title': 'Test', 'body': 'Test'},
        },
      };

      final response = await _authClient!.post(
        Uri.parse(_fcmEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(testPayload),
      );

      if (response.statusCode == 200 || response.statusCode == 400) {
        developer.log('FCM connection test successful');
      } else {
        developer.log(' FCM connection test failed: ${response.statusCode}');
      }
    } catch (e) {
      developer.log(' FCM connection test error: $e');
    }
  }

  static Future<void> _refreshAuthClientIfNeeded() async {
    if (_authClient == null ||
        _tokenExpiry == null ||
        DateTime.now().isAfter(_tokenExpiry!)) {
      developer.log(' Refreshing FCM auth client...');
      await initialize();
    }
  }

  // FIXED: Correct FCM v1 payload structure
  static Future<bool> sendToToken(
    String fcmToken, {
    required String title,
    required String body,
    String? type,
    String? screen,
    Map<String, dynamic>? data,
    String? clickAction,
  }) async {
    if (_authClient == null || _credentials == null) {
      developer.log(' FCMHandler not initialized, initializing now...');
      await initialize();
    }

    await _refreshAuthClientIfNeeded();

    try {
      developer.log('📤 === SENDING FCM TO TOKEN ===');
      developer.log('📤 Token: ${fcmToken.substring(0, 20)}...');
      developer.log('📤 Title: $title');
      developer.log(
        '📤 Body: ${body.length > 50 ? body.substring(0, 50) + "..." : body}',
      );
      developer.log('📤 Type: $type');

      // FIXED: Completely corrected FCM v1 payload structure
      final payload = {
        'message': {
          'token': fcmToken,
          'notification': {'title': title, 'body': body},
          'data': {
            'type': type ?? 'message',
            'screen': screen ?? '/chat',
            'click_action': clickAction ?? 'FLUTTER_NOTIFICATION_CLICK',
            ...?(data?.map((key, value) => MapEntry(key, value.toString()))),
          },
          'android': {
            'notification': {
              'channel_id': 'chat_messages', // Must match your app's channel
              'sound': 'default',
              'icon': '@mipmap/ic_launcher',
              'color': '#F48706',
              'tag': data?['chatId']?.toString(),
              // REMOVED: All invalid Android notification fields
              // priority, default_sound, default_vibrate_timings, default_light_settings
              // notification_priority, visibility are NOT supported here
            },
            'priority': 'high', // Priority belongs at android level
            'ttl': '3600s',
          },
          'apns': {
            'headers': {'apns-priority': '10', 'apns-push-type': 'alert'},
            'payload': {
              'aps': {
                'alert': {'title': title, 'body': body},
                'sound': 'default',
                'badge': 1,
                'category': 'MESSAGE_CATEGORY',
                // FIXED: Remove thread-id completely - it's causing the error
                // Only include if you really need it and ensure proper format
              },
              // FIXED: Custom data goes outside of 'aps'
              'chatId': data?['chatId']?.toString(),
              'senderId': data?['senderId']?.toString(),
              'type': type,
            },
          },
          'fcm_options': {'analytics_label': 'chat_message_direct'},
        },
      };

      final response = await _authClient!.post(
        Uri.parse(_fcmEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      developer.log('FCM Response: ${response.statusCode}');
      developer.log('FCM Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        developer.log(
          'FCM notification sent successfully: ${responseData['name']}',
        );
        return true;
      } else {
        developer.log(
          ' FCM notification failed: ${response.statusCode} - ${response.body}',
        );
        await _handleFCMError(response.statusCode, response.body);
        return false;
      }
    } catch (e) {
      developer.log(' Error sending FCM notification: $e');
      return false;
    }
  }

  // FIXED: Correct payload for user/topic notifications
  static Future<bool> sendToUser(
    String userId, {
    required String title,
    required String body,
    String? type,
    String? screen,
    Map<String, dynamic>? data,
    String? clickAction,
  }) async {
    if (_authClient == null || _credentials == null) {
      developer.log(' FCMHandler not initialized, initializing now...');
      await initialize();
    }

    await _refreshAuthClientIfNeeded();

    try {
      developer.log('📤 === SENDING FCM TO USER ===');
      developer.log('📤 User ID: $userId');
      developer.log('📤 Title: $title');
      developer.log(
        '📤 Body: ${body.length > 50 ? body.substring(0, 50) + "..." : body}',
      );

      final payload = {
        'message': {
          'topic': 'user_$userId',
          'notification': {'title': title, 'body': body},
          'data': {
            'type': type ?? 'message',
            'screen': screen ?? '/chat',
            'click_action': clickAction ?? 'FLUTTER_NOTIFICATION_CLICK',
            'userId': userId,
            ...?(data?.map((key, value) => MapEntry(key, value.toString()))),
          },
          'android': {
            'notification': {
              'channel_id': 'chat_messages',
              'sound': 'default',
              'icon': '@mipmap/ic_launcher',
              'color': '#F48706',
              'tag': data?['chatId']?.toString(),
              // REMOVED all invalid fields
            },
            'priority': 'high',
            'ttl': '3600s',
          },
          'apns': {
            'headers': {'apns-priority': '10', 'apns-push-type': 'alert'},
            'payload': {
              'aps': {
                'alert': {'title': title, 'body': body},
                'sound': 'default',
                'badge': 1,
                'category': 'MESSAGE_CATEGORY',
                // REMOVED thread-id
              },
              'chatId': data?['chatId']?.toString(),
              'userId': userId,
              'type': type,
            },
          },
          'fcm_options': {'analytics_label': 'chat_message_topic'},
        },
      };

      final response = await _authClient!.post(
        Uri.parse(_fcmEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      developer.log('FCM Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        developer.log('FCM notification sent successfully to user: $userId');
        developer.log('Message ID: ${responseData['name']}');
        return true;
      } else {
        developer.log(
          ' FCM notification failed: ${response.statusCode} - ${response.body}',
        );
        await _handleFCMError(response.statusCode, response.body);
        return false;
      }
    } catch (e) {
      developer.log(' Error sending FCM notification: $e');
      return false;
    }
  }

  static Future<bool> sendToTopic(
    String topic, {
    required String title,
    required String body,
    String? type,
    String? screen,
    Map<String, dynamic>? data,
    String? clickAction,
  }) async {
    if (_authClient == null || _credentials == null) {
      developer.log(' FCMHandler not initialized, initializing now...');
      await initialize();
    }

    await _refreshAuthClientIfNeeded();

    try {
      developer.log('📤 === SENDING FCM TO TOPIC ===');
      developer.log('📤 Topic: $topic');

      final payload = {
        'message': {
          'topic': topic,
          'notification': {'title': title, 'body': body},
          'data': {
            'type': type ?? 'general',
            'screen': screen ?? '/home',
            'click_action': clickAction ?? 'FLUTTER_NOTIFICATION_CLICK',
            'topic': topic,
            ...?(data?.map((key, value) => MapEntry(key, value.toString()))),
          },
          'android': {
            'notification': {
              'channel_id': 'general_notifications',
              'sound': 'default',
              'icon': '@mipmap/ic_launcher',
              'color': '#F48706',
            },
            'priority': 'normal',
          },
          'apns': {
            'payload': {
              'aps': {
                'alert': {'title': title, 'body': body},
                'sound': 'default',
                'badge': 1,
              },
              'topic': topic,
              'type': type,
            },
          },
        },
      };

      final response = await _authClient!.post(
        Uri.parse(_fcmEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        developer.log('FCM notification sent successfully to topic: $topic');
        return true;
      } else {
        developer.log(
          ' FCM notification failed: ${response.statusCode} - ${response.body}',
        );
        return false;
      }
    } catch (e) {
      developer.log(' Error sending FCM notification: $e');
      return false;
    }
  }

  static Future<void> _handleFCMError(
    int statusCode,
    String responseBody,
  ) async {
    try {
      final errorData = jsonDecode(responseBody);
      final errorCode = errorData['error']?['code'];
      final errorMessage = errorData['error']?['message'];

      developer.log(' FCM Error Details:');
      developer.log('   Status Code: $statusCode');
      developer.log('   Error Code: $errorCode');
      developer.log('   Error Message: $errorMessage');

      switch (statusCode) {
        case 400:
          developer.log(' Bad Request - Check payload format');
          // Log specific field violations
          final details = errorData['error']?['details'] as List<dynamic>?;
          if (details != null) {
            for (var detail in details) {
              if (detail.containsKey('fieldViolations')) {
                final violations = detail['fieldViolations'] as List<dynamic>;
                for (var violation in violations) {
                  developer.log('   Field: ${violation['field']}');
                  developer.log('   Issue: ${violation['description']}');
                }
              }
            }
          }
          break;
        case 401:
          developer.log(
            ' Unauthorized - Token may have expired, refreshing...',
          );
          await initialize();
          break;
        case 403:
          developer.log(' Forbidden - Check project permissions');
          break;
        case 404:
          developer.log(' Not Found - Invalid registration token or topic');
          break;
        case 429:
          developer.log(' Too Many Requests - Rate limited');
          break;
        case 500:
          developer.log(' Internal Server Error - Retry later');
          break;
        case 503:
          developer.log(' Service Unavailable - FCM service down');
          break;
        default:
          developer.log(' Unknown error: $statusCode');
      }
    } catch (e) {
      developer.log(' Error parsing FCM error response: $e');
    }
  }

  // Test method to verify FCM setup
  static Future<bool> sendTestNotification(String fcmToken) async {
    return await sendToToken(
      fcmToken,
      title: 'Test Notification',
      body: 'This is a test notification from your Flutter app!',
      type: 'test',
      data: {'test': 'true', 'timestamp': DateTime.now().toIso8601String()},
    );
  }

  // Batch send to multiple tokens
  static Future<List<bool>> sendToMultipleTokens(
    List<String> fcmTokens, {
    required String title,
    required String body,
    String? type,
    String? screen,
    Map<String, dynamic>? data,
    String? clickAction,
  }) async {
    final results = <bool>[];

    developer.log('📤 Sending to ${fcmTokens.length} tokens...');

    for (final token in fcmTokens) {
      final result = await sendToToken(
        token,
        title: title,
        body: body,
        type: type,
        screen: screen,
        data: data,
        clickAction: clickAction,
      );
      results.add(result);

      // Small delay to avoid rate limiting
      await Future.delayed(const Duration(milliseconds: 100));
    }

    final successCount = results.where((r) => r).length;
    developer.log(
      'Batch send completed: $successCount/${fcmTokens.length} successful',
    );

    return results;
  }

  static void dispose() {
    try {
      _authClient?.close();
      _authClient = null;
      _credentials = null;
      _tokenExpiry = null;
      developer.log('FCMHandler disposed');
    } catch (e) {
      developer.log(' Error disposing FCMHandler: $e');
    }
  }

  static Future<bool> isHealthy() async {
    try {
      if (_authClient == null || _credentials == null) {
        return false;
      }

      if (_tokenExpiry != null && DateTime.now().isAfter(_tokenExpiry!)) {
        return false;
      }

      return true;
    } catch (e) {
      developer.log(' Health check failed: $e');
      return false;
    }
  }
}
