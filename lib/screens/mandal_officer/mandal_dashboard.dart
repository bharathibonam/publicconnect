import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_demo_app/l10n/app_localizations.dart';
import 'dart:io';
import 'dart:typed_data';
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
import '../announcements/create_announcement_screen.dart';
import '../announcements/broadcast_history_screen.dart';
import '../super_admin/meetings/meetings_list_screen.dart';
import '../super_admin/meetings/create_meeting_screen.dart';

class MandalAdminNavHolder extends StatefulWidget {
  const MandalAdminNavHolder({super.key});

  @override
  State<MandalAdminNavHolder> createState() => _MandalAdminNavHolderState();
}

class _MandalAdminNavHolderState extends State<MandalAdminNavHolder> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final user = appState.currentUser;
    if (appState.requestedMandalOfficerTabIndex != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _currentIndex = appState.requestedMandalOfficerTabIndex!;
          });
          appState.clearMandalOfficerTabIndex();
        }
      });
    }

    final themeConfig = Provider.of<ThemeProvider>(context).activeParty;
    final l10n = AppLocalizations.of(context)!;

    final List<Widget> screens = [
      MandalDashboardHomeTab(
        onNavigateToTab: (index) {
          setState(() => _currentIndex = index);
        },
        onMenuPressed: () {
          _scaffoldKey.currentState?.openDrawer();
        },
      ),
      const MandalComplaintsTab(),
      const MandalReportsTab(),
      const MandalOverviewTab(),
      MandalProfileTab(
        onProfileSaved: () {
          setState(() => _currentIndex = 0);
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
                accountName: Text(user?.name ?? 'Mandal Officer', style: const TextStyle(fontWeight: FontWeight.bold)),
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
                leading: const Icon(Icons.grid_view_outlined),
                title: const Text('Services'),
                selected: _currentIndex == 3,
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _currentIndex = 3);
                },
              ),
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text(l10n.profile),
                selected: _currentIndex == 4,
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _currentIndex = 4);
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
              icon: const Icon(Icons.grid_view_outlined),
              activeIcon: const Icon(Icons.grid_view),
              label: 'Services',
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
class MandalDashboardHomeTab extends StatefulWidget {
  final Function(int)? onNavigateToTab;
  final VoidCallback? onMenuPressed;
  const MandalDashboardHomeTab({super.key, this.onNavigateToTab, this.onMenuPressed});

  @override
  State<MandalDashboardHomeTab> createState() => _MandalDashboardHomeTabState();
}

class _MandalDashboardHomeTabState extends State<MandalDashboardHomeTab> {
  int _selectedPriorityFilter = 0; // 0: High, 1: Medium, 2: Low

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final themeConfig = Provider.of<ThemeProvider>(context).activeParty;
    final user = appState.currentUser;

    final mandalComplaints = appState.complaintsForMandalOfficer(user);

    final totalCount = mandalComplaints.length;
    final newCount = mandalComplaints.where((c) => c.status == ComplaintStatus.submitted).length;
    final inProgressCount = mandalComplaints.where((c) => c.status == ComplaintStatus.inProgress).length;
    final resolvedCount = mandalComplaints.where((c) => c.status == ComplaintStatus.resolved).length;
    final escalatedCount = mandalComplaints.where((c) => c.isPushed || DateTime.now().difference(c.createdAt).inHours >= 48).length;
    final slaBreachedCount = mandalComplaints.where((c) => c.status != ComplaintStatus.resolved && DateTime.now().difference(c.createdAt).inHours >= 48).length;
    final pendingCount = mandalComplaints.where((c) => c.status == ComplaintStatus.submitted || c.status == ComplaintStatus.inProgress).length;
    final rejectedCount = mandalComplaints.where((c) => c.status == ComplaintStatus.rejected).length;

    // Dynamic Today's Tasks
    final now = DateTime.now();
    final todayAssigned = mandalComplaints.where((c) => c.createdAt.day == now.day && c.createdAt.month == now.month && c.createdAt.year == now.year).length;
    final meetingsCount = appState.meetings.length;
    final reviewsCount = inProgressCount;
    final dueToday = mandalComplaints.where((c) {
      if (c.status == ComplaintStatus.resolved) return false;
      final hours = now.difference(c.createdAt).inHours;
      return hours >= 42 && hours < 48;
    }).length;

    // Dynamic Priority Queue
    final highPriorityList = mandalComplaints.where((c) => c.priority == ComplaintPriority.high && c.status != ComplaintStatus.resolved).toList();
    final medPriorityList = mandalComplaints.where((c) => c.priority == ComplaintPriority.medium && c.status != ComplaintStatus.resolved).toList();
    final lowPriorityList = mandalComplaints.where((c) => c.priority == ComplaintPriority.low && c.status != ComplaintStatus.resolved).toList();

    List<Complaint> activePriorityList;
    if (_selectedPriorityFilter == 0) {
      activePriorityList = highPriorityList;
    } else if (_selectedPriorityFilter == 1) {
      activePriorityList = medPriorityList;
    } else {
      activePriorityList = lowPriorityList;
    }

    final mandalTitle = user?.mandalName != null && user!.mandalName!.isNotEmpty ? user.mandalName! : 'Mandal Officer';

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
                        const Text(
                          'Mandal Officer',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          mandalTitle,
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
                    onPressed: () => OfficerInteractiveDialogs.showQuickActionsModal(context, themeConfig),
                  ),
                  const NotificationBell(color: Colors.white),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      if (widget.onNavigateToTab != null) widget.onNavigateToTab!(4);
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
                            user?.name ?? 'Mandal Officer',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Mandal Administrative Officer',
                            style: TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            mandalTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Mandal Summary Section
            _buildSectionHeader('Mandal Summary', onViewAll: () {
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
                  appState.setMandalOfficerTabIndex(1, filter: 'All');
                }),
                _buildStatBox('New', newCount.toString(), Colors.blue, () {
                  appState.setMandalOfficerTabIndex(1, filter: 'New');
                }),
                _buildStatBox('In Progress', inProgressCount.toString(), Colors.orange, () {
                  appState.setMandalOfficerTabIndex(1, filter: 'In Progress');
                }),
                _buildStatBox('Resolved', resolvedCount.toString(), Colors.green, () {
                  appState.setMandalOfficerTabIndex(1, filter: 'Resolved');
                }),
                _buildStatBox('Escalated', escalatedCount.toString(), Colors.red.shade400, () {
                  appState.setMandalOfficerTabIndex(1, filter: 'Escalated');
                }),
                _buildStatBox('SLA Breached', slaBreachedCount.toString(), Colors.red.shade800, () {
                  appState.setMandalOfficerTabIndex(1, filter: 'SLA Breached');
                }),
                _buildStatBox('Pending', pendingCount.toString(), Colors.purple, () {
                  appState.setMandalOfficerTabIndex(1, filter: 'Pending');
                }),
                _buildStatBox('Rejected', rejectedCount.toString(), Colors.blueGrey, () {
                  appState.setMandalOfficerTabIndex(1, filter: 'Rejected');
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
                Expanded(child: _buildTaskCard('Assigned', todayAssigned.toString(), Colors.blue.shade700, onTap: () {
                  if (widget.onNavigateToTab != null) widget.onNavigateToTab!(1);
                })),
                const SizedBox(width: 8),
                Expanded(child: _buildTaskCard('Meetings', meetingsCount.toString(), Colors.purple.shade700, onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const MandalMeetingsScreen()));
                })),
                const SizedBox(width: 8),
                Expanded(child: _buildTaskCard('Reviews', reviewsCount.toString(), Colors.amber.shade800, onTap: () {
                  if (widget.onNavigateToTab != null) widget.onNavigateToTab!(2);
                })),
                const SizedBox(width: 8),
                Expanded(child: _buildTaskCard('Due Today', dueToday.toString(), Colors.red.shade700, onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const MandalSLATrackerScreen()));
                })),
              ],
            ),
            const SizedBox(height: 20),

            // Priority Queue Section
            _buildSectionHeader('Priority Queue', onViewAll: () {
              if (widget.onNavigateToTab != null) widget.onNavigateToTab!(1);
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
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onViewAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
        if (onViewAll != null)
          GestureDetector(
            onTap: onViewAll,
            child: const Text('View All', style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold)),
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

  Widget _buildTaskCard(String label, String count, Color color, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const MandalComplaintDetailsScreen()));
        },
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(Icons.report_problem_outlined, color: color, size: 20),
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
}

// -----------------------------------------------------------------------------
// 2. COMPLAINTS TAB
// -----------------------------------------------------------------------------
class MandalComplaintsTab extends StatefulWidget {
  const MandalComplaintsTab({super.key});

  @override
  State<MandalComplaintsTab> createState() => _MandalComplaintsTabState();
}

class _MandalComplaintsTabState extends State<MandalComplaintsTab> {
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final user = appState.currentUser;
    final allComplaints = appState.complaintsForMandalOfficer(user);

    final totalCount = allComplaints.length;
    final newCount = allComplaints.where((c) => c.status == ComplaintStatus.submitted).length;
    final inProgressCount = allComplaints.where((c) => c.status == ComplaintStatus.inProgress).length;
    final resolvedCount = allComplaints.where((c) => c.status == ComplaintStatus.resolved).length;
    final escalatedCount = allComplaints.where((c) => c.isPushed || DateTime.now().difference(c.createdAt).inHours >= 24).length;
    final slaBreachedCount = allComplaints.where((c) => c.status != ComplaintStatus.resolved && DateTime.now().difference(c.createdAt).inHours >= 24).length;
    final pendingCount = allComplaints.where((c) => c.status == ComplaintStatus.submitted).length;
    final rejectedCount = allComplaints.where((c) => c.status == ComplaintStatus.rejected).length;

    final activeFilter = appState.mandalOfficerActiveFilter;
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
    } else if (activeFilter == 'Pending') {
      filtered = filtered.where((c) => c.status == ComplaintStatus.submitted).toList();
    } else if (activeFilter == 'Rejected') {
      filtered = filtered.where((c) => c.status == ComplaintStatus.rejected).toList();
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
        title: const Text('Mandal Complaints', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () {
            appState.setMandalOfficerTabIndex(0);
          },
        ),
      ),
      body: Column(
        children: [
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
                  _buildFilterTab(appState, 'Pending', 'Pending ($pendingCount)'),
                  const SizedBox(width: 8),
                  _buildFilterTab(appState, 'Rejected', 'Rejected ($rejectedCount)'),
                ],
              ),
            ),
          ),
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
    final isSelected = appState.mandalOfficerActiveFilter == filter;
    return GestureDetector(
      onTap: () => appState.setMandalOfficerActiveFilter(filter),
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
class MandalComplaintDetailsScreen extends StatelessWidget {
  const MandalComplaintDetailsScreen({super.key});

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
              children: const [
                Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                SizedBox(width: 4),
                Text('Ward 12, Bhupalapatnam', style: TextStyle(fontSize: 12, color: Colors.black87)),
                Spacer(),
                Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey),
                SizedBox(width: 4),
                Text('16 Jul 2026 • 10:30 AM', style: TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
            const Divider(height: 24),

            const Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 6),
            const Text(
              'There is no proper water supply in our area since last 5 days. Please resolve this issue immediately.',
              style: TextStyle(fontSize: 13, color: Colors.black54, height: 1.4),
            ),
            const SizedBox(height: 16),

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
                height: 120, width: double.infinity, color: Colors.blueGrey.shade100,
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

            const Text('Timeline', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 12),
            _buildTimelineTile('Complaint Registered', '16 Jul 2026 • 10:30 AM', isDone: true),
            _buildTimelineTile('Assigned to Officer', '16 Jul 2026 • 11:20 AM', isDone: true),
            _buildTimelineTile('Work in Progress', '16 Jul 2026 • 01:45 PM', isDone: true),
            _buildTimelineTile('In Progress', '17 Jul 2026 • 09:15 AM', isDone: true),
            _buildTimelineTile('Resolved', '', isDone: false, isLast: true),

            const SizedBox(height: 20),
            const Text('Assigned Officer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: const Text('S. Prakash', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Assistant Engineer'),
              ),
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      OfficerInteractiveDialogs.showAssignWorkDialog(context, themeConfig);
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
// 4. MANDAL OVERVIEW TAB / SCREEN
// -----------------------------------------------------------------------------
class MandalOverviewTab extends StatelessWidget {
  const MandalOverviewTab({super.key});

  @override
  Widget build(BuildContext context) {
    final themeConfig = Provider.of<ThemeProvider>(context).activeParty;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Mandal Overview', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: const BackButton(color: Colors.black87),
        actions: [
          IconButton(icon: const Icon(Icons.search, color: Colors.black87), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats Row: Wards 23, Population 45,230, Villages 36
            Row(
              children: [
                Expanded(child: _buildOverviewStatCard('Wards', '23', Colors.green.shade50, Colors.green)),
                const SizedBox(width: 10),
                Expanded(child: _buildOverviewStatCard('Population', '45,230', Colors.blue.shade50, Colors.blue)),
                const SizedBox(width: 10),
                Expanded(child: _buildOverviewStatCard('Villages', '36', Colors.orange.shade50, Colors.orange)),
              ],
            ),
            const SizedBox(height: 20),

            // Complaint Analytics Donut Chart
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Complaint Analytics', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                GestureDetector(
                  onTap: () {},
                  child: const Text('View Report', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    SizedBox(
                      width: 110, height: 110,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          PieChart(
                            PieChartData(
                              sectionsSpace: 2, centerSpaceRadius: 36,
                              sections: [
                                PieChartSectionData(color: Colors.green, value: 55.5, radius: 14, showTitle: false),
                                PieChartSectionData(color: Colors.red, value: 30.5, radius: 14, showTitle: false),
                                PieChartSectionData(color: Colors.amber, value: 14.0, radius: 14, showTitle: false),
                              ],
                            ),
                          ),
                          const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('256', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                              Text('Total', style: TextStyle(fontSize: 10, color: Colors.grey)),
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
                          _buildLegendRow('Resolved', '142 (55.5%)', Colors.green),
                          const SizedBox(height: 8),
                          _buildLegendRow('In Progress', '78 (30.5%)', Colors.red),
                          const SizedBox(height: 8),
                          _buildLegendRow('Pending', '36 (14.0%)', Colors.amber),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Top Issue Categories Progress Bars
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Top Issue Categories', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                GestureDetector(
                  onTap: () {},
                  child: const Text('View All', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildCategoryProgressBar('Water Supply', 96, 0.375, Colors.blue),
            _buildCategoryProgressBar('Drainage', 58, 0.227, Colors.purple),
            _buildCategoryProgressBar('Street Light', 35, 0.137, Colors.amber),
            _buildCategoryProgressBar('Roads', 32, 0.125, Colors.red),
            _buildCategoryProgressBar('Garbage', 28, 0.109, Colors.green),
            const SizedBox(height: 20),

            // Mandal Performance
            const Text('Mandal Performance (This Month)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Column(
                        children: const [
                          Text('Avg. Resolution Time', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          SizedBox(height: 4),
                          Text('2.6 Days', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Column(
                        children: const [
                          Text('SLA Compliance', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          SizedBox(height: 4),
                          Text('81%', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                        ],
                      ),
                    ),
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

  Widget _buildOverviewStatCard(String label, String value, Color bg, Color textCol) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textCol)),
        ],
      ),
    );
  }

  Widget _buildLegendRow(String label, String value, Color color) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
        const Spacer(),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
// 5. REPORTS & ANALYTICS TAB
// -----------------------------------------------------------------------------
class MandalReportsTab extends StatelessWidget {
  const MandalReportsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final themeConfig = Provider.of<ThemeProvider>(context).activeParty;
    final user = appState.currentUser;
    final complaints = appState.complaintsForMandalOfficer(user);

    final total = complaints.length;
    final resolved = complaints.where((c) => c.status == ComplaintStatus.resolved).length;
    final pending = complaints.where((c) => c.status == ComplaintStatus.submitted).length;
    final inProgress = complaints.where((c) => c.status == ComplaintStatus.inProgress).length;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Reports & Analytics', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () {
            appState.setMandalOfficerTabIndex(0);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [


            const Text('Overview', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _buildOverviewBox('Total', total.toString(), Colors.blue.shade700)),
                const SizedBox(width: 8),
                Expanded(child: _buildOverviewBox('Resolved', resolved.toString(), Colors.green)),
                const SizedBox(width: 8),
                Expanded(child: _buildOverviewBox('Pending', pending.toString(), Colors.amber.shade800)),
                const SizedBox(width: 8),
                Expanded(child: _buildOverviewBox('In Progress', inProgress.toString(), Colors.purple)),
              ],
            ),
            const SizedBox(height: 20),

            // Category Wise Complaints Progress Bars
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Category Wise Complaints', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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
                    const SnackBar(content: Text('Generating Excel Report... Download started!')),
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

  Widget _buildOverviewBox(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
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
// 6. SLA TRACKER SCREEN
// -----------------------------------------------------------------------------
class MandalSLATrackerScreen extends StatelessWidget {
  const MandalSLATrackerScreen({super.key});

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
                _buildSLAChip('3', 'Within 72h', Colors.orange),
                _buildSLAChip('2', 'Overdue', Colors.red),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('Overdue Complaints (2)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.red)),
                const SizedBox(height: 8),
                _buildOverdueCard('Water Supply Issue', 'Ward 6, Bhupalapatnam • #CMP-201 • 12 Jul 2026', '2 Days Overdue'),
                _buildOverdueCard('Drainage Blocked', 'Ward 3, Bhupalapatnam • #CMP-198 • 11 Jul 2026', '3 Days Overdue'),
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

  Widget _buildSLAChip(String count, String label, Color color) {
    return Column(
      children: [
        Text(count, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _buildOverdueCard(String title, String subtitle, String overdueBadge) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 11)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(6)),
          child: Text(overdueBadge, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 10)),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 7. ASSIGNED OFFICERS SCREEN
// -----------------------------------------------------------------------------
class MandalAssignedOfficersScreen extends StatelessWidget {
  const MandalAssignedOfficersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeConfig = Provider.of<ThemeProvider>(context).activeParty;

    final officers = [
      {'name': 'S. Prakash', 'role': 'Assistant Engineer (Water Supply)', 'assigned': '48'},
      {'name': 'M. Ravi Kumar', 'role': 'Junior Engineer (Drainage)', 'assigned': '32'},
      {'name': 'K. Santhosh', 'role': 'AE (Roads & Buildings)', 'assigned': '27'},
      {'name': 'P. Anusha', 'role': 'Sanitary Inspector', 'assigned': '21'},
      {'name': 'V. Mahesh', 'role': 'Electrician Incharge', 'assigned': '19'},
    ];

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Assigned Officers', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: const BackButton(color: Colors.black87),
        actions: [
          IconButton(icon: const Icon(Icons.search, color: Colors.black87), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: officers.length,
              itemBuilder: (context, index) {
                final o = officers[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(o['name']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(o['role']!, style: const TextStyle(fontSize: 11, color: Colors.black54)),
                        Text('Assigned: ${o['assigned']}', style: TextStyle(fontSize: 10, color: themeConfig.primaryColor, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                );
              },
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
                child: const Text('View All Officers', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 8. MEETINGS & EVENTS SCREEN
// -----------------------------------------------------------------------------
class MandalMeetingsScreen extends StatefulWidget {
  const MandalMeetingsScreen({super.key});

  @override
  State<MandalMeetingsScreen> createState() => _MandalMeetingsScreenState();
}

class _MandalMeetingsScreenState extends State<MandalMeetingsScreen> {
  int _selectedTab = 0; // Upcoming, Completed, My Meetings

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Meetings', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: const BackButton(color: Colors.black87),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _buildTabChip(0, 'Upcoming'),
                const SizedBox(width: 8),
                _buildTabChip(1, 'Completed'),
                const SizedBox(width: 8),
                _buildTabChip(2, 'My Meetings'),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildMeetingCard('20', 'JUL', 'Mandal Review Meeting', 'Conference Hall, Mandal Office', '10:30 AM - 12:00 PM'),
                _buildMeetingCard('22', 'JUL', 'Department Coordination Meeting', 'Main Hall', '11:00 AM - 12:30 PM'),
                _buildMeetingCard('25', 'JUL', 'Work Progress Review', 'Virtual Room', '02:00 PM - 03:30 PM'),
                _buildMeetingCard('28', 'JUL', 'Grievance Redressal Meeting', 'Conference Hall', '11:30 AM - 01:00 PM'),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateMeetingScreen()));
                },
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text('+ Add New Meeting', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F766E),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabChip(int index, String label) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F766E) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 12)),
      ),
    );
  }

  Widget _buildMeetingCard(String dateNum, String dateMonth, String title, String location, String time) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
              child: Column(
                children: [
                  Text(dateNum, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                  Text(dateMonth, style: const TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(location, style: const TextStyle(fontSize: 11, color: Colors.black54)),
                  const SizedBox(height: 2),
                  Text(time, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 9. BROADCAST CENTER SCREEN
// -----------------------------------------------------------------------------
class MandalBroadcastCenterScreen extends StatelessWidget {
  const MandalBroadcastCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeConfig = Provider.of<ThemeProvider>(context).activeParty;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Broadcast Center', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: const BackButton(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateAnnouncementScreen()));
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: const Color(0xFF0F766E), borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        children: const [
                          Icon(Icons.campaign, color: Colors.white, size: 30),
                          SizedBox(height: 8),
                          Text('New Announcement', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const BroadcastHistoryScreen()));
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.blue.shade700, borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        children: const [
                          Icon(Icons.history, color: Colors.white, size: 30),
                          SizedBox(height: 8),
                          Text('Broadcast History', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Recent Broadcasts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                GestureDetector(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const BroadcastHistoryScreen()));
                  },
                  child: const Text('View All', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildBroadcastTile('Water Supply Schedule', '16 Jul 2026 • 10:30 AM', 'Text', Colors.blue),
            _buildBroadcastTile('Road Work Update', '15 Jul 2026 • 05:00 PM', 'Image', Colors.orange),
            _buildBroadcastTile('Garbage Collection Drive', '14 Jul 2026 • 09:00 AM', 'Video', Colors.purple),
            _buildBroadcastTile('Street Light Repair Info', '13 Jul 2026 • 04:30 PM', 'Text', Colors.blue),
          ],
        ),
      ),
    );
  }

  Widget _buildBroadcastTile(String title, String subtitle, String type, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(Icons.campaign, color: color, size: 22),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6)),
          child: Text(type, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black54)),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 10. PROFILE TAB
// -----------------------------------------------------------------------------
class MandalProfileTab extends StatefulWidget {
  final VoidCallback? onProfileSaved;
  const MandalProfileTab({super.key, this.onProfileSaved});

  @override
  State<MandalProfileTab> createState() => _MandalProfileTabState();
}

class _MandalProfileTabState extends State<MandalProfileTab> {
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
        appState.updateProfilePhotoLocally(pickedFile.path);
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
    final mandalName = user?.mandalName ?? 'Bhupalapatnam Mandal';

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () {
            appState.setMandalOfficerTabIndex(0);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
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
                          const Text('Mandal Administrative Officer', style: TextStyle(fontSize: 12, color: Colors.black54)),
                          const SizedBox(height: 2),
                          Text(mandalName, style: const TextStyle(fontSize: 11, color: Colors.grey)),
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

            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  _buildProfileTile(Icons.person_outline, 'My Profile', () {
                    _showInfoDialog(context, 'My Profile', 'Name: ${user?.name ?? ""}\nRole: Mandal Administrative Officer\nMandal: ${user?.mandalName ?? ""}\nPhone: ${user?.phoneNumber ?? ""}\nID: ${user?.id ?? ""}');
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
