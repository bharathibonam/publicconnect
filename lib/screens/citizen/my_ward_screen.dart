import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/app_state.dart';
import '../../themes/theme_provider.dart';
import '../../models/user.dart';
import '../../models/work_update.dart';
import '../../models/completed_work.dart';
import '../ward_admin/completed_work_details_screen.dart';

class MyWardScreen extends StatelessWidget {
  final String? initialUpdateId;
  const MyWardScreen({super.key, this.initialUpdateId});

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              child: Image.network(imageUrl, fit: BoxFit.contain),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final user = appState.currentUser;
    final isTelugu = appState.isTelugu;
    
    final activeParty = Provider.of<ThemeProvider>(context).activeParty;
    final primaryColor = activeParty.primaryColor;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text(isTelugu ? 'నా వార్డ్' : 'My Ward')),
        body: const Center(child: Text('User not found')),
      );
    }

    final List<WorkUpdate> updates;
    final List<CompletedWork> completedWorks;

    if (user.role == UserRole.superAdmin || user.role == UserRole.mandalOfficer || user.role == UserRole.categoryOfficer) {
      updates = appState.workUpdates.toList();
      completedWorks = appState.completedWorks.toList();
    } else {
      updates = appState.wardUpdatesForCitizen(user.wardId ?? '', user.wardName).toList();
      completedWorks = appState.completedWorksForCitizen(user.id).toList();
    }

    if (initialUpdateId != null) {
      final index = updates.indexWhere((u) => u.id == initialUpdateId);
      if (index != -1) {
        final item = updates.removeAt(index);
        updates.insert(0, item);
      }
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          title: Text(isTelugu ? 'నా వార్డ్' : 'My Ward'),
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: isTelugu ? 'నవీకరణలు' : 'Ward Updates'),
              Tab(text: isTelugu ? 'పూర్తయిన పనులు' : 'Completed Works'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // TAB 1: Ward Updates (Existing)
            updates.isEmpty
                ? Center(
                    child: Text(
                      isTelugu ? 'ఈ వార్డులో ఇంకా ఎలాంటి నవీకరణలు లేవు.' : 'No updates available for this ward yet.',
                      style: const TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: updates.length,
                    itemBuilder: (context, index) {
                      final u = updates[index];
                      final isHighlighted = u.id == initialUpdateId;
                      return Card(
                        color: isHighlighted ? primaryColor.withValues(alpha: 0.05) : Colors.white,
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: isHighlighted ? BorderSide(color: primaryColor, width: 2) : BorderSide.none,
                        ),
                        elevation: isHighlighted ? 4 : 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: primaryColor.withValues(alpha: 0.1),
                                    child: Icon(Icons.person, color: primaryColor),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          u.authorName ?? (isTelugu ? 'వార్డు సభ్యుడు' : 'Ward Member'),
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                        Text(
                                          u.wardName,
                                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    u.createdAt.toLocal().toString().split(' ')[0],
                                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                u.title,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text(u.description, style: const TextStyle(fontSize: 15)),
                              const SizedBox(height: 16),
                              if (u.imageUrls.isNotEmpty)
                                SizedBox(
                                  height: 150,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: u.imageUrls.length,
                                    itemBuilder: (ctx, imgIdx) {
                                      final imageUrl = u.imageUrls[imgIdx];
                                      return GestureDetector(
                                        onTap: () => _showFullScreenImage(context, imageUrl),
                                        child: Padding(
                                          padding: const EdgeInsets.only(right: 8),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(12),
                                            child: Image.network(
                                              imageUrl,
                                              width: 150,
                                              height: 150,
                                              fit: BoxFit.cover,
                                              errorBuilder: (ctx, _, _) => Container(
                                                width: 150,
                                                height: 150,
                                                color: Colors.grey[300],
                                                child: const Icon(Icons.broken_image),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
            
            // TAB 2: Completed Works (New)
            completedWorks.isEmpty
                ? Center(
                    child: Text(
                      isTelugu ? 'పూర్తయిన పనులు ఏవీ లేవు.' : 'No completed works found.',
                      style: const TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: completedWorks.length,
                    itemBuilder: (context, index) {
                      final cw = completedWorks[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(
                            builder: (_) => CompletedWorkDetailsScreen(work: cw),
                          ));
                        },
                        child: Card(
                          color: Colors.white,
                          margin: const EdgeInsets.only(bottom: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: Colors.green.withValues(alpha: 0.1),
                                      child: const Icon(Icons.check_circle, color: Colors.green),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            cw.category ?? 'Complaint Work',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.green),
                                          ),
                                          Text(
                                            cw.title,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      cw.completedAt.toLocal().toString().split(' ')[0],
                                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(cw.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.black87)),
                                const SizedBox(height: 12),
                                if (cw.afterImageUrl != null)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(cw.afterImageUrl!, height: 120, width: double.infinity, fit: BoxFit.cover),
                                  )
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  )
          ],
        ),
      ),
    );
  }
}
