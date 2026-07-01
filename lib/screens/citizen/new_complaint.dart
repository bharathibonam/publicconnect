
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../services/app_state.dart';
import '../../widgets/custom_map.dart';
import '../../utils/category_mapping.dart';
import '../../utils/mandal_mapping.dart';
import '../../themes/theme_provider.dart';
import '../../themes/party_theme_config.dart';



class NewComplaintScreen extends StatefulWidget {
  final VoidCallback onSubmissionSuccess;

  const NewComplaintScreen({super.key, required this.onSubmissionSuccess});

  @override
  State<NewComplaintScreen> createState() => _NewComplaintScreenState();
}

class _NewComplaintScreenState extends State<NewComplaintScreen> with TickerProviderStateMixin {
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _wardNumberController = TextEditingController();

  String? _selectedMandal;
  String? _selectedPanchayat;
  String? _selectedVillage;
  String? _selectedCategoryKey;

  late List<String> _categoryKeys;


  LatLng? _selectedLocation;
  String _resolvedAddress = '';

  Uint8List? _pickedMediaBytes;
  bool _isVideoSelected = false;

  bool _isFetchingLocation = false;
  bool _isSubmitting = false;

  late AnimationController _pulseController;


  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat(reverse: true);
    _categoryKeys = CategoryMapping.getAllCategories();

    _useMyLocation();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _wardNumberController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _useMyLocation() async {
    setState(() => _isFetchingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (_selectedLocation == null) await _onLocationPicked(const LatLng(17.3850, 78.4867));
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location services are disabled.')));
        setState(() => _isFetchingLocation = false);
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever || permission == LocationPermission.denied) {
        if (_selectedLocation == null) await _onLocationPicked(const LatLng(17.3850, 78.4867));
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permission denied.')));
        setState(() => _isFetchingLocation = false);
        return;
      }
      Position? pos;
      try {
        pos = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 15)));
      } catch (_) {
        pos = await Geolocator.getLastKnownPosition();
      }
      if (pos == null) throw Exception("Could not fetch location");
      final latLng = LatLng(pos.latitude, pos.longitude);
      await _onLocationPicked(latLng);
    } catch (e) {
      final fallback = const LatLng(12.9716, 77.5946);
      await _onLocationPicked(fallback);
    } finally {
      if (mounted) setState(() => _isFetchingLocation = false);
    }
  }

  Future<void> _onLocationPicked(LatLng loc) async {
    setState(() {
      _selectedLocation = loc;
      _resolvedAddress = 'Fetching Address...';
    });
    try {
      final placemarks = await placemarkFromCoordinates(loc.latitude, loc.longitude);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final parts = [p.subThoroughfare, p.thoroughfare, p.subLocality, p.locality].whereType<String>().where((s) => s.isNotEmpty).toList();
        setState(() {
          _resolvedAddress = parts.isNotEmpty ? parts.join(', ') : '${loc.latitude.toStringAsFixed(4)}, ${loc.longitude.toStringAsFixed(4)}';
        });
      }
    } catch (_) {
      setState(() {
        _resolvedAddress = '${loc.latitude.toStringAsFixed(5)}, ${loc.longitude.toStringAsFixed(5)}';
      });
    }
  }

  Future<void> _pickMedia(ImageSource source, bool isVideo) async {
    final picker = ImagePicker();
    final XFile? picked = isVideo
        ? await picker.pickVideo(source: source, maxDuration: const Duration(minutes: 2))
        : await picker.pickImage(source: source, imageQuality: 75, maxWidth: 1200);
    if (picked == null) return;

    final bytes = await picked.readAsBytes();

    setState(() {
      _pickedMediaBytes = bytes;
      _isVideoSelected = isVideo;
    });
  }


  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Choose Evidence Media', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('PHOTO', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 8),
                      IconButton.filledTonal(icon: const Icon(Icons.camera_alt), onPressed: () { Navigator.pop(ctx); _pickMedia(ImageSource.camera, false); }),
                      const Text('Camera'),
                      const SizedBox(height: 8),
                      IconButton.filledTonal(icon: const Icon(Icons.photo_library), onPressed: () { Navigator.pop(ctx); _pickMedia(ImageSource.gallery, false); }),
                      const Text('Gallery'),
                    ],
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('VIDEO', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 8),
                      IconButton.filledTonal(icon: const Icon(Icons.videocam), onPressed: () { Navigator.pop(ctx); _pickMedia(ImageSource.camera, true); }),
                      const Text('Camera'),
                      const SizedBox(height: 8),
                      IconButton.filledTonal(icon: const Icon(Icons.video_library), onPressed: () { Navigator.pop(ctx); _pickMedia(ImageSource.gallery, true); }),
                      const Text('Gallery'),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openVoiceDictation() async {
    final resultText = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => const _VoiceDictationSheet(isTeluguInitially: false),
    );

    if (resultText != null && resultText.trim().isNotEmpty) {
      setState(() {
        _descriptionController.text += _descriptionController.text.isNotEmpty ? ' $resultText' : resultText;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pickedMediaBytes == null || _selectedLocation == null || _selectedCategoryKey == null || _selectedVillage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please complete all mandatory fields.')));
      return;
    }
    setState(() => _isSubmitting = true);

    final appState = Provider.of<AppState>(context, listen: false);
    final wId = 'ward_${_wardNumberController.text.trim()}';
    final wName = 'Ward ${_wardNumberController.text.trim()} - $_selectedVillage';
    
    try {
      await appState.submitComplaint(
        category: _selectedCategoryKey!,
        description: _descriptionController.text.trim(),
        latitude: _selectedLocation!.latitude,
        longitude: _selectedLocation!.longitude,
        address: _resolvedAddress,
        imageBytes: _pickedMediaBytes,
        isVideo: _isVideoSelected,
        wardId: wId,
        wardName: wName,
        villageName: _selectedVillage!,
        mandalName: _selectedMandal!,
      );
      if (mounted) _showSuccessDialog();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Submission failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }

  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 64),
            const SizedBox(height: 16),
            const Text('Complaint Submitted Successfully!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                widget.onSubmissionSuccess();
              },
              child: const Text('Track Complaint'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final activeParty = themeProvider.activeParty;

    return Scaffold(
      backgroundColor: activeParty.backgroundColor,
      appBar: AppBar(
        title: Text(Provider.of<AppState>(context).isTelugu ? 'ఫిర్యాదు నమోదు' : 'File Complaint', style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black87),
        elevation: 1,

      ),
      body: Form(
        key: _formKey,
        child: Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: activeParty.primaryColor),
          ),
          child: Stepper(
            type: StepperType.horizontal,
            elevation: 0,
            currentStep: _currentStep,
            onStepContinue: () {
              if (_currentStep == 0 && _selectedCategoryKey == null) return;
              if (_currentStep == 1 && (_selectedVillage == null || _wardNumberController.text.isEmpty)) return;
              if (_currentStep == 2 && (_descriptionController.text.isEmpty || _pickedMediaBytes == null)) return;
              
              if (_currentStep < 3) {
                setState(() => _currentStep += 1);
              } else {
                _submit();
              }
            },
            onStepCancel: () {
              if (_currentStep > 0) {
                setState(() => _currentStep -= 1);
              }
            },
            steps: [
              Step(
                title: const FittedBox(child: Text('Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10))),
                isActive: _currentStep >= 0,
                state: StepState.indexed,
                content: _buildCategoryStep(activeParty),
              ),
              Step(
                title: const FittedBox(child: Text('Location', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10))),
                isActive: _currentStep >= 1,
                state: StepState.indexed,
                content: _buildLocationStep(activeParty),
              ),
              Step(
                title: const FittedBox(child: Text('Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10))),
                isActive: _currentStep >= 2,
                state: StepState.indexed,
                content: _buildDetailsStep(activeParty),
              ),
              Step(
                title: const FittedBox(child: Text('Submit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10))),
                isActive: _currentStep >= 3,
                state: StepState.indexed,
                content: _buildSubmitStep(activeParty),
              ),
            ],
            controlsBuilder: (context, details) {
              return Padding(
                padding: const EdgeInsets.only(top: 20, bottom: 80),
                child: Row(
                  children: [
                    if (_currentStep < 3)
                      Expanded(
                        child: ElevatedButton(
                          onPressed: details.onStepContinue,
                          style: ElevatedButton.styleFrom(backgroundColor: activeParty.primaryColor),
                          child: const Text('CONTINUE', style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    if (_currentStep == 3)
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : details.onStepContinue,
                          style: ElevatedButton.styleFrom(backgroundColor: activeParty.primaryColor),
                          child: _isSubmitting 
                            ? const CircularProgressIndicator(color: Colors.white) 
                            : const Text('SUBMIT COMPLAINT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    if (_currentStep > 0) ...[
                      const SizedBox(width: 12),
                      TextButton(
                        onPressed: details.onStepCancel,
                        child: Text('BACK', style: TextStyle(color: activeParty.primaryColor)),
                      ),
                    ]
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryStep(PartyThemeConfig party) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.85,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _categoryKeys.length,
      itemBuilder: (context, index) {
        final key = _categoryKeys[index];
        final isSelected = _selectedCategoryKey == key;
        final categoryColor = CategoryMapping.getColorForCategory(key);
        final categoryIcon = CategoryMapping.getIconForCategory(key);
        
        return GestureDetector(
          onTap: () => setState(() => _selectedCategoryKey = key),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? categoryColor.withValues(alpha: 0.1) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? categoryColor : Colors.grey.shade200,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected 
                  ? [BoxShadow(color: categoryColor.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 4))] 
                  : [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2))],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: categoryColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(categoryIcon, color: categoryColor, size: 28),
                ),
                const SizedBox(height: 10),
                Text(
                  key,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? categoryColor : Colors.black87,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    fontSize: 11,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLocationStep(PartyThemeConfig party) {
    final mandals = MandalMapping.mandals;
    List<String> panchayats = _selectedMandal != null ? MandalMapping.getPanchayatsForMandal(_selectedMandal!, Provider.of<AppState>(context, listen: false).uniquePanchayats) : [];
    List<String> villages = _selectedPanchayat != null ? MandalMapping.getVillagesForPanchayat(_selectedPanchayat!) : [];

    return Column(
      children: [
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(labelText: 'Mandal', filled: true, fillColor: Colors.white),
          initialValue: _selectedMandal,
          items: mandals.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
          onChanged: (val) => setState(() { _selectedMandal = val; _selectedPanchayat = null; _selectedVillage = null; }),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(labelText: 'Panchayat', filled: true, fillColor: Colors.white),
          initialValue: _selectedPanchayat,
          items: panchayats.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
          onChanged: _selectedMandal == null ? null : (val) => setState(() { _selectedPanchayat = val; _selectedVillage = null; }),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(labelText: 'Village', filled: true, fillColor: Colors.white),
          initialValue: _selectedVillage,
          items: villages.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
          onChanged: _selectedPanchayat == null ? null : (val) => setState(() => _selectedVillage = val),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _wardNumberController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Ward Number', filled: true, fillColor: Colors.white),
        ),
      ],
    );
  }

  Widget _buildDetailsStep(PartyThemeConfig party) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Description', style: TextStyle(fontWeight: FontWeight.bold)),
            IconButton(icon: Icon(Icons.mic, color: party.primaryColor), onPressed: _openVoiceDictation),
          ],
        ),
        TextFormField(
          controller: _descriptionController,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Describe the issue...', filled: true, fillColor: Colors.white),
        ),
        const SizedBox(height: 24),
        const Text('Evidence (Mandatory)', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _showImageSourceSheet,
          child: Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _pickedMediaBytes != null ? party.primaryColor : Colors.grey.shade400, width: 2),
            ),
            child: _pickedMediaBytes != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: (_isVideoSelected || kIsWeb) ? const Icon(Icons.insert_drive_file, size: 50, color: Colors.grey) : Image.memory(_pickedMediaBytes!, fit: BoxFit.cover),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt, size: 40, color: Colors.grey.shade400),
                    const Text('Tap to capture photo/video', style: TextStyle(color: Colors.grey)),
                  ],
                ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('GPS Location', style: TextStyle(fontWeight: FontWeight.bold)),
            TextButton.icon(
              icon: _isFetchingLocation ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.my_location),
              label: const Text('Fetch Location'),
              onPressed: _useMyLocation,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 150,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CustomMap(
              complaints: const [],
              isInteractiveSelection: true,
              selectedLocation: _selectedLocation,
              onLocationSelected: _onLocationPicked,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitStep(PartyThemeConfig party) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: party.primaryColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _summaryRow('Category', _selectedCategoryKey ?? 'Not selected'),
          const Divider(),
          _summaryRow('Location', '$_selectedVillage, ${_selectedPanchayat ?? ''}, ${_selectedMandal ?? ''}\nWard ${_wardNumberController.text}'),
          const Divider(),
          _summaryRow('GPS', _selectedLocation != null ? '${_selectedLocation!.latitude.toStringAsFixed(4)}, ${_selectedLocation!.longitude.toStringAsFixed(4)}' : 'Not verified'),
          const Divider(),
          _summaryRow('Evidence', _pickedMediaBytes != null ? (_isVideoSelected ? 'Video attached' : 'Photo attached') : 'Missing!'),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 80, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
        ],
      ),
    );
  }
}

class _VoiceDictationSheet extends StatefulWidget {
  final bool isTeluguInitially;
  const _VoiceDictationSheet({required this.isTeluguInitially});
  @override
  State<_VoiceDictationSheet> createState() => _VoiceDictationSheetState();
}

class _VoiceDictationSheetState extends State<_VoiceDictationSheet> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _dictatedText = '';

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _speech.initialize();
  }

  void _toggleListening() async {
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
    } else {
      setState(() => _isListening = true);
      await _speech.listen(onResult: (result) {
        setState(() => _dictatedText = result.recognizedWords);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 24, left: 24, right: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Voice Dictation', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _toggleListening,
            child: CircleAvatar(
              radius: 40,
              backgroundColor: _isListening ? Colors.red : Theme.of(context).primaryColor,
              child: const Icon(Icons.mic, color: Colors.white, size: 40),
            ),
          ),
          const SizedBox(height: 16),
          Text(_dictatedText.isEmpty ? 'Tap mic to speak' : _dictatedText),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, _dictatedText),
            child: const Text('Confirm'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
