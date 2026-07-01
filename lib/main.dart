
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';

import 'services/app_state.dart';

import 'themes/theme_provider.dart';
import 'models/user.dart';

import 'screens/splash/dynamic_welcome_screen.dart';
import 'screens/citizen/citizen_nav_holder.dart';
import 'screens/ward_admin/admin_dashboard.dart';
import 'screens/super_admin/super_dashboard.dart';
import 'screens/category_officer/officer_dashboard.dart';
import 'screens/mandal_officer/mandal_dashboard.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive and open boxes
  await Hive.initFlutter();
  await Hive.openBox('app_settings');
  await Hive.openBox('local_complaints');
  await Hive.openBox('local_notifications');
  await Hive.openBox('local_broadcasts');
  await Hive.openBox('theme_settings');

  // Load Environment Variables
  try {
    await dotenv.load(fileName: "supabase.env");
  } catch (e) {
    debugPrint('Warning: supabase.env file not found or failed to load. Ensure you have created it.');
  }

  // Try Supabase init — app works in offline mode if it fails
  try {
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL'] ?? 'https://dummy.supabase.co',
      anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? 'dummy_key',
    );
  } catch (e) {
    debugPrint('Supabase init failed — running in offline mode: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
        ChangeNotifierProxyProvider<AppState, ThemeProvider>(
          create: (_) => ThemeProvider(),
          update: (_, appState, themeProvider) => themeProvider!..updateUser(appState.currentUser),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Smart Governance Portal',
          theme: themeProvider.themeData.copyWith(
            textTheme: appState.isTelugu 
                ? GoogleFonts.notoSansTeluguTextTheme(themeProvider.themeData.textTheme) 
                : GoogleFonts.poppinsTextTheme(themeProvider.themeData.textTheme),
          ),
          debugShowCheckedModeBanner: false,
          locale: appState.isTelugu ? const Locale('te') : const Locale('en'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', ''),
            Locale('te', ''),
          ],
          home: const MainGatekeeper(),
        );
      },
    );
  }
}

class MainGatekeeper extends StatelessWidget {
  const MainGatekeeper({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final user = appState.currentUser;

    Widget currentFlow;

    if (user == null) {
      currentFlow = const DynamicWelcomeScreen();
    } else {
      switch (user.role) {
        case UserRole.citizen:
          currentFlow = const CitizenNavHolder();
          break;
        case UserRole.wardAdmin:
          currentFlow = const AdminNavHolder();
          break;
        case UserRole.categoryOfficer:
          currentFlow = const OfficerNavHolder();
          break;
        case UserRole.mandalOfficer:
          currentFlow = const MandalAdminNavHolder();
          break;
        case UserRole.superAdmin:
          currentFlow = const SuperAdminNavHolder();
          break;
      }
    }

    return Scaffold(
      body: Stack(
        children: [
          currentFlow,
        ],
      ),
    );
  }
}