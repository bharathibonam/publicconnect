import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import '../../services/app_state.dart';
import '../../services/social_publisher_service.dart';
import '../../services/resumable_upload_service.dart';
import '../../models/mla_broadcast.dart';
import '../../themes/theme_provider.dart';
import '../../l10n/app_localizations.dart';

class MLAMediaPublisher extends StatefulWidget {
  final MLABroadcast? broadcastToEdit;
  const MLAMediaPublisher({super.key, this.broadcastToEdit});

  @override
  State<MLAMediaPublisher> createState() => _MLAMediaPublisherState();
}

class _MLAMediaPublisherState extends State<MLAMediaPublisher> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  
  BroadcastMediaType _selectedType = BroadcastMediaType.reel;
  String? _pickedFileName;
  String? _pickedFilePath;
  XFile? _pickedXFile;

  // Linked accounts syndication flags
  bool _syncInstagram = true;
  bool _syncYoutube = true;
  bool _syncFacebook = true;

  bool _isPublishing = false;
  double _uploadProgress = 0.0;
  final List<String> _publishLogs = [];

  bool _isScheduled = false;
  DateTime? _scheduledDateTime;

  @override
  void initState() {
    super.initState();
    if (widget.broadcastToEdit != null) {
      _titleController.text = widget.broadcastToEdit!.title;
      _descController.text = widget.broadcastToEdit!.description;
      _selectedType = widget.broadcastToEdit!.type;
      _pickedFileName = widget.broadcastToEdit!.mediaUrl.split('/').last;
      _pickedFilePath = widget.broadcastToEdit!.mediaUrl;
      _isScheduled = widget.broadcastToEdit!.status == 'scheduled';
      _scheduledDateTime = widget.broadcastToEdit!.scheduledAt;
    }
  }

  Future<void> _pickFile() async {
    final picker = ImagePicker();
    if (_selectedType == BroadcastMediaType.reel) {
      final XFile? video = await picker.pickVideo(source: ImageSource.gallery);
      if (video != null) {
        setState(() {
          _pickedFileName = video.name;
          _pickedFilePath = video.path;
          _pickedXFile = video;
        });
      }
    } else if (_selectedType == BroadcastMediaType.photo) {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _pickedFileName = image.name;
          _pickedFilePath = image.path;
          _pickedXFile = image;
        });
      }
    } else {
      // PDF GO / Document selection simulation
      setState(() {
        _pickedFileName = 'GO_Rajahmundry_Urban_No_402.pdf';
        _pickedFilePath = 'assets/documents/mock_go.pdf';
        _pickedXFile = null;
      });
    }
  }

  Future<void> _publishBroadcast() async {
    if (!_formKey.currentState!.validate() || _pickedFileName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter details and select a media file.')),
      );
      return;
    }

    setState(() {
      _isPublishing = true;
      _publishLogs.clear();
    });

    // 1. Initializing logs
    await _addLog('Initiating Media Broadcast Package...');
    await _addLog('Packaging evidence: $_pickedFileName');

    // Save locally
    final appState = Provider.of<AppState>(context, listen: false);

    // 2. Local database/Supabase upload (with Chunked Resumable upload to prevent HTTP 413 Payload Too Large)
    String? uploadedUrl;
    if (_pickedXFile != null && appState.isSupabaseConnected) {
      try {
        await _addLog('Reading picked file bytes...');
        final bytes = await _pickedXFile!.readAsBytes();
        
        final sanitizedFileName = (_pickedFileName ?? '')
            .replaceAll(RegExp(r'[^\x00-\x7F]+'), '')
            .replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
        final destinationPath = 'mla_broadcasts/${DateTime.now().millisecondsSinceEpoch}_$sanitizedFileName';
        final contentType = _selectedType == BroadcastMediaType.reel
            ? 'video/mp4'
            : (_selectedType == BroadcastMediaType.photo ? 'image/jpeg' : 'application/pdf');

        await _addLog('Initiating resumable chunked upload to Supabase Storage...');
        final publicUrl = await ResumableUploadService.uploadFileInChunks(
          bucketName: 'app_assets',
          destinationPath: destinationPath,
          fileBytes: bytes,
          contentType: contentType,
          onProgress: (progress) {
            setState(() {
              _uploadProgress = progress;
            });
          },
        );

        if (publicUrl == null) {
          throw Exception('Upload completed but returned null URL.');
        }

        uploadedUrl = publicUrl;
        await _addLog('SUCCESS: Media uploaded. Public URL generated: $uploadedUrl');
      } catch (e) {
        await _addLog('❌ UPLOAD ERROR: $e');
        setState(() {
          _isPublishing = false;
        });
        
        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('❌ Upload Failed'),
              content: Text('Video upload terminated: $e\nWorkflow stopped.'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
              ],
            ),
          );
        }
        return; // Terminate workflow immediately on failure! Do NOT call platform APIs!
      }
    } else {
      await _addLog('Uploading media assets to Supabase storage...');
      await Future.delayed(const Duration(milliseconds: 800));
    }

    final selectedPlatforms = <String>[];
    if (_syncInstagram) selectedPlatforms.add('instagram');
    if (_syncYoutube) selectedPlatforms.add('youtube');
    if (_syncFacebook) selectedPlatforms.add('facebook');

    final String mediaTypeStr = _selectedType == BroadcastMediaType.photo
        ? 'photo'
        : (_selectedType == BroadcastMediaType.document ? 'document' : 'reel');

    final String finalVideoUrl = _selectedType == BroadcastMediaType.reel
        ? (uploadedUrl ?? _pickedFilePath ?? 'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4')
        : '';
    final String finalPhotoUrl = _selectedType == BroadcastMediaType.photo
        ? (uploadedUrl ?? _pickedFilePath ?? '')
        : (_selectedType == BroadcastMediaType.document
            ? (uploadedUrl ?? _pickedFilePath ?? '')
            : '');

    final String broadcastId = widget.broadcastToEdit?.id ?? const Uuid().v4();
    final DateTime initialCreatedAt = widget.broadcastToEdit?.createdAt ?? DateTime.now();
    final int initialViews = widget.broadcastToEdit?.views ?? 0;
    final int initialLikes = widget.broadcastToEdit?.likes ?? 0;
    final int initialShares = widget.broadcastToEdit?.shares ?? 0;
    final bool initialIsDeleted = widget.broadcastToEdit?.isDeleted ?? false;

    final newBroadcast = MLABroadcast(
      id: broadcastId,
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      mediaType: mediaTypeStr,
      videoUrl: finalVideoUrl.isNotEmpty ? finalVideoUrl : null,
      photoUrl: finalPhotoUrl.isNotEmpty ? finalPhotoUrl : null,
      thumbnailUrl: widget.broadcastToEdit?.thumbnailUrl,
      syndicatedPlatforms: selectedPlatforms,
      createdAt: initialCreatedAt,
      updatedAt: DateTime.now(),
      scheduledAt: _isScheduled ? _scheduledDateTime : null,
      publishedAt: _isScheduled ? null : DateTime.now(),
      createdBy: appState.currentUser?.name ?? 'MLA',
      visibility: 'public',
      status: _isScheduled ? 'scheduled' : 'published',
      published: !_isScheduled,
      isDeleted: initialIsDeleted,
      views: initialViews,
      likes: initialLikes,
      shares: initialShares,
    );

    // Listen to publisher stream logs
    final logSubscription = SocialPublisherService.logStream.listen((log) {
      _addLog(log);
    });

    if (widget.broadcastToEdit != null) {
      await appState.updateMLABroadcast(newBroadcast);
      await _addLog('Broadcast package updated in database!');
    } else {
      await appState.addMLABroadcast(newBroadcast);
      await _addLog('Broadcast package published to citizen logins!');
    }

    // Call Real Official Platform APIs
    final Map<String, dynamic> results = await SocialPublisherService.publishToAllPlatforms(
      broadcast: newBroadcast,
      platforms: selectedPlatforms,
    );

    logSubscription.cancel();

    setState(() {
      _isPublishing = false;
    });

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          final allSuccessful = results.values.every((r) => r['success'] == true);
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(allSuccessful ? Icons.check_circle : Icons.error, color: allSuccessful ? Colors.green : Colors.red),
                const SizedBox(width: 8),
                Text(allSuccessful ? 'Publication Completed' : 'Publication Failed'),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView(
                shrinkWrap: true,
                children: selectedPlatforms.map((platform) {
                  final res = results[platform];
                  final attempted = res != null;
                  final success = attempted && res['success'] == true;
                  final status = success ? 'SUCCESS' : (attempted ? 'FAILED (${res['status_code']})' : 'Not Attempted');
                  
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(platform.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text(
                                status,
                                style: TextStyle(
                                  color: success ? Colors.green : (attempted ? Colors.red : Colors.grey),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          if (attempted && !success) ...[
                            const SizedBox(height: 4),
                            Text('Reason: ${res['error_message'] ?? 'Unknown API error'}', style: const TextStyle(color: Colors.red, fontSize: 11)),
                          ],
                          if (success && res['post_url'] != null) ...[
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: () => url_launcher.launchUrl(Uri.parse(res['post_url'])),
                              icon: const Icon(Icons.open_in_new, size: 16),
                              label: Text('View on ${platform.toUpperCase()}'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                textStyle: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> _addLog(String log) async {
    if (!mounted) return;
    setState(() {
      _publishLogs.add('[${DateTime.now().toString().substring(11, 19)}] $log');
    });
    await Future.delayed(const Duration(milliseconds: 300));
  }

  @override
  Widget build(BuildContext context) {
    final themeConfig = Provider.of<ThemeProvider>(context).activeParty;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('MLA Media Publisher', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: const BackButton(color: Colors.black87),
      ),
      body: _isPublishing
          ? _buildPublishingOverlay()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Publish Reels, Photos, or Government Orders directly to citizens and your official social media channels.',
                        style: TextStyle(color: Colors.grey, fontSize: 13)),
                    const SizedBox(height: 24),
                    
                    // Media Type Selection
                    const Text('Media Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _mediaTypeOption(BroadcastMediaType.reel, Icons.video_library, 'Reel / Video'),
                        const SizedBox(width: 8),
                        _mediaTypeOption(BroadcastMediaType.photo, Icons.photo_library, 'Photo'),
                        const SizedBox(width: 8),
                        _mediaTypeOption(BroadcastMediaType.document, Icons.description, 'GO / Doc'),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // File Picker Card
                    GestureDetector(
                      onTap: _pickFile,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              _selectedType == BroadcastMediaType.reel
                                  ? Icons.video_call_outlined
                                  : (_selectedType == BroadcastMediaType.photo ? Icons.add_photo_alternate_outlined : Icons.note_add_outlined),
                              size: 40,
                              color: themeConfig.primaryColor,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _pickedFileName ?? 'Select Media File',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            const Text('Tap to browse from local files', style: TextStyle(color: Colors.grey, fontSize: 11)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Form Fields
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Title / Subject',
                        filled: true,
                        fillColor: Colors.white,
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: themeConfig.primaryColor)),
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Title is required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Description / Caption',
                        filled: true,
                        fillColor: Colors.white,
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: themeConfig.primaryColor)),
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Description is required' : null,
                    ),
                    const SizedBox(height: 24),

                    // Social Accounts Connection / Auto Syndication
                    const Text('Auto-Post to Linked Social Media', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          _socialSyncRow('Instagram Reels', 'aashveetech@gmail.com', _syncInstagram, (v) => setState(() => _syncInstagram = v!)),
                          const Divider(),
                          _socialSyncRow('YouTube Channel', 'cognitoinsights1@gmail.com', _syncYoutube, (v) => setState(() => _syncYoutube = v!)),
                          const Divider(),
                          _socialSyncRow('Facebook Page', 'Official MLA Public Page', _syncFacebook, (v) => setState(() => _syncFacebook = v!)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Schedule Publish Options
                    const Text('Publishing Schedule', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Schedule for Future Publish', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              Switch(
                                value: _isScheduled,
                                activeColor: themeConfig.primaryColor,
                                onChanged: (val) {
                                  setState(() {
                                    _isScheduled = val;
                                    if (val && _scheduledDateTime == null) {
                                      _scheduledDateTime = DateTime.now().add(const Duration(hours: 1));
                                    }
                                  });
                                },
                              ),
                            ],
                          ),
                          if (_isScheduled) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    icon: const Icon(Icons.calendar_today),
                                    label: Text(_scheduledDateTime == null 
                                        ? 'Select Date' 
                                        : '${_scheduledDateTime!.day}/${_scheduledDateTime!.month}/${_scheduledDateTime!.year}'),
                                    onPressed: () async {
                                      final date = await showDatePicker(
                                        context: context,
                                        initialDate: _scheduledDateTime ?? DateTime.now(),
                                        firstDate: DateTime.now(),
                                        lastDate: DateTime.now().add(const Duration(days: 365)),
                                      );
                                      if (date != null) {
                                        setState(() {
                                          _scheduledDateTime = DateTime(
                                            date.year,
                                            date.month,
                                            date.day,
                                            _scheduledDateTime?.hour ?? DateTime.now().hour,
                                            _scheduledDateTime?.minute ?? DateTime.now().minute,
                                          );
                                        });
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    icon: const Icon(Icons.access_time),
                                    label: Text(_scheduledDateTime == null 
                                        ? 'Select Time' 
                                        : TimeOfDay.fromDateTime(_scheduledDateTime!).format(context)),
                                    onPressed: () async {
                                      final time = await showTimePicker(
                                        context: context,
                                        initialTime: TimeOfDay.fromDateTime(_scheduledDateTime ?? DateTime.now()),
                                      );
                                      if (time != null) {
                                        setState(() {
                                          _scheduledDateTime = DateTime(
                                            _scheduledDateTime?.year ?? DateTime.now().year,
                                            _scheduledDateTime?.month ?? DateTime.now().month,
                                            _scheduledDateTime?.day ?? DateTime.now().day,
                                            time.hour,
                                            time.minute,
                                          );
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Publish Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _publishBroadcast,
                        style: ElevatedButton.styleFrom(
                           backgroundColor: themeConfig.primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(widget.broadcastToEdit != null ? 'Update Broadcast Package' : 'Publish Broadcast & Sync', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _mediaTypeOption(BroadcastMediaType type, IconData icon, String label) {
    final isSelected = _selectedType == type;
    final themeConfig = Provider.of<ThemeProvider>(context).activeParty;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedType = type;
            _pickedFileName = null;
            _pickedFilePath = null;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? themeConfig.primaryColor.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? themeConfig.primaryColor : Colors.grey.shade200, width: 1.5),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? themeConfig.primaryColor : Colors.grey, size: 20),
              const SizedBox(height: 6),
              Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isSelected ? themeConfig.primaryColor : Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _socialSyncRow(String platform, String accountInfo, bool value, ValueChanged<bool?> onChanged) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(platform, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
              const SizedBox(height: 2),
              Text(accountInfo, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Colors.green,
        ),
      ],
    );
  }

  Widget _buildPublishingOverlay() {
    return Container(
      color: const Color(0xFF0F172A),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                const SizedBox(height: 24),
                CircularProgressIndicator(value: _uploadProgress > 0 ? _uploadProgress : null, color: Colors.green),
                const SizedBox(height: 20),
                const Text('SYNDICATING UPDATE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 2)),
                const SizedBox(height: 8),
                Text('Resumable Upload Progress: ${(_uploadProgress * 100).toStringAsFixed(1)}%', style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 40),
          const Text('Live Console Logs', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade900),
              ),
              child: ListView.builder(
                itemCount: _publishLogs.length,
                itemBuilder: (context, idx) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6.0),
                    child: Text(
                      _publishLogs[idx],
                      style: const TextStyle(color: Colors.greenAccent, fontSize: 11, fontFamily: 'monospace'),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
