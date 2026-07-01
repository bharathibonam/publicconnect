class Ward {
  final String id;
  final String name;
  final String adminId;
  final String adminName;
  // Representative center coordinates for mapping
  final double centerLatitude;
  final double centerLongitude;

  // Coordinate bounds (simple rectangle check for automatic assignment)
  final double minLat;
  final double maxLat;
  final double minLng;
  final double maxLng;

  Ward({
    required this.id,
    required this.name,
    required this.adminId,
    required this.adminName,
    required this.centerLatitude,
    required this.centerLongitude,
    required this.minLat,
    required this.maxLat,
    required this.minLng,
    required this.maxLng,
  });

  // Check if a point is within this ward
  bool contains(double lat, double lng) {
    return lat >= minLat && lat <= maxLat && lng >= minLng && lng <= maxLng;
  }
}
