import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../themes/theme_provider.dart';
import '../../services/app_state.dart';
import '../../l10n/app_localizations.dart';
import 'citizen_home.dart';
import 'new_complaint.dart';
import 'track_complaints.dart';
import 'citizen_profile.dart';

class CitizenNavHolder extends StatefulWidget {
  const CitizenNavHolder({super.key});

  @override
  State<CitizenNavHolder> createState() => _CitizenNavHolderState();
}

class _CitizenNavHolderState extends State<CitizenNavHolder> {
  int _currentIndex = 0;
  StreamSubscription? _pushNotifSub;

  @override
  void initState() {
    super.initState();
    final appState = Provider.of<AppState>(context, listen: false);
    _pushNotifSub = appState.pushNotificationStream.listen((data) {
      _showInAppPushNotificationBanner(data['title'] ?? '', data['body'] ?? '');
    });
  }

  @override
  void dispose() {
    _pushNotifSub?.cancel();
    super.dispose();
  }

  void _showInAppPushNotificationBanner(String title, String body) {
    if (!mounted) return;
    final overlayState = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          left: 16,
          right: 16,
          child: Material(
            color: Colors.transparent,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 300),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, -20 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                  border: Border.all(color: Colors.grey.shade200, width: 1),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF3E8FF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.notifications_active, color: Color(0xFF7C3AED), size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            body,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16, color: Colors.grey),
                      onPressed: () {
                        overlayEntry.remove();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    overlayState.insert(overlayEntry);

    Future.delayed(const Duration(seconds: 4), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final activeParty = Provider.of<ThemeProvider>(context).activeParty;
    final appState = Provider.of<AppState>(context);
    
    if (appState.requestedCitizenTabIndex != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _currentIndex = appState.requestedCitizenTabIndex!;
          });
          appState.clearCitizenTabIndex();
        }
      });
    }
    
    final List<Widget> screens = [
      CitizenHome(
        onFileComplaintPressed: () {
          setState(() {
            _currentIndex = 1;
          });
        },
        onTrackComplaintsPressed: () {
          setState(() {
            _currentIndex = 2;
          });
        },
        onGoToProfile: () {
          setState(() {
            _currentIndex = 3;
          });
        },
      ),
      NewComplaintScreen(
        onSubmissionSuccess: () {
          setState(() {
            _currentIndex = 2; // Route to tracking screen on success
          });
        },
      ),
      const TrackComplaintsScreen(),
      const CitizenProfileScreen(),
    ];

    return Scaffold(
      extendBody: true, // Needed for floating nav bar
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _currentIndex,
          children: screens,
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 24.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildNavItem(0, Icons.home_outlined, Icons.home, loc.home, activeParty.primaryColor),
                _buildNavItem(1, Icons.assignment_outlined, Icons.assignment, loc.complaint, activeParty.primaryColor),
                _buildNavItem(2, Icons.track_changes_outlined, Icons.track_changes, loc.track, activeParty.primaryColor),
                _buildNavItem(3, Icons.person_outline, Icons.person, loc.profile, activeParty.primaryColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData outlineIcon, IconData filledIcon, String label, Color primaryColor) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? primaryColor : Colors.grey.shade500;
    
    return Expanded(
      flex: 1,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _currentIndex = index;
          });
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(isSelected ? filledIcon : outlineIcon, color: color, size: 24),
              const SizedBox(height: 4),
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
