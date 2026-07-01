import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/complaint.dart';

class CustomMap extends StatefulWidget {
  final List<Complaint> complaints;
  final LatLng initialCenter;
  final double initialZoom;
  final bool isInteractiveSelection;
  final Function(LatLng)? onLocationSelected;
  final LatLng? selectedLocation;
  final VoidCallback? onMyLocationPressed;
  final bool showHeatmap;

  const CustomMap({
    super.key,
    required this.complaints,
    this.initialCenter = const LatLng(12.9716, 77.5946),
    this.initialZoom = 14.5,
    this.isInteractiveSelection = false,
    this.onLocationSelected,
    this.selectedLocation,
    this.onMyLocationPressed,
    this.showHeatmap = false,
  });

  @override
  State<CustomMap> createState() => _CustomMapState();
}

class _CustomMapState extends State<CustomMap>
    with SingleTickerProviderStateMixin {
  late MapController _mapController;
  LatLng? _currentSelectedLocation;
  bool _hasFittedBounds = false;

  late AnimationController _pulseAnim;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _currentSelectedLocation = widget.selectedLocation;

    _pulseAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    // Auto-fit bounds after the map is ready
    if (!widget.isInteractiveSelection && widget.complaints.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_hasFittedBounds) {
          _fitBoundsToComplaints();
        }
      });
    }
  }

  @override
  void dispose() {
    _pulseAnim.dispose();
    super.dispose();
  }

  void _fitBoundsToComplaints() {
    if (widget.complaints.isEmpty) return;

    double minLat = double.infinity;
    double maxLat = -double.infinity;
    double minLng = double.infinity;
    double maxLng = -double.infinity;

    for (final c in widget.complaints) {
      minLat = min(minLat, c.latitude);
      maxLat = max(maxLat, c.latitude);
      minLng = min(minLng, c.longitude);
      maxLng = max(maxLng, c.longitude);
    }

    // Add padding to bounds
    final latPad = max((maxLat - minLat) * 0.15, 0.003);
    final lngPad = max((maxLng - minLng) * 0.15, 0.003);

    try {
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds(
            LatLng(minLat - latPad, minLng - lngPad),
            LatLng(maxLat + latPad, maxLng + lngPad),
          ),
          padding: const EdgeInsets.all(24),
        ),
      );
      _hasFittedBounds = true;
    } catch (e) {
      debugPrint('Map fitBounds error: $e');
    }
  }

  /// Smoothly animate the map to a new center/zoom
  void _animatedMove(LatLng target, double zoom) {
    _mapController.move(target, zoom);
  }

  @override
  void didUpdateWidget(covariant CustomMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedLocation != oldWidget.selectedLocation &&
        widget.selectedLocation != null) {
      setState(() {
        _currentSelectedLocation = widget.selectedLocation;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _animatedMove(_currentSelectedLocation!, widget.initialZoom);
        }
      });
    }
    // Re-fit if complaints change and we're not in interactive mode
    if (!widget.isInteractiveSelection &&
        widget.complaints.length != oldWidget.complaints.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _fitBoundsToComplaints();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<CircleMarker> circles = [];
    if (widget.showHeatmap) {
      for (final c in widget.complaints) {
        // Count nearby complaints within ~500 meters (approx 0.005 degrees lat/lng square)
        int nearbyCount = 0;
        for (final other in widget.complaints) {
          final latDiff = c.latitude - other.latitude;
          final lngDiff = c.longitude - other.longitude;
          final distSq = (latDiff * latDiff) + (lngDiff * lngDiff);
          if (distSq <= 0.000025) {
            nearbyCount++;
          }
        }

        // Determine color based on density (Hotspot intensity)
        Color densityColor;
        if (nearbyCount >= 5) {
          densityColor = const Color(0xFFEF4444); // Critical hotspot: Vibrant Red
        } else if (nearbyCount >= 3) {
          densityColor = const Color(0xFFF97316); // High density: Orange
        } else if (nearbyCount >= 2) {
          densityColor = const Color(0xFFFBBF24); // Medium density: Amber/Yellow
        } else {
          densityColor = const Color(0xFF3B82F6); // Low density: Soothing Blue
        }

        // 1. Large Outer Glow
        circles.add(
          CircleMarker(
            point: LatLng(c.latitude, c.longitude),
            color: densityColor.withValues(alpha: 0.04),
            borderStrokeWidth: 0,
            useRadiusInMeter: true,
            radius: 500,
          ),
        );
        // 2. Mid Glow
        circles.add(
          CircleMarker(
            point: LatLng(c.latitude, c.longitude),
            color: densityColor.withValues(alpha: 0.09),
            borderStrokeWidth: 0,
            useRadiusInMeter: true,
            radius: 300,
          ),
        );
        // 3. Inner Hot Core
        circles.add(
          CircleMarker(
            point: LatLng(c.latitude, c.longitude),
            color: densityColor.withValues(alpha: 0.18),
            borderStrokeWidth: 0,
            useRadiusInMeter: true,
            radius: 120,
          ),
        );
      }
    }

    // Build category pin markers
    final List<Marker> markers = widget.complaints.map((complaint) {
      if (widget.showHeatmap) {
        // Minimal, elegant small indicator dots for heatmap mode to prevent visual clutter
        return Marker(
          point: LatLng(complaint.latitude, complaint.longitude),
          width: 14,
          height: 14,
          alignment: Alignment.center,
          child: GestureDetector(
            onTap: () => _showComplaintDetailPopup(context, complaint),
            child: Container(
              decoration: BoxDecoration(
                color: complaint.statusColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      return Marker(
        point: LatLng(complaint.latitude, complaint.longitude),
        width: 36,
        height: 44,
        alignment: Alignment.topCenter,
        child: GestureDetector(
          onTap: () => _showComplaintDetailPopup(context, complaint),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pin head with category icon
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: complaint.statusColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: complaint.statusColor.withValues(alpha: 0.40),
                      blurRadius: 6,
                      spreadRadius: 1,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  _getCategoryIcon(complaint.category),
                  color: Colors.white,
                  size: 16,
                ),
              ),
              // Pin pointer triangle
              CustomPaint(
                size: const Size(10, 8),
                painter: _PinPointerPainter(color: complaint.statusColor),
              ),
            ],
          ),
        ),
      );
    }).toList();

    // Pulsing marker for interactive selection
    if (widget.isInteractiveSelection && _currentSelectedLocation != null) {
      markers.add(
        Marker(
          point: _currentSelectedLocation!,
          width: 60,
          height: 60,
          alignment: Alignment.bottomCenter,
          child: AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, _) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  Transform.scale(
                    scale: 0.5 + _pulseAnim.value * 0.5,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).primaryColor.withValues(alpha: 0.20),
                      ),
                    ),
                  ),
                  Icon(
                    Icons.location_pin,
                    color: Theme.of(context).primaryColor,
                    size: 36,
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      )
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentSelectedLocation ?? widget.initialCenter,
              initialZoom: widget.initialZoom,
              minZoom: 4,
              maxZoom: 18,
              // Smoother interaction settings
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
              onTap: widget.isInteractiveSelection
                  ? (tapPosition, point) {
                      setState(() {
                        _currentSelectedLocation = point;
                      });
                      widget.onLocationSelected?.call(point);
                    }
                  : null,
            ),
            children: [
              // Clean, minimal tile layer — OpenStreetMap
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.fluttergov.publicconnect',
              ),
              if (widget.showHeatmap)
                IgnorePointer(child: CircleLayer(circles: circles)),
              MarkerLayer(markers: markers),
            ],
          ),

          // Instruction banner (interactive mode)
          if (widget.isInteractiveSelection)
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Card(
                elevation: 4,
                color: Colors.white.withValues(alpha: 0.95),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                child: Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Icon(Icons.touch_app_outlined, color: Theme.of(context).primaryColor, size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tap the map to pin exact location, or use "Use My Location" above.',
                          style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Map legend (non-interactive mode)
          if (!widget.isInteractiveSelection && widget.complaints.isNotEmpty)
            Positioned(
              bottom: 12,
              left: 12,
              child: Card(
                elevation: 3,
                color: Colors.white.withValues(alpha: 0.92),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _legendItem(Colors.blue.shade400, 'New'),
                      const SizedBox(height: 3),
                      _legendItem(Theme.of(context).primaryColor, 'In Progress'),
                      const SizedBox(height: 3),
                      _legendItem(Colors.green.shade500, 'Resolved'),
                    ],
                  ),
                ),
              ),
            ),

          // Zoom controls
          Positioned(
            bottom: 12,
            right: 12,
            child: Column(
              children: [
                _mapButton(
                  heroTag: 'zoom_in_map',
                  icon: Icons.add,
                  onTap: () => _animatedMove(
                      _mapController.camera.center,
                      _mapController.camera.zoom + 1),
                ),
                const SizedBox(height: 6),
                _mapButton(
                  heroTag: 'zoom_out_map',
                  icon: Icons.remove,
                  onTap: () => _animatedMove(
                      _mapController.camera.center,
                      _mapController.camera.zoom - 1),
                ),
                if (!widget.isInteractiveSelection && widget.complaints.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _mapButton(
                    heroTag: 'fit_all_map',
                    icon: Icons.fit_screen_outlined,
                    onTap: _fitBoundsToComplaints,
                  ),
                ],
                if (_currentSelectedLocation != null) ...[
                  const SizedBox(height: 6),
                  _mapButton(
                    heroTag: 'recenter_map',
                    icon: Icons.my_location,
                    onTap: () => _animatedMove(
                        _currentSelectedLocation!, widget.initialZoom),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(5),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _mapButton(
      {required String heroTag,
      required IconData icon,
      required VoidCallback onTap}) {
    return FloatingActionButton.small(
      heroTag: heroTag,
      backgroundColor: Colors.white,
      foregroundColor: Theme.of(context).primaryColor,
      elevation: 3,
      onPressed: onTap,
      child: Icon(icon, size: 18),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Pothole & Road Repair':
        return Icons.edit_road;
      case 'Waste Management':
        return Icons.delete_outline;
      case 'Streetlight Issues':
        return Icons.lightbulb_outline;
      case 'Water Leakage':
        return Icons.water_drop_outlined;
      case 'Drainage & Sewerage':
        return Icons.plumbing;
      case 'Electricity & Power Issues':
        return Icons.bolt;
      case 'Public Sanitation':
        return Icons.cleaning_services;
      case 'Agriculture & Irrigation':
        return Icons.agriculture;
      case 'Fallen Tree Obstruction':
        return Icons.park;
      case 'Sewage Overflow':
        return Icons.water;
      default:
        return Icons.warning_amber_rounded;
    }
  }

  void _showComplaintDetailPopup(BuildContext context, Complaint complaint) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: complaint.statusColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(_getCategoryIcon(complaint.category),
                  color: complaint.statusColor),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(complaint.category,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _badgeRow('Status', complaint.statusText, complaint.statusColor),
            const SizedBox(height: 6),
            _badgeRow('Priority', complaint.priorityText, complaint.priorityColor),
            const SizedBox(height: 12),
            const Text('Description:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(complaint.description,
                style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 10),
            if (complaint.address.isNotEmpty) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on_outlined,
                      size: 13, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(complaint.address,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
            ],
            if (complaint.wardName.isNotEmpty)
              Row(
                children: [
                  const Icon(Icons.map_outlined,
                      size: 13, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(complaint.wardName,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey)),
                  ),
                ],
              ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.person_outline,
                    size: 13, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  '${complaint.citizenName} • ${complaint.citizenPhone}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            Text(
              'Date: ${complaint.createdAt.day}/${complaint.createdAt.month}/${complaint.createdAt.year}',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _badgeRow(String label, String value, Color color) {
    return Row(
      children: [
        Text('$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(value,
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 11)),
        ),
      ],
    );
  }
}

/// Custom painter for the triangular pin pointer at the bottom of map markers
class _PinPointerPainter extends CustomPainter {
  final Color color;
  _PinPointerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
