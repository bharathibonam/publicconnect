class AppConfig {
  final String id;
  final String politicianName;
  final String politicianRole;
  final String constituencyName;
  final String? partyLogoUrl;
  final String? politicianImageUrl;
  final DateTime? updatedAt;

  AppConfig({
    required this.id,
    required this.politicianName,
    required this.politicianRole,
    required this.constituencyName,
    this.partyLogoUrl,
    this.politicianImageUrl,
    this.updatedAt,
  });

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    return AppConfig(
      id: json['id'] as String,
      politicianName: json['politicianName'] as String,
      politicianRole: json['politicianRole'] as String,
      constituencyName: json['constituencyName'] as String,
      partyLogoUrl: json['partyLogoUrl'] as String?,
      politicianImageUrl: json['politicianImageUrl'] as String?,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'politicianName': politicianName,
      'politicianRole': politicianRole,
      'constituencyName': constituencyName,
      'partyLogoUrl': partyLogoUrl,
      'politicianImageUrl': politicianImageUrl,
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
