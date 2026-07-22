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

  @override
  Widget build(BuildContext context) {
    final themeConfig = Provider.of<ThemeProvider>(context).activeParty;
    final l10n = AppLocalizations.of(context)!;

    final List<Widget> screens = [
      OfficerDashboardHomeTab(onNavigateToTab: (index) {
        setState(() {
          _currentIndex = index;
        });
      }),
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

// -----------------------------------------------------------------------------
// 1. HOME DASHBOARD
// -----------------------------------------------------------------------------
class OfficerDashboardHomeTab extends StatefulWidget {
  final Function(int)? onNavigateToTab;
  const OfficerDashboardHomeTab({super.key, this.onNavigateToTab});

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
                  const Icon(Icons.dashboard_outlined, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Category Officer',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          'Water Supply Department • Bhupalapatnam GP',
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
            // Profile Card (matching screenshot 2 - frame 1)
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
                          Text(
                            'Category Officer - Water Supply',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Employee ID: CO1256',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
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
              childAspectRatio: 0.9,
              children: [
                _buildStatBox('Total', '128', themeConfig.primaryColor),
                _buildStatBox('New', '12', Colors.blue),
                _buildStatBox('In Progress', '25', Colors.orange),
                _buildStatBox('Resolved', '78', Colors.green),
                _buildStatBox('Escalated', '5', Colors.red.shade400),
                _buildStatBox('SLA Breached', '8', Colors.red.shade800),
                _buildStatBox('Rejected', '3', Colors.purple),
                _buildStatBox('On Hold', '2', Colors.blueGrey),
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
                Expanded(child: _buildTaskCard('Assigned', '8', Colors.blue.shade700)),
                const SizedBox(width: 8),
                Expanded(child: _buildTaskCard('Site Visits', '5', Colors.cyan.shade700)),
                const SizedBox(width: 8),
                Expanded(child: _buildTaskCard('Pending Updates', '7', Colors.amber.shade800)),
                const SizedBox(width: 8),
                Expanded(child: _buildTaskCard('Due Today', '4', Colors.red.shade700)),
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
                _buildPriorityFilterChip(0, 'High (3)', Colors.red),
                const SizedBox(width: 8),
                _buildPriorityFilterChip(1, 'Medium (4)', Colors.orange),
                const SizedBox(width: 8),
                _buildPriorityFilterChip(2, 'Low (6)', Colors.green),
              ],
            ),
            const SizedBox(height: 12),
            _buildPriorityItemCard(
              context,
              title: 'Water Leakage',
              location: 'Ward 12, Bhupalapatnam',
              priority: 'High',
              timeAgo: '2h ago',
              color: Colors.red,
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
                    _buildSLAStatChip('Within 24h', '6', Colors.green),
                    _buildSLAStatChip('Within 48h', '4', Colors.amber),
                    _buildSLAStatChip('Within 72h', '2', Colors.orange),
                    _buildSLAStatChip('Overdue', '1', Colors.red),
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
                                PieChartSectionData(color: Colors.green, value: 78, radius: 12, showTitle: false),
                                PieChartSectionData(color: Colors.grey.shade200, value: 22, radius: 12, showTitle: false),
                              ],
                            ),
                          ),
                          const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('78%', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
                              Text('Resolution Rate', style: TextStyle(fontSize: 7, color: Colors.grey)),
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
                              const Text('2.4 Days', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.verified_outlined, size: 16, color: Colors.grey),
                              const SizedBox(width: 6),
                              Text('SLA Compliance: ', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                              const Text('82%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green)),
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
          Text(count, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
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
  int _selectedFilter = 0; // All, Assigned, In Progress, Resolved
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _mockComplaints = [
    {'title': 'Water Supply Issue', 'location': 'Ward 12, Bhupalapatnam', 'id': '#CMP-248', 'date': '16 Jul 2026', 'priority': 'High', 'status': 'In Progress', 'color': Colors.orange, 'icon': Icons.water_drop},
    {'title': 'Drainage Blocked', 'location': 'Ward 6, Bhupalapatnam', 'id': '#CMP-246', 'date': '15 Jul 2026', 'priority': 'Medium', 'status': 'Pending', 'color': Colors.red, 'icon': Icons.opacity},
    {'title': 'Street Light Not Working', 'location': 'Ward 8, Bhupalapatnam', 'id': '#CMP-244', 'date': '15 Jul 2026', 'priority': 'Low', 'status': 'In Progress', 'color': Colors.orange, 'icon': Icons.lightbulb_outline},
    {'title': 'Garbage Not Cleared', 'location': 'Ward 5, Bhupalapatnam', 'id': '#CMP-242', 'date': '14 Jul 2026', 'priority': 'Medium', 'status': 'Pending', 'color': Colors.red, 'icon': Icons.delete_outline},
    {'title': 'Road Repair Needed', 'location': 'Ward 9, Bhupalapatnam', 'id': '#CMP-241', 'date': '13 Jul 2026', 'priority': 'High', 'status': 'Resolved', 'color': Colors.green, 'icon': Icons.add_road},
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
          // Filter Tabs (All (120), Assigned (38), In Progress (25), Resolved (78))
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterTab(0, 'All (120)'),
                  const SizedBox(width: 8),
                  _buildFilterTab(1, 'Assigned (38)'),
                  const SizedBox(width: 8),
                  _buildFilterTab(2, 'In Progress (25)'),
                  const SizedBox(width: 8),
                  _buildFilterTab(3, 'Resolved (78)'),
                ],
              ),
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
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

          // Complaint list
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
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoryComplaintDetailsScreen()));
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
            // Month selector
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

            // Analytics Overview Donut
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
                        _buildOverviewStat('Total', '128', Colors.blue.shade700),
                        _buildOverviewStat('Resolved', '78', Colors.green),
                        _buildOverviewStat('Pending', '25', Colors.amber.shade800),
                        _buildOverviewStat('In Progress', '25', Colors.purple),
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
                                PieChartSectionData(color: Colors.green, value: 60.9, radius: 18, showTitle: false),
                                PieChartSectionData(color: Colors.purple, value: 19.5, radius: 18, showTitle: false),
                                PieChartSectionData(color: Colors.amber, value: 19.5, radius: 18, showTitle: false),
                              ],
                            ),
                          ),
                          const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('128', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              Text('Total', style: TextStyle(fontSize: 10, color: Colors.grey)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildLegendItem('Resolved', '78 (60.9%)', Colors.green),
                        const SizedBox(width: 16),
                        _buildLegendItem('In Progress', '25 (19.5%)', Colors.purple),
                        const SizedBox(width: 16),
                        _buildLegendItem('Pending', '25 (19.5%)', Colors.amber),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Category Wise Complaints Progress Bars
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Category Wise Complaints', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text('View All', style: TextStyle(color: themeConfig.primaryColor, fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 10),
            _buildCategoryProgressBar('Water Supply', 52, 0.406, Colors.blue),
            _buildCategoryProgressBar('Drainage', 28, 0.219, Colors.purple),
            _buildCategoryProgressBar('Street Light', 18, 0.141, Colors.amber),
            _buildCategoryProgressBar('Garbage', 16, 0.125, Colors.red),
            _buildCategoryProgressBar('Roads', 14, 0.109, Colors.green),

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
class CategoryProfileTab extends StatelessWidget {
  final VoidCallback? onProfileSaved;
  const CategoryProfileTab({super.key, this.onProfileSaved});

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
            // User Header Card (matching screenshot 2 - frame 9)
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
                          const Text('Category Officer - Water Supply', style: TextStyle(fontSize: 12, color: Colors.black54)),
                          const SizedBox(height: 2),
                          const Text('Employee ID: CO1256', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ),
                    IconButton(icon: const Icon(Icons.edit_outlined, color: Colors.grey), onPressed: () {}),
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

            // Logout Button
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
