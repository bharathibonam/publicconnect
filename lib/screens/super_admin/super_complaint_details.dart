import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_demo_app/l10n/app_localizations.dart';
import '../../services/app_state.dart';
import '../../themes/theme_provider.dart';
import '../../models/complaint.dart';

class SuperComplaintDetailsScreen extends StatelessWidget {
  final Complaint complaint;

  const SuperComplaintDetailsScreen({super.key, required this.complaint});

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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Complaint Details', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          IconButton(icon: const Icon(Icons.share, color: Colors.black87), onPressed: (){}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(backgroundColor: Colors.blue.shade50, child: const Icon(Icons.water_drop, color: Colors.blue)),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(complaint.category, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              Text('${complaint.villageName}, ${complaint.mandalName}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(12)),
                        child: Text(complaint.statusText, style: const TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('#PC/${complaint.id.substring(0,8)}', style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 12, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text('16 Jul 2026 - 10:30 AM', style: const TextStyle(fontSize: 12, color: Colors.grey)), // Mock date
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Description', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(complaint.description, style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black87)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.location, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                Text(l10n.viewOnMap, style: const TextStyle(fontSize: 12, color: Colors.blue)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.red, size: 16),
                const SizedBox(width: 4),
                Text('${complaint.villageName}, ${complaint.mandalName}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
              child: const Center(child: Icon(Icons.map, size: 40, color: Colors.grey)),
            ),
            const SizedBox(height: 24),
            Text(l10n.timeline, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _timelineStep('Complaint Registered', '16 Jul 2026 • 10:30 AM', true, true),
            _timelineStep('Assigned to Officer', '16 Jul 2026 • 11:20 AM', true, true),
            _timelineStep('Work in Progress', '', false, true),
            _timelineStep('Resolved', '', false, false),
            const SizedBox(height: 24),
            Text(l10n.assignedOfficer, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
              child: Row(
                children: [
                  const CircleAvatar(backgroundImage: AssetImage('assets/images/placeholder.png')), // placeholder
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('S. Prakash', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text('Executive Engineer', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.call, color: Colors.blue), onPressed: (){}),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _timelineStep(String title, String subtitle, bool isCompleted, bool isLast) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted ? Colors.green : Colors.grey.shade300,
                border: Border.all(color: isCompleted ? Colors.green : Colors.grey.shade400, width: 2),
              ),
              child: isCompleted ? const Icon(Icons.check, size: 12, color: Colors.white) : null,
            ),
            if (isLast)
              Container(
                width: 2,
                height: 40,
                color: isCompleted ? Colors.green : Colors.grey.shade300,
              ),
          ],
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isCompleted ? Colors.black87 : Colors.grey)),
            if (subtitle.isNotEmpty)
              Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 20),
          ],
        ),
      ],
    );
  }
}
