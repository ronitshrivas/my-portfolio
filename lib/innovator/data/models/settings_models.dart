/// User settings mirrored from ProfileService `GET /api/settings`.
///
/// Every field is present on GET. Keys are the exact snake_case the backend
/// uses so [toJson] round-trips and partial PATCH bodies use matching names.
class SettingsModel {
  const SettingsModel({
    this.pushEnabled = true,
    this.notifyLikes = true,
    this.notifyComments = true,
    this.notifyFollows = true,
    this.notifyMentions = true,
    this.notifyMessages = true,
    this.notifyReposts = true,
    this.emailDigest = false,
    this.privateAccount = false,
    this.whoCanMessage = 'everyone',
    this.whoCanComment = 'everyone',
    this.showActivityStatus = true,
    this.showInSearch = true,
    this.language = 'en',
    this.theme = 'system',
    this.timezone,
  });

  final bool pushEnabled;
  final bool notifyLikes;
  final bool notifyComments;
  final bool notifyFollows;
  final bool notifyMentions;
  final bool notifyMessages;
  final bool notifyReposts;
  final bool emailDigest;

  final bool privateAccount;

  /// One of: everyone | followers | none.
  final String whoCanMessage;

  /// One of: everyone | followers | none.
  final String whoCanComment;

  final bool showActivityStatus;
  final bool showInSearch;

  final String language;

  /// One of: system | light | dark.
  final String theme;
  final String? timezone;

  factory SettingsModel.fromJson(Map<String, dynamic> json) {
    bool boolOf(String key, bool fallback) =>
        json[key] is bool ? json[key] as bool : fallback;
    String strOf(String key, String fallback) {
      final value = json[key];
      return value is String && value.isNotEmpty ? value : fallback;
    }

    return SettingsModel(
      pushEnabled: boolOf('push_enabled', true),
      notifyLikes: boolOf('notify_likes', true),
      notifyComments: boolOf('notify_comments', true),
      notifyFollows: boolOf('notify_follows', true),
      notifyMentions: boolOf('notify_mentions', true),
      notifyMessages: boolOf('notify_messages', true),
      notifyReposts: boolOf('notify_reposts', true),
      emailDigest: boolOf('email_digest', false),
      privateAccount: boolOf('private_account', false),
      whoCanMessage: strOf('who_can_message', 'everyone'),
      whoCanComment: strOf('who_can_comment', 'everyone'),
      showActivityStatus: boolOf('show_activity_status', true),
      showInSearch: boolOf('show_in_search', true),
      language: strOf('language', 'en'),
      theme: strOf('theme', 'system'),
      timezone: json['timezone'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'push_enabled': pushEnabled,
        'notify_likes': notifyLikes,
        'notify_comments': notifyComments,
        'notify_follows': notifyFollows,
        'notify_mentions': notifyMentions,
        'notify_messages': notifyMessages,
        'notify_reposts': notifyReposts,
        'email_digest': emailDigest,
        'private_account': privateAccount,
        'who_can_message': whoCanMessage,
        'who_can_comment': whoCanComment,
        'show_activity_status': showActivityStatus,
        'show_in_search': showInSearch,
        'language': language,
        'theme': theme,
        'timezone': timezone,
      };

  SettingsModel copyWith({
    bool? pushEnabled,
    bool? notifyLikes,
    bool? notifyComments,
    bool? notifyFollows,
    bool? notifyMentions,
    bool? notifyMessages,
    bool? notifyReposts,
    bool? emailDigest,
    bool? privateAccount,
    String? whoCanMessage,
    String? whoCanComment,
    bool? showActivityStatus,
    bool? showInSearch,
    String? language,
    String? theme,
    String? timezone,
  }) {
    return SettingsModel(
      pushEnabled: pushEnabled ?? this.pushEnabled,
      notifyLikes: notifyLikes ?? this.notifyLikes,
      notifyComments: notifyComments ?? this.notifyComments,
      notifyFollows: notifyFollows ?? this.notifyFollows,
      notifyMentions: notifyMentions ?? this.notifyMentions,
      notifyMessages: notifyMessages ?? this.notifyMessages,
      notifyReposts: notifyReposts ?? this.notifyReposts,
      emailDigest: emailDigest ?? this.emailDigest,
      privateAccount: privateAccount ?? this.privateAccount,
      whoCanMessage: whoCanMessage ?? this.whoCanMessage,
      whoCanComment: whoCanComment ?? this.whoCanComment,
      showActivityStatus: showActivityStatus ?? this.showActivityStatus,
      showInSearch: showInSearch ?? this.showInSearch,
      language: language ?? this.language,
      theme: theme ?? this.theme,
      timezone: timezone ?? this.timezone,
    );
  }
}
