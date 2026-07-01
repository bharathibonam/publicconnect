import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/completed_work.dart';
import '../../services/app_state.dart';

class CompletedWorkDetailsScreen extends StatefulWidget {
  final CompletedWork work;
  final String? notificationId;

  const CompletedWorkDetailsScreen({
    super.key,
    required this.work,
    this.notificationId,
  });

  @override
  State<CompletedWorkDetailsScreen> createState() => _CompletedWorkDetailsScreenState();
}

class _CompletedWorkDetailsScreenState extends State<CompletedWorkDetailsScreen> {
  @override
  void initState() {
    super.initState();
    _markRead();
  }

  void _markRead() {
    if (widget.notificationId != null) {
      final appState = Provider.of<AppState>(context, listen: false);
      appState.markNotificationAsRead(widget.notificationId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Completed Work Details'),
        backgroundColor: const Color(0xFF22C55E),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.work.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Completed: ${widget.work.completedAt.toLocal().toString().split('.')[0]}', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            const Text('Description', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(widget.work.description, style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 24),
            if (widget.work.beforeImageUrl != null || widget.work.afterImageUrl != null)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.work.beforeImageUrl != null)
                    Expanded(
                      child: Column(
                        children: [
                          const Text('Before', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(widget.work.beforeImageUrl!, height: 150, width: double.infinity, fit: BoxFit.cover),
                          ),
                        ],
                      ),
                    ),
                  if (widget.work.beforeImageUrl != null && widget.work.afterImageUrl != null)
                    const SizedBox(width: 16),
                  if (widget.work.afterImageUrl != null)
                    Expanded(
                      child: Column(
                        children: [
                          const Text('After', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(widget.work.afterImageUrl!, height: 150, width: double.infinity, fit: BoxFit.cover),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            const SizedBox(height: 24),
            if (widget.work.remarks != null && widget.work.remarks!.isNotEmpty) ...[
              const Text('Remarks', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(widget.work.remarks!, style: const TextStyle(fontSize: 15)),
              const SizedBox(height: 24),
            ],
            // Files placeholder
            if (widget.work.videoUrl != null || widget.work.pdfUrl != null || widget.work.voiceUrl != null) ...[
              const Text('Attachments', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (widget.work.videoUrl != null)
                ListTile(
                  leading: const Icon(Icons.video_library, color: Colors.blue),
                  title: const Text('View Video'),
                  tileColor: Colors.grey.shade100,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              if (widget.work.pdfUrl != null)
                ListTile(
                  leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                  title: const Text('View PDF Report'),
                  tileColor: Colors.grey.shade100,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              if (widget.work.voiceUrl != null)
                ListTile(
                  leading: const Icon(Icons.mic, color: Colors.orange),
                  title: const Text('Play Voice Note'),
                  tileColor: Colors.grey.shade100,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
            ]
          ],
        ),
      ),
    );
  }
}
