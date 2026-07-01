class AnnouncementRead {
  final String id;
  final String announcementId;
  final String userId;
  final DateTime readAt;

  AnnouncementRead({
    required this.id,
    required this.announcementId,
    required this.userId,
    required this.readAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'announcement_id': announcementId,
      'user_id': userId,
      'read_at': readAt.toUtc().toIso8601String(),
    };
  }

  factory AnnouncementRead.fromMap(Map<String, dynamic> map) {
    return AnnouncementRead(
      id: map['id'] ?? '',
      announcementId: map['announcement_id'] ?? '',
      userId: map['user_id'] ?? '',
      readAt: DateTime.tryParse(map['read_at']?.toString() ?? '')?.toLocal() ?? DateTime.now(),
    );
  }
}
