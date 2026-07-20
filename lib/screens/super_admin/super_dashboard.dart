import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_demo_app/l10n/app_localizations.dart';
import '../../services/app_state.dart';
import '../../themes/theme_provider.dart';
import '../../themes/party_theme_config.dart';
import '../../models/complaint.dart';
import '../../widgets/shared_officer_widgets.dart';
import '../citizen/track_complaints.dart';
import 'admin_management.dart';
import 'app_config_tab.dart';
import 'complaint_location_explorer.dart';
import '../../widgets/notification_bell.dart';
import '../announcements/create_announcement_screen.dart';
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
      const SuperDashboardTab(),
      const SuperComplaintsTab(),
      const SuperReportsTab(),
      const SuperProfileTab(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: themeConfig.primaryColor,
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            activeIcon: const Icon(Icons.home),
            label: l10n.home,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.list_alt_outlined),
            activeIcon: const Icon(Icons.list_alt),
            label: l10n.complaint,
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
    );
  }
}

class SuperDashboardTab extends StatelessWidget {
  const SuperDashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final themeConfig = themeProvider.activeParty;
    final l10n = AppLocalizations.of(context)!;
    final isTelugu = appState.isTelugu;

    // Derived statistics from real stream
    final complaints = appState.complaints;
    final total = complaints.length;
    final resolved = complaints.where((c) => c.status == ComplaintStatus.resolved).length;
    final pending = complaints.where((c) => c.status == ComplaintStatus.submitted).length;
    final inReview = complaints.where((c) => c.status == ComplaintStatus.inProgress).length;

    // Primary Services Status Grid calculation
    Map<String, double> computeDepartmentStats() {
      final targetCategories = ['Water Supply', 'Electricity', 'Roads & Infrastructure', 'Sanitation'];
      Map<String, double> stats = {};
      for (String cat in targetCategories) {
        final catComplaints = complaints.where((c) => c.category == cat).toList();
        if (catComplaints.isEmpty) {
          stats[cat] = 0.0;
        } else {
          final resolvedCount = catComplaints.where((c) => c.status == ComplaintStatus.resolved).length;
          stats[cat] = (resolvedCount / catComplaints.length) * 100;
        }
      }
      return stats;
    }
    
    // Top Mandals calculation
    List<MapEntry<String, double>> computeTopMandals() {
      Map<String, List<Complaint>> mandalMap = {};
      for (var c in complaints) {
        if (c.mandalName.isNotEmpty) {
          mandalMap.putIfAbsent(c.mandalName, () => []).add(c);
        }
      }
      Map<String, double> perfMap = {};
      mandalMap.forEach((mandal, list) {
        final res = list.where((c) => c.status == ComplaintStatus.resolved).length;
        perfMap[mandal] = (res / list.length) * 100;
      });
      var sorted = perfMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      return sorted.take(5).toList();
    }
    
    final topMandals = computeTopMandals();

    // Chart logic
    List<FlSpot> computeWeeklyTrend() {
      // Mocked weekly trend based on actual data sizes if needed, or simple compute
      // Just returning some basic points for the line chart since we don't have historical snapshots
      return const [
        FlSpot(1, 10),
        FlSpot(2, 25),
        FlSpot(3, 40),
        FlSpot(4, 30),
      ];
    }

    return Scaffold(
      backgroundColor: themeConfig.backgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [themeConfig.primaryColor, themeConfig.secondaryColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leadingWidth: 0,
            leading: const SizedBox.shrink(),
            titleSpacing: 16,
            centerTitle: false,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.mlaDashboard,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  l10n.constituencySummary,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            actions: [
              const NotificationBell(color: Colors.white),
              // Language Toggle
              Container(
                margin: const EdgeInsets.only(right: 16, top: 12, bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () => appState.setLanguage(false),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 40,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: !isTelugu ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'English',
                          style: TextStyle(
                            color: !isTelugu ? themeConfig.primaryColor : Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => appState.setLanguage(true),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 40,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: isTelugu ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'తెలుగు',
                          style: TextStyle(
                            color: isTelugu ? themeConfig.primaryColor : Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUrgentBanner(context, appState, 'MLA', themeConfig, isTelugu),
            Container(
              width: double.infinity,
              height: 140, // Compact height
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [themeConfig.primaryColor, themeConfig.primaryColor.withValues(alpha: 0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 4)),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.only(left: 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Left Content Area: Welcome Text & Name
                    Expanded(
                      flex: 5,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            l10n.welcome,
                            style: const TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            l10n.welcomeGaru(themeConfig.getLocalizedMlaName(context)),
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.constituencySuffix(themeConfig.getLocalizedConstituencyName(context)),
                            style: const TextStyle(color: Colors.black54, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    ),
                    // Right Content Area: MLA Photo & Watermark
                    Expanded(
                      flex: 5,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(bottomRight: Radius.circular(16)),
                        child: Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.bottomRight,
                          children: [
                            // Background Watermark: Party Logo
                            if (themeConfig.id == 'tdp' && themeConfig.logoUrl != null)
                              Positioned(
                                right: 0,
                                top: 10,
                                width: 90,
                                height: 90,
                                child: Opacity(
                                  opacity: 0.15,
                                  child: themeConfig.logoUrl!.startsWith('http')
                                      ? Image.network(themeConfig.logoUrl!, fit: BoxFit.contain)
                                      : Image.asset(themeConfig.logoUrl!, fit: BoxFit.contain),
                                ),
                              ),
                            // MLA Photo
                            Positioned.fill(
                              child: Align(
                                alignment: Alignment.bottomRight,
                                child: (themeConfig.mlaPhotoUrl != null && themeConfig.mlaPhotoUrl!.isNotEmpty)
                                    ? (themeConfig.mlaPhotoUrl!.startsWith('http')
                                        ? Image.network(themeConfig.mlaPhotoUrl!, fit: BoxFit.contain, alignment: Alignment.bottomRight)
                                        : Image.asset(themeConfig.mlaPhotoUrl!, fit: BoxFit.contain, alignment: Alignment.bottomRight))
                                    : const SizedBox(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Constituency Summary
            SectionHeader(title: l10n.constituencySummary),
            const SizedBox(height: 12),
            InlineStatRow(
              total: total,
              resolved: resolved,
              pending: pending,
              inReview: inReview,
              isTelugu: isTelugu,
              themeConfig: themeConfig,
            ),
            const SizedBox(height: 24),

            // Primary Services
            SectionHeader(
              title: l10n.primaryServicesStatus,
              onViewAll: l10n.viewMoreServices,
              onTapViewAll: () {
                // Navigate to services
              },
            ),
            const SizedBox(height: 12),
            ServiceStatusGrid(
              departmentStats: computeDepartmentStats(),
              isTelugu: isTelugu,
              themeConfig: themeConfig,
            ),
            const SizedBox(height: 24),

            // Analytics Section
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 600;
                final widget1 = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.complaintAnalytics, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: SizedBox(
                          height: 150,
                          child: total == 0 
                              ? Center(child: EmptyStateWidget(message: l10n.noComplaints))
                              : Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    PieChart(
                                      PieChartData(
                                        sectionsSpace: 2,
                                        centerSpaceRadius: 35,
                                        sections: [
                                          PieChartSectionData(color: themeConfig.chartColors.isNotEmpty ? themeConfig.chartColors[0] : Colors.green, value: resolved.toDouble(), showTitle: false, radius: 15),
                                          PieChartSectionData(color: themeConfig.chartColors.length > 1 ? themeConfig.chartColors[1] : Colors.orange, value: inReview.toDouble(), showTitle: false, radius: 15),
                                          PieChartSectionData(color: themeConfig.chartColors.length > 2 ? themeConfig.chartColors[2] : Colors.red, value: pending.toDouble(), showTitle: false, radius: 15),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(l10n.total, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                        Text('$total', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                      ],
                                    )
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ],
                );
                
                final widget2 = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(l10n.thisMonthTrend, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), overflow: TextOverflow.ellipsis)),
                        GestureDetector(
                          onTap: () {}, // view all reports
                          child: Text(l10n.viewAll, style: TextStyle(fontSize: 10, color: themeConfig.primaryColor)),
                        )
                      ],
                    ),
                    const SizedBox(height: 8),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: SizedBox(
                          height: 150,
                          child: LineChart(
                            LineChartData(
                              gridData: const FlGridData(show: false),
                              titlesData: const FlTitlesData(show: false),
                              borderData: FlBorderData(show: false),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: computeWeeklyTrend(),
                                  isCurved: true,
                                  color: themeConfig.primaryColor,
                                  barWidth: 3,
                                  isStrokeCapRound: true,
                                  dotData: const FlDotData(show: false),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: themeConfig.primaryColor.withValues(alpha: 0.2),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );

                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: widget1),
                      const SizedBox(width: 12),
                      Expanded(child: widget2),
                    ],
                  );
                } else {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      widget1,
                      const SizedBox(height: 24),
                      widget2,
                    ],
                  );
                }
              },
            ),
            const SizedBox(height: 24),

            // Recent Complaints
            SectionHeader(
              title: l10n.recentComplaints,
              onViewAll: l10n.viewAll,
              onTapViewAll: () {
                // navigate
              },
            ),
            const SizedBox(height: 12),
            if (complaints.isEmpty)
              EmptyStateWidget(message: l10n.noComplaints)
            else
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                color: Colors.white,
                child: Column(
                  children: complaints.take(5).map((c) => ComplaintListTile(
                    complaint: c,
                    isTelugu: isTelugu,
                    onTap: () {
                      appState.setHighlightedComplaintId(c.id);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const TrackComplaintsScreen()));
                    },
                  )).toList(),
                ),
              ),
            const SizedBox(height: 24),

            // Top Mandals
            SectionHeader(
              title: l10n.topMandals,
              onViewAll: l10n.viewAll,
              onTapViewAll: () {},
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              color: Colors.white,
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: topMandals.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final mandalName = topMandals[index].key;
                  final perf = topMandals[index].value;
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Text('${index+1}.', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                        const SizedBox(width: 12),
                        Expanded(child: Text(mandalName, style: const TextStyle(fontWeight: FontWeight.w600))),
                        Text('${perf.toStringAsFixed(0)}%', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Broadcast Section
            SectionHeader(title: l10n.broadcast),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const CreateAnnouncementScreen())),
                    icon: const Icon(Icons.campaign, size: 18),
                    label: Text(l10n.newAnnouncement),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeConfig.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const BroadcastHistoryScreen())),
                    icon: const Icon(Icons.history, size: 18),
                    label: Text(l10n.broadcastHistory),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: themeConfig.primaryColor,
                      side: BorderSide(color: themeConfig.primaryColor),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 80), // Padding for bottom nav
          ],
        ),
      ),
    );
  }
}

class SuperComplaintsTab extends StatelessWidget {
  const SuperComplaintsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final themeConfig = themeProvider.activeParty;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: themeConfig.backgroundColor,
      appBar: OfficerAppBar(
        title: l10n.complaint,
        subtitle: l10n.constituency,
        isTelugu: appState.isTelugu,
        onLanguageToggle: () => appState.setLanguage(!appState.isTelugu),
        showLanguageToggle: true,
        onProfileTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(body: const SuperProfileTab())));
        },
      ),
      body: appState.complaints.isEmpty
          ? Center(child: EmptyStateWidget(message: l10n.noComplaints))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: appState.complaints.length,
              itemBuilder: (context, index) {
                final complaint = appState.complaints[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    color: Colors.white,
                    child: ComplaintListTile(
                      complaint: complaint,
                      isTelugu: appState.isTelugu,
                      onTap: () {
                        appState.setHighlightedComplaintId(complaint.id);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const TrackComplaintsScreen()));
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class SuperReportsTab extends StatelessWidget {
  const SuperReportsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final l10n = AppLocalizations.of(context)!;
    
    final themeProvider = Provider.of<ThemeProvider>(context);
    final themeConfig = themeProvider.activeParty;
    
    return Scaffold(
      appBar: OfficerAppBar(
        title: l10n.reports,
        subtitle: l10n.constituency,
        isTelugu: appState.isTelugu,
        onLanguageToggle: () => appState.setLanguage(!appState.isTelugu),
        showLanguageToggle: true,
        onProfileTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(body: const SuperProfileTab())));
        },
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const ComplaintLocationExplorer(),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.download),
              label: Text(l10n.generateExcel),
              style: ElevatedButton.styleFrom(
                backgroundColor: themeConfig.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.generatingExcel)),
                );
              },
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}




class SuperProfileTab extends StatefulWidget {
  const SuperProfileTab({super.key});

  @override
  State<SuperProfileTab> createState() => _SuperProfileTabState();
}

class _SuperProfileTabState extends State<SuperProfileTab> {
  bool _isUploading = false;

  Future<void> _updateProfilePhoto(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 70);
    if (pickedFile == null) return;

    setState(() => _isUploading = true);
    if (!mounted) return;
    final appState = Provider.of<AppState>(context, listen: false);
    final user = appState.currentUser;
    if (user != null) {
      final cloudUrl = await SupabaseService.uploadProfileImage(File(pickedFile.path), user.id);
      if (cloudUrl != null) {
        appState.updateUserProfile(user.name, user.phoneNumber, cloudUrl);
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.profileUpdated)));
        }
      } else {
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.photoUploadFailed)));
        }
      }
    }
    if (mounted) {
      setState(() => _isUploading = false);
    }
  }

  void _showImageSourceActionSheet(BuildContext context, dynamic themeConfig) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt, color: themeConfig.primaryColor),
              title: Text(l10n.camera),
              onTap: () {
                Navigator.pop(ctx);
                _updateProfilePhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library, color: themeConfig.primaryColor),
              title: Text(l10n.gallery),
              onTap: () {
                Navigator.pop(ctx);
                _updateProfilePhoto(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final themeConfig = themeProvider.activeParty;
    final user = appState.currentUser;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: themeConfig.backgroundColor,
      appBar: OfficerAppBar(
        title: l10n.profile,
        subtitle: '',
        isTelugu: appState.isTelugu,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: themeConfig.primaryColor.withValues(alpha: 0.2),
                  backgroundImage: user?.profilePhotoUrl != null && user!.profilePhotoUrl!.isNotEmpty
                      ? (user.profilePhotoUrl!.startsWith('http') || kIsWeb
                          ? NetworkImage(user.profilePhotoUrl!) as ImageProvider
                          : FileImage(File(user.profilePhotoUrl!)))
                      : null,
                  child: (user?.profilePhotoUrl == null || user!.profilePhotoUrl!.isEmpty)
                      ? Icon(Icons.person, size: 50, color: themeConfig.primaryColor)
                      : null,
                ),
                if (_isUploading)
                  const CircularProgressIndicator(),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () => _showImageSourceActionSheet(context, themeConfig),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: themeConfig.primaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(user?.name ?? 'Super Admin', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text(user?.phoneNumber ?? '', style: const TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 32),
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              color: Colors.white,
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.supervised_user_circle, color: themeConfig.accentColor),
                    title: Text(l10n.adminManagement, style: const TextStyle(fontWeight: FontWeight.w600)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(
                        appBar: AppBar(title: Text(l10n.adminManagement), backgroundColor: themeConfig.primaryColor),
                        body: const AdminManagementTab(),
                      )));
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.palette, color: themeConfig.accentColor),
                    title: Text(l10n.systemConfig, style: const TextStyle(fontWeight: FontWeight.w600)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(
                        appBar: AppBar(title: Text(l10n.systemConfig), backgroundColor: themeConfig.primaryColor),
                        body: const AppConfigTab(),
                      )));
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: () {
                appState.logout();
              },
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildUrgentBanner(BuildContext context, AppState appState, String targetRole, PartyThemeConfig themeConfig, bool isTelugu) {
  final urgentComplaints = appState.complaints.where((c) {
    return c.isPushed && c.pushedTo == targetRole && c.status != ComplaintStatus.resolved;
  }).toList();

  if (urgentComplaints.isEmpty) return const SizedBox();

  final count = urgentComplaints.length;

  return Container(
    margin: const EdgeInsets.only(bottom: 16),
    child: InkWell(
      onTap: () {
        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (ctx) {
            return StatefulBuilder(
              builder: (ctx, setSheetState) {
                final currentList = Provider.of<AppState>(context).complaints;
                final index = currentList.indexWhere((c) => c.id == urgentComplaints.first.id);
                if (index == -1 || currentList[index].status == ComplaintStatus.resolved) {
                  return const SizedBox();
                }
                final c = currentList[index];

                return Container(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isTelugu ? 'అత్యవసర ఫిర్యాదు' : 'URGENT COMPLAINT',
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${isTelugu ? "వర్గం" : "Category"}: ${c.category}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        c.description,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final picker = ImagePicker();
                          final picked = await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
                          if (picked != null) {
                            await appState.updateComplaintStatus(c.id, ComplaintStatus.resolved, resolvedImageUrl: picked.path);
                            if (context.mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text(isTelugu ? 'ఫిర్యాదు విజయవంతంగా పరిష్కరించబడింది!' : 'Complaint Resolved!'),
                              ));
                            }
                          }
                        },
                        icon: const Icon(Icons.camera_alt, size: 18),
                        label: Text(
                          isTelugu ? 'వెంటనే పరిష్కరించండి (ఫోటో తప్పనిసరి)' : 'Resolve Immediately (Photo Required)',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.shade900,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isTelugu ? 'అత్యవసర ఫిర్యాదులు: $count' : 'URGENT COMPLAINTS: $count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isTelugu 
                        ? 'అధికారి ద్వారా బదిలీ చేయబడింది. వెంటనే పరిష్కరించడానికి క్లిక్ చేయండి.' 
                        : 'Pushed by Category Officer. Click to resolve immediately.',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white, size: 20),
          ],
        ),
      ),
    ),
  );
}
