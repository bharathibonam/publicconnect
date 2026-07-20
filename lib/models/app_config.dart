class AppConfig {
  final String id;
  final String politicianName;
  final String politicianRole;
  final String constituencyName;
  final String? politicianNameTe;
  final String? politicianRoleTe;
  final String? constituencyNameTe;
  final String? partyLogoUrl;
  final String? politicianImageUrl;
  final DateTime? updatedAt;

  AppConfig({
    required this.id,
    required this.politicianName,
    required this.politicianRole,
    required this.constituencyName,
    this.politicianNameTe,
    this.politicianRoleTe,
    this.constituencyNameTe,
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
      politicianNameTe: json['politicianNameTe'] as String?,
      politicianRoleTe: json['politicianRoleTe'] as String?,
      constituencyNameTe: json['constituencyNameTe'] as String?,
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
      'politicianNameTe': politicianNameTe,
      'politicianRoleTe': politicianRoleTe,
      'constituencyNameTe': constituencyNameTe,
      'partyLogoUrl': partyLogoUrl,
      'politicianImageUrl': politicianImageUrl,
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
