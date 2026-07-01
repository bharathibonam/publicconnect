import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_demo_app/l10n/app_localizations.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../services/app_state.dart';
import '../../themes/theme_provider.dart';
import '../../themes/party_theme_config.dart';
import '../../models/complaint.dart';
import '../../widgets/shared_officer_widgets.dart';
import '../../widgets/notification_bell.dart';
import '../citizen/track_complaints.dart';
import '../../utils/mandal_mapping.dart';
import '../announcements/create_announcement_screen.dart';
import '../announcements/broadcast_history_screen.dart';

class MandalAdminNavHolder extends StatefulWidget {
  const MandalAdminNavHolder({super.key});

  @override
  State<MandalAdminNavHolder> createState() => _MandalAdminNavHolderState();
}

class _MandalAdminNavHolderState extends State<MandalAdminNavHolder> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final themeConfig = Provider.of<ThemeProvider>(context).activeParty;
    final l10n = AppLocalizations.of(context)!;

    final List<Widget> screens = [
      const MandalDashboardTab(),
      const MandalComplaintsTab(),
      const MandalReportsTab(),
      MandalProfileTab(
        onProfileSaved: () {
          setState(() {
            _currentIndex = 0; // Go to Home tab
          });
        },
      ),
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

class MandalDashboardTab extends StatelessWidget {
  const MandalDashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final themeConfig = Provider.of<ThemeProvider>(context).activeParty;
    final l10n = AppLocalizations.of(context)!;
    final isTelugu = appState.isTelugu;
    final user = appState.currentUser;

    // Filter complaints by this officer's mandal
    final myMandal = user?.mandalName ?? '';
    final complaints = appState.complaints.where((c) {
      String cMandal = c.mandalName.isNotEmpty && c.mandalName != 'Unknown' 
          ? c.mandalName 
          : MandalMapping.getMandalForVillage(c.villageName);
      String normC = cMandal.toLowerCase().replaceAll(' mandal', '').trim();
      String normU = myMandal.toLowerCase().replaceAll(' mandal', '').trim();
      if (normU.isEmpty) return true;
      return normC.contains(normU) || normU.contains(normC);
    }).toList();
    
    final total = complaints.length;
    final resolved = complaints.where((c) => c.status == ComplaintStatus.resolved).length;
    final pending = complaints.where((c) => c.status == ComplaintStatus.submitted).length;
    final inReview = complaints.where((c) => c.status == ComplaintStatus.inProgress).length;

    // Service-wise Status Grid
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

    // Chart logic
    List<FlSpot> computeWeeklyTrend() {
      return const [
        FlSpot(1, 5),
        FlSpot(2, 10),
        FlSpot(3, 16),
        FlSpot(4, 23),
      ];
    }

    // Today's Service Requests
    List<MapEntry<String, int>> computeTodayRequests() {
      final today = DateTime.now();
      final todayComplaints = complaints.where((c) => 
        c.createdAt.year == today.year && 
        c.createdAt.month == today.month && 
        c.createdAt.day == today.day
      ).toList();
      
      Map<String, int> deptCounts = {};
      for (var c in todayComplaints) {
        deptCounts[c.category] = (deptCounts[c.category] ?? 0) + 1;
      }
      return deptCounts.entries.toList();
    }
    final todayRequests = computeTodayRequests();
    final todayTotal = todayRequests.fold<int>(0, (sum, item) => sum + item.value);

    // Village Rankings
    List<MapEntry<String, int>> computeVillageRankings() {
      Map<String, int> counts = {};
      for (var c in complaints) {
        if (c.villageName.isNotEmpty) {
          counts[c.villageName] = (counts[c.villageName] ?? 0) + 1;
        }
      }
      var sorted = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      return sorted.take(5).toList();
    }
    final topVillages = computeVillageRankings();

    // Top Mandals performance (from all mandals)
    List<MapEntry<String, double>> computeTopMandals() {
      Map<String, List<Complaint>> mandalMap = {};
      for (var c in appState.complaints) {
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
                  l10n.mandalOfficerDashboard,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  isTelugu ? '$myMandal పరిధి' : '$myMandal Jurisdiction',
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
            _buildUrgentBanner(context, appState, 'Mandal Officer', themeConfig, isTelugu, myMandal),
            OfficerProfileCard(
              user: user,
              location: isTelugu ? '$myMandal మండలం' : '$myMandal Mandal',
              roleBadge: user?.officerRole,
              themeConfig: themeConfig,
              onProfileTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const MandalProfileTab(isPushed: true)));
              },
            ),
            const SizedBox(height: 24),

            SectionHeader(title: l10n.mandalSummary),
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

            SectionHeader(
              title: l10n.primaryServicesStatus,
              onViewAll: l10n.viewMoreServices,
              onTapViewAll: () {},
            ),
            const SizedBox(height: 12),
            ServiceStatusGrid(
              departmentStats: computeDepartmentStats(),
              isTelugu: isTelugu,
              themeConfig: themeConfig,
            ),
            const SizedBox(height: 24),

            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 600;
                final widget1 = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.thisMonthTrend, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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
                final widget2 = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.todayServiceRequests, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: SizedBox(
                          height: 150,
                          child: todayRequests.isEmpty
                              ? Center(child: Text(l10n.noComplaints, style: const TextStyle(fontSize: 12, color: Colors.grey)))
                              : Column(
                                  children: [
                                    Expanded(
                                      child: ListView.builder(
                                        itemCount: todayRequests.length,
                                        itemBuilder: (context, index) {
                                          final req = todayRequests[index];
                                          return Padding(
                                            padding: const EdgeInsets.only(bottom: 8.0),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(child: Text(req.key, style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis)),
                                                Text('${req.value}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    const Divider(height: 1),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(l10n.total, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: themeConfig.primaryColor)),
                                        Text('$todayTotal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: themeConfig.primaryColor)),
                                      ],
                                    )
                                  ],
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

            SectionHeader(
              title: l10n.recentComplaints,
              onViewAll: 'View All',
              onTapViewAll: () {},
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

            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 600;
                final widget1 = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionHeader(
                      title: l10n.villageWiseComplaints,
                      onViewAll: 'View All',
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
                        itemCount: topVillages.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                Text('${index+1}.', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                const SizedBox(width: 8),
                                Expanded(child: Text(topVillages[index].key, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                                Text('${topVillages[index].value}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
                final widget2 = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionHeader(
                      title: l10n.topMandals,
                      onViewAll: 'View All',
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
                          return Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                Text('${index+1}.', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                const SizedBox(width: 8),
                                Expanded(child: Text(topMandals[index].key, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                                Text('${topMandals[index].value.toStringAsFixed(0)}%', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 12)),
                              ],
                            ),
                          );
                        },
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
            SectionHeader(title: 'Broadcast'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const CreateAnnouncementScreen())),
                    icon: const Icon(Icons.campaign, size: 18),
                    label: const Text('New Announcement'),
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
                    label: const Text('Broadcast History'),
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
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

class MandalComplaintsTab extends StatelessWidget {
  const MandalComplaintsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final themeConfig = Provider.of<ThemeProvider>(context).activeParty;
    final l10n = AppLocalizations.of(context)!;
    final myMandal = appState.currentUser?.mandalName ?? '';
    final complaints = appState.complaints.where((c) {
      String cMandal = c.mandalName.isNotEmpty && c.mandalName != 'Unknown' 
          ? c.mandalName 
          : MandalMapping.getMandalForVillage(c.villageName);
      String normC = cMandal.toLowerCase().replaceAll(' mandal', '').trim();
      String normU = myMandal.toLowerCase().replaceAll(' mandal', '').trim();
      if (normU.isEmpty) return true;
      return normC.contains(normU) || normU.contains(normC);
    }).toList();

    return Scaffold(
      backgroundColor: themeConfig.backgroundColor,
      appBar: OfficerAppBar(
        title: l10n.complaint,
        subtitle: myMandal,
        isTelugu: appState.isTelugu,
      ),
      body: complaints.isEmpty
          ? Center(child: EmptyStateWidget(message: l10n.noComplaints))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: complaints.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    color: Colors.white,
                    child: ComplaintListTile(
                      complaint: complaints[index],
                      isTelugu: appState.isTelugu,
                      onTap: () {
                        appState.setHighlightedComplaintId(complaints[index].id);
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

class MandalReportsTab extends StatelessWidget {
  const MandalReportsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final l10n = AppLocalizations.of(context)!;
    final themeConfig = Provider.of<ThemeProvider>(context).activeParty;

    return Scaffold(
      backgroundColor: themeConfig.backgroundColor,
      appBar: OfficerAppBar(
        title: l10n.reports,
        subtitle: '',
        isTelugu: appState.isTelugu,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.table_chart_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.download),
              label: Text(appState.isTelugu ? 'ఎక్సెల్ షీట్ డౌన్‌లోడ్ చేయండి' : 'Generate Excel Sheet'),
              style: ElevatedButton.styleFrom(
                backgroundColor: themeConfig.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(appState.isTelugu ? 'ఎక్సెల్ షీట్ డౌన్‌లోడ్ చేయబడుతోంది...' : 'Generating Excel Sheet...')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class MandalProfileTab extends StatefulWidget {
  final VoidCallback? onProfileSaved;
  final bool isPushed;

  const MandalProfileTab({super.key, this.onProfileSaved, this.isPushed = false});

  @override
  State<MandalProfileTab> createState() => _MandalProfileTabState();
}

class _MandalProfileTabState extends State<MandalProfileTab> {
  final ImagePicker _picker = ImagePicker();
  bool _isSaving = false;

  Future<void> _pickImage() async {
    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final isTelugu = appState.isTelugu;
      final userId = appState.currentUser?.id ?? 'user';
      final name = appState.currentUser?.name ?? '';
      final phone = appState.currentUser?.phoneNumber ?? '';

      final pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (pickedFile != null) {
        final appDir = await getApplicationDocumentsDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final destPath = '${appDir.path}/profile_${userId}_$timestamp.jpg';
        final destFile = await File(pickedFile.path).copy(destPath);
        
        setState(() => _isSaving = true);
        await appState.updateUserProfile(
          name,
          phone,
          destFile.path,
        );
        setState(() => _isSaving = false);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isTelugu ? 'ప్రొఫైల్ చిత్రం నవీకరించబడింది!' : 'Profile picture updated!'),
              backgroundColor: Theme.of(context).primaryColor,
            ),
          );
          if (widget.isPushed) {
            Navigator.pop(context);
          } else if (widget.onProfileSaved != null) {
            widget.onProfileSaved!();
          }
        }
      }
    } catch (e) {
      debugPrint('Error picking profile image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final themeConfig = Provider.of<ThemeProvider>(context).activeParty;
    final user = appState.currentUser;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: themeConfig.backgroundColor,
      appBar: OfficerAppBar(
        title: l10n.profile,
        subtitle: '',
        isTelugu: appState.isTelugu,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                OfficerProfileCard(
                  user: user,
                  location: user?.mandalName ?? '',
                  roleBadge: user?.officerRole,
                  themeConfig: themeConfig,
                  onProfileTap: _pickImage,
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeConfig.primaryColor,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  onPressed: () {
                    appState.logout();
                  },
                ),
              ],
            ),
          ),
          if (_isSaving)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}

Widget _buildUrgentBanner(BuildContext context, AppState appState, String targetRole, PartyThemeConfig themeConfig, bool isTelugu, String myMandal) {
  final urgentComplaints = appState.complaints.where((c) {
    if (!c.isPushed || c.pushedTo != targetRole || c.status == ComplaintStatus.resolved) return false;
    String cMandal = c.mandalName.isNotEmpty && c.mandalName != 'Unknown' 
        ? c.mandalName 
        : MandalMapping.getMandalForVillage(c.villageName);
    String normC = cMandal.toLowerCase().replaceAll(' mandal', '').trim();
    String normU = myMandal.toLowerCase().replaceAll(' mandal', '').trim();
    if (normU.isEmpty) return true;
    return normC.contains(normU) || normU.contains(normC);
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

