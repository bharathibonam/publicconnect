import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/completed_work.dart';
import '../../services/app_state.dart';
import 'package:url_launcher/url_launcher.dart';

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

  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open attachment link.')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
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
            
            // Before Image Card
            if (widget.work.beforeImageUrl != null && widget.work.beforeImageUrl!.isNotEmpty) ...[
              const Text('Before Image', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Card(
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 2,
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FullScreenImageViewer(imageUrl: widget.work.beforeImageUrl!),
                      ),
                    );
                  },
                  child: Hero(
                    tag: widget.work.beforeImageUrl!,
                    child: Image.network(
                      widget.work.beforeImageUrl!,
                      width: double.infinity,
                      height: 220,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 220,
                        color: Colors.grey.shade100,
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, color: Colors.red, size: 36),
                            SizedBox(height: 8),
                            Text('Image unavailable', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // After Image Card
            if (widget.work.afterImageUrl != null && widget.work.afterImageUrl!.isNotEmpty) ...[
              const Text('After Image', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Card(
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 2,
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FullScreenImageViewer(imageUrl: widget.work.afterImageUrl!),
                      ),
                    );
                  },
                  child: Hero(
                    tag: widget.work.afterImageUrl!,
                    child: Image.network(
                      widget.work.afterImageUrl!,
                      width: double.infinity,
                      height: 220,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 220,
                        color: Colors.grey.shade100,
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, color: Colors.red, size: 36),
                            SizedBox(height: 8),
                            Text('Image unavailable', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            if (widget.work.remarks != null && widget.work.remarks!.isNotEmpty) ...[
              const Text('Remarks', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(widget.work.remarks!, style: const TextStyle(fontSize: 15)),
              const SizedBox(height: 24),
            ],
            // Files placeholder
            if ((widget.work.videoUrl != null && widget.work.videoUrl!.isNotEmpty) || 
                (widget.work.pdfUrl != null && widget.work.pdfUrl!.isNotEmpty) || 
                (widget.work.voiceUrl != null && widget.work.voiceUrl!.isNotEmpty)) ...[
              const Text('Attachments', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (widget.work.videoUrl != null && widget.work.videoUrl!.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.video_library, color: Colors.blue),
                  title: const Text('View Video'),
                  tileColor: Colors.grey.shade100,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  onTap: () => _launchUrl(widget.work.videoUrl!),
                ),
              const SizedBox(height: 8),
              if (widget.work.pdfUrl != null && widget.work.pdfUrl!.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                  title: const Text('View PDF Report'),
                  tileColor: Colors.grey.shade100,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  onTap: () => _launchUrl(widget.work.pdfUrl!),
                ),
              const SizedBox(height: 8),
              if (widget.work.voiceUrl != null && widget.work.voiceUrl!.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.mic, color: Colors.orange),
                  title: const Text('Play Voice Note'),
                  tileColor: Colors.grey.shade100,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  onTap: () => _launchUrl(widget.work.voiceUrl!),
                ),
            ]
          ],
        ),
      ),
    );
  }
}

class FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;
  const FullScreenImageViewer({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity != null && details.primaryVelocity! > 300) {
            Navigator.pop(context);
          }
        },
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                panEnabled: true,
                boundaryMargin: const EdgeInsets.all(20),
                minScale: 0.5,
                maxScale: 4.0,
                child: Hero(
                  tag: imageUrl,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Text('Failed to load image', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: CircleAvatar(
                    backgroundColor: Colors.black54,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
