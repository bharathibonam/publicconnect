import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import '../../models/app_config.dart';
import '../../services/app_state.dart';
import '../../themes/theme_provider.dart';
import '../auth/login_screen.dart';

class DynamicWelcomeScreen extends StatefulWidget {
  const DynamicWelcomeScreen({super.key});

  @override
  State<DynamicWelcomeScreen> createState() => _DynamicWelcomeScreenState();
}

class _DynamicWelcomeScreenState extends State<DynamicWelcomeScreen> {
  final Map<String, String> _translations = {};
  bool _isTranslating = false;
  String _lastConfigId = '';

  Future<void> _translateText(String text) async {
    if (_translations.containsKey(text)) return;
    try {
      final url = Uri.parse('https://translate.googleapis.com/translate_a/single?client=gtx&sl=en&tl=te&dt=t&q=${Uri.encodeComponent(text)}');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final translated = decoded[0][0][0] as String;
        if (mounted) {
          setState(() {
            _translations[text] = translated;
          });
        }
      }
    } catch (e) {
      // ignore
    }
  }

  void _translateConfig(AppConfig config) async {
    if (mounted) setState(() => _isTranslating = true);
    await Future.wait([
      _translateText(config.politicianName),
      _translateText(config.politicianRole),
      _translateText(config.constituencyName),
      _translateText('An initiative by'),
    ]);
    if (mounted) setState(() => _isTranslating = false);
  }

  String _getDynamicText(String englishText, bool isTelugu) {
    if (!isTelugu) return englishText;
    // Provide a better manual translation for "An initiative by" if Google translates it poorly
    if (englishText == 'An initiative by' && (_translations[englishText] == null || _translations[englishText] == 'ఒక చొరవ')) {
      return 'వీరి ఆధ్వర్యంలో';
    }
    return _translations[englishText] ?? englishText;
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final activeParty = themeProvider.activeParty;
    final theme = Theme.of(context);
    
    final config = appState.appConfig ?? AppConfig(
      id: 'default',
      politicianName: 'Jyoothula Nehru',
      politicianRole: 'Member of the Legislative Assembly of Andhra Pradesh',
      constituencyName: 'Jaggampeta',
      partyLogoUrl: null,
      politicianImageUrl: null,
    );
    final isTelugu = appState.isTelugu;

    final mlaName = (config.politicianName.isNotEmpty) ? config.politicianName : activeParty.mlaName;
    final mlaPhoto = config.politicianImageUrl ?? activeParty.mlaPhotoUrl;
    final logoUrl = config.partyLogoUrl ?? activeParty.logoUrl;
    final constituencyName = (config.constituencyName.isNotEmpty) ? config.constituencyName : activeParty.constituencyName;
    final mlaRole = (config.politicianRole.isNotEmpty) ? config.politicianRole : 'Member of the Legislative Assembly';

    // Translate dynamic text automatically when needed
    if (config.id != _lastConfigId) {
      _lastConfigId = config.id;
      _translateConfig(config);
    } else if (isTelugu && !_translations.containsKey(mlaName) && !_isTranslating) {
      _translateConfig(config);
    }

    final nameText = _getDynamicText(mlaName, isTelugu);
    final roleText = _getDynamicText(mlaRole, isTelugu);
    final constituencyText = _getDynamicText(constituencyName, isTelugu);

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.primaryColor.withValues(alpha: 0.1),
              theme.scaffoldBackgroundColor,
              theme.primaryColor.withValues(alpha: 0.1),
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
              const SizedBox(height: 20),
              // Main Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isTelugu ? 'స్మార్ట్' : 'SMART',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Theme.of(context).primaryColor, // Teal
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isTelugu ? 'గవర్నెన్స్' : 'GOVERNANCE',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A), // Dark Navy
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isTelugu ? 'సిస్టమ్' : 'SYSTEM',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: theme.primaryColor, 
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Subtitle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.remove, color: theme.primaryColor, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        isTelugu
                            ? 'మీ గుమ్మం వద్దకే డిజిటల్ సేవలు'
                            : 'Digital services at your doorstep',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.remove, color: theme.primaryColor, size: 20),
                    ],
                  ),
                ),
              ),
              
              const Spacer(flex: 1),

              // Dynamic Image Stack
              SizedBox(
                height: 250,
                width: double.infinity,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Background Party Logo/Color - Small & Top Left
                    Positioned(
                      top: 0,
                      left: 20,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 10,
                              spreadRadius: 2,
                            )
                          ],
                        ),
                        child: ClipOval(
                          child: logoUrl != null && logoUrl.isNotEmpty
                              ? (logoUrl.startsWith('http')
                                  ? Image.network(logoUrl, fit: BoxFit.cover)
                                  : (logoUrl.startsWith('assets/')
                                      ? Image.asset(logoUrl, fit: BoxFit.cover)
                                      : (kIsWeb
                                          ? const Icon(Icons.image_not_supported)
                                          : Image.file(File(logoUrl), fit: BoxFit.cover))))
                              : Container(color: theme.primaryColor.withValues(alpha: 0.5)),
                        ),
                      ),
                    ),
                    
                    // Politician Foreground Image - Large & Centered
                    if (mlaPhoto != null && mlaPhoto.isNotEmpty)
                      Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 6),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 15, spreadRadius: 3)
                          ],
                        ),
                        child: ClipOval(
                          child: mlaPhoto.startsWith('http')
                              ? Image.network(mlaPhoto, fit: BoxFit.cover, alignment: Alignment.topCenter)
                              : (mlaPhoto.startsWith('assets/')
                                  ? Image.asset(mlaPhoto, fit: BoxFit.cover, alignment: Alignment.topCenter)
                                  : (kIsWeb
                                      ? const Icon(Icons.person, size: 80, color: Colors.grey)
                                      : Image.file(File(mlaPhoto), fit: BoxFit.cover, alignment: Alignment.topCenter))),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Dynamic Text Details
              Text(
                _getDynamicText('An initiative by', isTelugu),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    isTelugu ? '$nameText ' : nameText,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.secondary, 
                    ),
                  ),
                  Text(
                    isTelugu ? 'గారు' : ' Garu',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  '$roleText - $constituencyText',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Location chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_on, color: theme.primaryColor, size: 20),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        constituencyText,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 2),

              // Language Selection Cards
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    // Telugu Card
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          appState.setLanguage(true);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isTelugu ? theme.primaryColor : Colors.grey.shade300,
                              width: isTelugu ? 2 : 1,
                            ),
                            boxShadow: [
                              if (isTelugu)
                                BoxShadow(
                                  color: theme.primaryColor.withValues(alpha: 0.2),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                )
                            ],
                          ),
                          child: Column(
                            children: [
                              CircleAvatar(
                                backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
                                child: Text('అ', style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'తెలుగు',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.primaryColor),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'తెలుగులో సేవలను చూడండి మరియు ఉపయోగించండి',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 10, color: Colors.black54),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: theme.primaryColor,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Center(
                                  child: Text('కొనసాగించండి', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // English Card
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          appState.setLanguage(false);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: !isTelugu ? theme.primaryColor : Colors.grey.shade300,
                              width: !isTelugu ? 2 : 1,
                            ),
                            boxShadow: [
                              if (!isTelugu)
                                BoxShadow(
                                  color: theme.primaryColor.withValues(alpha: 0.2),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                )
                            ],
                          ),
                          child: Column(
                            children: [
                              CircleAvatar(
                                backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
                                child: Text('A', style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'English',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.primaryColor),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'View and access services in English',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 10, color: Colors.black54),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: theme.primaryColor,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Center(
                                  child: Text('Continue', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Proceed Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 5,
                    ),
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen(isLoginMode: false)),
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isTelugu ? 'ముందుకు వెళ్ళండి' : 'PROCEED',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.arrow_forward, size: 24),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
