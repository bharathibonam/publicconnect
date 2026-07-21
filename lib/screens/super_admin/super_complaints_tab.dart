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

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const Icon(Icons.arrow_back, color: Colors.black87),
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
                _filterChip('All', '1,254', true, themeConfig.primaryColor),
                _filterChip('Pending', '156', false, Colors.grey),
                _filterChip('In Review', '50', false, Colors.grey),
                _filterChip('Resolved', '1,048', false, Colors.grey),
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
            child: appState.complaints.isEmpty
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
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: (){},
        backgroundColor: themeConfig.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(l10n.registerNewComplaint, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _filterChip(String label, String count, bool isSelected, Color color) {
    return Expanded(
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
    );
  }
}
