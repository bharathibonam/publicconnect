class ChatMessage {
  final String id;
  final String complaintId;
  final String senderId;
  final String receiverId;
  final String message;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.complaintId,
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'complaintId': complaintId,
      'senderId': senderId,
      'receiverId': receiverId,
      'message': message,
      'createdAt': createdAt.toUtc().toIso8601String(),
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] ?? '',
      complaintId: map['complaintId'] ?? '',
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      message: map['message'] ?? '',
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '')?.toLocal() ?? DateTime.now(),
    );
  }
}
