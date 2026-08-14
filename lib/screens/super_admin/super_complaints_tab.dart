import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_demo_app/l10n/app_localizations.dart';
import '../../services/app_state.dart';
import '../../themes/theme_provider.dart';
import '../../models/complaint.dart';
import '../../widgets/shared_officer_widgets.dart';
import '../citizen/track_complaints.dart';

class SuperComplaintsTab extends StatelessWidget {
  const SuperComplaintsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final themeConfig = Provider.of<ThemeProvider>(context).activeParty;
    final l10n = AppLocalizations.of(context)!;

    final activeFilter = appState.superAdminActiveFilter;
    final allComplaints = appState.complaints;
    
    final int totalCount = allComplaints.length;
    final int pendingCount = allComplaints.where((c) => c.status == ComplaintStatus.submitted).length;
    final int inProgressCount = allComplaints.where((c) => c.status == ComplaintStatus.inProgress).length;
    final int resolvedCount = allComplaints.where((c) => c.status == ComplaintStatus.resolved).length;

    final filteredComplaints = allComplaints.where((c) {
      if (activeFilter == 'all') return true;
      if (activeFilter == 'pending') return c.status == ComplaintStatus.submitted;
      if (activeFilter == 'inProgress') return c.status == ComplaintStatus.inProgress;
      if (activeFilter == 'resolved') return c.status == ComplaintStatus.resolved;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Provider.of<AppState>(context, listen: false).setSuperAdminTabIndex(0);
            }
          },
        ),
        title: Text(l10n.complaints, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          IconButton(icon: const Icon(Icons.filter_list, color: Colors.black87), onPressed: (){}),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _filterChip('All', totalCount.toString(), activeFilter == 'all', themeConfig.primaryColor, () {
                  appState.setSuperAdminActiveFilter('all');
                }),
                _filterChip('Pending', pendingCount.toString(), activeFilter == 'pending', themeConfig.primaryColor, () {
                  appState.setSuperAdminActiveFilter('pending');
                }),
                _filterChip('In Review', inProgressCount.toString(), activeFilter == 'inProgress', themeConfig.primaryColor, () {
                  appState.setSuperAdminActiveFilter('inProgress');
                }),
                _filterChip('Resolved', resolvedCount.toString(), activeFilter == 'resolved', themeConfig.primaryColor, () {
                  appState.setSuperAdminActiveFilter('resolved');
                }),
              ],
            ),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: l10n.searchComplaintByKeyword,
                hintStyle: const TextStyle(fontSize: 14),
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          Expanded(
            child: filteredComplaints.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        const Text('No complaints available', style: TextStyle(color: Colors.grey, fontSize: 16)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredComplaints.length,
                    itemBuilder: (context, index) {
                      final complaint = filteredComplaints[index];
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
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String count, bool isSelected, Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(right: 4),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isSelected ? color : Colors.grey.shade300),
          ),
          child: Column(
            children: [
              Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.grey, fontSize: 11)),
              const SizedBox(height: 2),
              Text(count, style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}
