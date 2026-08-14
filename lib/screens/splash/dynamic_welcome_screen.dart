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
      politicianName: activeParty.mlaName,
      politicianRole: activeParty.id == 'bjp'
          ? 'Member of Parliament of Lok Sabha'
          : 'Member of the Legislative Assembly of AP',
      constituencyName: activeParty.constituencyName,
      partyLogoUrl: activeParty.logoUrl,
      politicianImageUrl: activeParty.mlaPhotoUrl,
    );
    final isTelugu = appState.isTelugu;

    final mlaName = (config.politicianName.isNotEmpty) ? config.politicianName : activeParty.mlaName;
    final mlaPhoto = config.politicianImageUrl ?? activeParty.mlaPhotoUrl;
    final logoUrl = config.partyLogoUrl ?? activeParty.logoUrl;
    final constituencyName = (config.constituencyName.isNotEmpty) ? config.constituencyName : activeParty.constituencyName;
    final mlaRole = (config.politicianRole.isNotEmpty) ? config.politicianRole : 'Member of Parliament of Lok Sabha';

    if (config.id != _lastConfigId) {
      _lastConfigId = config.id;
      _translateConfig(config);
    } else if (isTelugu && !_translations.containsKey(mlaName) && !_isTranslating) {
      _translateConfig(config);
    }

    final nameText = _getDynamicText(mlaName, isTelugu);
    final roleText = _getDynamicText(mlaRole, isTelugu);
    final constituencyText = _getDynamicText(constituencyName, isTelugu);

    final selectedBorderColor = activeParty.id == 'bjp' ? const Color(0xFFFF9933) : Colors.green;

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.primaryColor.withValues(alpha: 0.08),
              theme.scaffoldBackgroundColor,
              theme.primaryColor.withValues(alpha: 0.08),
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 8),
                          
                          // 1. HEADER
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  isTelugu ? 'స్మార్ట్ ' : 'SMART ',
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w900,
                                    color: theme.primaryColor,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Text(
                                  isTelugu ? 'గవర్నెన్స్ ' : 'GOVERNANCE ',
                                  style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF0F172A),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Text(
                                  isTelugu ? 'సిస్టమ్' : 'SYSTEM',
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w900,
                                    color: theme.primaryColor,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(width: 14, height: 1.5, color: theme.primaryColor),
                                const SizedBox(width: 6),
                                Text(
                                  isTelugu
                                      ? 'మీ గుమ్మం వద్దకే డిజిటల్ సేవలు'
                                      : 'Digital services at your doorstep',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(width: 14, height: 1.5, color: theme.primaryColor),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 16),

                          // 2. LOGO + PHOTO (Responsive Circular Frame with Badge)
                          SizedBox(
                            height: 180,
                            width: double.infinity,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Centered Circular Photo Frame
                                if (mlaPhoto != null && mlaPhoto.isNotEmpty)
                                  Container(
                                    width: 165,
                                    height: 165,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 4),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.black12,
                                          blurRadius: 12,
                                          spreadRadius: 2,
                                          offset: Offset(0, 4),
                                        )
                                      ],
                                    ),
                                    child: ClipOval(
                                      child: mlaPhoto.startsWith('http')
                                          ? Image.network(mlaPhoto, fit: BoxFit.cover, alignment: Alignment.topCenter)
                                          : (mlaPhoto.startsWith('assets/')
                                              ? Image.asset(mlaPhoto, fit: BoxFit.cover, alignment: Alignment.topCenter)
                                              : (kIsWeb
                                                  ? const Icon(Icons.person, size: 70, color: Colors.grey)
                                                  : Image.file(File(mlaPhoto), fit: BoxFit.cover, alignment: Alignment.topCenter))),
                                    ),
                                  ),
                                
                                // BJP Logo Badge - Top Left with safe spacing
                                Positioned(
                                  top: 4,
                                  left: (constraints.maxWidth > 0 ? (constraints.maxWidth - 165) / 2 - 20 : 40).clamp(10.0, 100.0).toDouble(),
                                  child: Container(
                                    width: 54,
                                    height: 54,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                      border: Border.all(color: Colors.grey.shade200, width: 1.5),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.black12,
                                          blurRadius: 8,
                                          spreadRadius: 1,
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
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          // 3. MLA INFORMATION
                          Text(
                            _getDynamicText('An initiative by', isTelugu),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 2),
                          RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: nameText,
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: theme.colorScheme.secondary,
                                    height: 1.2,
                                  ),
                                ),
                                TextSpan(
                                  text: isTelugu ? ' గారు' : ' Garu',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isTelugu
                                ? '$constituencyText లోక్‌సభ సభ్యురాలు'
                                : '$roleText representing $constituencyText',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF475569),
                              height: 1.3,
                            ),
                          ),

                          const SizedBox(height: 12),

                          // 4. LOCATION PILL
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.grey.shade300),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                )
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.location_on, color: theme.primaryColor, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  constituencyText,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // 5 & 6. LANGUAGE CARDS (No Continue Buttons Inside)
                          IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Telugu Card
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      appState.setLanguage(true);
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: isTelugu ? selectedBorderColor : Colors.grey.shade300,
                                          width: isTelugu ? 2 : 1,
                                        ),
                                        boxShadow: [
                                          if (isTelugu)
                                            BoxShadow(
                                              color: selectedBorderColor.withValues(alpha: 0.2),
                                              blurRadius: 8,
                                              spreadRadius: 1,
                                            )
                                          else
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.02),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            )
                                        ],
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          CircleAvatar(
                                            radius: 18,
                                            backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
                                            child: Text(
                                              'అ',
                                              style: TextStyle(
                                                color: theme.primaryColor,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            'తెలుగు',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: theme.primaryColor,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          const Text(
                                            'తెలుగులో సేవలను చూడండి మరియు ఉపయోగించండి',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.black54,
                                              height: 1.2,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // English Card
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      appState.setLanguage(false);
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: !isTelugu ? selectedBorderColor : Colors.grey.shade300,
                                          width: !isTelugu ? 2 : 1,
                                        ),
                                        boxShadow: [
                                          if (!isTelugu)
                                            BoxShadow(
                                              color: selectedBorderColor.withValues(alpha: 0.2),
                                              blurRadius: 8,
                                              spreadRadius: 1,
                                            )
                                          else
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.02),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            )
                                        ],
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          CircleAvatar(
                                            radius: 18,
                                            backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
                                            child: Text(
                                              'A',
                                              style: TextStyle(
                                                color: theme.primaryColor,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            'English',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: theme.primaryColor,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          const Text(
                                            'View and access services in English',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.black54,
                                              height: 1.2,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // 7. PROCEED BUTTON (Single Primary Proceed Button at Bottom)
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                                elevation: 3,
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
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_forward, size: 22),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
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
