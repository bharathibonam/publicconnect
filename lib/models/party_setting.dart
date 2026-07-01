import 'package:flutter/material.dart';

class PartySetting {
  final String id;
  final String partyName;
  final String? logoUrl;
  final String? partyIconUrl;
  final String? mlaName;
  final String? mlaPhotoUrl;
  final String? constituencyName;
  final String? primaryColor;
  final String? secondaryColor;
  final String? accentColor;
  final String? backgroundColor;
  final String? surfaceColor;
  final String? borderColor;
  final String? textColor;
  final String? successColor;
  final String? warningColor;
  final String? errorColor;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  PartySetting({
    required this.id,
    required this.partyName,
    this.logoUrl,
    this.partyIconUrl,
    this.mlaName,
    this.mlaPhotoUrl,
    this.constituencyName,
    this.primaryColor,
    this.secondaryColor,
    this.accentColor,
    this.backgroundColor,
    this.surfaceColor,
    this.borderColor,
    this.textColor,
    this.successColor,
    this.warningColor,
    this.errorColor,
    this.isActive = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PartySetting.fromMap(Map<String, dynamic> map) {
    return PartySetting(
      id: map['id'] ?? '',
      partyName: map['partyName'] ?? '',
      logoUrl: map['logoUrl'],
      partyIconUrl: map['partyIconUrl'],
      mlaName: map['mlaName'],
      mlaPhotoUrl: map['mlaPhotoUrl'],
      constituencyName: map['constituencyName'],
      primaryColor: map['primaryColor'],
      secondaryColor: map['secondaryColor'],
      accentColor: map['accentColor'],
      backgroundColor: map['backgroundColor'],
      surfaceColor: map['surfaceColor'],
      borderColor: map['borderColor'],
      textColor: map['textColor'],
      successColor: map['successColor'],
      warningColor: map['warningColor'],
      errorColor: map['errorColor'],
      isActive: map['isActive'] ?? false,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'partyName': partyName,
      'logoUrl': logoUrl,
      'partyIconUrl': partyIconUrl,
      'mlaName': mlaName,
      'mlaPhotoUrl': mlaPhotoUrl,
      'constituencyName': constituencyName,
      'primaryColor': primaryColor,
      'secondaryColor': secondaryColor,
      'accentColor': accentColor,
      'backgroundColor': backgroundColor,
      'surfaceColor': surfaceColor,
      'borderColor': borderColor,
      'textColor': textColor,
      'successColor': successColor,
      'warningColor': warningColor,
      'errorColor': errorColor,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Color? getPrimaryColor() => _parseColor(primaryColor);
  Color? getSecondaryColor() => _parseColor(secondaryColor);
  Color? getAccentColor() => _parseColor(accentColor);
  Color? getBackgroundColor() => _parseColor(backgroundColor);
  Color? getSurfaceColor() => _parseColor(surfaceColor);
  Color? getBorderColor() => _parseColor(borderColor);
  Color? getTextColor() => _parseColor(textColor);
  Color? getSuccessColor() => _parseColor(successColor);
  Color? getWarningColor() => _parseColor(warningColor);
  Color? getErrorColor() => _parseColor(errorColor);

  Color? _parseColor(String? hexColor) {
    if (hexColor == null || hexColor.isEmpty) return null;
    hexColor = hexColor.toUpperCase().replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    final int? value = int.tryParse(hexColor, radix: 16);
    return value != null ? Color(value) : null;
  }
}
