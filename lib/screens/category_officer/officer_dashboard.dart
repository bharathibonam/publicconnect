import 'dart:typed_data';
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
import '../../models/user.dart';
import '../../widgets/shared_officer_widgets.dart';
import '../../widgets/notification_bell.dart';
import '../../widgets/officer_interactive_dialogs.dart';
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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final user = appState.currentUser;
    if (appState.requestedCategoryOfficerTabIndex != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _currentIndex = appState.requestedCategoryOfficerTabIndex!;
          });
          appState.clearCategoryOfficerTabIndex();
        }
      });
    }

    final themeConfig = Provider.of<ThemeProvider>(context).activeParty;
    final l10n = AppLocalizations.of(context)!;

    final List<Widget> screens = [
      OfficerDashboardHomeTab(
        onNavigateToTab: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        onMenuPressed: () {
          _scaffoldKey.currentState?.openDrawer();
        },
      ),
      const CategoryComplaintsTab(),
      const CategoryReportsTab(),
      CategoryProfileTab(
        onProfileSaved: () {
          setState(() {
            _currentIndex = 0;
          });
        },
      ),
    ];

    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (_currentIndex != 0) {
          setState(() {
            _currentIndex = 0;
          });
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        drawer: Drawer(
          child: Column(
            children: [
              UserAccountsDrawerHeader(
                decoration: BoxDecoration(color: themeConfig.primaryColor),
                accountName: Text(user?.name ?? 'Category Officer', style: const TextStyle(fontWeight: FontWeight.bold)),
                accountEmail: Text(user?.phoneNumber ?? ''),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 40, color: themeConfig.primaryColor),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.home_outlined),
                title: Text(l10n.home),
                selected: _currentIndex == 0,
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _currentIndex = 0);
                },
              ),
              ListTile(
                leading: const Icon(Icons.list_alt_outlined),
                title: Text(l10n.complaint),
                selected: _currentIndex == 1,
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _currentIndex = 1);
                },
              ),
              ListTile(
                leading: const Icon(Icons.bar_chart_outlined),
                title: Text(l10n.reports),
                selected: _currentIndex == 2,
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _currentIndex = 2);
                },
              ),
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text(l10n.profile),
                selected: _currentIndex == 3,
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _currentIndex = 3);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Logout', style: TextStyle(color: Colors.red)),
                onTap: () async {
                  Navigator.pop(context);
                  await appState.logout();
                  if (context.mounted) {
                    Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
                  }
                },
              ),
            ],
          ),
        ),
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
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 1. HOME DASHBOARD
// -----------------------------------------------------------------------------
class OfficerDashboardHomeTab extends StatefulWidget {
  final Function(int)? onNavigateToTab;
  final VoidCallback? onMenuPressed;
  const OfficerDashboardHomeTab({super.key, this.onNavigateToTab, this.onMenuPressed});

  @override
  State<OfficerDashboardHomeTab> createState() => _OfficerDashboardHomeTabState();
}

class _OfficerDashboardHomeTabState extends State<OfficerDashboardHomeTab> {
  int _selectedPriorityFilter = 0; // 0: High, 1: Medium, 2: Low

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final themeConfig = Provider.of<ThemeProvider>(context).activeParty;
    final l10n = AppLocalizations.of(context)!;
    final isTelugu = appState.isTelugu;
    final user = appState.currentUser;

    // Dynamic stats calculated from real Supabase DB complaints
    final categoryComplaints = appState.complaintsForCategoryOfficer(user);

    final totalCount = categoryComplaints.length;
    final newCount = categoryComplaints.where((c) => c.status == ComplaintStatus.submitted).length;
    final inProgressCount = categoryComplaints.where((c) => c.status == ComplaintStatus.inProgress).length;
    final resolvedCount = categoryComplaints.where((c) => c.status == ComplaintStatus.resolved).length;
    final escalatedCount = categoryComplaints.where((c) => c.isPushed || DateTime.now().difference(c.createdAt).inHours >= 24).length;
    final slaBreachedCount = categoryComplaints.where((c) => c.status != ComplaintStatus.resolved && DateTime.now().difference(c.createdAt).inHours >= 24).length;
    final rejectedCount = categoryComplaints.where((c) => c.status == ComplaintStatus.rejected).length;
    final onHoldCount = categoryComplaints.where((c) => c.status == ComplaintStatus.onHold).length;

    // Dynamic Today's Tasks
    final now = DateTime.now();
    final todayAssigned = categoryComplaints.where((c) => c.createdAt.day == now.day && c.createdAt.month == now.month && c.createdAt.year == now.year).length;
    final siteVisits = inProgressCount;
    final pendingUpdates = newCount;
    final dueToday = categoryComplaints.where((c) {
      if (c.status == ComplaintStatus.resolved) return false;
      final hours = now.difference(c.createdAt).inHours;
      return hours >= 18 && hours < 24;
    }).length;

    // Dynamic Priority Queues
    final highPriorityList = categoryComplaints.where((c) => c.priority == ComplaintPriority.high && c.status != ComplaintStatus.resolved).toList();
    final medPriorityList = categoryComplaints.where((c) => c.priority == ComplaintPriority.medium && c.status != ComplaintStatus.resolved).toList();
    final lowPriorityList = categoryComplaints.where((c) => c.priority == ComplaintPriority.low && c.status != ComplaintStatus.resolved).toList();

    List<Complaint> activePriorityList;
    if (_selectedPriorityFilter == 0) {
      activePriorityList = highPriorityList;
    } else if (_selectedPriorityFilter == 1) {
      activePriorityList = medPriorityList;
    } else {
      activePriorityList = lowPriorityList;
    }

    // Dynamic SLA Tracker
    final within24h = categoryComplaints.where((c) => c.status != ComplaintStatus.resolved && now.difference(c.createdAt).inHours < 24).length;
    final within48h = categoryComplaints.where((c) => c.status != ComplaintStatus.resolved && now.difference(c.createdAt).inHours >= 24 && now.difference(c.createdAt).inHours < 48).length;
    final within72h = categoryComplaints.where((c) => c.status != ComplaintStatus.resolved && now.difference(c.createdAt).inHours >= 48 && now.difference(c.createdAt).inHours < 72).length;
    final overdueCount = categoryComplaints.where((c) => c.status != ComplaintStatus.resolved && now.difference(c.createdAt).inHours >= 72).length;

    // Dynamic Performance Metrics
    final resolutionRate = totalCount > 0 ? ((resolvedCount / totalCount) * 100).round() : 0;
    final slaCompliance = totalCount > 0 ? ((((totalCount - slaBreachedCount) / totalCount) * 100).round().clamp(0, 100)) : 100;

    final canonicalRole = user?.officerRole != null && user!.officerRole!.isNotEmpty ? user.officerRole! : 'Category Officer';
    final userMandalVillage = '${user?.mandalName ?? "Constituency"} ${user?.villageName != null ? "• ${user!.villageName}" : ""}';

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [themeConfig.primaryColor, themeConfig.primaryColor.withOpacity(0.85)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.menu, color: Colors.white, size: 24),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: widget.onMenuPressed ?? () {},
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          canonicalRole,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          userMandalVillage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.flash_on_rounded, color: Colors.yellowAccent),
                    tooltip: 'Quick Actions',
                    onPressed: () => OfficerInteractiveDialogs.showQuickActionsModal(context, themeConfig, isCategoryOfficer: true),
                  ),
                  const NotificationBell(color: Colors.white),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      if (widget.onNavigateToTab != null) {
                        widget.onNavigateToTab!(3);
                      }
                    },
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.white24,
                      backgroundImage: user?.profilePhotoUrl != null && user!.profilePhotoUrl!.isNotEmpty
                          ? (user.profilePhotoUrl!.startsWith('http') || kIsWeb
                              ? NetworkImage(user.profilePhotoUrl!)
                              : FileImage(File(user.profilePhotoUrl!)) as ImageProvider)
                          : null,
                      child: (user?.profilePhotoUrl == null || user!.profilePhotoUrl!.isEmpty)
                          ? const Icon(Icons.person, color: Colors.white, size: 18)
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: themeConfig.primaryColor.withOpacity(0.1),
                      backgroundImage: user?.profilePhotoUrl != null && user!.profilePhotoUrl!.isNotEmpty
                          ? (user.profilePhotoUrl!.startsWith('http') || kIsWeb
                              ? NetworkImage(user.profilePhotoUrl!)
                              : FileImage(File(user.profilePhotoUrl!)) as ImageProvider)
                          : null,
                      child: (user?.profilePhotoUrl == null || user!.profilePhotoUrl!.isEmpty)
                          ? Icon(Icons.person_rounded, size: 32, color: themeConfig.primaryColor)
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.name ?? 'Category Officer',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Category Officer - ${user?.officerRole ?? "General"}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Officer ID: ${user?.id != null ? (user!.id.length > 8 ? user.id.substring(0, 8).toUpperCase() : user.id) : "CO1001"}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Department Summary Section
            _buildSectionHeader('Department Summary', onViewAll: () {
              if (widget.onNavigateToTab != null) widget.onNavigateToTab!(1);
            }),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.82,
              children: [
                _buildStatBox('Total', totalCount.toString(), themeConfig.primaryColor, () {
                  appState.setCategoryOfficerTabIndex(1, filter: 'All');
                }),
                _buildStatBox('New', newCount.toString(), Colors.blue, () {
                  appState.setCategoryOfficerTabIndex(1, filter: 'New');
                }),
                _buildStatBox('In Progress', inProgressCount.toString(), Colors.orange, () {
                  appState.setCategoryOfficerTabIndex(1, filter: 'In Progress');
                }),
                _buildStatBox('Resolved', resolvedCount.toString(), Colors.green, () {
                  appState.setCategoryOfficerTabIndex(1, filter: 'Resolved');
                }),
                _buildStatBox('Escalated', escalatedCount.toString(), Colors.red.shade400, () {
                  appState.setCategoryOfficerTabIndex(1, filter: 'Escalated');
                }),
                _buildStatBox('SLA Breached', slaBreachedCount.toString(), Colors.red.shade800, () {
                  appState.setCategoryOfficerTabIndex(1, filter: 'SLA Breached');
                }),
                _buildStatBox('Rejected', rejectedCount.toString(), Colors.purple, () {
                  appState.setCategoryOfficerTabIndex(1, filter: 'Rejected');
                }),
                _buildStatBox('On Hold', onHoldCount.toString(), Colors.blueGrey, () {
                  appState.setCategoryOfficerTabIndex(1, filter: 'On Hold');
                }),
              ],
            ),
            const SizedBox(height: 20),

            // Today's Tasks Section
            _buildSectionHeader("Today's Tasks", onViewAll: () {
              if (widget.onNavigateToTab != null) widget.onNavigateToTab!(1);
            }),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildTaskCard('Assigned', todayAssigned.toString(), Colors.blue.shade700)),
                const SizedBox(width: 8),
                Expanded(child: _buildTaskCard('Site Visits', siteVisits.toString(), Colors.cyan.shade700)),
                const SizedBox(width: 8),
                Expanded(child: _buildTaskCard('Pending Updates', pendingUpdates.toString(), Colors.amber.shade800)),
                const SizedBox(width: 8),
                Expanded(child: _buildTaskCard('Due Today', dueToday.toString(), Colors.red.shade700)),
              ],
            ),
            const SizedBox(height: 20),

            // Priority Queue Section
            _buildSectionHeader('Priority Queue', onViewAll: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoryPriorityQueueScreen()));
            }),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildPriorityFilterChip(0, 'High (${highPriorityList.length})', Colors.red),
                const SizedBox(width: 8),
                _buildPriorityFilterChip(1, 'Medium (${medPriorityList.length})', Colors.orange),
                const SizedBox(width: 8),
                _buildPriorityFilterChip(2, 'Low (${lowPriorityList.length})', Colors.green),
              ],
            ),
            const SizedBox(height: 12),
            if (activePriorityList.isNotEmpty)
              ...activePriorityList.take(3).map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: _buildPriorityItemCard(
                      context,
                      title: item.category,
                      location: '${item.wardName ?? "Ward"}, ${item.villageName ?? "Village"}',
                      priority: item.priority.name.toUpperCase(),
                      timeAgo: '${DateTime.now().difference(item.createdAt).inHours}h ago',
                      color: item.priority == ComplaintPriority.high
                          ? Colors.red
                          : (item.priority == ComplaintPriority.medium ? Colors.orange : Colors.green),
                    ),
                  ))
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: const Center(
                  child: Text('No active complaints in this priority queue.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ),
              ),
            const SizedBox(height: 20),

            // SLA Tracker Preview
            _buildSectionHeader('SLA Tracker', onViewAll: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const CategorySLATrackerScreen()));
            }),
            const SizedBox(height: 12),
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSLAStatChip('Within 24h', within24h.toString(), Colors.green),
                    _buildSLAStatChip('Within 48h', within48h.toString(), Colors.amber),
                    _buildSLAStatChip('Within 72h', within72h.toString(), Colors.orange),
                    _buildSLAStatChip('Overdue', overdueCount.toString(), Colors.red),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Department Performance Section
            _buildSectionHeader('Department Performance', onViewAllText: 'View Report', onViewAll: () {
              if (widget.onNavigateToTab != null) widget.onNavigateToTab!(2);
            }),
            const SizedBox(height: 12),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    SizedBox(
                      width: 90,
                      height: 90,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          PieChart(
                            PieChartData(
                              sectionsSpace: 0,
                              centerSpaceRadius: 28,
                              sections: [
                                PieChartSectionData(color: Colors.green, value: resolutionRate.toDouble(), radius: 12, showTitle: false),
                                PieChartSectionData(color: Colors.grey.shade200, value: (100 - resolutionRate).clamp(0, 100).toDouble(), radius: 12, showTitle: false),
                              ],
                            ),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('$resolutionRate%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
                              const Text('Resolution', style: TextStyle(fontSize: 7, color: Colors.grey)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.timer_outlined, size: 16, color: Colors.grey),
                              const SizedBox(width: 6),
                              Text('Avg. Resolution Time: ', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                              Text('${resolvedCount > 0 ? "1.2" : "0"} Days', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.verified_outlined, size: 16, color: Colors.grey),
                              const SizedBox(width: 6),
                              Text('SLA Compliance: ', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                              Text('$slaCompliance%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {String onViewAllText = 'View All', VoidCallback? onViewAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
        if (onViewAll != null)
          GestureDetector(
            onTap: onViewAll,
            child: Text(onViewAllText, style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold)),
          ),
      ],
    );
  }

  Widget _buildStatBox(String label, String value, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
              ),
            ),
            const SizedBox(height: 2),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.0),
              child: Text(
                label,
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCard(String label, String count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(count, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityFilterChip(int index, String label, Color color) {
    final isSelected = _selectedPriorityFilter == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedPriorityFilter = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.12) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? color : Colors.grey.shade300),
        ),
        child: Text(label, style: TextStyle(color: isSelected ? color : Colors.grey.shade700, fontWeight: FontWeight.bold, fontSize: 12)),
      ),
    );
  }

  Widget _buildPriorityItemCard(BuildContext context, {required String title, required String location, required String priority, required String timeAgo, required Color color}) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoryComplaintDetailsScreen()));
        },
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(Icons.water_drop, color: color, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(location, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
              child: Text(priority, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 4),
            Text(timeAgo, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildSLAStatChip(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// 2. COMPLAINTS TAB
// -----------------------------------------------------------------------------
class CategoryComplaintsTab extends StatefulWidget {
  const CategoryComplaintsTab({super.key});

  @override
  State<CategoryComplaintsTab> createState() => _CategoryComplaintsTabState();
}

class _CategoryComplaintsTabState extends State<CategoryComplaintsTab> {
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final user = appState.currentUser;
    final allComplaints = appState.complaintsForCategoryOfficer(user);

    final totalCount = allComplaints.length;
    final newCount = allComplaints.where((c) => c.status == ComplaintStatus.submitted).length;
    final inProgressCount = allComplaints.where((c) => c.status == ComplaintStatus.inProgress).length;
    final resolvedCount = allComplaints.where((c) => c.status == ComplaintStatus.resolved).length;
    final escalatedCount = allComplaints.where((c) => c.isPushed || DateTime.now().difference(c.createdAt).inHours >= 24).length;
    final slaBreachedCount = allComplaints.where((c) => c.status != ComplaintStatus.resolved && DateTime.now().difference(c.createdAt).inHours >= 24).length;
    final rejectedCount = allComplaints.where((c) => c.status == ComplaintStatus.rejected).length;
    final onHoldCount = allComplaints.where((c) => c.status == ComplaintStatus.onHold).length;

    final activeFilter = appState.categoryOfficerActiveFilter;
    var filtered = allComplaints;

    if (activeFilter == 'New') {
      filtered = filtered.where((c) => c.status == ComplaintStatus.submitted).toList();
    } else if (activeFilter == 'In Progress') {
      filtered = filtered.where((c) => c.status == ComplaintStatus.inProgress).toList();
    } else if (activeFilter == 'Resolved') {
      filtered = filtered.where((c) => c.status == ComplaintStatus.resolved).toList();
    } else if (activeFilter == 'Escalated') {
      filtered = filtered.where((c) => c.isPushed || DateTime.now().difference(c.createdAt).inHours >= 24).toList();
    } else if (activeFilter == 'SLA Breached') {
      filtered = filtered.where((c) => c.status != ComplaintStatus.resolved && DateTime.now().difference(c.createdAt).inHours >= 24).toList();
    } else if (activeFilter == 'Rejected') {
      filtered = filtered.where((c) => c.status == ComplaintStatus.rejected).toList();
    } else if (activeFilter == 'On Hold') {
      filtered = filtered.where((c) => c.status == ComplaintStatus.onHold).toList();
    }

    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered.where((c) {
        return c.id.toLowerCase().contains(query) ||
            c.category.toLowerCase().contains(query) ||
            c.description.toLowerCase().contains(query) ||
            c.wardName.toLowerCase().contains(query);
      }).toList();
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Department Complaints', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () {
            appState.setCategoryOfficerTabIndex(0);
          },
        ),
      ),
      body: Column(
        children: [
          // Dynamic Filter Tabs
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterTab(appState, 'All', 'All ($totalCount)'),
                  const SizedBox(width: 8),
                  _buildFilterTab(appState, 'New', 'New ($newCount)'),
                  const SizedBox(width: 8),
                  _buildFilterTab(appState, 'In Progress', 'In Progress ($inProgressCount)'),
                  const SizedBox(width: 8),
                  _buildFilterTab(appState, 'Resolved', 'Resolved ($resolvedCount)'),
                  const SizedBox(width: 8),
                  _buildFilterTab(appState, 'Escalated', 'Escalated ($escalatedCount)'),
                  const SizedBox(width: 8),
                  _buildFilterTab(appState, 'SLA Breached', 'SLA Breached ($slaBreachedCount)'),
                  const SizedBox(width: 8),
                  _buildFilterTab(appState, 'Rejected', 'Rejected ($rejectedCount)'),
                  const SizedBox(width: 8),
                  _buildFilterTab(appState, 'On Hold', 'On Hold ($onHoldCount)'),
                ],
              ),
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search by ID, category or location',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
              ),
            ),
          ),

          // Complaint list
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('No complaints found.', style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final c = filtered[index];
                      Color badgeColor = Colors.orange;
                      if (c.status == ComplaintStatus.resolved) badgeColor = Colors.green;
                      if (c.status == ComplaintStatus.inProgress) badgeColor = Colors.blue;

                      return Card(
                        elevation: 1,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          onTap: () => ComplaintDetailsModal.show(context, c, appState.isTelugu),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: badgeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                            child: Icon(Icons.assignment_outlined, color: badgeColor, size: 24),
                          ),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(child: Text(c.category, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: badgeColor.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                                child: Text(c.status.name.toUpperCase(), style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text('${c.wardName}, ${c.villageName}', style: const TextStyle(fontSize: 12, color: Colors.black54), maxLines: 1, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('ID: ${c.id.length > 8 ? c.id.substring(0, 8).toUpperCase() : c.id}', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                                  Text(c.priority.name.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: c.priority == ComplaintPriority.high ? Colors.red : Colors.orange)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab(AppState appState, String filter, String label) {
    final isSelected = appState.categoryOfficerActiveFilter == filter;
    return GestureDetector(
      onTap: () => appState.setCategoryOfficerActiveFilter(filter),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F766E) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.w600, fontSize: 12)),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 3. COMPLAINT DETAILS SCREEN
// -----------------------------------------------------------------------------
class CategoryComplaintDetailsScreen extends StatelessWidget {
  const CategoryComplaintDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeConfig = Provider.of<ThemeProvider>(context).activeParty;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Complaint Details', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: const BackButton(color: Colors.black87),
        actions: [
          IconButton(icon: const Icon(Icons.share_outlined, color: Colors.black87), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Complaint Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle),
                  child: const Icon(Icons.water_drop, color: Colors.blue, size: 26),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Water Supply Issue', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('#CMP-248', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
                  child: const Text('In Progress', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                const Text('Ward 12, Bhupalapatnam', style: TextStyle(fontSize: 12, color: Colors.black87)),
                const Spacer(),
                const Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                const Text('16 Jul 2026 • 10:30 AM', style: TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
            const Divider(height: 24),

            // Description
            const Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 6),
            const Text(
              'There is no proper water supply in our area since last 5 days. Please resolve this issue immediately.',
              style: TextStyle(fontSize: 13, color: Colors.black54, height: 1.4),
            ),
            const SizedBox(height: 16),

            // Location with Map Preview
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Location', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                GestureDetector(
                  onTap: () => OfficerInteractiveDialogs.showNavigateDialog(context),
                  child: const Text('View on Map', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: const [
                Icon(Icons.pin_drop, size: 16, color: Colors.red),
                SizedBox(width: 4),
                Text('1st Cross Road, Ward 12, Bhupalapatnam', style: TextStyle(fontSize: 12, color: Colors.black87)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 120,
                width: double.infinity,
                color: Colors.blueGrey.shade100,
                child: Stack(
                  alignment: Alignment.center,
                  children: const [
                    Icon(Icons.map, size: 50, color: Colors.grey),
                    Icon(Icons.location_on, size: 36, color: Colors.red),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Timeline
            const Text('Timeline', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 12),
            _buildTimelineTile('Complaint Registered', '16 Jul 2026 • 10:30 AM', isDone: true),
            _buildTimelineTile('Assigned to Officer', '16 Jul 2026 • 11:20 AM', isDone: true),
            _buildTimelineTile('Work in Progress', '16 Jul 2026 • 01:45 PM', isDone: true),
            _buildTimelineTile('In Progress', '17 Jul 2026 • 09:15 AM', isDone: true),
            _buildTimelineTile('Resolved', '', isDone: false, isLast: true),

            const Divider(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoryUpdateWorkScreen()));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeConfig.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Update Status', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      OfficerInteractiveDialogs.showAddFeedbackSheet(context, themeConfig);
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: themeConfig.primaryColor),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text('Add Feedback', style: TextStyle(color: themeConfig.primaryColor, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineTile(String title, String subtitle, {required bool isDone, bool isLast = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Icon(isDone ? Icons.check_circle : Icons.radio_button_unchecked, size: 18, color: isDone ? Colors.blue : Colors.grey),
            if (!isLast) Container(width: 2, height: 26, color: isDone ? Colors.blue : Colors.grey.shade300),
          ],
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontWeight: isDone ? FontWeight.bold : FontWeight.normal, fontSize: 13)),
            if (subtitle.isNotEmpty) Text(subtitle, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// 4. UPDATE WORK SCREEN
// -----------------------------------------------------------------------------
class CategoryUpdateWorkScreen extends StatefulWidget {
  const CategoryUpdateWorkScreen({super.key});

  @override
  State<CategoryUpdateWorkScreen> createState() => _CategoryUpdateWorkScreenState();
}

class _CategoryUpdateWorkScreenState extends State<CategoryUpdateWorkScreen> {
  String _selectedStatus = 'Work In Progress';
  String _selectedNextAction = 'Issue Resolved';
  final TextEditingController _descController = TextEditingController(text: 'Pipeline repaired and water supply restored successfully.');
  final TextEditingController _remarksController = TextEditingController();
  final List<File> _photos = [];

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      setState(() {
        _photos.add(File(picked.path));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeConfig = Provider.of<ThemeProvider>(context).activeParty;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Update Work', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: const BackButton(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Update Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _selectedStatus,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: ['Work In Progress', 'Issue Resolved', 'On Hold', 'Pending Verification']
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (val) => setState(() => _selectedStatus = val!),
            ),
            const SizedBox(height: 16),

            const Text('Work Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 6),
            TextField(
              controller: _descController,
              maxLines: 3,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),

            const Text('Upload Photos (Optional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            Row(
              children: [
                ..._photos.map((file) => Container(
                  margin: const EdgeInsets.only(right: 10),
                  width: 70, height: 70,
                  child: Stack(
                    children: [
                      ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(file, width: 70, height: 70, fit: BoxFit.cover)),
                      Positioned(
                        top: 2, right: 2,
                        child: GestureDetector(
                          onTap: () => setState(() => _photos.remove(file)),
                          child: Container(color: Colors.black54, child: const Icon(Icons.close, size: 14, color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                )),
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 70, height: 70,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400, style: BorderStyle.solid),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.add, color: Colors.grey, size: 30),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            const Text('Next Action', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _selectedNextAction,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: ['Select Next Action', 'Issue Resolved', 'Request Materials', 'Forward to Higher Officer']
                  .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                  .toList(),
              onChanged: (val) => setState(() => _selectedNextAction = val!),
            ),
            const SizedBox(height: 16),

            const Text('Remarks (Optional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 6),
            TextField(
              controller: _remarksController,
              decoration: const InputDecoration(hintText: 'Enter remarks...', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Work update submitted successfully!')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeConfig.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Submit Update', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 5. REPORTS & ANALYTICS TAB
// -----------------------------------------------------------------------------
class CategoryReportsTab extends StatelessWidget {
  const CategoryReportsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final themeConfig = Provider.of<ThemeProvider>(context).activeParty;
    final user = appState.currentUser;
    final complaints = appState.complaintsForCategoryOfficer(user);

    final total = complaints.length;
    final resolved = complaints.where((c) => c.status == ComplaintStatus.resolved).length;
    final pending = complaints.where((c) => c.status == ComplaintStatus.submitted).length;
    final inProgress = complaints.where((c) => c.status == ComplaintStatus.inProgress).length;

    final resolvedPct = total > 0 ? (resolved / total * 100).toStringAsFixed(1) : '0.0';
    final inProgressPct = total > 0 ? (inProgress / total * 100).toStringAsFixed(1) : '0.0';
    final pendingPct = total > 0 ? (pending / total * 100).toStringAsFixed(1) : '0.0';

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Reports & Analytics', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () {
            appState.setCategoryOfficerTabIndex(0);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Text('Complaint Analytics', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 10),
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildOverviewStat('Total', total.toString(), Colors.blue.shade700),
                        _buildOverviewStat('Resolved', resolved.toString(), Colors.green),
                        _buildOverviewStat('Pending', pending.toString(), Colors.amber.shade800),
                        _buildOverviewStat('In Progress', inProgress.toString(), Colors.purple),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 140,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          PieChart(
                            PieChartData(
                              sectionsSpace: 2,
                              centerSpaceRadius: 40,
                              sections: [
                                PieChartSectionData(color: Colors.green, value: total > 0 ? resolved.toDouble() : 1, radius: 18, showTitle: false),
                                PieChartSectionData(color: Colors.purple, value: total > 0 ? inProgress.toDouble() : 0, radius: 18, showTitle: false),
                                PieChartSectionData(color: Colors.amber, value: total > 0 ? pending.toDouble() : 0, radius: 18, showTitle: false),
                              ],
                            ),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(total.toString(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              const Text('Total', style: TextStyle(fontSize: 10, color: Colors.grey)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildLegendItem('Resolved', '$resolved ($resolvedPct%)', Colors.green),
                        const SizedBox(width: 12),
                        _buildLegendItem('In Progress', '$inProgress ($inProgressPct%)', Colors.purple),
                        const SizedBox(width: 12),
                        _buildLegendItem('Pending', '$pending ($pendingPct%)', Colors.amber),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Category Wise Breakdown', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text('Live Data', style: TextStyle(color: themeConfig.primaryColor, fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 10),
            if (complaints.isEmpty)
              const Center(child: Text('No complaints recorded in database.', style: TextStyle(color: Colors.grey)))
            else
              ..._buildDynamicCategoryBars(complaints),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Generating Excel Report from Supabase... Download started!')),
                  );
                },
                icon: const Icon(Icons.download, color: Colors.white),
                label: const Text('Generate Excel Report', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeConfig.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildDynamicCategoryBars(List<Complaint> complaints) {
    final Map<String, int> counts = {};
    for (var c in complaints) {
      counts[c.category] = (counts[c.category] ?? 0) + 1;
    }
    final total = complaints.length;
    final List<Widget> bars = [];
    counts.forEach((cat, count) {
      final ratio = total > 0 ? count / total : 0.0;
      bars.add(_buildCategoryProgressBar(cat, count, ratio, Colors.blue.shade700));
    });
    return bars;
  }

  Widget _buildOverviewStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Widget _buildLegendItem(String label, String pct, Color color) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text('$label $pct', style: const TextStyle(fontSize: 10, color: Colors.black87)),
      ],
    );
  }

  Widget _buildCategoryProgressBar(String label, int count, double pct, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
              Text('$count (${(pct * 100).toStringAsFixed(1)}%)', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: pct, minHeight: 8, backgroundColor: Colors.grey.shade200, color: color),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 6. PRIORITY QUEUE SCREEN
// -----------------------------------------------------------------------------
class CategoryPriorityQueueScreen extends StatefulWidget {
  const CategoryPriorityQueueScreen({super.key});

  @override
  State<CategoryPriorityQueueScreen> createState() => _CategoryPriorityQueueScreenState();
}

class _CategoryPriorityQueueScreenState extends State<CategoryPriorityQueueScreen> {
  int _selectedFilter = 0; // High (3), Medium (4), Low (6)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Priority Queue', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: const BackButton(color: Colors.black87),
        actions: [
          IconButton(icon: const Icon(Icons.filter_list, color: Colors.black87), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _buildPriorityChip(0, 'High (3)', Colors.red),
                const SizedBox(width: 8),
                _buildPriorityChip(1, 'Medium (4)', Colors.orange),
                const SizedBox(width: 8),
                _buildPriorityChip(2, 'Low (6)', Colors.green),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildPriorityCard('Water Leakage', 'Ward 12, Bhupalapatnam', 'High', '2h ago', Colors.red),
                _buildPriorityCard('Drainage Blocked', 'Ward 6, Bhupalapatnam', 'High', '3h ago', Colors.red),
                _buildPriorityCard('Road Repair Needed', 'Ward 9, Bhupalapatnam', 'Medium', '5h ago', Colors.orange),
                _buildPriorityCard('Street Light Not Working', 'Ward 3, Bhupalapatnam', 'Medium', '1d ago', Colors.orange),
                _buildPriorityCard('Garbage Not Cleared', 'Ward 5, Bhupalapatnam', 'Low', '1d ago', Colors.green),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F766E),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('View All Complaints', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityChip(int index, String label, Color color) {
    final isSelected = _selectedFilter == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? color : Colors.transparent),
        ),
        child: Text(label, style: TextStyle(color: isSelected ? color : Colors.black87, fontWeight: FontWeight.bold, fontSize: 12)),
      ),
    );
  }

  Widget _buildPriorityCard(String title, String location, String priority, String timeAgo, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoryComplaintDetailsScreen()));
        },
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(location, style: const TextStyle(fontSize: 12, color: Colors.black54)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(priority, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
            const SizedBox(height: 2),
            Text(timeAgo, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 7. SLA TRACKER SCREEN
// -----------------------------------------------------------------------------
class CategorySLATrackerScreen extends StatelessWidget {
  const CategorySLATrackerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('SLA Tracker', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: const BackButton(color: Colors.black87),
        actions: [
          IconButton(icon: const Icon(Icons.info_outline, color: Colors.black87), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSLAChip('6', 'Within 24h', Colors.green),
                _buildSLAChip('4', 'Within 48h', Colors.amber),
                _buildSLAChip('2', 'Within 72h', Colors.orange),
                _buildSLAChip('1', 'Overdue', Colors.red),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('Overdue Complaints (1)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.red)),
                const SizedBox(height: 8),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    title: const Text('Water Supply Issue', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: const Text('Ward 8, Bhupalapatnam • #CMP-201 • Due 12 Jul 2026', style: TextStyle(fontSize: 11)),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(6)),
                      child: const Text('2 Days Overdue', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 10)),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                const Text('Due Soon', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                _buildDueSoonCard('Drainage Blocked', 'Ward 6, Bhupalapatnam', 'Due in 10h'),
                _buildDueSoonCard('Street Light Not Working', 'Ward 3, Bhupalapatnam', 'Due in 16h'),
                _buildDueSoonCard('Garbage Not Cleared', 'Ward 1, Bhupalapatnam', 'Due in 20h'),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F766E),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('View All', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSLAChip(String count, String label, Color color) {
    return Column(
      children: [
        Text(count, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _buildDueSoonCard(String title, String location, String dueText) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        subtitle: Text(location, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(6)),
          child: Text(dueText, style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 10)),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 9. PROFILE TAB
// -----------------------------------------------------------------------------
class CategoryProfileTab extends StatefulWidget {
  final VoidCallback? onProfileSaved;
  const CategoryProfileTab({super.key, this.onProfileSaved});

  @override
  State<CategoryProfileTab> createState() => _CategoryProfileTabState();
}

class _CategoryProfileTabState extends State<CategoryProfileTab> {
  final ImagePicker _picker = ImagePicker();
  bool _isSaving = false;

  void _showInfoDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CLOSE', style: TextStyle(color: Color(0xFF0F766E), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    final appState = Provider.of<AppState>(context, listen: false);
    final userId = appState.currentUser?.id ?? 'user';
    final name = appState.currentUser?.name ?? '';
    final phone = appState.currentUser?.phoneNumber ?? '';

    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (pickedFile != null) {
        String finalPath = pickedFile.path;
        Uint8List? bytes;
        
        if (kIsWeb) {
          bytes = await pickedFile.readAsBytes();
        } else {
          final appDir = await getApplicationDocumentsDirectory();
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final destPath = '${appDir.path}/profile_${userId}_$timestamp.jpg';
          final destFile = await File(pickedFile.path).copy(destPath);
          finalPath = destFile.path;
        }
        
        setState(() => _isSaving = true);
        await appState.updateUserProfile(name, phone, finalPath, profilePhotoBytes: bytes);
        if (mounted) {
          setState(() => _isSaving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile picture updated successfully!'), backgroundColor: Color(0xFF0F766E)),
          );
        }
      }
    } catch (e) {
      debugPrint('Error picking profile image: $e');
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final user = appState.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () {
            appState.setCategoryOfficerTabIndex(0);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // User Header Card
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.green.shade100,
                          backgroundImage: user != null && user.profilePhotoUrl != null && user.profilePhotoUrl!.isNotEmpty
                              ? (user.profilePhotoUrl!.startsWith('http') || kIsWeb
                                  ? NetworkImage(user.profilePhotoUrl!) as ImageProvider
                                  : FileImage(File(user.profilePhotoUrl!)))
                              : null,
                          child: (user == null || user.profilePhotoUrl == null || user.profilePhotoUrl!.isEmpty)
                              ? const Icon(Icons.person, size: 36, color: Colors.green)
                              : null,
                        ),
                        if (_isSaving)
                          const Positioned.fill(
                            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0F766E)),
                          ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: Color(0xFF0F766E),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.camera_alt, size: 12, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user?.name ?? 'Ramesh Kumar', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text('Category Officer - ${user?.officerRole ?? "General"}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                          const SizedBox(height: 2),
                          Text('Employee ID: ${user?.id != null ? (user!.id.length > 8 ? user.id.substring(0, 8).toUpperCase() : user.id) : "CO1256"}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: Colors.grey), 
                      onPressed: () {
                        _showInfoDialog(context, 'Edit Profile', 'Please contact Secretariat HR or Mandal Admin to update your official profile information.');
                      }
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Profile Settings List
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  _buildProfileTile(Icons.person_outline, 'My Profile', () {
                    _showInfoDialog(context, 'My Profile', 'Name: ${user?.name ?? ""}\nRole: Category Officer - ${user?.officerRole ?? "General"}\nPhone: ${user?.phoneNumber ?? ""}\nID: ${user?.id ?? ""}');
                  }),
                  const Divider(height: 1),
                  _buildProfileTile(Icons.lock_outline, 'Change Password', () {
                    _showInfoDialog(context, 'Change Password', 'Password change instructions have been sent to your official mobile number: ${user?.phoneNumber ?? ""}.');
                  }),
                  const Divider(height: 1),
                  _buildProfileTile(Icons.notifications_none, 'Notification Settings', () {
                    _showInfoDialog(context, 'Notification Settings', 'Urgent complaint push notifications and WhatsApp alerts are active.');
                  }),
                  const Divider(height: 1),
                  _buildProfileTile(Icons.language, 'Language', () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Select Language', style: TextStyle(fontWeight: FontWeight.bold)),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              title: const Text('English'),
                              onTap: () {
                                appState.setLanguage(false);
                                Navigator.pop(ctx);
                              },
                            ),
                            ListTile(
                              title: const Text('తెలుగు (Telugu)'),
                              onTap: () {
                                appState.setLanguage(true);
                                Navigator.pop(ctx);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  }, trailingText: appState.isTelugu ? 'తెలుగు >' : 'English >'),
                  const Divider(height: 1),
                  _buildProfileTile(Icons.help_outline, 'Help & Support', () {
                    _showInfoDialog(context, 'Help & Support', 'For technical assistance, please email admin-support@smartgov.gov.in or raise a ticket on the Secretariat portal.');
                  }),
                  const Divider(height: 1),
                  _buildProfileTile(Icons.info_outline, 'About Us', () {
                    _showInfoDialog(context, 'About Us', 'Smart Governance App v2.4.0\nSecure Category Officer & Mandal Officer dashboard module.');
                  }),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Logout Button
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Logout', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                onTap: () async {
                  await appState.logout();
                  if (context.mounted) {
                    Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
                  }
                },
              ),
            ),
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTile(IconData icon, String title, VoidCallback onTap, {String? trailingText}) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey.shade700),
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      trailing: trailingText != null
          ? Text(trailingText, style: const TextStyle(color: Colors.grey, fontSize: 12))
          : const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
      onTap: onTap,
    );
  }
}
