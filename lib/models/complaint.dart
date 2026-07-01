import 'package:flutter/material.dart';

enum ComplaintStatus {
  submitted,
  inProgress,
  resolved,
}

enum ComplaintPriority {
  low,
  medium,
  high,
}

class Complaint {
  final String id;
  final String userId;
  final String citizenName;
  final String citizenPhone;
  final String category;
  final String description;
  final String? imageUrl;
  final String? resolvedImageUrl; // Resolution image uploaded by admin
  final String? voiceUrl;         // Voice complaint audio recording URL
  final double latitude;
  final double longitude;
  final String wardId;
  final String wardName;     // Human-readable ward display name
  final String villageName;  // Village name
  final String mandalName;   // Mandal name
  final String address;      // Reverse-geocoded street address
  final String? assignedOfficerId; // Officer assigned to this complaint
  final String deviceInfo;   // Device details (OS, network status etc)
  ComplaintStatus status;
  ComplaintPriority priority;
  final DateTime createdAt;
  DateTime? resolvedAt;      // When the complaint was resolved
  String? feedbackRating;    // Feedback rating (poor, good, excellent)
  bool isClosed;             // Whether the complaint case is closed
  bool isPushed;             // Whether the complaint is escalated/pushed
  String? pushedTo;          // Role the complaint is pushed to

  Complaint({
    required this.id,
    required this.userId,
    required this.citizenName,
    required this.citizenPhone,
    required this.category,
    required this.description,
    this.imageUrl,
    this.resolvedImageUrl,
    this.voiceUrl,
    required this.latitude,
    required this.longitude,
    required this.wardId,
    this.wardName = '',
    this.villageName = '',
    this.mandalName = '',
    this.address = '',
    this.assignedOfficerId,
    this.deviceInfo = 'Unknown Device',
    this.status = ComplaintStatus.submitted,
    this.priority = ComplaintPriority.low,
    required this.createdAt,
    this.resolvedAt,
    this.feedbackRating,
    this.isClosed = false,
    this.isPushed = false,
    this.pushedTo,
  });

  // ─── Status helpers ──────────────────────────────────────────────────────────

  Color get statusColor {
    switch (status) {
      case ComplaintStatus.submitted:
        return Colors.blue.shade400;
      case ComplaintStatus.inProgress:
        return Colors.amber.shade600;
      case ComplaintStatus.resolved:
        return Colors.green.shade500;
    }
  }

  String get statusText {
    switch (status) {
      case ComplaintStatus.submitted:
        return 'Submitted';
      case ComplaintStatus.inProgress:
        return 'In Progress';
      case ComplaintStatus.resolved:
        return 'Resolved';
    }
  }

  // ─── Priority helpers ────────────────────────────────────────────────────────

  Color get priorityColor {
    switch (priority) {
      case ComplaintPriority.low:
        return Colors.blue.shade400;
      case ComplaintPriority.medium:
        return Colors.orange.shade400;
      case ComplaintPriority.high:
        return Colors.deepOrange.shade600;
    }
  }

  String get priorityText {
    switch (priority) {
      case ComplaintPriority.low:
        return 'Low';
      case ComplaintPriority.medium:
        return 'Medium';
      case ComplaintPriority.high:
        return 'High';
    }
  }

  bool get isVideoEvidence {
    if (imageUrl == null || imageUrl!.isEmpty) return false;
    final url = imageUrl!.toLowerCase();
    return url.contains('.mp4') ||
        url.contains('.mov') ||
        url.contains('.3gp') ||
        url.contains('.mkv') ||
        url.startsWith('local_video:');
  }

  bool get isResolvedVideoEvidence {
    if (resolvedImageUrl == null || resolvedImageUrl!.isEmpty) return false;
    final url = resolvedImageUrl!.toLowerCase();
    return url.contains('.mp4') ||
        url.contains('.mov') ||
        url.contains('.3gp') ||
        url.contains('.mkv') ||
        url.startsWith('local_video:');
  }

  // ─── Serialization ───────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'citizenName': citizenName,
      'citizenPhone': citizenPhone,
      'category': category,
      'description': description,
      'imageUrl': imageUrl,
      'resolvedImageUrl': resolvedImageUrl,
      'voiceUrl': voiceUrl,
      'latitude': latitude,
      'longitude': longitude,
      'wardId': wardId,
      'wardName': wardName,
      'villageName': villageName,
      'mandalName': mandalName,
      'address': address,
      'assignedOfficerId': assignedOfficerId,
      'deviceInfo': deviceInfo,
      'status': status.toString().split('.').last,
      'priority': priority.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
      'resolvedAt': resolvedAt?.toIso8601String(),
      'feedbackRating': feedbackRating,
      'isClosed': isClosed,
      'isPushed': isPushed,
      'pushedTo': pushedTo,
    };
  }

  factory Complaint.fromMap(Map<String, dynamic> map) {
    try {
      return Complaint(
        id: map['id']?.toString() ?? '',
        userId: map['userId']?.toString() ?? '',
        citizenName: map['citizenName']?.toString() ?? '',
        citizenPhone: map['citizenPhone']?.toString() ?? '',
        category: map['category']?.toString() ?? '',
        description: map['description']?.toString() ?? '',
        imageUrl: map['imageUrl']?.toString(),
        resolvedImageUrl: map['resolvedImageUrl']?.toString(),
        voiceUrl: map['voiceUrl']?.toString(),
        latitude: double.tryParse(map['latitude']?.toString() ?? '') ?? 0.0,
        longitude: double.tryParse(map['longitude']?.toString() ?? '') ?? 0.0,
        wardId: map['wardId']?.toString() ?? '',
        wardName: map['wardName']?.toString() ?? '',
        villageName: map['villageName']?.toString() ?? '',
        mandalName: map['mandalName']?.toString() ?? '',
        address: map['address']?.toString() ?? '',
        assignedOfficerId: map['assignedOfficerId']?.toString(),
        deviceInfo: map['deviceInfo']?.toString() ?? 'Unknown Device',
        status: ComplaintStatus.values.firstWhere(
          (e) => e.toString().split('.').last == map['status']?.toString(),
          orElse: () => ComplaintStatus.submitted,
        ),
        priority: ComplaintPriority.values.firstWhere(
          (e) => e.toString().split('.').last == map['priority']?.toString(),
          orElse: () => ComplaintPriority.low,
        ),
        createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? DateTime.now(),
        resolvedAt: map['resolvedAt'] != null
            ? DateTime.tryParse(map['resolvedAt'].toString())
            : null,
        feedbackRating: map['feedbackRating']?.toString(),
        isClosed: map['isClosed'] == true || map['isClosed'] == 'true',
        isPushed: map['isPushed'] == true || map['isPushed'] == 'true',
        pushedTo: map['pushedTo']?.toString(),
      );
    } catch (e) {
      debugPrint('Error parsing complaint fromMap: $e');
      // Return a dummy error complaint so the stream doesn't crash completely.
      // This will be filtered out by UI if needed, or at least won't crash the whole list.
      return Complaint(
        id: map['id']?.toString() ?? 'error',
        userId: 'error',
        citizenName: 'Error Loading',
        citizenPhone: '',
        category: 'Error',
        description: 'Failed to load this complaint: $e',
        latitude: 0,
        longitude: 0,
        wardId: 'error',
        createdAt: DateTime.now(),
      );
    }
  }
}
