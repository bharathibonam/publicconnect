class WorkUpdate {
  final String id;
  final String title;
  final String description;
  final List<String> imageUrls;
  final String wardId;
  final String wardName;
  final String wardMemberId;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Optional fields for backward compatibility or UI convenience
  final String? location;
  final String? authorName;

  WorkUpdate({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrls,
    required this.wardId,
    required this.wardName,
    required this.wardMemberId,
    required this.createdAt,
    required this.updatedAt,
    this.location,
    this.authorName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'image_urls': imageUrls,
      'ward_id': wardId,
      'ward_name': wardName,
      'ward_member_id': wardMemberId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      if (location != null) 'location': location,
      if (authorName != null) 'author_name': authorName,
    };
  }

  factory WorkUpdate.fromMap(Map<String, dynamic> map) {
    return WorkUpdate(
      id: map['id']?.toString() ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? map['shortNote'] ?? '', // Fallback for old data
      imageUrls: List<String>.from(map['image_urls'] ?? map['imagePaths'] ?? []),
      wardId: map['ward_id'] ?? '',
      wardName: map['ward_name'] ?? map['wardName'] ?? '',
      wardMemberId: map['ward_member_id'] ?? map['authorId'] ?? '',
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : (map['completionDate'] != null ? DateTime.parse(map['completionDate']) : DateTime.now()),
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : DateTime.now(),
      location: map['location'],
      authorName: map['author_name'] ?? map['authorName'],
    );
  }
}
