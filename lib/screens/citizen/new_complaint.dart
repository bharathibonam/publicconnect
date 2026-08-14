import 'dart:typed_data';
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'dart:js' as js;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:record/record.dart';
import '../../services/whisper_service.dart';
import '../../services/app_state.dart';
import '../../services/supabase_service.dart';
import '../../widgets/custom_map.dart';
import '../../utils/category_mapping.dart';
import '../../utils/mandal_mapping.dart';
import '../../themes/theme_provider.dart';
import '../../themes/party_theme_config.dart';
import '../../utils/camera_helper.dart';

class SelectedMedia {
  final String id;
  final Uint8List bytes;
  final bool isVideo;
  double uploadProgress;
  String? remoteUrl;
  bool hasError;
  bool isUploading;

  SelectedMedia({
    required this.id,
    required this.bytes,
    required this.isVideo,
    this.uploadProgress = 0.0,
    this.remoteUrl,
    this.hasError = false,
    this.isUploading = false,
  });
}

class NewComplaintScreen extends StatefulWidget {
  final VoidCallback onSubmissionSuccess;
  final VoidCallback? onBackPressed;

  const NewComplaintScreen({
    super.key,
    required this.onSubmissionSuccess,
    this.onBackPressed,
  });

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

  late String _currentComplaintId;
  final List<SelectedMedia> _selectedMediaList = [];

  bool _isFetchingLocation = false;
  bool _isSubmitting = false;
  bool _isSubmitted = false;
  bool _isResetting = false;

  late AnimationController _pulseController;

  void _generateNewComplaintId() {
    final randomSuffix = DateTime.now().microsecondsSinceEpoch % 100000;
    _currentComplaintId = 'comp_${DateTime.now().millisecondsSinceEpoch}_$randomSuffix';
  }

  void _saveDraftState() {
    if (_isResetting) return;
    try {
      final box = Hive.box('app_settings');
      box.put('draft_step', _currentStep);
      box.put('draft_category', _selectedCategoryKey);
      box.put('draft_mandal', _selectedMandal);
      box.put('draft_panchayat', _selectedPanchayat);
      box.put('draft_village', _selectedVillage);
      box.put('draft_ward', _wardNumberController.text);
      box.put('draft_description', _descriptionController.text);
      
      // Save draft bytes for recovery
      final savedBytes = _selectedMediaList.map((m) => {
        'id': m.id,
        'bytes': m.bytes,
        'isVideo': m.isVideo,
        'remoteUrl': m.remoteUrl,
      }).toList();
      box.put('draft_media_items', savedBytes);
      box.put('draft_complaint_id', _currentComplaintId);

      if (_selectedLocation != null) {
        box.put('draft_lat', _selectedLocation!.latitude);
        box.put('draft_lng', _selectedLocation!.longitude);
      } else {
        box.delete('draft_lat');
        box.delete('draft_lng');
      }
      debugPrint('[DraftFlow] Saved draft state.');
    } catch (e) {
      debugPrint('[DraftFlow] Error saving draft: $e');
    }
  }

  Future<void> _clearDraftState() async {
    try {
      final box = Hive.box('app_settings');
      await box.delete('draft_step');
      await box.delete('draft_category');
      await box.delete('draft_mandal');
      await box.delete('draft_panchayat');
      await box.delete('draft_village');
      await box.delete('draft_ward');
      await box.delete('draft_description');
      await box.delete('draft_media_items');
      await box.delete('draft_complaint_id');
      await box.delete('draft_lat');
      await box.delete('draft_lng');
      debugPrint('[DraftFlow] Cleared draft state.');
    } catch (e) {
      debugPrint('[DraftFlow] Error clearing draft: $e');
    }
  }

  void _loadDraftState() {
    try {
      final box = Hive.box('app_settings');
      if (box.containsKey('draft_step')) {
        setState(() {
          _currentStep = box.get('draft_step') as int;
          _selectedCategoryKey = box.get('draft_category') as String?;
          _selectedMandal = box.get('draft_mandal') as String?;
          _selectedPanchayat = box.get('draft_panchayat') as String?;
          _selectedVillage = box.get('draft_village') as String?;
          _wardNumberController.text = box.get('draft_ward', defaultValue: '') as String;
          _descriptionController.text = box.get('draft_description', defaultValue: '') as String;
          
          if (box.containsKey('draft_complaint_id')) {
            _currentComplaintId = box.get('draft_complaint_id') as String;
          } else {
            _generateNewComplaintId();
          }

          final savedItems = box.get('draft_media_items');
          if (savedItems != null) {
            _selectedMediaList.clear();
            for (final map in List<Map>.from(savedItems)) {
              final item = SelectedMedia(
                id: map['id'] as String,
                bytes: map['bytes'] as Uint8List,
                isVideo: map['isVideo'] as bool,
                remoteUrl: map['remoteUrl'] as String?,
                uploadProgress: map['remoteUrl'] != null ? 1.0 : 0.0,
                hasError: false,
                isUploading: false,
              );
              _selectedMediaList.add(item);
              // Trigger background upload if it was not completed
              if (item.remoteUrl == null) {
                _uploadMediaItem(item);
              }
            }
          }

          final lat = box.get('draft_lat') as double?;
          final lng = box.get('draft_lng') as double?;
          if (lat != null && lng != null) {
            _selectedLocation = LatLng(lat, lng);
          }
        });
        debugPrint('[DraftFlow] Loaded draft state successfully.');
      } else {
        _generateNewComplaintId();
      }
    } catch (e) {
      debugPrint('[DraftFlow] Error loading draft: $e');
      _generateNewComplaintId();
    }
  }

  Future<void> _resetForm() async {
    _isResetting = true;
    _descriptionController.removeListener(_saveDraftState);
    _wardNumberController.removeListener(_saveDraftState);

    await _clearDraftState();
    _descriptionController.clear();
    _wardNumberController.clear();

    setState(() {
      _currentStep = 0;
      _selectedMandal = null;
      _selectedPanchayat = null;
      _selectedVillage = null;
      _selectedCategoryKey = null;
      _selectedLocation = null;
      _resolvedAddress = '';
      _selectedMediaList.clear();
      _isFetchingLocation = false;
      _isSubmitting = false;
      _isSubmitted = false;
      _generateNewComplaintId();
    });

    _descriptionController.addListener(_saveDraftState);
    _wardNumberController.addListener(_saveDraftState);

    Future.microtask(() {
      _isResetting = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat(reverse: true);
    _categoryKeys = CategoryMapping.getAllCategories();
    _loadDraftState();
    _descriptionController.addListener(_saveDraftState);
    _wardNumberController.addListener(_saveDraftState);
    _retrieveLostData();
  }

  Future<void> _retrieveLostData() async {
    try {
      final picker = ImagePicker();
      final LostDataResponse response = await picker.retrieveLostData();
      debugPrint('[CameraFlow] retrieveLostData() retrieved: ${response.isEmpty ? "empty" : "data"}');
      if (response.isEmpty) return;
      if (response.file != null) {
        final bytes = await response.file!.readAsBytes();
        final item = SelectedMedia(
          id: '${DateTime.now().microsecondsSinceEpoch}',
          bytes: bytes,
          isVideo: response.type == RetrieveType.video,
        );
        setState(() {
          _selectedMediaList.add(item);
        });
        _saveDraftState();
        _uploadMediaItem(item);
        debugPrint('[CameraFlow] retrieveLostData() restored file bytes size: ${bytes.length}');
      }
    } catch (e) {
      debugPrint('Error retrieving lost data: $e');
    }
  }

  Future<void> _uploadMediaItem(SelectedMedia item) async {
    setState(() {
      item.isUploading = true;
      item.hasError = false;
      item.uploadProgress = 0.1;
    });

    final progressTimer = Stream.periodic(const Duration(milliseconds: 200), (count) => count)
        .take(8)
        .listen((count) {
      if (mounted && item.isUploading) {
        setState(() {
          item.uploadProgress = 0.1 + (count * 0.1);
        });
      }
    });

    int attempts = 3;
    while (attempts > 0) {
      try {
        final path = item.isVideo 
            ? '$_currentComplaintId/videos/video_${item.id}_${DateTime.now().millisecondsSinceEpoch}.mp4'
            : '$_currentComplaintId/images/image_${item.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        
        final url = await SupabaseService.uploadComplaintBytesCustom(
          item.bytes,
          path,
          item.isVideo ? 'video/mp4' : 'image/jpeg',
        );

        if (url != null) {
          progressTimer.cancel();
          setState(() {
            item.remoteUrl = url;
            item.isUploading = false;
            item.uploadProgress = 1.0;
            item.hasError = false;
          });
          _saveDraftState();
          return;
        }
      } catch (e) {
        debugPrint('[Upload] Background upload failed: $e');
      }
      attempts--;
      if (attempts > 0) {
        await Future.delayed(const Duration(seconds: 1));
      }
    }

    progressTimer.cancel();
    setState(() {
      item.isUploading = false;
      item.hasError = true;
    });
  }

  @override
  void dispose() {
    _descriptionController.removeListener(_saveDraftState);
    _wardNumberController.removeListener(_saveDraftState);
    _descriptionController.dispose();
    _wardNumberController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _showLocationPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Location Permission Required'),
        content: const Text('Location permission is required to fetch your current location.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Geolocator.openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _useMyLocation();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Future<void> _useMyLocation() async {
    if (_isSubmitting || _isSubmitted) return;

    // Explicitly reset and clear all old location data before fetching fresh GPS
    setState(() {
      _isFetchingLocation = true;
      _selectedMandal = null;
      _selectedPanchayat = null;
      _selectedVillage = null;
      _wardNumberController.clear();
      _resolvedAddress = '';
      _locationStateVersion++;
    });
    _saveDraftState();

    debugPrint('[GPSFlow] _useMyLocation() called.');
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      debugPrint('[GPSFlow] Location service enabled status: $serviceEnabled');
      if (!serviceEnabled) {
        if (_selectedLocation == null) await _onLocationPicked(const LatLng(17.3850, 78.4867));
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location services are disabled.')));
        setState(() => _isFetchingLocation = false);
        return;
      }

      if (!kIsWeb) {
        LocationPermission permission = await Geolocator.checkPermission();
        debugPrint('[GPSFlow] Initial permission status: $permission');
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          debugPrint('[GPSFlow] Permission status after request: $permission');
        }
        if (permission == LocationPermission.deniedForever || permission == LocationPermission.denied) {
          setState(() => _isFetchingLocation = false);
          if (mounted) {
            _showLocationPermissionDialog();
          }
          return;
        }
      }

      Position? pos;
      try {
        pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 15),
          ),
        );
        debugPrint('[GPSFlow] Retrieved position: Lat: ${pos.latitude}, Lng: ${pos.longitude}');
      } catch (e) {
        debugPrint('[GPSFlow] getCurrentPosition failed: $e. Trying last known position.');
        pos = await Geolocator.getLastKnownPosition();
        if (pos == null && kIsWeb) {
          final errStr = e.toString().toLowerCase();
          if (errStr.contains('permission') || errStr.contains('denied')) {
            debugPrint('[GPSFlow] Web permission denied caught.');
            if (mounted) {
              _showLocationPermissionDialog();
            }
            return;
          }
        }
      }
      if (pos == null) throw Exception("Could not fetch location");
      final latLng = LatLng(pos.latitude, pos.longitude);
      await _onLocationPicked(latLng);
    } catch (e) {
      debugPrint('[GPSFlow] CRITICAL GPS EXCEPTION: $e');
      final fallback = const LatLng(12.9716, 77.5946);
      await _onLocationPicked(fallback);
    } finally {
      if (mounted) setState(() => _isFetchingLocation = false);
    }
  }

  int _locationStateVersion = 0;

  Future<void> _onLocationPicked(LatLng loc) async {
    setState(() {
      _selectedLocation = loc;
      _resolvedAddress = 'Fetching Address...';
      _selectedMandal = null;
      _selectedPanchayat = null;
      _selectedVillage = null;
      _wardNumberController.clear();
      _locationStateVersion++;
    });
    _saveDraftState();
    try {
      final placemarks = await placemarkFromCoordinates(loc.latitude, loc.longitude);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final parts = [p.subThoroughfare, p.thoroughfare, p.subLocality, p.locality].whereType<String>().where((s) => s.isNotEmpty).toList();
        
        String? matchedMandal;
        String? matchedPanchayat;
        String? matchedVillage;
        String? extractedWard;

        // Try extracting ward number from placemark text
        final fullText = '${p.subLocality} ${p.thoroughfare} ${p.name} ${p.locality}';
        final wardMatch = RegExp(r'(?:ward|w)[\s#-]*(\d+)', caseSensitive: false).firstMatch(fullText);
        if (wardMatch != null) {
          extractedWard = wardMatch.group(1);
        }

        final searchTerms = [
          p.locality,
          p.subLocality,
          p.thoroughfare,
          p.name,
          p.subAdministrativeArea,
          p.administrativeArea,
        ].whereType<String>().map((s) => s.toLowerCase().trim()).toList();

        debugPrint('[GeocodeFlow] Placemark details: Locality: ${p.locality}, SubLocality: ${p.subLocality}, AdminArea: ${p.administrativeArea}');

        for (final gp in MandalMapping.panchayatToVillages.keys) {
          final villagesInGp = MandalMapping.panchayatToVillages[gp] ?? [];
          for (final v in villagesInGp) {
            final cleanV = v.toLowerCase().replaceAll(RegExp(r'\s*(town|gp|village)\s*'), '').trim();
            if (cleanV.isNotEmpty && searchTerms.any((term) => term.contains(cleanV) || cleanV.contains(term))) {
              matchedVillage = v;
              matchedPanchayat = gp;
              matchedMandal = MandalMapping.getMandalForPanchayat(gp);
              break;
            }
          }
          if (matchedVillage != null) break;
        }

        if (matchedVillage == null) {
          for (final gp in MandalMapping.panchayatToVillages.keys) {
            final cleanGp = gp.toLowerCase().replaceAll(RegExp(r'\s*(gp|panchayat)\s*'), '').trim();
            if (cleanGp.isNotEmpty && searchTerms.any((term) => term.contains(cleanGp) || cleanGp.contains(term))) {
              matchedPanchayat = gp;
              matchedMandal = MandalMapping.getMandalForPanchayat(gp);
              final vList = MandalMapping.panchayatToVillages[gp] ?? [];
              if (vList.isNotEmpty) {
                matchedVillage = vList.first;
              }
              break;
            }
          }
        }

        if (matchedMandal == null) {
          for (final m in MandalMapping.mandals) {
            final cleanM = m.toLowerCase().trim();
            if (cleanM.isNotEmpty && searchTerms.any((term) => term.contains(cleanM) || cleanM.contains(term))) {
              matchedMandal = m;
              final gps = MandalMapping.getPanchayatsForMandal(m);
              if (gps.isNotEmpty) {
                matchedPanchayat = gps.first;
                final vList = MandalMapping.panchayatToVillages[matchedPanchayat] ?? [];
                if (vList.isNotEmpty) {
                  matchedVillage = vList.first;
                }
              }
              break;
            }
          }
        }

        if (matchedMandal == null || !MandalMapping.mandals.contains(matchedMandal)) {
          matchedMandal = 'Part-Rajahmundry Urban Mandal / RMC';
          matchedPanchayat = 'Part-Rajahmundry Urban Mandal / RMC GP';
          matchedVillage = 'Part-Rajahmundry Urban Mandal / RMC Town';
        }

        final validPanchayats = MandalMapping.getPanchayatsForMandal(matchedMandal, Provider.of<AppState>(context, listen: false).uniquePanchayats);
        if (matchedPanchayat == null || !validPanchayats.contains(matchedPanchayat)) {
          matchedPanchayat = validPanchayats.isNotEmpty ? validPanchayats.first : 'Part-Rajahmundry Urban Mandal / RMC GP';
        }

        final validVillages = MandalMapping.getVillagesForPanchayat(matchedPanchayat);
        if (matchedVillage == null || !validVillages.contains(matchedVillage)) {
          matchedVillage = validVillages.isNotEmpty ? validVillages.first : 'Part-Rajahmundry Urban Mandal / RMC Town';
        }

        setState(() {
          _resolvedAddress = parts.isNotEmpty ? parts.join(', ') : '${loc.latitude.toStringAsFixed(4)}, ${loc.longitude.toStringAsFixed(4)}';
          _selectedMandal = matchedMandal;
          _selectedPanchayat = matchedPanchayat;
          _selectedVillage = matchedVillage;
          if (extractedWard != null) {
            _wardNumberController.text = extractedWard;
          }
          _locationStateVersion++;
        });
        _saveDraftState();
        debugPrint('[GeocodeFlow] Matched location: Mandal: $_selectedMandal, Panchayat: $_selectedPanchayat, Village: $_selectedVillage');
      }
    } catch (e) {
      debugPrint('[GeocodeFlow] Geocode failed: $e');
      setState(() {
        _resolvedAddress = '${loc.latitude.toStringAsFixed(5)}, ${loc.longitude.toStringAsFixed(5)}';
        if (_selectedMandal == null) {
          _selectedMandal = 'Part-Rajahmundry Urban Mandal / RMC';
          _selectedPanchayat = 'Part-Rajahmundry Urban Mandal / RMC GP';
          _selectedVillage = 'Part-Rajahmundry Urban Mandal / RMC Town';
        }
        _locationStateVersion++;
      });
      _saveDraftState();
    }
  }

  Future<void> _pickMedia(ImageSource source, bool isVideo) async {
    if (_isSubmitting || _isSubmitted) return;
    debugPrint('[CameraFlow] _pickMedia called. Source: $source, IsVideo: $isVideo, kIsWeb: $kIsWeb');
    try {
      if (kIsWeb) {
        if (isVideo) {
          if (source == ImageSource.camera) {
            final bytes = await CameraHelper.pickVideoFromCamera();
            if (bytes != null) {
              final item = SelectedMedia(
                id: '${DateTime.now().microsecondsSinceEpoch}',
                bytes: bytes,
                isVideo: true,
              );
              setState(() {
                _selectedMediaList.add(item);
              });
              _saveDraftState();
              _uploadMediaItem(item);
            }
          } else {
            final pickedFiles = await CameraHelper.pickMultiVideosFromGallery();
            for (final file in pickedFiles) {
              final item = SelectedMedia(
                id: '${DateTime.now().microsecondsSinceEpoch}',
                bytes: file.bytes,
                isVideo: true,
              );
              setState(() {
                _selectedMediaList.add(item);
              });
              _saveDraftState();
              _uploadMediaItem(item);
              await Future.delayed(const Duration(milliseconds: 2));
            }
          }
        } else {
          if (source == ImageSource.camera) {
            final bytes = await CameraHelper.pickImageFromCamera();
            if (bytes != null) {
              final item = SelectedMedia(
                id: '${DateTime.now().microsecondsSinceEpoch}',
                bytes: bytes,
                isVideo: false,
              );
              setState(() {
                _selectedMediaList.add(item);
              });
              _saveDraftState();
              _uploadMediaItem(item);
            }
          } else {
            final pickedFiles = await CameraHelper.pickMultiImagesFromGallery();
            for (final file in pickedFiles) {
              final item = SelectedMedia(
                id: '${DateTime.now().microsecondsSinceEpoch}',
                bytes: file.bytes,
                isVideo: false,
              );
              setState(() {
                _selectedMediaList.add(item);
              });
              _saveDraftState();
              _uploadMediaItem(item);
              await Future.delayed(const Duration(milliseconds: 2));
            }
          }
        }
        return;
      }

      // Mobile native platform logic
      if (isVideo) {
        final picker = ImagePicker();
        final picked = await picker.pickVideo(source: source, maxDuration: const Duration(minutes: 2));
        if (picked == null) return;
        final bytes = await picked.readAsBytes();
        final item = SelectedMedia(
          id: '${DateTime.now().microsecondsSinceEpoch}',
          bytes: bytes,
          isVideo: true,
        );
        setState(() {
          _selectedMediaList.add(item);
        });
        _saveDraftState();
        _uploadMediaItem(item);
      } else {
        final picker = ImagePicker();
        if (source == ImageSource.gallery) {
          final List<XFile> pickedList = await picker.pickMultiImage(imageQuality: 75, maxWidth: 1200);
          if (pickedList.isNotEmpty) {
            for (final file in pickedList) {
              final bytes = await file.readAsBytes();
              final item = SelectedMedia(
                id: '${DateTime.now().microsecondsSinceEpoch}',
                bytes: bytes,
                isVideo: false,
              );
              setState(() {
                _selectedMediaList.add(item);
              });
              _saveDraftState();
              _uploadMediaItem(item);
              await Future.delayed(const Duration(milliseconds: 2));
            }
          }
        } else {
          final picked = await picker.pickImage(source: source, imageQuality: 75, maxWidth: 1200);
          if (picked == null) return;
          final bytes = await picked.readAsBytes();
          final item = SelectedMedia(
            id: '${DateTime.now().microsecondsSinceEpoch}',
            bytes: bytes,
            isVideo: false,
          );
          setState(() {
            _selectedMediaList.add(item);
          });
          _saveDraftState();
          _uploadMediaItem(item);
        }
      }
    } catch (e, stackTrace) {
      debugPrint('[CameraFlow] CRITICAL ERROR PICKING MEDIA: $e');
      debugPrint('[CameraFlow] StackTrace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to capture media: $e')),
        );
      }
    }
  }

  void _showImageSourceSheet() {
    if (_isSubmitting || _isSubmitted) return;
    final isTelugu = Provider.of<AppState>(context, listen: false).isTelugu;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isTelugu ? 'సాక్ష్యాల మీడియాను ఎంచుకోండి' : 'Choose Evidence Media',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(isTelugu ? 'ఫోటో' : 'PHOTO', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 8),
                      IconButton.filledTonal(icon: const Icon(Icons.camera_alt), onPressed: () { Navigator.pop(ctx); _pickMedia(ImageSource.camera, false); }),
                      Text(isTelugu ? 'కెమెరా' : 'Camera'),
                      const SizedBox(height: 8),
                      IconButton.filledTonal(icon: const Icon(Icons.photo_library), onPressed: () { Navigator.pop(ctx); _pickMedia(ImageSource.gallery, false); }),
                      Text(isTelugu ? 'గ్యాలరీ' : 'Gallery'),
                    ],
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(isTelugu ? 'వీడియో' : 'VIDEO', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 8),
                      IconButton.filledTonal(icon: const Icon(Icons.videocam), onPressed: () { Navigator.pop(ctx); _pickMedia(ImageSource.camera, true); }),
                      Text(isTelugu ? 'కెమెరా' : 'Camera'),
                      const SizedBox(height: 8),
                      IconButton.filledTonal(icon: const Icon(Icons.video_library), onPressed: () { Navigator.pop(ctx); _pickMedia(ImageSource.gallery, true); }),
                      Text(isTelugu ? 'గ్యాలరీ' : 'Gallery'),
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
    if (_isSubmitting || _isSubmitted) return;
    final isTelugu = Provider.of<AppState>(context, listen: false).isTelugu;
    final resultText = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => _VoiceDictationSheet(isTeluguInitially: isTelugu),
    );

    if (resultText != null && resultText.trim().isNotEmpty) {
      setState(() {
        _descriptionController.text += _descriptionController.text.isNotEmpty ? ' $resultText' : resultText;
      });
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting || _isSubmitted) return;
    final isTelugu = Provider.of<AppState>(context, listen: false).isTelugu;
    if (!_formKey.currentState!.validate()) return;
    if (_selectedMediaList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isTelugu ? 'దయచేసి కనీసం ఒక చిత్రం లేదా వీడియోను ఎంచుకోండి.' : 'Please select at least one image or video.')),
      );
      return;
    }
    if (_selectedLocation == null || _selectedCategoryKey == null || _selectedVillage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isTelugu ? 'దయచేసి అనివార్యమైన వివరాలన్నీ పూర్తి చేయండి.' : 'Please complete all mandatory fields.')),
      );
      return;
    }

    // Check if any media items are still uploading or failed
    final bool anyUploading = _selectedMediaList.any((m) => m.isUploading);
    if (anyUploading) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isTelugu ? 'దయచేసి మీడియా ఫైళ్లు పూర్తి అప్‌లోడ్ అయ్యే వరకు వేచి చూడండి.' : 'Please wait for all media files to finish uploading.')),
      );
      return;
    }

    final bool anyErrors = _selectedMediaList.any((m) => m.hasError);
    if (anyErrors) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please retry or remove failed media uploads.')));
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final appState = Provider.of<AppState>(context, listen: false);
    final wId = 'ward_${_wardNumberController.text.trim()}';
    final wName = 'Ward ${_wardNumberController.text.trim()} - $_selectedVillage';

    final List<String> imageUrls = _selectedMediaList.where((m) => !m.isVideo && m.remoteUrl != null).map((m) => m.remoteUrl!).toList();
    final List<String> videoUrls = _selectedMediaList.where((m) => m.isVideo && m.remoteUrl != null).map((m) => m.remoteUrl!).toList();
    
    try {
      await appState.submitComplaint(
        category: _selectedCategoryKey!,
        description: _descriptionController.text.trim(),
        latitude: _selectedLocation!.latitude,
        longitude: _selectedLocation!.longitude,
        address: _resolvedAddress,
        preUploadedImageUrls: imageUrls,
        preUploadedVideoUrls: videoUrls,
        complaintId: _currentComplaintId,
        wardId: wId,
        wardName: wName,
        villageName: _selectedVillage!,
        mandalName: _selectedMandal!,
      );
      if (mounted) {
        await _resetForm();
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Submission failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    widget.onSubmissionSuccess();
                  },
                  child: const Text('Track Complaints'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                  },
                  child: const Text('File Another'),
                ),
              ],
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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (_currentStep > 0) {
          setState(() {
            _currentStep -= 1;
          });
        } else {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          } else if (widget.onBackPressed != null) {
            widget.onBackPressed!();
          }
        }
      },
      child: Scaffold(
        backgroundColor: activeParty.backgroundColor,
        appBar: AppBar(
          title: Text(Provider.of<AppState>(context).isTelugu ? 'ఫిర్యాదు నమోదు' : 'File Complaint', style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Colors.black87),
          elevation: 1,
          leading: (widget.onBackPressed != null || Navigator.canPop(context) || _currentStep > 0)
              ? IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black87),
                  onPressed: () {
                    if (_currentStep > 0) {
                      setState(() {
                        _currentStep -= 1;
                      });
                    } else {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      } else if (widget.onBackPressed != null) {
                        widget.onBackPressed!();
                      }
                    }
                  },
                )
              : null,
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: (_isSubmitting || _isSubmitted) ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF22C55E),
                    disabledBackgroundColor: const Color(0xFF22C55E).withOpacity(0.5),
                    disabledForegroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSubmitted
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check, color: Colors.white),
                          SizedBox(width: 8),
                          Text('Complaint Submitted', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      )
                    : _isSubmitting
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                      : const Text('Submit Complaint', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
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
              if (_currentStep == 2 && _selectedMediaList.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select at least one image or video.')));
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
                  splashColor: categoryColor.withOpacity(0.1),
                  highlightColor: categoryColor.withOpacity(0.05),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? categoryColor.withOpacity(0.05) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? categoryColor : Colors.transparent,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isSelected ? categoryColor.withOpacity(0.2) : Colors.black.withOpacity(0.04),
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

    // Validate selectedMandal against mandals
    String? currentMandal = _selectedMandal;
    if (currentMandal != null && !mandals.contains(currentMandal)) {
      currentMandal = mandals.contains('Part-Rajahmundry Urban Mandal / RMC') ? 'Part-Rajahmundry Urban Mandal / RMC' : mandals.first;
    }

    // Get panchayats for currentMandal
    List<String> panchayats = currentMandal != null 
        ? MandalMapping.getPanchayatsForMandal(currentMandal, Provider.of<AppState>(context, listen: false).uniquePanchayats) 
        : [];

    String? currentPanchayat = _selectedPanchayat;
    if (currentPanchayat != null && !panchayats.contains(currentPanchayat)) {
      currentPanchayat = panchayats.isNotEmpty ? panchayats.first : null;
    }

    // Get villages for currentPanchayat
    List<String> villages = currentPanchayat != null 
        ? MandalMapping.getVillagesForPanchayat(currentPanchayat) 
        : [];

    String? currentVillage = _selectedVillage;
    if (currentVillage != null && !villages.contains(currentVillage)) {
      currentVillage = villages.isNotEmpty ? villages.first : null;
    }

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
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 6))],
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
            label: const Text('Use My Location (GPS)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              minimumSize: const Size(double.infinity, 48),
              elevation: 0,
            ),
          ),
          
          if (_selectedLocation != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: Color(0xFF3B82F6), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Selected Location Coordinates:\nLatitude: ${_selectedLocation!.latitude.toStringAsFixed(6)}, Longitude: ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E3A8A)),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 24),
          const Text('Location Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 12),
          
          DropdownButtonFormField<String>(
            key: ValueKey('mandal_${currentMandal ?? 'none'}_$_locationStateVersion'),
            decoration: InputDecoration(
              labelText: 'Mandal', 
              filled: true, 
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
            ),
            value: currentMandal,
            items: mandals.map((m) => DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(fontSize: 13)))).toList(),
            onChanged: (val) {
              setState(() { 
                _selectedMandal = val; 
                _selectedPanchayat = null; 
                _selectedVillage = null; 
                _locationStateVersion++;
              });
              _saveDraftState();
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            key: ValueKey('panchayat_${currentPanchayat ?? 'none'}_$_locationStateVersion'),
            decoration: InputDecoration(
              labelText: 'Panchayat', 
              filled: true, 
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
            ),
            value: currentPanchayat,
            items: panchayats.map((p) => DropdownMenuItem(value: p, child: Text(p, style: const TextStyle(fontSize: 13)))).toList(),
            onChanged: currentMandal == null ? null : (val) {
              setState(() { 
                _selectedPanchayat = val; 
                _selectedVillage = null; 
                _locationStateVersion++;
              });
              _saveDraftState();
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            key: ValueKey('village_${currentVillage ?? 'none'}_$_locationStateVersion'),
            decoration: InputDecoration(
              labelText: 'Village', 
              filled: true, 
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
            ),
            value: currentVillage,
            items: villages.map((v) => DropdownMenuItem(value: v, child: Text(v, style: const TextStyle(fontSize: 13)))).toList(),
            onChanged: currentPanchayat == null ? null : (val) {
              setState(() { 
                _selectedVillage = val; 
                _locationStateVersion++;
              });
              _saveDraftState();
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _wardNumberController,
            keyboardType: TextInputType.number,
            onChanged: (_) => _saveDraftState(),
            decoration: InputDecoration(
              labelText: 'Ward Number', 
              filled: true, 
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
            ),
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
                          color: const Color(0xFFEAB308).withOpacity(0.3 + (_pulseController.value * 0.2)),
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
          const Text('Evidence Media (Photos & Videos)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              GestureDetector(
                onTap: _showImageSourceSheet,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo_outlined, color: Colors.grey, size: 28),
                      SizedBox(height: 4),
                      Text('Add Media', style: TextStyle(color: Colors.grey, fontSize: 11)),
                    ],
                  ),
                ),
              ),
              ...List.generate(_selectedMediaList.length, (index) {
                final item = _selectedMediaList[index];
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 100,
                        height: 100,
                        color: item.isVideo ? Colors.black87 : Colors.grey.shade100,
                        child: item.isVideo
                            ? const Center(child: Icon(Icons.play_circle_fill, color: Colors.white, size: 36))
                            : Image.memory(
                                item.bytes,
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, err, st) => const Icon(Icons.broken_image, color: Colors.red),
                              ),
                      ),
                    ),
                    if (item.isUploading)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black54,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${(item.uploadProgress * 100).toStringAsFixed(0)}%',
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    if (item.hasError)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black54,
                          child: Center(
                            child: IconButton(
                              icon: const Icon(Icons.refresh, color: Colors.white, size: 32),
                              onPressed: () => _uploadMediaItem(item),
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedMediaList.removeAt(index);
                          });
                          _saveDraftState();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                    if (!item.isUploading && !item.hasError && !item.isVideo)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => FullScreenImageViewer(imageBytes: item.bytes, tag: 'img_${item.id}'),
                              ),
                            );
                          },
                          child: Container(
                            color: Colors.black38,
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: const Text(
                              'Preview',
                              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              }),
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
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 6))],
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
                if (_selectedMediaList.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 32),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _selectedMediaList.map((item) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            width: 60,
                            height: 60,
                            child: item.isVideo
                                ? Container(
                                    color: Colors.black87,
                                    child: const Icon(Icons.videocam, color: Colors.white),
                                  )
                                : Image.memory(item.bytes, fit: BoxFit.cover),
                          ),
                        );
                      }).toList(),
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

enum DictationState { idle, requestingPermission, permissionDenied, recording, processing, completed, error }

class _VoiceDictationSheet extends StatefulWidget {
  final bool isTeluguInitially;
  const _VoiceDictationSheet({required this.isTeluguInitially});

  @override
  State<_VoiceDictationSheet> createState() => _VoiceDictationSheetState();
}

class _VoiceDictationSheetState extends State<_VoiceDictationSheet> with SingleTickerProviderStateMixin {
  final AudioRecorder _audioRecorder = AudioRecorder();
  late TextEditingController _transcriptController;
  late AnimationController _pulseAnimController;

  DictationState _state = DictationState.idle;
  String _selectedLocaleId = 'te_IN';
  String _errorMessage = '';

  Timer? _timer;
  int _secondsElapsed = 0;
  bool _isActionInProgress = false;
  DateTime? _recordingStartTime;   // Used to enforce minimum recording duration

  @override
  void initState() {
    super.initState();
    _transcriptController = TextEditingController();
    _selectedLocaleId = widget.isTeluguInitially ? 'te_IN' : 'en_IN';

    _pulseAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _checkInitialPermission();
  }

  Future<void> _checkInitialPermission() async {
    try {
      final hasPerm = await _audioRecorder.hasPermission();
      if (mounted) {
        setState(() {
          if (!hasPerm) {
            _state = DictationState.idle;
          }
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseAnimController.dispose();
    _transcriptController.dispose();
    _stopAndDisposeRecorder();
    super.dispose();
  }

  Future<void> _stopAndDisposeRecorder() async {
    try {
      if (await _audioRecorder.isRecording()) {
        await _audioRecorder.stop();
      }
    } catch (_) {}
    _audioRecorder.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _secondsElapsed = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _state == DictationState.recording) {
        setState(() => _secondsElapsed++);
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
  }

  String get _formattedTime {
    final mins = (_secondsElapsed ~/ 60).toString().padLeft(2, '0');
    final secs = (_secondsElapsed % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  Future<void> _startRecording() async {
    if (_isActionInProgress) return;
    if (_state == DictationState.recording || _state == DictationState.processing) return;
    _isActionInProgress = true;

    try {
      if (await _audioRecorder.isRecording()) {
        await _audioRecorder.stop();
      }

      final bool hasPermission = await _audioRecorder.hasPermission();
      if (!hasPermission) {
        if (mounted) {
          _stopTimer();
          setState(() {
            _state = DictationState.permissionDenied;
            _errorMessage = widget.isTeluguInitially
                ? 'మైక్రోఫోన్ అనుమతి అవసరం. దయచేసి మీ బ్రౌజర్ లేదా పరికర సెట్టింగ్‌లలో మైక్రోఫోన్ యాక్సెస్‌ను అనుమతించండి.'
                : 'Microphone permission is required. Please allow microphone access in your browser or device settings.';
          });
        }
        return;
      }

      const config = RecordConfig(
        encoder: kIsWeb ? AudioEncoder.opus : AudioEncoder.aacLc,
        sampleRate: 48000,
        numChannels: 1,
        bitRate: 128000,
      );

      await _audioRecorder.start(config, path: '');
      debugPrint('[VoiceSTT] Recording started');

      // Allow 300ms for the browser mic to warm up before we start the timer.
      // This prevents the first 300ms of silence from being included in the
      // audio data that Whisper receives.
      await Future.delayed(const Duration(milliseconds: 300));

      // Record the start time AFTER warmup — used to enforce minimum duration
      _recordingStartTime = DateTime.now();

      if (mounted) {
        setState(() {
          _errorMessage = '';
          _state = DictationState.recording;
        });
        _startTimer();
      }
    } catch (e) {
      debugPrint('[VoiceSTT] ERROR: Start audio recorder error: $e');
      if (mounted) {
        _stopTimer();
        setState(() {
          _state = DictationState.permissionDenied;
          _errorMessage = widget.isTeluguInitially
              ? 'మైక్రోఫోన్ ప్రారంభించడంలో విఫలమైంది. దయచేసి మళ్ళీ ప్రయత్నించండి.'
              : 'Failed to access microphone. Please try again.';
        });
      }
    } finally {
      _isActionInProgress = false;
    }
  }

  Future<void> _stopRecording() async {
    if (_isActionInProgress) return;
    _isActionInProgress = true;
    _stopTimer();

    // ── Minimum 2-second recording guard ─────────────────────────────────────
    // Whisper needs at least 2 seconds of real speech to produce a meaningful
    // transcript. If the user stops too quickly, show a helpful message instead
    // of sending garbage audio that causes the server to return an error.
    final elapsed = _recordingStartTime == null
        ? 0
        : DateTime.now().difference(_recordingStartTime!).inMilliseconds;

    if (elapsed < 2000) {
      debugPrint('[VoiceSTT] Recording stopped too early (${elapsed}ms). Minimum is 2000ms.');
      try {
        if (await _audioRecorder.isRecording()) await _audioRecorder.stop();
      } catch (_) {}
      if (mounted) {
        setState(() {
          _state = DictationState.error;
          _errorMessage = widget.isTeluguInitially
              ? 'చాలా తక్కువ సమయం మాట్లాడారు. దయచేసి 🔴 బటన్ నొక్కి కనీసం 2 సెకన్లు మాట్లాడండి.'
              : 'Too short! Tap 🔴 and speak for at least 2 seconds.';
        });
      }
      _isActionInProgress = false;
      return;
    }

    if (mounted) {
      setState(() {
        _state = DictationState.processing;
        _errorMessage = '';
      });
    }

    try {
      final String? path = await _audioRecorder.stop();
      debugPrint('[VoiceSTT] Recording stopped');
      if (path == null || path.isEmpty) {
        if (mounted) {
          setState(() {
            _state = DictationState.error;
            _errorMessage = widget.isTeluguInitially
                ? 'మాట్లాడటం ఏదీ గుర్తించబడలేదు. దయచేసి స్పష్టంగా మాట్లాడండి.'
                : 'No speech recognized. Please speak clearly into the mic and try again.';
          });
        }
        return;
      }

      Uint8List audioBytes = Uint8List(0);
      String fileName = 'recording.webm';

      if (kIsWeb) {
        try {
          final res = await http.get(Uri.parse(path));
          audioBytes = res.bodyBytes;
        } catch (e) {
          debugPrint('[VoiceSTT] ERROR: http.get blob error: $e');
        }
        fileName = 'recording.webm';
      } else {
        final file = File(path);
        audioBytes = await file.readAsBytes();
        fileName = path.split('/').last;
      }

      debugPrint('[VoiceSTT] Audio bytes: ${audioBytes.length}');
      debugPrint('[VoiceSTT] MIME: audio/webm');

      if (audioBytes.length < 1200) {
        debugPrint('[VoiceSTT] ERROR: Audio bytes < 1200 (silent/too short: ${audioBytes.length} bytes)');
        if (mounted) {
          setState(() {
            _state = DictationState.error;
            _errorMessage = widget.isTeluguInitially
                ? 'రికార్డింగ్ చాలా తక్కువగా ఉంది. దయచేసి మైక్ నొక్కి కనీసం 2 సెకన్ల పాటు స్పష్టంగా మాట్లాడండి.'
                : 'Recording was too short. Please tap the mic and speak clearly for at least 2 seconds.';
          });
        }
        return;
      }

      final String modeName = _selectedLocaleId == 'auto'
          ? 'Auto Detect'
          : (_selectedLocaleId == 'te_IN' ? 'Telugu' : 'English');
      final String langCode = _selectedLocaleId == 'auto'
          ? 'auto'
          : (_selectedLocaleId == 'te_IN' ? 'te' : 'en');

      debugPrint('[VoiceSTT] Selected mode: $modeName');
      debugPrint('[VoiceSTT] Language sent: $langCode');

      final whisperResult = await WhisperService.transcribeAudio(
        audioBytes: audioBytes,
        language: langCode,
      );

      if (mounted) {
        if (whisperResult['success'] == true) {
          final String text = (whisperResult['text'] ?? '').toString().trim();
          setState(() {
            if (text.isNotEmpty) {
              _transcriptController.text = text;
              _transcriptController.selection = TextSelection.fromPosition(
                TextPosition(offset: text.length),
              );
              _state = DictationState.completed;
            } else {
              _state = DictationState.error;
              _errorMessage = widget.isTeluguInitially
                  ? 'మాట్లాడటం ఏదీ గుర్తించబడలేదు. దయచేసి మైక్ నొక్కి స్పష్టంగా మాట్లాడండి.'
                  : 'No speech recognized. Please speak clearly into the mic and try again.';
            }
          });
        } else {
          // Map server-internal error messages to user-friendly text
          final String rawErr = (whisperResult['error'] ?? '').toString();
          final bool isTelugu = widget.isTeluguInitially;
          String friendlyError;

          if (rawErr.contains('unreachable') || rawErr.contains('OPENAI_API_KEY') || rawErr.contains('server')) {
            // Server connectivity error
            friendlyError = isTelugu
                ? 'వాయిస్ సర్వర్ అందుబాటులో లేదు. దయచేసి Wi-Fi తనిఖీ చేసి మళ్ళీ ప్రయత్నించండి.'
                : 'Voice server is temporarily unavailable. Please check your connection and try again.';
          } else if (rawErr.contains('recognized') || rawErr.contains('speak') || rawErr.contains('Muted') || rawErr.contains('muted')) {
            // No speech / silent audio
            friendlyError = isTelugu
                ? 'మాట్లాడటం వినిపించలేదు. దయచేసి మైక్ నొక్కి స్పష్టంగా మాట్లాడండి.'
                : 'No speech detected. Please tap mic and speak clearly.';
          } else if (rawErr.contains('too large') || rawErr.contains('413')) {
            friendlyError = isTelugu
                ? 'ఆడియో ఫైల్ చాలా పెద్దది. దయచేసి తక్కువ సేపు మాట్లాడండి.'
                : 'Audio too large. Please record a shorter clip.';
          } else if (rawErr.isNotEmpty) {
            // Pass through any other specific message from the server
            friendlyError = rawErr;
          } else {
            friendlyError = isTelugu
                ? 'వాయిస్ రికగ్నిషన్ లభ్యం కాలేదు. దయచేసి మళ్ళీ ప్రయత్నించండి.'
                : 'Speech transcription failed. Please try again.';
          }

          setState(() {
            _state = DictationState.error;
            _errorMessage = friendlyError;
          });
        }
      }
    } catch (e) {
      debugPrint('[VoiceDictation] Transcribe exception: $e');
      if (mounted) {
        setState(() {
          _state = DictationState.error;
          _errorMessage = widget.isTeluguInitially
              ? 'వాయిస్ ప్రాసెసింగ్ నెట్‌వర్క్ లోపం. దయచేసి మళ్ళీ ప్రయత్నించండి.'
              : 'Speech network connection issue. Please try again.';
        });
      }
    } finally {
      _isActionInProgress = false;
    }
  }

  Future<void> _recordAgain() async {
    if (_isActionInProgress) return;
    _stopTimer();
    try {
      if (await _audioRecorder.isRecording()) {
        await _audioRecorder.stop();
      }
    } catch (_) {}

    setState(() {
      _secondsElapsed = 0;
      _errorMessage = '';
      _transcriptController.clear();
      _state = DictationState.idle;
    });

    await _startRecording();
  }

  void _clearTranscript() {
    if (_isActionInProgress) return;
    _stopTimer();
    try {
      _audioRecorder.isRecording().then((recording) {
        if (recording) _audioRecorder.stop();
      });
    } catch (_) {}

    setState(() {
      _transcriptController.clear();
      _errorMessage = '';
      _secondsElapsed = 0;
      _state = DictationState.idle;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isTeluguUI = widget.isTeluguInitially;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 20,
        left: 20,
        right: 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.mic, color: Color(0xFF3B82F6), size: 22),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      isTeluguUI ? 'వాయిస్ డిక్టేషన్' : 'Voice Dictation',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () {
                    _stopTimer();
                    try {
                      _audioRecorder.isRecording().then((rec) {
                        if (rec) _audioRecorder.stop();
                      });
                    } catch (_) {}
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Language Switcher Toggle (Telugu / English / Auto Detect)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: (_state == DictationState.recording || _state == DictationState.processing)
                          ? null
                          : () {
                              if (_selectedLocaleId != 'te_IN') {
                                setState(() => _selectedLocaleId = 'te_IN');
                              }
                            },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _selectedLocaleId == 'te_IN' ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: _selectedLocaleId == 'te_IN'
                              ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)]
                              : [],
                        ),
                        child: Text(
                          'తెలుగు (Telugu)',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            color: _selectedLocaleId == 'te_IN' ? const Color(0xFF3B82F6) : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: (_state == DictationState.recording || _state == DictationState.processing)
                          ? null
                          : () {
                              if (_selectedLocaleId != 'en_IN') {
                                setState(() => _selectedLocaleId = 'en_IN');
                              }
                            },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _selectedLocaleId == 'en_IN' ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: _selectedLocaleId == 'en_IN'
                              ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)]
                              : [],
                        ),
                        child: Text(
                          'English',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            color: _selectedLocaleId == 'en_IN' ? const Color(0xFF3B82F6) : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: (_state == DictationState.recording || _state == DictationState.processing)
                          ? null
                          : () {
                              if (_selectedLocaleId != 'auto') {
                                setState(() => _selectedLocaleId = 'auto');
                              }
                            },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _selectedLocaleId == 'auto' ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: _selectedLocaleId == 'auto'
                              ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)]
                              : [],
                        ),
                        child: Text(
                          isTeluguUI ? 'ఆటో గుర్తింపు' : 'Auto Detect',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            color: _selectedLocaleId == 'auto' ? const Color(0xFF3B82F6) : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Mic Animation & Status Banner
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (_state == DictationState.recording) {
                        _stopRecording();
                      } else if (_state == DictationState.processing) {
                        // Ignore tap while processing
                      } else {
                        _startRecording();
                      }
                    },
                    child: AnimatedBuilder(
                      animation: _pulseAnimController,
                      builder: (context, child) {
                        final isRecording = _state == DictationState.recording;
                        final isProcessing = _state == DictationState.processing;
                        final scale = isRecording ? (1.0 + (_pulseAnimController.value * 0.15)) : 1.0;
                        return Transform.scale(
                          scale: scale,
                          child: Container(
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(
                              color: isRecording 
                                  ? const Color(0xFFEF4444) 
                                  : (isProcessing ? const Color(0xFFF59E0B) : const Color(0xFF3B82F6)),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: (isRecording 
                                          ? const Color(0xFFEF4444) 
                                          : (isProcessing ? const Color(0xFFF59E0B) : const Color(0xFF3B82F6)))
                                      .withOpacity(0.35),
                                  blurRadius: isRecording ? 20 : 10,
                                  spreadRadius: isRecording ? 6 : 2,
                                )
                              ],
                            ),
                            child: isProcessing
                                ? const Padding(
                                    padding: EdgeInsets.all(24.0),
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                                  )
                                : Icon(
                                    isRecording ? Icons.stop : Icons.mic,
                                    color: Colors.white,
                                    size: 42,
                                  ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Status Text & Actions
                  if (_state == DictationState.recording) ...[
                    Text(
                      _formattedTime,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFEF4444),
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _stopRecording,
                      icon: const Icon(Icons.stop, color: Colors.white, size: 18),
                      label: Text(
                        isTeluguUI ? 'ఆపు & పంపు' : 'Stop & Transcribe',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isTeluguUI ? 'వింటున్నాము... మాట్లాడటం పూర్తి చేశాక "ఆపు" నొక్కండి' : 'Listening... Tap Stop when finished speaking',
                      style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ] else if (_state == DictationState.processing) ...[
                    Text(
                      isTeluguUI ? 'AI వాయిస్ ప్రాసెసింగ్ జరుగుతోంది...' : 'Processing speech with AI...',
                      style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 13, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ] else if (_state == DictationState.permissionDenied || _state == DictationState.error) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          Text(
                            _errorMessage.isNotEmpty 
                                ? _errorMessage 
                                : (isTeluguUI ? 'మైక్రోఫోన్ లేదా నెట్‌వర్క్ లోపం' : 'Microphone or Network Error'),
                            style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w600),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            onPressed: _startRecording,
                            icon: const Icon(Icons.mic, color: Color(0xFF3B82F6), size: 18),
                            label: Text(
                              isTeluguUI ? 'మైక్రోఫోన్ అనుమతించు (Allow Mic)' : 'Allow Microphone Permission',
                              style: const TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF3B82F6)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else if (_state == DictationState.completed) ...[
                    Text(
                      isTeluguUI ? 'వాయిస్ రికగ్నిషన్ విజయవంతమైంది!' : 'Speech transcribed successfully!',
                      style: const TextStyle(color: Colors.green, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ] else ...[
                    Text(
                      isTeluguUI ? 'మాట్లాడేందుకు మైక్రోఫోన్ నొక్కండి' : 'Tap microphone to start speaking',
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Live Editable Transcript Field
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _transcriptController,
              builder: (context, value, child) {
                return TextFormField(
                  controller: _transcriptController,
                  enabled: _state != DictationState.processing,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: isTeluguUI ? 'మీ వివరణ ఇక్కడ కనిపించును...' : 'Recognized speech will appear here...',
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // Controls Row (Record Again, Clear, Confirm)
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _transcriptController,
              builder: (context, value, child) {
                final hasText = value.text.trim().isNotEmpty;
                final canConfirm = hasText && _state != DictationState.processing && _state != DictationState.recording;

                return Row(
                  children: [
                    // Retry Button
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: (_state == DictationState.processing || _state == DictationState.recording)
                            ? null
                            : _recordAgain,
                        icon: const Icon(Icons.refresh, size: 18),
                        label: Text(isTeluguUI ? 'మళ్ళీ' : 'Retry'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF0F172A),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Clear Button
                    OutlinedButton(
                      onPressed: (_state == DictationState.processing || _state == DictationState.recording)
                          ? null
                          : _clearTranscript,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade700,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Icon(Icons.delete_outline, size: 20),
                    ),
                    const SizedBox(width: 8),
                    // Confirm & Add Button
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: canConfirm
                            ? () {
                                _stopTimer();
                                try {
                                  _audioRecorder.isRecording().then((rec) {
                                    if (rec) _audioRecorder.stop();
                                  });
                                } catch (_) {}
                                Navigator.pop(context, _transcriptController.text.trim());
                              }
                            : null,
                        icon: const Icon(Icons.check, color: Colors.white, size: 18),
                        label: Text(
                          isTeluguUI ? 'వివరణ జోడించు' : 'Confirm & Add',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          disabledBackgroundColor: Colors.grey.shade300,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class FullScreenImageViewer extends StatefulWidget {
  final Uint8List imageBytes;
  final String tag;
  const FullScreenImageViewer({super.key, required this.imageBytes, this.tag = 'complaint_image_preview'});

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  final TransformationController _transformationController = TransformationController();
  TapDownDetails? _doubleTapDetails;

  void _handleDoubleTap() {
    if (_transformationController.value != Matrix4.identity()) {
      _transformationController.value = Matrix4.identity();
    } else {
      final position = _doubleTapDetails!.localPosition;
      _transformationController.value = Matrix4.identity()
        ..translate(-position.dx * 2.0, -position.dy * 2.0)
        ..scale(3.0);
    }
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onVerticalDragUpdate: (details) {
          if (details.delta.dy > 8) {
            Navigator.pop(context);
          }
        },
        child: Stack(
          children: [
            Center(
              child: GestureDetector(
                onDoubleTapDown: (details) => _doubleTapDetails = details,
                onDoubleTap: _handleDoubleTap,
                child: InteractiveViewer(
                  transformationController: _transformationController,
                  panEnabled: true,
                  boundaryMargin: const EdgeInsets.all(20),
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Hero(
                    tag: widget.tag,
                    child: Image.memory(
                      widget.imageBytes,
                      fit: BoxFit.contain,
                      errorBuilder: (ctx, err, st) => const Icon(Icons.broken_image, color: Colors.white, size: 64),
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
