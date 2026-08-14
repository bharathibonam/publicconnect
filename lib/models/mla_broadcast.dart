enum BroadcastMediaType {
  reel,
  photo,
  document,
}

class MLABroadcast {
  final String id;
  final String title;
  final String description;
  final String mediaType; // 'reel', 'photo', 'document'
  final String? videoUrl;
  final String? photoUrl;
  final String? thumbnailUrl;
  final List<String> syndicatedPlatforms;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? scheduledAt;
  final DateTime? publishedAt;
  final String createdBy;
  final String visibility;
  final String status; // 'published', 'scheduled', 'draft', 'failed'
  final bool published;
  final bool isDeleted;
  final int views;
  final int likes;
  final int shares;

  MLABroadcast({
    required this.id,
    required this.title,
    required this.description,
    required this.mediaType,
    this.videoUrl,
    this.photoUrl,
    this.thumbnailUrl,
    required this.syndicatedPlatforms,
    required this.createdAt,
    this.updatedAt,
    this.scheduledAt,
    this.publishedAt,
    required this.createdBy,
    required this.visibility,
    required this.status,
    required this.published,
    required this.isDeleted,
    required this.views,
    required this.likes,
    required this.shares,
  });

  // Compatibility getters
  String get mediaUrl => videoUrl ?? photoUrl ?? '';
  BroadcastMediaType get type {
    if (mediaType == 'photo') return BroadcastMediaType.photo;
    if (mediaType == 'document') return BroadcastMediaType.document;
    return BroadcastMediaType.reel;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'media_type': mediaType,
        'video_url': videoUrl,
        'photo_url': photoUrl,
        'thumbnail_url': thumbnailUrl,
        'syndicated_platforms': syndicatedPlatforms,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
        'scheduled_at': scheduledAt?.toIso8601String(),
        'published_at': publishedAt?.toIso8601String(),
        'created_by': createdBy,
        'visibility': visibility,
        'status': status,
        'published': published,
        'is_deleted': isDeleted,
        'views': views,
        'likes': likes,
        'shares': shares,
      };

  factory MLABroadcast.fromJson(Map<String, dynamic> json) => MLABroadcast(
        id: json['id'] ?? '',
        title: json['title'] ?? '',
        description: json['description'] ?? '',
        mediaType: json['media_type'] ?? json['mediaType'] ?? (json['type'] ?? 'reel'),
        videoUrl: json['video_url'] ?? json['videoUrl'] ?? json['mediaUrl'],
        photoUrl: json['photo_url'] ?? json['photoUrl'] ?? json['mediaUrl'],
        thumbnailUrl: json['thumbnail_url'] ?? json['thumbnailUrl'],
        syndicatedPlatforms: List<String>.from(json['syndicated_platforms'] ?? json['syndicatedPlatforms'] ?? []),
        createdAt: json['created_at'] != null 
            ? DateTime.parse(json['created_at']) 
            : (json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now()),
        updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
        scheduledAt: json['scheduled_at'] != null ? DateTime.parse(json['scheduled_at']) : null,
        publishedAt: json['published_at'] != null ? DateTime.parse(json['published_at']) : null,
        createdBy: json['created_by'] ?? json['createdBy'] ?? 'mla',
        visibility: json['visibility'] ?? 'public',
        status: json['status'] ?? 'published',
        published: json['published'] ?? true,
        isDeleted: json['is_deleted'] ?? json['isDeleted'] ?? false,
        views: json['views'] ?? 0,
        likes: json['likes'] ?? 0,
        shares: json['shares'] ?? 0,
      );
}
