import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'party_theme_config.dart';
import '../models/user.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _boxName = 'theme_settings';
  static const String _activePartyKey = 'active_party_id';

  PartyThemeConfig _baseParty = PartyThemeConfig.tdp;
  ThemeData _themeData = _buildThemeData(PartyThemeConfig.tdp);
  User? _currentUser;

  PartyThemeConfig get activeParty {
    if (_currentUser != null) {
      if (_currentUser!.role == UserRole.wardAdmin) {
        return PartyThemeConfig.violetOfficerTheme;
      }
      if (_currentUser!.role == UserRole.mandalOfficer || _currentUser!.role == UserRole.categoryOfficer) {
        return PartyThemeConfig.greenOfficerTheme;
      }
    }
    return _baseParty;
  }

  ThemeData get themeData => _themeData;

  ThemeProvider() {
    _loadTheme();
  }

  void updateUser(User? user) {
    if (_currentUser?.role != user?.role || _currentUser?.id != user?.id) {
      _currentUser = user;
      _refreshThemeData();
    }
  }

  void _refreshThemeData() {
    _themeData = _buildThemeData(activeParty);
    notifyListeners();
  }

  Future<void> _loadTheme() async {
    final box = await Hive.openBox(_boxName);
    final savedPartyId = box.get(_activePartyKey, defaultValue: 'tdp');
    
    _baseParty = PartyThemeConfig.availableThemes[savedPartyId] ?? PartyThemeConfig.tdp;
    _refreshThemeData();
  }

  Future<void> setActiveParty(String partyId) async {
    if (!PartyThemeConfig.availableThemes.containsKey(partyId)) return;
    
    _baseParty = PartyThemeConfig.availableThemes[partyId]!;
    _refreshThemeData();

    final box = await Hive.openBox(_boxName);
    await box.put(_activePartyKey, partyId);
  }

  static ThemeData _buildThemeData(PartyThemeConfig config) {
    return ThemeData(
      useMaterial3: true,
      primaryColor: config.primaryColor,
      scaffoldBackgroundColor: config.backgroundColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: config.primaryColor,
        primary: config.primaryColor,
        secondary: config.secondaryColor,
        surface: config.backgroundColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: config.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: config.primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: config.primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }
}

