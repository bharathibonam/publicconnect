
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
        child: Column(
          children: [
            _buildCustomStepper(_currentStep, activeParty),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(begin: const Offset(0.05, 0), end: Offset.zero).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: KeyedSubtree(
                  key: ValueKey<int>(_currentStep),
                  child: _buildCurrentStep(activeParty),
                ),
              ),
            ),
            _buildBottomBar(activeParty),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStep(PartyThemeConfig party) {
    switch (_currentStep) {
      case 0: return _buildCategoryStep(party);
      case 1: return _buildLocationStep(party);
      case 2: return _buildDetailsStep(party);
      case 3: return _buildSubmitStep(party);
      default: return const SizedBox.shrink();
    }
  }

  Widget _buildCustomStepper(int currentStep, PartyThemeConfig party) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStepItem(0, 'Category', currentStep, party),
          _buildStepDivider(0, currentStep, party),
          _buildStepItem(1, 'Location', currentStep, party),
          _buildStepDivider(1, currentStep, party),
          _buildStepItem(2, 'Details', currentStep, party),
          _buildStepDivider(2, currentStep, party),
          _buildStepItem(3, 'Submit', currentStep, party),
        ],
      ),
    );
  }

  Widget _buildStepItem(int stepIndex, String title, int currentStep, PartyThemeConfig party) {
    final isCompleted = stepIndex < currentStep;
    final isActive = stepIndex == currentStep;
    final color = isCompleted || isActive ? const Color(0xFFEAB308) : Colors.grey.shade300;

    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isCompleted ? const Color(0xFF22C55E) : (isActive ? const Color(0xFFEAB308) : Colors.white),
            shape: BoxShape.circle,
            border: Border.all(color: isCompleted ? const Color(0xFF22C55E) : color, width: 2),
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : Text('${stepIndex + 1}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isActive ? Colors.white : Colors.grey)),
          ),
        ),
        const SizedBox(height: 8),
        Text(title, style: TextStyle(fontSize: 11, fontWeight: isActive ? FontWeight.bold : FontWeight.w500, color: isActive ? const Color(0xFFEAB308) : Colors.grey)),
      ],
    );
  }

  Widget _buildStepDivider(int stepIndex, int currentStep, PartyThemeConfig party) {
    final isCompleted = stepIndex < currentStep;
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 4).copyWith(bottom: 24),
        color: isCompleted ? const Color(0xFF22C55E) : Colors.grey.shade300,
      ),
    );
  }

  Widget _buildBottomBar(PartyThemeConfig party) {
    if (_currentStep == 3) {
      return Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16.0),
        child: SafeArea(
          top: false,
          child: SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF22C55E), // Green for submit
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSubmitting 
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                : const Text('Submit Complaint', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ),
      );
    }

    String nextText = '';
    if (_currentStep == 0) nextText = 'Next: Location';
    if (_currentStep == 1) nextText = 'Next: Details';
    if (_currentStep == 2) nextText = 'Next: Review';

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16.0),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: () {
              if (_currentStep == 0 && _selectedCategoryKey == null) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a category')));
                return;
              }
              if (_currentStep == 1 && (_selectedVillage == null || _wardNumberController.text.isEmpty)) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all location details')));
                return;
              }
              if (_currentStep == 2 && (_descriptionController.text.isEmpty || _pickedMediaBytes == null)) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please provide description and evidence')));
                return;
              }
              
              setState(() => _currentStep += 1);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEAB308),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(nextText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryStep(PartyThemeConfig party) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Select Category', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 4),
          const Text('Choose the category of your issue', style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 24),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.9,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _categoryKeys.length,
            itemBuilder: (context, index) {
              final key = _categoryKeys[index];
              final isSelected = _selectedCategoryKey == key;
              final categoryColor = CategoryMapping.getColorForCategory(key);
              final categoryIcon = CategoryMapping.getIconForCategory(key);
              
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => setState(() => _selectedCategoryKey = key),
                  borderRadius: BorderRadius.circular(20),
                  splashColor: categoryColor.withValues(alpha: 0.1),
                  highlightColor: categoryColor.withValues(alpha: 0.05),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? categoryColor.withValues(alpha: 0.05) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? categoryColor : Colors.transparent,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isSelected ? categoryColor.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.04),
                          blurRadius: isSelected ? 12 : 8,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(categoryIcon, color: categoryColor, size: 32),
                        const SizedBox(height: 12),
                        Text(
                          CategoryMapping.getLocalizedCategory(context, key),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.black87,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                            fontSize: 10,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLocationStep(PartyThemeConfig party) {
    final mandals = MandalMapping.mandals;
    List<String> panchayats = _selectedMandal != null ? MandalMapping.getPanchayatsForMandal(_selectedMandal!, Provider.of<AppState>(context, listen: false).uniquePanchayats) : [];
    List<String> villages = _selectedPanchayat != null ? MandalMapping.getVillagesForPanchayat(_selectedPanchayat!) : [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Select Location', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 4),
          const Text('Confirm or adjust the location', style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 24),
          
          Container(
            height: 220,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey.shade100),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 6))],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: CustomMap(
                complaints: const [],
                isInteractiveSelection: true,
                selectedLocation: _selectedLocation,
                onLocationSelected: _onLocationPicked,
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          ElevatedButton.icon(
            onPressed: _useMyLocation,
            icon: _isFetchingLocation 
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
              : const Icon(Icons.my_location, color: Colors.white, size: 20),
            label: const Text('Use My Location', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6), // Blue
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              minimumSize: const Size(double.infinity, 48),
              elevation: 0,
            ),
          ),
          
          const SizedBox(height: 24),
          const Text('Location Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Mandal', 
                    filled: true, 
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                  ),
                  initialValue: _selectedMandal,
                  items: mandals.map((m) => DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(fontSize: 13)))).toList(),
                  onChanged: (val) => setState(() { _selectedMandal = val; _selectedPanchayat = null; _selectedVillage = null; }),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Panchayat', 
                    filled: true, 
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                  ),
                  initialValue: _selectedPanchayat,
                  items: panchayats.map((p) => DropdownMenuItem(value: p, child: Text(p, style: const TextStyle(fontSize: 13)))).toList(),
                  onChanged: _selectedMandal == null ? null : (val) => setState(() { _selectedPanchayat = val; _selectedVillage = null; }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Village', 
                    filled: true, 
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                  ),
                  initialValue: _selectedVillage,
                  items: villages.map((v) => DropdownMenuItem(value: v, child: Text(v, style: const TextStyle(fontSize: 13)))).toList(),
                  onChanged: _selectedPanchayat == null ? null : (val) => setState(() => _selectedVillage = val),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _wardNumberController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Ward Number', 
                    filled: true, 
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsStep(PartyThemeConfig party) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Describe Your Issue', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 4),
          const Text('You can speak or type your issue', style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 24),
          
          Center(
            child: GestureDetector(
              onTap: _openVoiceDictation,
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    width: 80 + (_pulseController.value * 12),
                    height: 80 + (_pulseController.value * 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAB308),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFEAB308).withValues(alpha: 0.3 + (_pulseController.value * 0.2)),
                          blurRadius: 16 + (_pulseController.value * 12),
                          spreadRadius: _pulseController.value * 6,
                          offset: const Offset(0, 8),
                        )
                      ],
                    ),
                    child: child,
                  );
                },
                child: const Center(child: Icon(Icons.mic, color: Colors.white, size: 40)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Center(child: Text('Tap to speak', style: TextStyle(color: Colors.grey, fontSize: 14))),
          const SizedBox(height: 24),
          
          TextFormField(
            controller: _descriptionController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Or type your issue here...', 
              filled: true, 
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
            ),
          ),
          
          const SizedBox(height: 24),
          const Text('Add Photos (Optional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          
          Row(
            children: [
              GestureDetector(
                onTap: _showImageSourceSheet,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: const Center(child: Icon(Icons.camera_alt_outlined, color: Colors.grey)),
                ),
              ),
              const SizedBox(width: 12),
              if (_pickedMediaBytes != null)
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: (_isVideoSelected || kIsWeb) ? const Icon(Icons.videocam, color: Colors.grey) : Image.memory(_pickedMediaBytes!, fit: BoxFit.cover),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitStep(PartyThemeConfig party) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Review & Submit', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 4),
          const Text('Please review your complaint details', style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 24),
          
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey.shade100),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 6))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _reviewItem(Icons.category, 'Category', _selectedCategoryKey != null ? CategoryMapping.getLocalizedCategory(context, _selectedCategoryKey!) : 'Not selected'),
                const Divider(height: 24),
                _reviewItem(Icons.location_on, 'Location', '$_selectedVillage, ${_selectedPanchayat ?? ''}, ${_selectedMandal ?? ''}\nWard ${_wardNumberController.text}'),
                const Divider(height: 24),
                _reviewItem(Icons.description, 'Description', _descriptionController.text.isNotEmpty ? _descriptionController.text : 'No description provided'),
                const Divider(height: 24),
                
                Row(
                  children: [
                    const Icon(Icons.attachment, color: Colors.grey, size: 20),
                    const SizedBox(width: 12),
                    const Text('Attachments', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                if (_pickedMediaBytes != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 32),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 60,
                        height: 60,
                        child: (_isVideoSelected || kIsWeb) ? const Icon(Icons.videocam, color: Colors.grey) : Image.memory(_pickedMediaBytes!, fit: BoxFit.cover),
                      ),
                    ),
                  )
                else
                  const Padding(
                    padding: EdgeInsets.only(left: 32),
                    child: Text('No attachments', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  ),
                  
                const Divider(height: 24),
                Row(
                  children: [
                    const Icon(Icons.access_time, color: Colors.grey, size: 20),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Reported On', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 2),
                        const Text('Just now', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _reviewItem(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.grey, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
            ],
          ),
        ),
      ],
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
