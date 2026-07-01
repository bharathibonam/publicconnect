import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_demo_app/l10n/app_localizations.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../services/app_state.dart';
import '../../themes/theme_provider.dart';
import '../../models/complaint.dart';
import '../../widgets/shared_officer_widgets.dart';
import '../../widgets/notification_bell.dart';
import '../citizen/track_complaints.dart';
import '../../utils/category_mapping.dart';

import '../announcements/create_announcement_screen.dart';
import '../announcements/broadcast_history_screen.dart';

class OfficerNavHolder extends StatefulWidget {
  const OfficerNavHolder({super.key});

  @override
  State<OfficerNavHolder> createState() => _OfficerNavHolderState();
}

class _OfficerNavHolderState extends State<OfficerNavHolder> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final themeConfig = Provider.of<ThemeProvider>(context).activeParty;
    final l10n = AppLocalizations.of(context)!;

    final List<Widget> screens = [
      const OfficerDashboardTab(),
      const OfficerComplaintsTab(),
      const OfficerReportsTab(),
      OfficerProfileTab(
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

class OfficerDashboardTab extends StatefulWidget {
  const OfficerDashboardTab({super.key});

  @override
  State<OfficerDashboardTab> createState() => _OfficerDashboardTabState();
}

class _OfficerDashboardTabState extends State<OfficerDashboardTab> {
  int _selectedPriorityFilter = 0; // 0: All, 1: Low, 2: Medium, 3: High

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final themeConfig = Provider.of<ThemeProvider>(context).activeParty;
    final l10n = AppLocalizations.of(context)!;
    final isTelugu = appState.isTelugu;
    final user = appState.currentUser;

    // Filter complaints strictly by this officer's assigned department
    final myRole = user?.officerRole ?? '';
    final allComplaints = appState.complaints.where((c) {
      return CategoryMapping.getOfficerRoleForCategory(c.category) == myRole;
    }).toList();

    // 6 stat cards
    final totalAssigned = allComplaints.length;
    final newComplaints = allComplaints.where((c) => c.status == ComplaintStatus.submitted).length;
    final inProgress = allComplaints.where((c) => c.status == ComplaintStatus.inProgress).length;
    final resolved = allComplaints.where((c) => c.status == ComplaintStatus.resolved).length;
    
    final now = DateTime.now();
    final escalated = allComplaints.where((c) => c.status != ComplaintStatus.resolved && now.difference(c.createdAt).inHours > 24).length;
    final slaBreached = allComplaints.where((c) => c.status != ComplaintStatus.resolved && now.difference(c.createdAt).inHours > 72).length;

    // Today's assignments & priority filtering
    final today = DateTime.now();
    final todayComplaints = allComplaints.where((c) => 
      c.createdAt.year == today.year && 
      c.createdAt.month == today.month && 
      c.createdAt.day == today.day
    ).toList();
    
    List<Complaint> filteredTodayComplaints = todayComplaints;
    if (_selectedPriorityFilter == 1) {
      filteredTodayComplaints = todayComplaints.where((c) => c.priority == ComplaintPriority.low).toList();
    } else if (_selectedPriorityFilter == 2) {
      filteredTodayComplaints = todayComplaints.where((c) => c.priority == ComplaintPriority.medium).toList();
    } else if (_selectedPriorityFilter == 3) {
      filteredTodayComplaints = todayComplaints.where((c) => c.priority == ComplaintPriority.high).toList();
    }

    // SLA Tracker counts
    final activeComplaints = allComplaints.where((c) => c.status != ComplaintStatus.resolved).toList();
    int due24 = 0, due48 = 0, due72 = 0, overdue = 0;
    for (var c in activeComplaints) {
      final hoursPassed = now.difference(c.createdAt).inHours;
      final hoursRemaining = 72 - hoursPassed;
      if (hoursRemaining < 0) { overdue++; } else if (hoursRemaining <= 24) { due24++; } else if (hoursRemaining <= 48) { due48++; } else { due72++; }
    }

    // Sub-category distribution
    Map<String, int> subCatCounts = {};
    for (var c in allComplaints) {
      subCatCounts[c.category] = (subCatCounts[c.category] ?? 0) + 1;
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
                  '$myRole ${l10n.categoryOfficerDashboard}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  isTelugu ? '${user?.wardName ?? ''} పరిధి' : '${user?.wardName ?? ''} Jurisdiction',
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
            OfficerProfileCard(
              user: user,
              location: user?.wardName ?? '',
              themeConfig: themeConfig,
              onProfileTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const OfficerProfileTab(isPushed: true)));
              },
            ),
            const SizedBox(height: 24),

            SectionHeader(title: l10n.myDepartmentSummary),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.2,
              children: [
                _buildGridStat(l10n.total, totalAssigned, themeConfig.primaryColor),
                _buildGridStat(l10n.newComplaints, newComplaints, Colors.blue),
                _buildGridStat(l10n.inProgress, inProgress, Colors.orange),
                _buildGridStat(l10n.resolved, resolved, Colors.green),
                _buildGridStat(l10n.escalated, escalated, Colors.red.shade400),
                _buildGridStat(l10n.slaBreached, slaBreached, Colors.red.shade900),
              ],
            ),
            const SizedBox(height: 24),

            SectionHeader(title: l10n.priorityQueue),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildPriorityTab(0, l10n.total, todayComplaints.length, Colors.grey),
                  const SizedBox(width: 8),
                  _buildPriorityTab(1, l10n.normal, todayComplaints.where((c) => c.priority == ComplaintPriority.low).length, Colors.green),
                  const SizedBox(width: 8),
                  _buildPriorityTab(2, l10n.highPriority, todayComplaints.where((c) => c.priority == ComplaintPriority.medium).length, Colors.orange),
                  const SizedBox(width: 8),
                  _buildPriorityTab(3, l10n.urgent, todayComplaints.where((c) => c.priority == ComplaintPriority.high).length, Colors.red),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              color: Colors.white,
              child: filteredTodayComplaints.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Center(child: Text(l10n.noComplaints, style: const TextStyle(color: Colors.grey))),
                    )
                  : Column(
                      children: filteredTodayComplaints.map((c) => ComplaintListTile(
                        complaint: c,
                        isTelugu: isTelugu,
                        showPriority: true,
                        onTap: () {
                          appState.setHighlightedComplaintId(c.id);
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const TrackComplaintsScreen()));
                        },
                      )).toList(),
                    ),
            ),
            const SizedBox(height: 24),

            SectionHeader(title: l10n.slaTracker),
            const SizedBox(height: 12),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSLABar('24h', due24, activeComplaints.length, Colors.green),
                    _buildSLABar('48h', due48, activeComplaints.length, Colors.orange),
                    _buildSLABar('72h', due72, activeComplaints.length, Colors.deepOrange),
                    _buildSLABar(l10n.overdue, overdue, activeComplaints.length, Colors.red),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.subCategoryDetails, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: SizedBox(
                            height: 150,
                            child: subCatCounts.isEmpty
                                ? Center(child: Text(l10n.noComplaints, style: const TextStyle(fontSize: 12, color: Colors.grey)))
                                : PieChart(
                                    PieChartData(
                                      sectionsSpace: 2,
                                      centerSpaceRadius: 20,
                                      sections: subCatCounts.entries.map((e) {
                                        return PieChartSectionData(
                                          color: CategoryMapping.getColorForCategory(e.key),
                                          value: e.value.toDouble(),
                                          showTitle: true,
                                          title: '${e.value}',
                                          radius: 25,
                                          titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.resolutionProgress, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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
                                    spots: const [FlSpot(1, 2), FlSpot(2, 5), FlSpot(3, 4), FlSpot(4, 8), FlSpot(5, 7)],
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
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            SectionHeader(title: l10n.quickActions),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildQuickActionBtn(Icons.forward, l10n.forward, themeConfig.primaryColor, () {}),
                  _buildQuickActionBtn(Icons.warning, l10n.escalate, themeConfig.primaryColor, () {}),
                  _buildQuickActionBtn(Icons.check_circle, l10n.close, themeConfig.primaryColor, () {}),
                  _buildQuickActionBtn(Icons.phone, l10n.callCitizen, themeConfig.primaryColor, () {}),
                  _buildQuickActionBtn(Icons.picture_as_pdf, l10n.generateReport, themeConfig.primaryColor, () {}),
                ],
              ),
            ),
            const SizedBox(height: 24),

            SectionHeader(title: l10n.broadcastSection),
            const SizedBox(height: 12),
            Column(
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateAnnouncementScreen()));
                  },
                  icon: const Icon(Icons.campaign),
                  label: Text(l10n.departmentAnnouncement),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 45),
                    backgroundColor: Colors.white,
                    foregroundColor: themeConfig.primaryColor,
                    elevation: 1,
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const BroadcastHistoryScreen()));
                  },
                  icon: const Icon(Icons.history),
                  label: const Text('Broadcast History'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 45),
                    backgroundColor: themeConfig.primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 1,
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

  Widget _buildGridStat(String label, int value, Color color) {
    return Card(
      elevation: 0,
      color: color.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('$value', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey.shade700), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildPriorityTab(int index, String label, int count, Color color) {
    final isSelected = _selectedPriorityFilter == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPriorityFilter = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? color : Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Text(label, style: TextStyle(color: isSelected ? color : Colors.grey.shade700, fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('$count', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSLABar(String label, int count, int total, Color color) {
    double pct = total > 0 ? count / total : 0.0;
    return Column(
      children: [
        Text('$count', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Container(
          height: 40,
          width: 8,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(4),
          ),
          alignment: Alignment.bottomCenter,
          child: FractionallySizedBox(
            heightFactor: pct,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildQuickActionBtn(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 16),
        width: 70,
        child: Column(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: color.withValues(alpha: 0.1),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class OfficerComplaintsTab extends StatelessWidget {
  const OfficerComplaintsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final themeConfig = Provider.of<ThemeProvider>(context).activeParty;
    final l10n = AppLocalizations.of(context)!;
    final myRole = appState.currentUser?.officerRole ?? '';
    final complaints = appState.complaints.where((c) {
      return CategoryMapping.getOfficerRoleForCategory(c.category) == myRole;
    }).toList();

    return Scaffold(
      backgroundColor: themeConfig.backgroundColor,
      appBar: OfficerAppBar(
        title: l10n.complaint,
        subtitle: myRole,
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
                      showPriority: true,
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

class OfficerReportsTab extends StatelessWidget {
  const OfficerReportsTab({super.key});

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

class OfficerProfileTab extends StatefulWidget {
  final VoidCallback? onProfileSaved;
  final bool isPushed;

  const OfficerProfileTab({super.key, this.onProfileSaved, this.isPushed = false});

  @override
  State<OfficerProfileTab> createState() => _OfficerProfileTabState();
}

class _OfficerProfileTabState extends State<OfficerProfileTab> {
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
    final isTelugu = appState.isTelugu;

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
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey.shade300,
                          backgroundImage: user?.profilePhotoUrl != null && user!.profilePhotoUrl!.isNotEmpty
                              ? (user.profilePhotoUrl!.startsWith('http') || kIsWeb
                                  ? NetworkImage(user.profilePhotoUrl!) as ImageProvider
                                  : FileImage(File(user.profilePhotoUrl!)))
                              : null,
                          child: (user?.profilePhotoUrl == null || user!.profilePhotoUrl!.isEmpty)
                              ? const Icon(Icons.person, size: 50, color: Colors.grey)
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: themeConfig.primaryColor,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: _isSaving 
                                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user?.name ?? 'Officer Name',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isTelugu ? '${user?.wardName} - ${user?.officerRole}' : '${user?.wardName} - ${user?.officerRole}',
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const Divider(height: 32),
                    Row(
                      children: [
                        const Icon(Icons.phone_outlined, size: 20, color: Colors.grey),
                        const SizedBox(width: 12),
                        Text(user?.phoneNumber ?? '', style: const TextStyle(fontSize: 15)),
                      ],
                    ),
                  ],
                ),
              ),
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
    );
  }
}

