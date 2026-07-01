class BroadcastAlert {
  final String id;
  final String title;
  final String description;
  final String wardId; // 'global' or ward_X
  final String wardName; // Target ward name (empty if global)
  final String createdBy; // Name of publisher
  final String createdByRole; // 'wardAdmin' or 'superAdmin'
  final DateTime createdAt;
  final String targetAudience; // 'citizens' or 'admins'
  final String? audioUrl; // Path/URI to the voice memo attachment

  BroadcastAlert({
    required this.id,
    required this.title,
    required this.description,
    required this.wardId,
    this.wardName = '',
    required this.createdBy,
    required this.createdByRole,
    required this.createdAt,
    this.targetAudience = 'citizens',
    this.audioUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'wardId': wardId,
      'wardName': wardName,
      'createdBy': createdBy,
      'createdByRole': createdByRole,
      'createdAt': createdAt.toIso8601String(),
      'targetAudience': targetAudience,
      'audioUrl': audioUrl,
    };
  }

  factory BroadcastAlert.fromMap(Map<String, dynamic> map) {
    return BroadcastAlert(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      wardId: map['wardId'] ?? 'global',
      wardName: map['wardName'] ?? '',
      createdBy: map['createdBy'] ?? '',
      createdByRole: map['createdByRole'] ?? '',
      createdAt: map['createdAt'] != null
          ? (DateTime.tryParse(map['createdAt'].toString().endsWith('Z') 
              ? map['createdAt'].toString() 
              : '${map['createdAt']}Z') ?? DateTime.now())
          : DateTime.now(),
      targetAudience: map['targetAudience'] ?? 'citizens',
      audioUrl: map['audioUrl'],
    );
  }
}
