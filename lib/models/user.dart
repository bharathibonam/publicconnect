import 'package:flutter/foundation.dart';

enum UserRole {
  citizen,
  wardAdmin,
  superAdmin,
  categoryOfficer,
  mandalOfficer,
}

class User {
  final String id;
  final String name;
  final String phoneNumber;
  final String password;
  final UserRole role;
  final String? wardId;    // Assigned ward for wardAdmin/categoryOfficer, null for others
  final String? wardName;  // Display name of the assigned ward
  final String? mandalName;
  final String? villageName;
  final String? officerRole; // Assigned category for categoryOfficer (e.g. Water Supply Officer)
  final DateTime? createdAt;
  final String? profilePhotoUrl; // Uploaded profile photo url
  final String? profileImageUrl;
  final String? fcmToken;
  final bool isEmployed;
  final String education;

  User({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.password,
    required this.role,
    this.wardId,
    this.wardName,
    this.mandalName,
    this.villageName,
    this.officerRole,
    this.createdAt,
    this.profilePhotoUrl,
    this.profileImageUrl,
    this.fcmToken,
    this.isEmployed = false,
    this.education = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'password': password,
      'role': role.toString().split('.').last,
      'wardId': wardId,
      'wardName': wardName,
      'mandalName': mandalName,
      'villageName': villageName,
      'officerRole': officerRole,
      'createdAt': createdAt?.toIso8601String(),
      'profilePhotoUrl': profilePhotoUrl,
      'isEmployed': isEmployed,
      'education': education,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    try {
      return User(
        id: map['id']?.toString() ?? '',
        name: map['name']?.toString() ?? '',
        phoneNumber: map['phoneNumber']?.toString() ?? '',
        password: map['password']?.toString() ?? '',
        role: UserRole.values.firstWhere(
          (e) => e.toString().split('.').last.toLowerCase() == (map['role']?.toString().trim().toLowerCase() ?? ''),
          orElse: () => UserRole.citizen,
        ),
        wardId: map['wardId']?.toString(),
        wardName: map['wardName']?.toString(),
        mandalName: map['mandalName']?.toString(),
        villageName: map['villageName']?.toString(),
        officerRole: map['officerRole']?.toString(),
        createdAt: map['createdAt'] != null
            ? DateTime.tryParse(map['createdAt'].toString())
            : null,
        profilePhotoUrl: map['profilePhotoUrl']?.toString(),
        profileImageUrl: map['profileImageUrl']?.toString(),
        fcmToken: map['fcmToken']?.toString(),
        isEmployed: map['isEmployed'] == true,
        education: map['education']?.toString() ?? '',
      );
    } catch (e) {
      debugPrint('Error parsing user fromMap: $e');
      return User(
        id: map['id']?.toString() ?? 'error',
        name: 'Error',
        phoneNumber: '',
        password: '',
        role: UserRole.citizen,
      );
    }
  }
}
