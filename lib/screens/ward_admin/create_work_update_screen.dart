import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import '../../services/app_state.dart';
import '../../services/supabase_service.dart';
import '../../themes/party_theme_config.dart';
import '../../models/completed_work.dart';
import '../../models/complaint.dart';

import '../../widgets/shared_officer_widgets.dart';

class CreateWorkUpdateScreen extends StatefulWidget {
  final Complaint complaint;
  const CreateWorkUpdateScreen({super.key, required this.complaint});

  @override
  State<CreateWorkUpdateScreen> createState() => _CreateWorkUpdateScreenState();
}

class _CreateWorkUpdateScreenState extends State<CreateWorkUpdateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();
  final _remarksController = TextEditingController();
  
  Uint8List? _beforeImage;
  Uint8List? _afterImage;
  Uint8List? _video;
  Uint8List? _pdf;
  Uint8List? _voice;
  DateTime _completionDate = DateTime.now();

  bool _isPublishing = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source, bool isBefore) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: source, imageQuality: 70);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        if (isBefore) {
          _beforeImage = bytes;
        } else {
          _afterImage = bytes;
        }
      });
    }
  }

  Future<void> _pickFile(String type) async {
    FileType fileType;
    if (type == 'video') {
      fileType = FileType.video;
    } else if (type == 'pdf') {
      fileType = FileType.custom;
    } else {
      fileType = FileType.audio;
    }

    final result = await FilePicker.pickFiles(
      type: fileType,
      allowedExtensions: type == 'pdf' ? ['pdf'] : null,
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      Uint8List? bytes = result.files.first.bytes;
      if (bytes == null && result.files.first.path != null && !kIsWeb) {
        bytes = await File(result.files.first.path!).readAsBytes();
      }
      
      if (bytes != null) {
        setState(() {
          if (type == 'video') {
            _video = bytes;
          } else if (type == 'pdf') {
            _pdf = bytes;
          } else {
            _voice = bytes;
          }
        });
      }
    }
  }

  void _showImagePicker(bool isBefore) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera, isBefore);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery, isBefore);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _publish() async {
    if (!_formKey.currentState!.validate()) return;
    if (_afterImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('After Image is required.')));
      return;
    }

    setState(() => _isPublishing = true);

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final user = appState.currentUser!;
      final complaint = widget.complaint;

      final workId = const Uuid().v4();

      String? beforeUrl, afterUrl, videoUrl, pdfUrl, voiceUrl;

      if (_beforeImage != null) {
        beforeUrl = await SupabaseService.uploadCompletedWorkBytes(_beforeImage!, workId, 'before', 'jpg', 'image/jpeg');
      }
      afterUrl = await SupabaseService.uploadCompletedWorkBytes(_afterImage!, workId, 'after', 'jpg', 'image/jpeg');
      if (_video != null) {
        videoUrl = await SupabaseService.uploadCompletedWorkBytes(_video!, workId, 'video', 'mp4', 'video/mp4');
      }
      if (_pdf != null) {
        pdfUrl = await SupabaseService.uploadCompletedWorkBytes(_pdf!, workId, 'pdf', 'pdf', 'application/pdf');
      }
      if (_voice != null) {
        voiceUrl = await SupabaseService.uploadCompletedWorkBytes(_voice!, workId, 'voice', 'm4a', 'audio/m4a');
      }

      final work = CompletedWork(
        id: workId,
        complaintId: complaint.id,
        wardMemberId: user.id,
        citizenId: complaint.userId,
        title: _titleController.text.trim(),
        description: _noteController.text.trim(),
        beforeImageUrl: beforeUrl,
        afterImageUrl: afterUrl,
        videoUrl: videoUrl,
        pdfUrl: pdfUrl,
        voiceUrl: voiceUrl,
        remarks: _remarksController.text.trim(),
        completedAt: _completionDate,
        createdAt: DateTime.now(),
      );

      await SupabaseService.submitCompletedWork(work);

      if (mounted) {
        setState(() {
          _isPublishing = false;
        });
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Completed work published successfully!')),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('Error publishing Completed Work: $e\n$stackTrace');
      if (mounted) {
        setState(() => _isPublishing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error publishing: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const themeConfig = PartyThemeConfig.violetOfficerTheme;
    
    return Scaffold(
      backgroundColor: themeConfig.backgroundColor,
      appBar: const OfficerAppBar(
        title: 'Complete Work',
        subtitle: 'Upload work completion details',
        isTelugu: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Completion Title',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _noteController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Completion Description',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Work Completion Date'),
                subtitle: Text('${_completionDate.toLocal()}'.split(' ')[0]),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _completionDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) setState(() => _completionDate = date);
                },
              ),
              const SizedBox(height: 24),
              const Text('Attachments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildAttachBtn('Before Image', Icons.image, () => _showImagePicker(true), _beforeImage != null)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildAttachBtn('After Image *', Icons.image, () => _showImagePicker(false), _afterImage != null)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _buildAttachBtn('Video', Icons.video_file, () => _pickFile('video'), _video != null)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildAttachBtn('PDF Report', Icons.picture_as_pdf, () => _pickFile('pdf'), _pdf != null)),
                ],
              ),
              const SizedBox(height: 8),
              _buildAttachBtn('Voice Note', Icons.mic, () => _pickFile('voice'), _voice != null),
              const SizedBox(height: 16),
              TextFormField(
                controller: _remarksController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Additional Remarks',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isPublishing ? null : _publish,
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeConfig.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: _isPublishing
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Submit Completed Work', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttachBtn(String label, IconData icon, VoidCallback onTap, bool hasFile) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(hasFile ? Icons.check_circle : icon, color: hasFile ? Colors.green : Colors.grey),
      label: Text(label, style: TextStyle(color: hasFile ? Colors.green : Colors.black87, fontSize: 12)),
      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
    );
  }
}
