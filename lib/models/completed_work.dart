

class CompletedWork {
  final String id;
  final String complaintId;
  final String wardMemberId;
  final String citizenId;
  final String title;
  final String description;
  final String? beforeImageUrl;
  final String? afterImageUrl;
  final String? videoUrl;
  final String? voiceUrl;
  final String? pdfUrl;
  final String? remarks;
  final DateTime completedAt;
  final DateTime createdAt;
  final String status;
  
  // These are often joined for UI
  final String? category;
  final String? wardMemberName;

  CompletedWork({
    required this.id,
    required this.complaintId,
    required this.wardMemberId,
    required this.citizenId,
    required this.title,
    required this.description,
    this.beforeImageUrl,
    this.afterImageUrl,
    this.videoUrl,
    this.voiceUrl,
    this.pdfUrl,
    this.remarks,
    required this.completedAt,
    required this.createdAt,
    this.status = 'completed',
    this.category,
    this.wardMemberName,
  });

  factory CompletedWork.fromMap(Map<String, dynamic> map) {
    return CompletedWork(
      id: map['id'] ?? '',
      complaintId: map['complaint_id'] ?? '',
      wardMemberId: map['ward_member_id'] ?? '',
      citizenId: map['citizen_id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      beforeImageUrl: map['before_image_url'],
      afterImageUrl: map['after_image_url'],
      videoUrl: map['video_url'],
      voiceUrl: map['voice_url'],
      pdfUrl: map['pdf_url'],
      remarks: map['remarks'],
      completedAt: DateTime.tryParse(map['completed_at']?.toString() ?? '') ?? DateTime.now(),
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.now(),
      status: map['status'] ?? 'completed',
      category: map['complaints'] != null ? map['complaints']['category'] : null,
      wardMemberName: map['users'] != null ? map['users']['name'] : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'complaint_id': complaintId,
      'ward_member_id': wardMemberId,
      'citizen_id': citizenId,
      'title': title,
      'description': description,
      'before_image_url': beforeImageUrl,
      'after_image_url': afterImageUrl,
      'video_url': videoUrl,
      'voice_url': voiceUrl,
      'pdf_url': pdfUrl,
      'remarks': remarks,
      'completed_at': completedAt.toIso8601String(),
      'status': status,
    };
  }
}
