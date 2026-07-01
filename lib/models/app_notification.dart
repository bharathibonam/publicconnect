class AppNotification {
  final String id;
  final String userId;
  final String title;
  final String body;
  final DateTime createdAt;
  bool isRead;
  final String? complaintId;     // for complaint / ward_update notifications
  final String? announcementId;  // for announcement notifications (links to announcements table)
  final String? type;            // legacy field — kept for backward compat
  final String? notificationType; // canonical type: 'announcement' | 'complaint' | 'ward_update' | 'broadcast' | 'system'
  final String? receiverRole;
  final String? referenceId;
  DateTime? readAt;

  AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.createdAt,
    this.isRead = false,
    this.complaintId,
    this.announcementId,
    this.type,
    this.notificationType,
    this.receiverRole,
    this.referenceId,
    this.readAt,
  });

  /// Returns the effective notification type, preferring notificationType over type.
  String get effectiveType => notificationType ?? type ?? 'system';

  /// Returns true if this notification links to an announcement.
  bool get isAnnouncementNotification =>
      announcementId != null ||
      effectiveType == 'announcement' ||
      effectiveType == 'broadcast';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'body': body,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'isRead': isRead,
      'complaintId': complaintId,
      'type': type,
      if (announcementId != null) 'announcement_id': announcementId,
      if (notificationType != null) 'notification_type': notificationType,
      if (receiverRole != null) 'receiver_role': receiverRole,
      if (referenceId != null) 'reference_id': referenceId,
      if (readAt != null) 'read_at': readAt!.toUtc().toIso8601String(),
    };
  }

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'] ?? '',
      // DB uses "userId" (camelCase) for existing column
      userId: map['userId'] ?? map['user_id'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      // DB uses "createdAt" (camelCase) for existing column
      createdAt: DateTime.tryParse(
                   (map['createdAt'] ?? map['created_at'] ?? '').toString(),
                 )?.toLocal() ?? DateTime.now(),
      isRead: map['isRead'] ?? map['is_read'] ?? false,
      complaintId: map['complaintId'] ?? map['complaint_id'],
      announcementId: map['announcement_id'],
      type: map['type'],
      notificationType: map['notification_type'],
      receiverRole: map['receiver_role'],
      referenceId: map['reference_id'] ?? map['referenceId'],
      readAt: map['read_at'] != null
          ? DateTime.tryParse(map['read_at'].toString())?.toLocal()
          : null,
    );
  }
}
