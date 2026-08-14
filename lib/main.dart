
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';

import 'services/app_state.dart';
import 'services/whisper_service.dart';

import 'themes/theme_provider.dart';
import 'models/user.dart';

import 'screens/splash/dynamic_welcome_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/citizen/citizen_nav_holder.dart';
import 'screens/ward_admin/admin_dashboard.dart';
import 'screens/super_admin/super_dashboard.dart';
import 'screens/category_officer/officer_dashboard.dart';
import 'screens/mandal_officer/mandal_dashboard.dart';
import 'widgets/shared_officer_widgets.dart';
import 'models/complaint.dart';


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

  // Load Groq (or OpenAI) API key into WhisperService for cloud Whisper fallback.
  // Priority: GROQ_API_KEY first (gsk_...), then OPENAI_API_KEY (sk-...).
  // .trim() removes Windows \r\n line endings that dotenv may leave in the value.
  final groqKey = (dotenv.env['GROQ_API_KEY'] ?? '').trim();
  final openAiKey = (dotenv.env['OPENAI_API_KEY'] ?? '').trim();
  debugPrint('[main] GROQ_API_KEY loaded: "${groqKey.length > 8 ? groqKey.substring(0, 8) + "..." : groqKey}"');
  final cloudKey = groqKey.startsWith('gsk_') ? groqKey
      : openAiKey.startsWith('sk-') ? openAiKey
      : '';
  if (cloudKey.isNotEmpty) {
    WhisperService.setApiKey(cloudKey);
    debugPrint('[main] Cloud Whisper fallback enabled (${cloudKey.startsWith('gsk_') ? 'Groq' : 'OpenAI'}).');
  } else {
    debugPrint('[main] No valid cloud API key — Whisper will use self-hosted server only.');
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

    if (user == null) {
      return const DynamicWelcomeScreen();
    }

    Widget activeFlow;
    switch (user.role) {
      case UserRole.citizen:
        activeFlow = const CitizenNavHolder();
        break;
      case UserRole.wardAdmin:
        activeFlow = const AdminNavHolder();
        break;
      case UserRole.categoryOfficer:
        activeFlow = const OfficerNavHolder();
        break;
      case UserRole.mandalOfficer:
        activeFlow = const MandalAdminNavHolder();
        break;
      case UserRole.superAdmin:
        activeFlow = const SuperAdminNavHolder();
        break;
      default:
        activeFlow = const LoginScreen();
        break;
    }

    return EscalationPopupWrapper(child: activeFlow);
  }
}

class EscalationPopupWrapper extends StatefulWidget {
  final Widget child;
  const EscalationPopupWrapper({super.key, required this.child});

  @override
  State<EscalationPopupWrapper> createState() => _EscalationPopupWrapperState();
}

class _EscalationPopupWrapperState extends State<EscalationPopupWrapper> {
  bool _isShowingDialog = false;

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final user = appState.currentUser;

    if (user != null && !_isShowingDialog) {
      final pendingComplaint = appState.getPendingEscalationPopup(user);
      if (pendingComplaint != null) {
        _isShowingDialog = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _showEscalationAlert(context, pendingComplaint, appState);
          }
        });
      }
    }

    return widget.child;
  }

  void _showEscalationAlert(BuildContext context, Complaint c, AppState appState) {
    final isTelugu = appState.isTelugu;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isTelugu ? '🚨 అత్యవసర / కేటాయించిన ఫిర్యాదు!' : '🚨 Escalated Complaint Alert!',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isTelugu
                  ? 'మీకు కొత్త ఫిర్యాదు నివేదించబడింది/కేటాయించబడింది:'
                  : 'A complaint has been escalated & assigned to your queue:',
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ID: #${c.id.length > 8 ? c.id.substring(0, 8).toUpperCase() : c.id}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${isTelugu ? "వర్గం" : "Category"}: ${c.category}',
                    style: const TextStyle(fontSize: 12, color: Colors.blueAccent, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${isTelugu ? "వార్డు" : "Ward"}: ${c.wardName} (${c.mandalName})',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    c.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              appState.acknowledgeEscalationPopup(c.id);
              Navigator.pop(dialogCtx);
              setState(() => _isShowingDialog = false);
            },
            child: Text(isTelugu ? 'తరువాత చూడండి' : 'Dismiss'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              appState.acknowledgeEscalationPopup(c.id);
              Navigator.pop(dialogCtx);
              setState(() => _isShowingDialog = false);
              ComplaintDetailsModal.show(context, c, isTelugu);
            },
            child: Text(isTelugu ? 'వివరాలు చూడండి' : 'View Details'),
          ),
        ],
      ),
    );
  }
}