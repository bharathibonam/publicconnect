import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_demo_app/l10n/app_localizations.dart';
import '../../services/app_state.dart';
import '../../themes/theme_provider.dart';
import 'super_complaints_tab.dart';
import 'super_polling_tab.dart';
import 'super_reports_tab.dart';
import 'super_profile_tab.dart';
import 'super_dashboard_home.dart';
import 'super_constituency_overview.dart';
import 'meetings/meetings_list_screen.dart';
import 'system_configuration_screen.dart';
import '../announcements/broadcast_history_screen.dart';

class SuperAdminNavHolder extends StatefulWidget {
  const SuperAdminNavHolder({super.key});

  @override
  State<SuperAdminNavHolder> createState() => _SuperAdminNavHolderState();
}

class _SuperAdminNavHolderState extends State<SuperAdminNavHolder> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final themeConfig = themeProvider.activeParty;
    final l10n = AppLocalizations.of(context)!;

    final List<Widget> screens = [
      const SuperDashboardHome(),
      const SuperComplaintsTab(),
      const SuperPollingTab(),
      const SuperReportsTab(),
      const SuperProfileTab(),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      drawer: _buildDrawer(context, themeConfig, l10n),
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: themeConfig.primaryColor,
          unselectedItemColor: Colors.grey.shade400,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 10),
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_outlined),
              activeIcon: const Icon(Icons.home),
              label: l10n.home,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.article_outlined),
              activeIcon: const Icon(Icons.article),
              label: l10n.complaints,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.how_to_vote_outlined),
              activeIcon: const Icon(Icons.how_to_vote),
              label: l10n.polling,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.bar_chart_outlined),
              activeIcon: const Icon(Icons.bar_chart),
              label: l10n.reports,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_outline),
              activeIcon: const Icon(Icons.person),
              label: l10n.profile,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, dynamic themeConfig, AppLocalizations l10n) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(top: 50, left: 20, bottom: 20),
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [themeConfig.primaryColor, themeConfig.secondaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  radius: 30,
                  child: const Icon(Icons.person, color: Colors.white, size: 30),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.mlaDashboard,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  l10n.constituencySuffix(themeConfig.getLocalizedConstituencyName(context)),
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _drawerItem(Icons.dashboard_outlined, l10n.dashboard, () {
                  Navigator.pop(context);
                  setState(() => _currentIndex = 0);
                }, themeConfig),
                _drawerItem(Icons.edit_document, l10n.complaints, () {
                  Navigator.pop(context);
                  setState(() => _currentIndex = 1);
                }, themeConfig),
                _drawerItem(Icons.how_to_vote_outlined, l10n.polling, () {
                  Navigator.pop(context);
                  setState(() => _currentIndex = 2);
                }, themeConfig),
                _drawerItem(Icons.analytics_outlined, l10n.reportsAnalytics, () {
                  Navigator.pop(context);
                  setState(() => _currentIndex = 3);
                }, themeConfig),
                const Divider(),
                _drawerItem(Icons.groups_outlined, l10n.meetingsEvents, () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const MeetingsListScreen()));
                }, themeConfig),
                _drawerItem(Icons.campaign_outlined, l10n.broadcastCenter, () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const BroadcastHistoryScreen()));
                }, themeConfig),
                _drawerItem(Icons.contact_phone_outlined, l10n.officerDirectory, () {
                  Navigator.pop(context);
                }, themeConfig),
                _drawerItem(Icons.map_outlined, 'Constituency Overview', () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SuperConstituencyOverview()));
                }, themeConfig),
                _drawerItem(Icons.smart_toy_outlined, 'AI Assistant', () {
                  Navigator.pop(context);
                }, themeConfig),
                const Divider(),
                _drawerItem(Icons.settings_system_daydream, 'System Configuration', () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SystemConfigurationScreen()));
                }, themeConfig),
                _drawerItem(Icons.settings_outlined, l10n.settings, () {
                  Navigator.pop(context);
                }, themeConfig),
                _drawerItem(Icons.person_outline, l10n.profile, () {
                  Navigator.pop(context);
                  setState(() => _currentIndex = 4);
                }, themeConfig),
                _drawerItem(Icons.logout, l10n.logout, () {
                  Provider.of<AppState>(context, listen: false).logout();
                }, themeConfig, color: Colors.red),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title, VoidCallback onTap, dynamic themeConfig, {Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.grey.shade700),
      title: Text(title, style: TextStyle(color: color ?? Colors.black87, fontWeight: FontWeight.w500)),
      onTap: onTap,
    );
  }
}
