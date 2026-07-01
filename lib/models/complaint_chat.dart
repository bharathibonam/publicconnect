class ComplaintChat {
  final String id;
  final String complaintId;
  final DateTime createdAt;
  final DateTime lastMessageAt;

  ComplaintChat({
    required this.id,
    required this.complaintId,
    required this.createdAt,
    required this.lastMessageAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'complaint_id': complaintId,
      'created_at': createdAt.toUtc().toIso8601String(),
      'last_message_at': lastMessageAt.toUtc().toIso8601String(),
    };
  }

  factory ComplaintChat.fromMap(Map<String, dynamic> map) {
    return ComplaintChat(
      id: map['id'] ?? '',
      complaintId: map['complaint_id'] ?? '',
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '')?.toLocal() ?? DateTime.now(),
      lastMessageAt: DateTime.tryParse(map['last_message_at']?.toString() ?? '')?.toLocal() ?? DateTime.now(),
    );
  }
}
