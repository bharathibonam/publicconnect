import 'package:flutter/material.dart';

class PartyThemeConfig {
  final String id;
  final String partyName;
  final String mlaName;
  final String constituencyName;
  final String? logoUrl;
  final String? mlaPhotoUrl;
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final Color backgroundColor;
  final List<Color> chartColors;
  final Color cardAccentColor;
  final Color progressColor;
  final String bannerUrl;

  const PartyThemeConfig({
    required this.id,
    required this.partyName,
    required this.mlaName,
    required this.constituencyName,
    this.logoUrl,
    this.mlaPhotoUrl,
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    required this.backgroundColor,
    required this.chartColors,
    required this.cardAccentColor,
    required this.progressColor,
    required this.bannerUrl,
  });

  static const tdp = PartyThemeConfig(
    id: 'tdp',
    partyName: 'Telugu Desam Party',
    mlaName: 'Jyoothula Nehru',
    constituencyName: 'Jaggampeta',
    logoUrl: 'assets/images/tdp_logo.png', // Placeholder
    mlaPhotoUrl: 'assets/images/tdp_mla.png', // Placeholder
    primaryColor: Color(0xFFEBB62A),
    secondaryColor: Color(0xFFD89B00),
    accentColor: Color(0xFF005BAC),
    backgroundColor: Color(0xFFFFFDF7),
    chartColors: [Color(0xFFEBB62A), Color(0xFFD89B00), Color(0xFFFFD54F), Color(0xFF005BAC), Color(0xFF1E3A8A)],
    cardAccentColor: Color(0xFFEBB62A),
    progressColor: Color(0xFF005BAC),
    bannerUrl: 'assets/images/tdp_banner.png', // Fallback, will use existing banner asset
  );

  static const jsp = PartyThemeConfig(
    id: 'jsp',
    partyName: 'JSP',
    mlaName: 'Pawan Kalyan',
    constituencyName: 'Pithapuram',
    logoUrl: 'assets/images/jsp_logo.png', // Placeholder
    mlaPhotoUrl: 'assets/images/jsp_mla.png', // Placeholder
    primaryColor: Color(0xFFC8102E),
    secondaryColor: Color(0xFFE53935),
    accentColor: Color(0xFF8B0000),
    backgroundColor: Color(0xFFFFF7F8),
    chartColors: [Color(0xFFC8102E), Color(0xFFE53935), Color(0xFFFF5252), Color(0xFF8B0000), Color(0xFF4A0000)],
    cardAccentColor: Color(0xFFC8102E),
    progressColor: Color(0xFFE53935),
    bannerUrl: 'assets/images/jsp_banner.png', // Fallback, will use existing banner asset
  );

  static const greenOfficerTheme = PartyThemeConfig(
    id: 'green_officer',
    partyName: 'Administration',
    mlaName: '',
    constituencyName: '',
    primaryColor: Color(0xFF16A34A),
    secondaryColor: Color(0xFF22C55E),
    accentColor: Color(0xFF86EFAC),
    backgroundColor: Color(0xFFF7FFF8),
    chartColors: [Color(0xFF16A34A), Color(0xFF22C55E), Color(0xFF4ADE80), Color(0xFF86EFAC), Color(0xFF15803D)],
    cardAccentColor: Color(0xFF16A34A),
    progressColor: Color(0xFF16A34A),
    bannerUrl: '',
  );

  static const violetOfficerTheme = PartyThemeConfig(
    id: 'violet_officer',
    partyName: 'Field Operations',
    mlaName: '',
    constituencyName: '',
    primaryColor: Color(0xFF7C3AED),
    secondaryColor: Color(0xFF8B5CF6),
    accentColor: Color(0xFFA78BFA),
    backgroundColor: Color(0xFFFAF8FF),
    chartColors: [Color(0xFF7C3AED), Color(0xFF8B5CF6), Color(0xFFA78BFA), Color(0xFF6D28D9), Color(0xFF5B21B6)],
    cardAccentColor: Color(0xFF7C3AED),
    progressColor: Color(0xFF7C3AED),
    bannerUrl: '',
  );

  static const Map<String, PartyThemeConfig> availableThemes = {
    'tdp': tdp,
    'jsp': jsp,
  };

  Color get cardColor {
    if (id == 'tdp') return const Color(0xFFFAF8F0);
    return const Color(0xFFFFFFFF);
  }

  Color get borderColor {
    if (id == 'tdp') return const Color(0xFFE6D28A);
    if (id == 'jsp') return const Color(0xFFF0B0B0);
    return primaryColor.withValues(alpha: 0.2);
  }

  Color get primaryTextColor {
    if (id == 'tdp') return const Color(0xFF2D2D2D);
    return Colors.white;
  }

  Color get primaryHoverColor {
    if (id == 'tdp') return const Color(0xFFD9A520);
    if (id == 'jsp') return const Color(0xFFE84541);
    return primaryColor.withValues(alpha: 0.8);
  }

  Color get primaryActiveColor {
    if (id == 'tdp') return const Color(0xFFC9971A);
    if (id == 'jsp') return const Color(0xFFB22222);
    return primaryColor;
  }

  Color get textPrimaryColor => const Color(0xFF2D2D2D);
  Color get textSecondaryColor => const Color(0xFF666666);
}

