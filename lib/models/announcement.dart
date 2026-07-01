class Announcement {
  final String id;
  final String title;
  final String message;
  final String? attachmentUrl;
  final String? imageUrl;
  final String? voiceUrl;
  final String createdById;
  final String createdByRole;
  final String createdByName;
  final String? categoryScope;
  final String targetAudience;
  final String? targetMandal;
  final String? targetPanchayat;
  final String? targetWard;
  final String targetType;   // 'role' | 'ward' | 'village' | 'all'
  final String? targetId;    // role string, ward_id, etc. or null for 'all'
  final int totalSent;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Announcement({
    required this.id,
    required this.title,
    required this.message,
    this.attachmentUrl,
    this.imageUrl,
    this.voiceUrl,
    required this.createdById,
    required this.createdByRole,
    required this.createdByName,
    this.categoryScope,
    required this.targetAudience,
    this.targetMandal,
    this.targetPanchayat,
    this.targetWard,
    this.targetType = 'role',
    this.targetId,
    this.totalSent = 0,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'attachment_url': attachmentUrl,
      'image_url': imageUrl,
      'voice_url': voiceUrl,
      'pdf_url': attachmentUrl, // Insert duplicate or explicit pdf_url
      'created_by_id': createdById,
      'created_by_role': createdByRole,
      'created_by_name': createdByName,
      'sender_name': createdByName, // Insert explicitly
      'sender_role': createdByRole,
      'category_scope': categoryScope,
      'target_audience': targetAudience,
      'target_mandal': targetMandal,
      'target_panchayat': targetPanchayat,
      'target_ward': targetWard,
      'target_type': targetType,
      'target_id': targetId,
      'total_sent': totalSent,
      'created_at': createdAt.toUtc().toIso8601String(),
    };
  }

  factory Announcement.fromMap(Map<String, dynamic> map) {
    return Announcement(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      attachmentUrl: map['attachment_url'] ?? map['pdf_url'],
      imageUrl: map['image_url'],
      voiceUrl: map['voice_url'],
      createdById: map['created_by_id'] ?? '',
      createdByRole: map['sender_role'] ?? map['created_by_role'] ?? '',
      createdByName: map['sender_name'] ?? map['created_by_name'] ?? '',
      categoryScope: map['category_scope'],
      targetAudience: map['target_audience'] ?? '',
      targetMandal: map['target_mandal'],
      targetPanchayat: map['target_panchayat'],
      targetWard: map['target_ward'],
      targetType: map['target_type'] ?? 'role',
      targetId: map['target_id'],
      totalSent: map['total_sent'] ?? 0,
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '')?.toLocal() ?? DateTime.now(),
      updatedAt: map['updated_at'] != null ? DateTime.tryParse(map['updated_at'].toString())?.toLocal() : null,
    );
  }
}
