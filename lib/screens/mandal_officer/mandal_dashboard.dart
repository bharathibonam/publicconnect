import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_demo_app/l10n/app_localizations.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

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

  @override
  Widget build(BuildContext context) {
    final themeConfig = Provider.of<ThemeProvider>(context).activeParty;
    final l10n = AppLocalizations.of(context)!;

    final List<Widget> screens = [
      MandalDashboardHomeTab(onNavigateToTab: (index) {
        setState(() => _currentIndex = index);
      }),
      const MandalComplaintsTab(),
      const MandalReportsTab(),
      const MandalOverviewTab(),
      MandalProfileTab(
        onProfileSaved: () {
          setState(() => _currentIndex = 0);
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
    );
  }
}

// -----------------------------------------------------------------------------
// 1. HOME DASHBOARD
// -----------------------------------------------------------------------------
class MandalDashboardHomeTab extends StatefulWidget {
  final Function(int)? onNavigateToTab;
  const MandalDashboardHomeTab({super.key, this.onNavigateToTab});

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
                  const Icon(Icons.menu, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Mandal Officer App',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          'Bhupalapatnam Mandal',
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
                  Stack(
                    alignment: Alignment.topRight,
                    children: [
                      const NotificationBell(color: Colors.white),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                        child: const Text('3', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
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
            // Profile Card (matching screenshot 1 - frame 1)
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
                      child: Icon(Icons.person_rounded, size: 32, color: themeConfig.primaryColor),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.name ?? 'Ramesh Kumar',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Mandal Officer',
                            style: TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Bhupalapatnam Mandal',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.phone, color: Colors.green),
                      onPressed: () => OfficerInteractiveDialogs.showCallCitizenDialog(context, themeConfig),
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
              childAspectRatio: 0.9,
              children: [
                _buildStatBox('Total', '256', themeConfig.primaryColor),
                _buildStatBox('New', '26', Colors.blue),
                _buildStatBox('In Progress', '78', Colors.orange),
                _buildStatBox('Resolved', '142', Colors.green),
                _buildStatBox('Escalated', '10', Colors.red.shade400),
                _buildStatBox('SLA Breached', '7', Colors.red.shade800),
                _buildStatBox('Pending', '24', Colors.purple),
                _buildStatBox('Rejected', '3', Colors.blueGrey),
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
                Expanded(child: _buildTaskCard('Assigned', '18', Colors.blue.shade700, onTap: () {
                  if (widget.onNavigateToTab != null) widget.onNavigateToTab!(1);
                })),
                const SizedBox(width: 8),
                Expanded(child: _buildTaskCard('Meetings', '2', Colors.purple.shade700, onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const MandalMeetingsScreen()));
                })),
                const SizedBox(width: 8),
                Expanded(child: _buildTaskCard('Reviews', '4', Colors.amber.shade800, onTap: () {
                  if (widget.onNavigateToTab != null) widget.onNavigateToTab!(2);
                })),
                const SizedBox(width: 8),
                Expanded(child: _buildTaskCard('Due Today', '6', Colors.red.shade700, onTap: () {
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
                _buildPriorityFilterChip(0, 'High (5)', Colors.red),
                const SizedBox(width: 8),
                _buildPriorityFilterChip(1, 'Medium (7)', Colors.orange),
                const SizedBox(width: 8),
                _buildPriorityFilterChip(2, 'Low (10)', Colors.green),
              ],
            ),
            const SizedBox(height: 12),
            _buildPriorityItemCard(context, title: 'Water Supply Issue', location: 'Ward 12, Bhupalapatnam', priority: 'High', timeAgo: '1h ago', color: Colors.red),
            _buildPriorityItemCard(context, title: 'Drainage Blocked', location: 'Ward 6, Bhupalapatnam', priority: 'Medium', timeAgo: '3h ago', color: Colors.orange),
            _buildPriorityItemCard(context, title: 'Road Repair Needed', location: 'Ward 3, Bhupalapatnam', priority: 'Low', timeAgo: '5h ago', color: Colors.green),
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

  Widget _buildStatBox(String label, String value, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.grey.shade700), textAlign: TextAlign.center),
        ],
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
            Text(count, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
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
  int _selectedFilter = 0; // All (256), New (26), In Progress (78), Resolved (142)

  final List<Map<String, dynamic>> _mockComplaints = [
    {'title': 'Water Supply Issue', 'location': 'Ward 12, Bhupalapatnam', 'id': '#CMP-248', 'date': '16 Jul 2026', 'priority': 'High', 'status': 'In Progress', 'color': Colors.orange, 'icon': Icons.water_drop},
    {'title': 'Drainage Blocked', 'location': 'Ward 6, Bhupalapatnam', 'id': '#CMP-246', 'date': '15 Jul 2026', 'priority': 'Medium', 'status': 'Pending', 'color': Colors.red, 'icon': Icons.opacity},
    {'title': 'Street Light Not Working', 'location': 'Ward 8, Bhupalapatnam', 'id': '#CMP-244', 'date': '15 Jul 2026', 'priority': 'Low', 'status': 'In Progress', 'color': Colors.orange, 'icon': Icons.lightbulb_outline},
    {'title': 'Garbage Not Cleared', 'location': 'Ward 5, Bhupalapatnam', 'id': '#CMP-242', 'date': '14 Jul 2026', 'priority': 'Medium', 'status': 'Pending', 'color': Colors.red, 'icon': Icons.delete_outline},
    {'title': 'Road Repair Needed', 'location': 'Ward 3, Bhupalapatnam', 'id': '#CMP-241', 'date': '13 Jul 2026', 'priority': 'High', 'status': 'Resolved', 'color': Colors.green, 'icon': Icons.add_road},
    {'title': 'Overflowing Waste Bin', 'location': 'Ward 2, Bhupalapatnam', 'id': '#CMP-239', 'date': '12 Jul 2026', 'priority': 'Low', 'status': 'In Review', 'color': Colors.purple, 'icon': Icons.restore_from_trash},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Complaints', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: const BackButton(color: Colors.black87),
        actions: [
          IconButton(icon: const Icon(Icons.search, color: Colors.black87), onPressed: () {}),
          IconButton(icon: const Icon(Icons.tune, color: Colors.black87), onPressed: () {}),
        ],
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
                  _buildFilterTab(0, 'All (256)'),
                  const SizedBox(width: 8),
                  _buildFilterTab(1, 'New (26)'),
                  const SizedBox(width: 8),
                  _buildFilterTab(2, 'In Progress (78)'),
                  const SizedBox(width: 8),
                  _buildFilterTab(3, 'Resolved (142)'),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by ID, keyword or location',
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
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _mockComplaints.length,
              itemBuilder: (context, index) {
                final c = _mockComplaints[index];
                return Card(
                  elevation: 1,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const MandalComplaintDetailsScreen()));
                    },
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10)),
                      child: Icon(c['icon'] as IconData, color: Colors.blue.shade700, size: 24),
                    ),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(c['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: (c['color'] as Color).withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                          child: Text(c['status'], style: TextStyle(color: c['color'] as Color, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(c['location'], style: const TextStyle(fontSize: 12, color: Colors.black54)),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${c['id']}  •  ${c['date']}', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                            Text(c['priority'], style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: c['priority'] == 'High' ? Colors.red : Colors.orange)),
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

  Widget _buildFilterTab(int index, String label) {
    final isSelected = _selectedFilter == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = index),
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
                trailing: IconButton(
                  icon: const Icon(Icons.phone, color: Colors.green),
                  onPressed: () => OfficerInteractiveDialogs.showCallCitizenDialog(context, themeConfig),
                ),
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
    final themeConfig = Provider.of<ThemeProvider>(context).activeParty;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Reports & Analytics', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: const BackButton(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade300)),
              child: Row(
                children: const [
                  Icon(Icons.calendar_month, color: Colors.grey, size: 20),
                  SizedBox(width: 10),
                  Text('This Month (Jul 2026)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Spacer(),
                  Icon(Icons.arrow_drop_down, color: Colors.grey),
                ],
              ),
            ),
            const SizedBox(height: 20),

            const Text('Overview', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _buildOverviewBox('Total', '256', Colors.blue.shade700)),
                const SizedBox(width: 8),
                Expanded(child: _buildOverviewBox('Resolved', '142', Colors.green)),
                const SizedBox(width: 8),
                Expanded(child: _buildOverviewBox('Pending', '36', Colors.amber.shade800)),
                const SizedBox(width: 8),
                Expanded(child: _buildOverviewBox('In Progress', '78', Colors.purple)),
              ],
            ),
            const SizedBox(height: 20),

            // Complaint Trend Line Chart
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Complaint Trend', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                GestureDetector(onTap: () {}, child: const Text('View Report', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12))),
              ],
            ),
            const SizedBox(height: 10),
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  height: 160,
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: const FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: const [FlSpot(1, 10), FlSpot(7, 35), FlSpot(14, 25), FlSpot(21, 45), FlSpot(28, 68), FlSpot(31, 60)],
                          isCurved: true,
                          color: Colors.green,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: true),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Category Wise Complaints', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                GestureDetector(onTap: () {}, child: const Text('View All', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12))),
              ],
            ),
            const SizedBox(height: 10),
            _buildCategoryProgressBar('Water Supply', 96, 0.375, Colors.blue),
            _buildCategoryProgressBar('Drainage', 58, 0.227, Colors.purple),
            _buildCategoryProgressBar('Street Light', 35, 0.137, Colors.amber),
            _buildCategoryProgressBar('Roads', 32, 0.125, Colors.red),
            _buildCategoryProgressBar('Garbage', 28, 0.109, Colors.green),

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
                    trailing: IconButton(
                      icon: const Icon(Icons.phone, color: Colors.green),
                      onPressed: () => OfficerInteractiveDialogs.showCallCitizenDialog(context, themeConfig),
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
class MandalProfileTab extends StatelessWidget {
  final VoidCallback? onProfileSaved;
  const MandalProfileTab({super.key, this.onProfileSaved});

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
        leading: const BackButton(color: Colors.black87),
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
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.green.shade100,
                      child: const Icon(Icons.person, size: 36, color: Colors.green),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user?.name ?? 'Ramesh Kumar', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          const Text('Mandal Officer', style: TextStyle(fontSize: 12, color: Colors.black54)),
                          const SizedBox(height: 2),
                          const Text('Bhupalapatnam Mandal', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ),
                    IconButton(icon: const Icon(Icons.edit_outlined, color: Colors.grey), onPressed: () {}),
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
                  _buildProfileTile(Icons.person_outline, 'My Profile', () {}),
                  const Divider(height: 1),
                  _buildProfileTile(Icons.lock_outline, 'Change Password', () {}),
                  const Divider(height: 1),
                  _buildProfileTile(Icons.notifications_none, 'Notification Settings', () {}),
                  const Divider(height: 1),
                  _buildProfileTile(Icons.language, 'Language', () {}, trailingText: 'English >'),
                  const Divider(height: 1),
                  _buildProfileTile(Icons.help_outline, 'Help & Support', () {}),
                  const Divider(height: 1),
                  _buildProfileTile(Icons.info_outline, 'About Us', () {}),
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
                onTap: () => appState.logout(),
              ),
            ),
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
