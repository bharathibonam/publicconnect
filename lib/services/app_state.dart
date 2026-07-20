import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:hive/hive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../models/user.dart';
import '../models/complaint.dart';
import '../models/ward.dart';
import '../models/app_notification.dart';
import '../models/broadcast_alert.dart';
import '../models/announcement.dart';
import '../models/announcement_read.dart';
import '../models/work_update.dart';
import '../models/completed_work.dart';
import '../models/app_config.dart';
import '../utils/category_mapping.dart';
import '../utils/mandal_mapping.dart';
import 'supabase_service.dart';

enum ConnectionStatus { checking, connected, offline }

class AppState extends ChangeNotifier {
  // ─── Connection & Caching ───────────────────────────────────────────────────
  ConnectionStatus _connectionStatus = ConnectionStatus.checking;
  ConnectionStatus get connectionStatus => _connectionStatus;
  bool get isSupabaseConnected =>
      _connectionStatus == ConnectionStatus.connected;

  final StreamController<ConnectionStatus> _connectionStatusController =
      StreamController<ConnectionStatus>.broadcast();
  Stream<ConnectionStatus> get connectionStatusStream =>
      _connectionStatusController.stream;

  final StreamController<Map<String, String>> _pushNotificationController =
      StreamController<Map<String, String>>.broadcast();
  Stream<Map<String, String>> get pushNotificationStream =>
      _pushNotificationController.stream;

  void triggerInAppPushNotification({
    required String title,
    required String body,
  }) {
    _pushNotificationController.add({'title': title, 'body': body});
  }

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  // ─── Bilingual Translation State ────────────────────────────────────────────
  bool _isTelugu = false;
  bool get isTelugu => _isTelugu;

  // ─── Work Updates ───────────────────────────────────────────────────────────
  List<WorkUpdate> _workUpdates = [];
  List<WorkUpdate> get workUpdates => _workUpdates;

  List<CompletedWork> _completedWorks = [];
  List<CompletedWork> get completedWorks => _completedWorks;
  int? _requestedCitizenTabIndex;
  int? get requestedCitizenTabIndex => _requestedCitizenTabIndex;

  void setCitizenTabIndex(int index) {
    _requestedCitizenTabIndex = index;
    notifyListeners();
  }

  String? _highlightedComplaintId;
  String? get highlightedComplaintId => _highlightedComplaintId;

  void setHighlightedComplaintId(String? id) {
    _highlightedComplaintId = id;
    notifyListeners();
  }

  void clearCitizenTabIndex() {
    if (_requestedCitizenTabIndex != null) {
      _requestedCitizenTabIndex = null;
      notifyListeners();
    }
  }

  // ─── Live Data ──────────────────────────────────────────────────────────────
  List<Ward> _wards = [];
  List<User> _users = [];
  List<Complaint> _complaints = [];
  List<AppNotification> _notifications = [];
  List<BroadcastAlert> _broadcasts = [];
  List<Announcement> _announcements = [];
  AppConfig? _appConfig;

  User? _currentUser;

  List<Ward> get wards => List.unmodifiable(_wards);

  List<String> get uniquePanchayats {
    final set = <String>{};
    for (var w in _wards) {
      final parts = w.name.split(' - ');
      if (parts.length > 1) {
        set.add(parts[1].trim());
      }
    }
    final list = set.toList();
    list.sort();
    return list;
  }

  List<User> get users => List.unmodifiable(_users);
  List<Complaint> get complaints => List.unmodifiable(_complaints);
  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  List<BroadcastAlert> get broadcasts {
    final now = DateTime.now();
    final active = _broadcasts
        .where((b) => now.difference(b.createdAt).inHours < 48)
        .toList();
    active.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(active);
  }

  List<Announcement> get announcements => List.unmodifiable(_announcements);

  List<Announcement> getVisibleAnnouncements() {
    if (_currentUser == null) return [];

    final user = _currentUser!;
    final List<Announcement> visible = [];

    // Pre-calculate user's announcement IDs from notifications to guarantee visibility
    final userNotifAnnouncementIds = _notifications
        .where((n) => n.isAnnouncementNotification && n.announcementId != null)
        .map((n) => n.announcementId!)
        .toSet();

    debugPrint('====================================================');
    debugPrint('DEBUG: getVisibleAnnouncements() called');
    debugPrint('DEBUG: Total notifications for user: ${_notifications.length}');
    debugPrint('DEBUG: Total announcements loaded: ${_announcements.length}');
    debugPrint('DEBUG: userNotifAnnouncementIds: $userNotifAnnouncementIds');
    debugPrint('====================================================');

    // Derive user's panchayat from their village, if applicable
    String? userPanchayat;
    if (user.villageName != null && user.villageName!.isNotEmpty) {
      for (final entry in MandalMapping.panchayatToVillages.entries) {
        if (entry.value.any(
          (v) =>
              v.trim().toLowerCase() == user.villageName!.trim().toLowerCase(),
        )) {
          userPanchayat = entry.key;
          break;
        }
      }
    }

    for (var a in _announcements) {
      debugPrint('DEBUG: Evaluating announcement: ${a.id} - ${a.title}');

      // If user has a direct notification for this announcement, it's visible.
      if (userNotifAnnouncementIds.contains(a.id)) {
        debugPrint('DEBUG: -> Matched via notification.announcement_id');
        visible.add(a);
        continue;
      }

      // If user is the creator, they can see it regardless of audience
      if (a.createdById == user.id) {
        visible.add(a);
        continue;
      }

      bool audienceMatch = false;
      if (a.targetAudience == 'All Users') {
        audienceMatch = true;
      } else if (user.role == UserRole.wardAdmin &&
          a.targetAudience == 'wardAdmin') {
        audienceMatch = true;
      } else if (user.role == UserRole.categoryOfficer &&
          a.targetAudience == 'categoryOfficer') {
        audienceMatch = true;
      } else if (user.role == UserRole.mandalOfficer &&
          a.targetAudience == 'mandalOfficer') {
        audienceMatch = true;
      } else if (user.role == UserRole.superAdmin) {
        audienceMatch = true; // Super admin sees everything
      }

      // ─── STRICT CITIZEN REQUIREMENT ─────────────────────────────────────
      // Citizen announcements MUST NOT be filtered by targetAudience.
      // They MUST be joined via notifications.announcement_id only.
      if (user.role == UserRole.citizen) {
        debugPrint('DEBUG: -> Skipped. Citizen did not have a matching notification for announcement_id: ${a.id}');
        continue;
      }

      // If user is the creator, they can see it regardless of audience
      if (a.createdById == user.id) {
        visible.add(a);
        continue;
      }

      if (!audienceMatch) continue;

      bool locationMatch = true;
      // Filter by Mandal
      if (a.targetMandal != null && a.targetMandal!.isNotEmpty) {
        if (user.mandalName != a.targetMandal) locationMatch = false;
      }
      // Filter by Panchayat
      if (locationMatch &&
          a.targetPanchayat != null &&
          a.targetPanchayat!.isNotEmpty) {
        if (userPanchayat != a.targetPanchayat) locationMatch = false;
      }
      // Filter by Ward
      if (locationMatch && a.targetWard != null && a.targetWard!.isNotEmpty) {
        if (user.wardName != a.targetWard) locationMatch = false;
      }

      if (locationMatch) {
        visible.add(a);
      }
    }

    visible.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return visible;
  }

  Future<void> markAnnouncementAsRead(Announcement announcement) async {
    if (_currentUser == null || !isSupabaseConnected) return;

    final read = AnnouncementRead(
      id: 'read_${announcement.id}_${_currentUser!.id}',
      announcementId: announcement.id,
      userId: _currentUser!.id,
      readAt: DateTime.now(),
    );
    await SupabaseService.markAnnouncementAsRead(read);
  }

  AppConfig? get appConfig => _appConfig;

  User? get currentUser => _currentUser;

  // ─── Stream Subscriptions ───────────────────────────────────────────────────
  StreamSubscription<List<Ward>>? _wardsSub;
  StreamSubscription<List<User>>? _usersSub;
  StreamSubscription<List<Complaint>>? _complaintsSub;
  StreamSubscription<List<BroadcastAlert>>? _broadcastsSub;
  StreamSubscription? _chatSub;
  StreamSubscription? _announcementsSub;
  StreamSubscription? _wardUpdatesSub;
  StreamSubscription? _completedWorksSub;
  StreamSubscription<List<AppNotification>>? _notificationsSub;

  AppState() {
    _init();
  }

  Future<void> _init() async {
    // 1. Initialize local cache boxes
    final settingsBox = Hive.box('app_settings');
    _isTelugu = settingsBox.get('isTelugu', defaultValue: false) as bool;

    // Load cached broadcasts
    _loadLocalBroadcasts();

    // 2. Load cached app config
    final cachedConfig = settingsBox.get('app_config');
    if (cachedConfig != null) {
      _appConfig = AppConfig.fromJson(Map<String, dynamic>.from(cachedConfig));
    }

    // 3. Auto-login if user is cached locally
    final cachedUserMap = settingsBox.get('logged_in_user');
    if (cachedUserMap != null) {
      _currentUser = User.fromMap(Map<String, dynamic>.from(cachedUserMap));
      _loadNotifications();
      notifyListeners();
    }

    // 4. Initial connectivity check & Firestore Stream start
    final connected = await SupabaseService.checkConnection();
    _connectionStatus = connected
        ? ConnectionStatus.connected
        : ConnectionStatus.offline;
    _connectionStatusController.add(_connectionStatus);
    notifyListeners();

    if (connected) {
      _fetchAppConfig();
      _startFirestoreStreams();
      await syncOfflineProfilePhotos();
      await syncOfflineComplaints();
      await syncOfflineBroadcasts();
    }

    // 5. Setup dynamic network monitoring
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final hasConnection = !results.contains(ConnectivityResult.none);
      _updateConnectionStatus(hasConnection);
    });
  }

  void _updateConnectionStatus(bool hasConnection) async {
    if (hasConnection) {
      final pingOk = await SupabaseService.checkConnection();
      _connectionStatus = pingOk
          ? ConnectionStatus.connected
          : ConnectionStatus.offline;
    } else {
      _connectionStatus = ConnectionStatus.offline;
    }
    _connectionStatusController.add(_connectionStatus);
    notifyListeners();

    if (_connectionStatus == ConnectionStatus.connected) {
      _fetchAppConfig();
      _startFirestoreStreams();
      await syncOfflineProfilePhotos();
      await syncOfflineComplaints();
      await syncOfflineBroadcasts();
    }
  }

  // ─── Manual Connection Retry ────────────────────────────────────────────────
  void retryConnection() {
    _updateConnectionStatus(true);
  }

  // ─── Bilingual Language Switch ──────────────────────────────────────────────
  void setLanguage(bool toTelugu) {
    _isTelugu = toTelugu;
    Hive.box('app_settings').put('isTelugu', toTelugu);
    notifyListeners();
  }

  // ─── Work Updates ───────────────────────────────────────────────────────────
  Future<void> addWorkUpdate(WorkUpdate update, List<File> imageFiles) async {
    if (!isSupabaseConnected || _currentUser == null) return;

    // Upload images
    List<String> uploadedUrls = [];
    for (int i = 0; i < imageFiles.length; i++) {
      final url = await SupabaseService.uploadWorkUpdateImage(
        imageFiles[i],
        update.id,
        i,
      );
      if (url != null) uploadedUrls.add(url);
    }

    final finalUpdate = WorkUpdate(
      id: update.id,
      title: update.title,
      description: update.description,
      imageUrls: uploadedUrls,
      wardId: update.wardId,
      wardName: update.wardName,
      wardMemberId: update.wardMemberId,
      createdAt: update.createdAt,
      updatedAt: update.updatedAt,
    );

    // Insert to DB
    await SupabaseService.submitWorkUpdate(finalUpdate);

    // Find all citizens in the ward
    final targetCitizens = _users
        .where((u) => u.wardId == update.wardId && u.role == UserRole.citizen)
        .toList();

    // Generate Notifications
    List<AppNotification> newNotifs = [];
    final ts = DateTime.now().millisecondsSinceEpoch;

    for (var citizen in targetCitizens) {
      final notif = AppNotification(
        id: 'notif_${ts}_${citizen.id.hashCode}',
        userId: citizen.id,
        title: 'New Work Update',
        body:
            'Ward Member has published a new work update in ${update.wardName}.',
        type: 'ward_update',
        createdAt: DateTime.now(),
        isRead: false,
        complaintId: finalUpdate.id,
      );
      newNotifs.add(notif);

      // Also add to local cache if that user is somehow the current user (edge case, but good practice)
      if (currentUser?.id == citizen.id) {
        _notifications.insert(0, notif);
      }
    }

    await SupabaseService.batchInsertNotifications(newNotifs);

    // Notify listeners for immediate UI feedback
    _workUpdates.insert(0, finalUpdate);
    notifyListeners();
  }

  List<WorkUpdate> get wardUpdates => _workUpdates;

  List<WorkUpdate> wardUpdatesForCitizen(String wardId, [String? wardName]) {
    var list = _workUpdates
        .where(
          (u) =>
              u.wardId == wardId ||
              (wardName != null && u.wardName == wardName),
        )
        .toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  List<WorkUpdate> wardUpdatesForMember(String memberId) {
    var list = _workUpdates.where((u) => u.wardMemberId == memberId).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  // ─── Completed Works Helpers ──────────────────────────────────────────────────
  List<CompletedWork> completedWorksForCitizen(String citizenId) {
    var list = _completedWorks.where((u) => u.citizenId == citizenId).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  List<CompletedWork> completedWorksForMember(String memberId) {
    var list = _completedWorks
        .where((u) => u.wardMemberId == memberId)
        .toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  // ─── App Config ─────────────────────────────────────────────────────────────
  Future<void> _fetchAppConfig({String? forcePartyId}) async {
    final box = await Hive.openBox('theme_settings');
    final activePartyId =
        forcePartyId ?? box.get('active_party_id', defaultValue: 'tdp');

    final config = await SupabaseService.getAppConfig(activePartyId);
    if (config != null) {
      _appConfig = config;
      Hive.box('app_settings').put('app_config', config.toJson());
      notifyListeners();
    }
  }

  Future<void> updateAppConfig(AppConfig config) async {
    _appConfig = config;
    Hive.box('app_settings').put('app_config', config.toJson());
    notifyListeners();
    if (isSupabaseConnected) {
      await SupabaseService.updateAppConfig(config);
    }
  }

  Future<void> reloadAppConfigForParty(String partyId) async {
    await _fetchAppConfig(forcePartyId: partyId);
  }

  // ─── Seed Firestore with local data if empty ────────────────────────────────

  // ─── Start real-time Firestore streams ──────────────────────────────────────
  void _startFirestoreStreams() {
    _wardsSub?.cancel();
    _wardsSub = SupabaseService.streamWards().listen((wards) {
      _wards = wards;
      notifyListeners();
    }, onError: (_) {});

    _usersSub?.cancel();
    _usersSub = SupabaseService.streamUsers().listen((users) {
      _users = users;
      // Re-sync currentUser if logged in
      if (_currentUser != null) {
        final updated = _users.where((u) => u.id == _currentUser!.id);
        if (updated.isNotEmpty) {
          final dbUser = updated.first;
          final currentPhoto = _currentUser!.profilePhotoUrl;
          String? mergedPhoto = dbUser.profilePhotoUrl;
          if (currentPhoto != null &&
              !currentPhoto.startsWith('http') &&
              (dbUser.profilePhotoUrl == null ||
                  dbUser.profilePhotoUrl!.isEmpty)) {
            mergedPhoto = currentPhoto;
          }
          _currentUser = User(
            id: dbUser.id,
            name: dbUser.name,
            phoneNumber: dbUser.phoneNumber,
            password: dbUser.password,
            role: dbUser.role,
            wardId: dbUser.wardId,
            wardName: dbUser.wardName,
            mandalName: dbUser.mandalName,
            villageName: dbUser.villageName,
            officerRole: dbUser.officerRole,
            createdAt: dbUser.createdAt,
            profilePhotoUrl: mergedPhoto,
            profileImageUrl: dbUser.profileImageUrl,
            fcmToken: dbUser.fcmToken,
            isEmployed: dbUser.isEmployed,
            education: dbUser.education,
          );
          Hive.box('app_settings').put('logged_in_user', _currentUser!.toMap());
        }
      }
      notifyListeners();
    }, onError: (_) {});

    _complaintsSub?.cancel();
    _complaintsSub = SupabaseService.streamComplaints().listen(
      (newComplaints) {
        _checkAndNotifyResolved(newComplaints);
        _complaints = newComplaints;
        notifyListeners();
      },
      onError: (e) {
        debugPrint('Complaints stream error: $e');
      },
    );

    _broadcastsSub?.cancel();
    _broadcastsSub = SupabaseService.streamBroadcasts().listen((newAlerts) {
      final now = DateTime.now();
      final List<BroadcastAlert> activeAlerts = [];

      for (final alert in newAlerts) {
        final age = now.difference(alert.createdAt);
        if (age.inHours >= 48) {
          debugPrint(
            '[AUTO_DELETE] Broadcast ${alert.id} has expired (age: ${age.inHours} hours). Auto-deleting from Firestore...',
          );
          SupabaseService.deleteBroadcast(alert.id).catchError((e) {
            debugPrint(
              '[AUTO_DELETE] Error auto-deleting expired broadcast ${alert.id}: $e',
            );
          });
        } else {
          activeAlerts.add(alert);
        }
      }

      _broadcasts = activeAlerts;
      // Cache in Hive
      final box = Hive.box('local_broadcasts');
      final cachedKeys = box.keys
          .where((k) => k.toString().startsWith('broadcast_'))
          .toList();
      for (final k in cachedKeys) {
        box.delete(k);
      }
      for (final alert in activeAlerts) {
        box.put('broadcast_${alert.id}', alert.toMap());
      }
      notifyListeners();
    }, onError: (_) {});

    _announcementsSub?.cancel();
    _announcementsSub = SupabaseService.streamAnnouncements().listen((data) {
      _announcements = data;
      notifyListeners();
    }, onError: (_) {});

    _wardUpdatesSub?.cancel();
    _wardUpdatesSub = SupabaseService.streamWardUpdates().listen((data) {
      _workUpdates = data;
      notifyListeners();
    }, onError: (_) {});

    _completedWorksSub?.cancel();
    _completedWorksSub = SupabaseService.streamCompletedWorks().listen((data) {
      _completedWorks = data;
      notifyListeners();
    }, onError: (_) {});

    // ─── Supabase Realtime: Notifications for current user ───
    if (_currentUser != null) {
      _startNotificationsStream(_currentUser!.id);
    }
  }

  void _startNotificationsStream(String userId) {
    _notificationsSub?.cancel();
    _notificationsSub = SupabaseService.streamNotificationsForUser(userId)
        .listen((supabaseNotifs) {
          // Merge: Supabase is source of truth; Hive is only offline seed
          final Map<String, AppNotification> merged = {};

          // Seed from existing Hive-cached notifications
          for (final n in _notifications) {
            merged[n.id] = n;
          }
          // Overwrite with Supabase versions (more authoritative)
          for (final n in supabaseNotifs) {
            merged[n.id] = n;
          }

          _notifications = merged.values.toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

          // Persist to Hive for offline cache
          final box = Hive.box('local_notifications');
          for (final n in supabaseNotifs) {
            box.put(n.id, n.toMap());
          }
          notifyListeners();
        }, onError: (e) => debugPrint('Notifications stream error: $e'));
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    _wardsSub?.cancel();
    _usersSub?.cancel();
    _complaintsSub?.cancel();
    _chatSub?.cancel();
    _announcementsSub?.cancel();
    _wardUpdatesSub?.cancel();
    _completedWorksSub?.cancel();
    _notificationsSub?.cancel();
    _connectionStatusController.close();
    _pushNotificationController.close();
    super.dispose();
  }

  // ─── Escalations Finder (Complaints unresolved > 24 hours) ──────────────────
  List<Complaint> get escalatedComplaints {
    final now = DateTime.now();
    return _complaints.where((c) {
      final isUnresolved =
          c.status == ComplaintStatus.submitted ||
          c.status == ComplaintStatus.inProgress;
      if (isUnresolved) {
        final durationHours = now.difference(c.createdAt).inHours;
        return durationHours >= 24;
      }
      return false;
    }).toList();
  }

  // ─── Auth ───────────────────────────────────────────────────────────────────
  // Returns null on success, or an error message string on failure
  Future<String?> login(String phone, String password) async {
    final trimmedPhone = phone.trim();
    final trimmedPassword = password.trim();

    if (isSupabaseConnected) {
      final user = await SupabaseService.loginUser(
        trimmedPhone,
        trimmedPassword,
      );
      if (user != null) {
        _currentUser = user;
        _loadNotifications();
        await Hive.box('app_settings').put('logged_in_user', user.toMap());
        notifyListeners();
        return null; // success
      }
      // Try to find out WHY login failed — phone not found or wrong password?
      final phoneCheck = _users
          .where((u) => u.phoneNumber.trim() == trimmedPhone)
          .firstOrNull;
      if (phoneCheck == null) {
        return 'Phone number not registered. Please check and try again.';
      }
      return 'Incorrect password. Please try again.';
    } else {
      // Offline fallback login
      final user = _users
          .where(
            (u) =>
                u.phoneNumber.trim() == trimmedPhone &&
                u.password.trim() == trimmedPassword,
          )
          .firstOrNull;
      if (user != null) {
        _currentUser = user;
        _loadNotifications();
        await Hive.box('app_settings').put('logged_in_user', user.toMap());
        notifyListeners();
        return null; // success
      }
      final phoneCheck = _users
          .where((u) => u.phoneNumber.trim() == trimmedPhone)
          .firstOrNull;
      if (phoneCheck == null) {
        return 'Phone number not registered. Please check and try again.';
      }
      return 'Incorrect password. Please try again.';
    }
  }

  void loginAsUser(User user) {
    _currentUser = user;
    _loadNotifications();
    Hive.box('app_settings').put('logged_in_user', user.toMap());
    notifyListeners();
  }

  void logout() {
    _currentUser = null;
    _notifications = [];
    _notificationsSub?.cancel();
    _notificationsSub = null;
    Hive.box('app_settings').delete('logged_in_user');
    notifyListeners();
  }

  Future<bool> register(
    String name,
    String phone,
    String password,
    bool isEmployed,
    String education,
  ) async {
    if (isSupabaseConnected) {
      final user = await SupabaseService.registerUser(
        name,
        phone,
        password,
        isEmployed,
        education,
      );
      if (user != null) {
        _currentUser = user;
        _loadNotifications();
        await Hive.box('app_settings').put('logged_in_user', user.toMap());
        notifyListeners();
        return true;
      }
      return false;
    } else {
      if (_users.any((u) => u.phoneNumber == phone)) return false;
      final newUser = User(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        phoneNumber: phone,
        password: password,
        role: UserRole.citizen,
        createdAt: DateTime.now(),
        isEmployed: isEmployed,
        education: education,
      );
      _users.add(newUser);
      _currentUser = newUser;
      _loadNotifications();
      await Hive.box('app_settings').put('logged_in_user', newUser.toMap());
      notifyListeners();
      return true;
    }
  }

  Future<void> updateUserProfile(
    String name,
    String phone,
    String? profilePhotoUrl,
  ) async {
    if (_currentUser == null) return;

    String? finalPhotoUrl = profilePhotoUrl ?? _currentUser!.profilePhotoUrl;
    if (finalPhotoUrl != null && !finalPhotoUrl.startsWith('http')) {
      final file = File(finalPhotoUrl);
      if (file.existsSync()) {
        if (isSupabaseConnected) {
          final cloudUrl = await SupabaseService.uploadProfileImage(
            file,
            _currentUser!.id,
          );
          if (cloudUrl != null) {
            finalPhotoUrl = cloudUrl;
          }
        }
      }
    }

    final updatedUser = User(
      id: _currentUser!.id,
      name: name,
      phoneNumber: phone,
      password: _currentUser!.password,
      role: _currentUser!.role,
      wardId: _currentUser!.wardId,
      wardName: _currentUser!.wardName,
      officerRole: _currentUser!.officerRole,
      createdAt: _currentUser!.createdAt,
      profilePhotoUrl: finalPhotoUrl,
    );

    _currentUser = updatedUser;

    // Update local memory list
    final index = _users.indexWhere((u) => u.id == updatedUser.id);
    if (index != -1) {
      _users[index] = updatedUser;
    }

    // Persist local state
    await Hive.box('app_settings').put('logged_in_user', updatedUser.toMap());

    // Update in Firebase if connected
    if (isSupabaseConnected) {
      await SupabaseService.updateUser(updatedUser);
    }

    notifyListeners();
  }

  Future<void> syncOfflineProfilePhotos() async {
    if (!isSupabaseConnected || _currentUser == null) return;
    final photo = _currentUser!.profilePhotoUrl;
    if (photo != null && !photo.startsWith('http')) {
      final file = File(photo);
      if (file.existsSync()) {
        final cloudUrl = await SupabaseService.uploadProfileImage(
          file,
          _currentUser!.id,
        );
        if (cloudUrl != null) {
          final updatedUser = User(
            id: _currentUser!.id,
            name: _currentUser!.name,
            phoneNumber: _currentUser!.phoneNumber,
            password: _currentUser!.password,
            role: _currentUser!.role,
            wardId: _currentUser!.wardId,
            wardName: _currentUser!.wardName,
            officerRole: _currentUser!.officerRole,
            createdAt: _currentUser!.createdAt,
            profilePhotoUrl: cloudUrl,
          );
          _currentUser = updatedUser;
          await Hive.box(
            'app_settings',
          ).put('logged_in_user', updatedUser.toMap());
          await SupabaseService.updateUser(updatedUser);

          final index = _users.indexWhere((u) => u.id == updatedUser.id);
          if (index != -1) {
            _users[index] = updatedUser;
          }
          notifyListeners();
        }
      }
    }
  }

  // ─── Ward Detection ─────────────────────────────────────────────────────────
  Ward? getWardForLocation(double lat, double lng) {
    for (var w in _wards) {
      if (w.contains(lat, lng)) return w;
    }
    // Fallback: return closest ward by distance
    Ward? closest;
    double minDist = double.infinity;
    for (var w in _wards) {
      final d =
          ((lat - w.centerLatitude) * (lat - w.centerLatitude)) +
          ((lng - w.centerLongitude) * (lng - w.centerLongitude));
      if (d < minDist) {
        minDist = d;
        closest = w;
      }
    }
    return closest;
  }

  // ─── Complaint Submission ───────────────────────────────────────────────────
  User? getDynamicAssignedOfficer(Complaint c) {
    final String targetRole = CategoryMapping.getOfficerRoleForCategory(
      c.category,
    );

    // ── Step 1: Find the Panchayat for the complaint's village ──────────────
    String? complaintPanchayat;
    if (c.villageName.isNotEmpty) {
      for (final entry in MandalMapping.panchayatToVillages.entries) {
        if (entry.value.any(
          (v) => v.trim().toLowerCase() == c.villageName.trim().toLowerCase(),
        )) {
          complaintPanchayat = entry.key;
          break;
        }
      }
    }

    if (complaintPanchayat != null) {
      final panchayatLower = complaintPanchayat.trim().toLowerCase();

      // ── Step 2a: EXACT MATCH — correct role + correct panchayat ──────────
      final exactMatches = _users
          .where(
            (u) =>
                u.role == UserRole.categoryOfficer &&
                u.wardId?.trim().toLowerCase() == panchayatLower &&
                u.officerRole?.trim().toLowerCase() ==
                    targetRole.trim().toLowerCase(),
          )
          .toList();

      if (exactMatches.isNotEmpty) {
        // Prefer one with matching village name, else take first
        return exactMatches.firstWhere(
          (u) =>
              u.villageName?.trim().toLowerCase() ==
              c.villageName.trim().toLowerCase(),
          orElse: () => exactMatches.first,
        );
      }

      // ── Step 2b: PANCHAYAT FALLBACK — any category officer in same panchayat ──
      // This catches officers whose role was stored incorrectly in the database.
      final panchayatOfficers = _users
          .where(
            (u) =>
                u.role == UserRole.categoryOfficer &&
                u.wardId?.trim().toLowerCase() == panchayatLower,
          )
          .toList();

      if (panchayatOfficers.isNotEmpty) {
        return panchayatOfficers.firstWhere(
          (u) =>
              u.villageName?.trim().toLowerCase() ==
              c.villageName.trim().toLowerCase(),
          orElse: () => panchayatOfficers.first,
        );
      }
    }

    // ── Step 3: Ward Admin fallback ─────────────────────────────────────────
    final wardAdmins = _users
        .where(
          (u) =>
              u.role == UserRole.wardAdmin &&
              (u.wardId == c.wardId ||
                  (u.wardName != null && u.wardName == c.wardName)),
        )
        .toList();

    if (wardAdmins.isNotEmpty) {
      return wardAdmins.firstWhere(
        (u) => u.villageName?.toLowerCase() == c.villageName.toLowerCase(),
        orElse: () => wardAdmins.first,
      );
    }

    // ── Step 4: Mandal Officer — exact role match for this category ─────────
    final mandalRole = CategoryMapping.getMandalRoleForCategory(c.category);
    final mandalOfficer = _users
        .where(
          (u) =>
              u.role == UserRole.mandalOfficer &&
              u.officerRole?.trim().toLowerCase() ==
                  mandalRole.trim().toLowerCase() &&
              (u.mandalName == null ||
                  u.mandalName!.isEmpty ||
                  u.mandalName == c.mandalName),
        )
        .firstOrNull;

    if (mandalOfficer != null) return mandalOfficer;

    // ── Step 5: Any mandal officer (last resort before super admin) ─────────
    final anyMandal = _users
        .where((u) => u.role == UserRole.mandalOfficer)
        .firstOrNull;
    if (anyMandal != null) return anyMandal;

    // ── Step 6: Super Admin (absolute last resort, never crashes) ───────────
    return _users.where((u) => u.role == UserRole.superAdmin).firstOrNull;
  }

  Future<void> submitComplaint({
    required String category,
    required String description,
    required double latitude,
    required double longitude,
    required String address,
    required String wardId,
    required String wardName,
    required String villageName,
    required String mandalName,
    String? imageUrl,
    Uint8List? imageBytes,
    bool isVideo = false,
  }) async {
    if (_currentUser == null) return;

    final complaintId = 'comp_${DateTime.now().millisecondsSinceEpoch}';

    // Simple device/network details capture
    String systemInfo = 'Unknown Platform';
    try {
      if (kIsWeb) {
        systemInfo = 'Web';
      } else if (Platform.isAndroid) {
        systemInfo = 'Android ${Platform.operatingSystemVersion}';
      } else if (Platform.isIOS) {
        systemInfo = 'iOS ${Platform.operatingSystemVersion}';
      }
    } catch (_) {
      systemInfo = 'Platform Simulator';
    }

    String? finalImageUrl = imageUrl;

    if (imageBytes != null) {
      if (isSupabaseConnected) {
        final cloudUrl = await SupabaseService.uploadComplaintBytes(
          imageBytes,
          complaintId,
          isVideo: isVideo,
        );
        if (cloudUrl != null) {
          finalImageUrl = cloudUrl;
        }
      }
    } else if (imageUrl != null &&
        (imageUrl.startsWith('local:') ||
            imageUrl.startsWith('local_video:'))) {
      if (!kIsWeb) {
        final isVideoFile = imageUrl.startsWith('local_video:');
        final localPath = imageUrl.substring(
          isVideoFile ? 'local_video:'.length : 'local:'.length,
        );
        final file = File(localPath);
        if (file.existsSync()) {
          if (isSupabaseConnected) {
            final cloudUrl = await SupabaseService.uploadComplaintImage(
              file,
              complaintId,
            );
            if (cloudUrl != null) {
              finalImageUrl = cloudUrl;
            }
          }
        }
      }
    }

    final tempComplaint = Complaint(
      id: complaintId,
      userId: _currentUser!.id,
      citizenName: _currentUser!.name,
      citizenPhone: _currentUser!.phoneNumber,
      category: category,
      description: description,
      latitude: latitude,
      longitude: longitude,
      wardId: wardId,
      wardName: wardName,
      villageName: villageName,
      mandalName: mandalName,
      address: address,
      createdAt: DateTime.now(),
    );

    final assignedOfficer = getDynamicAssignedOfficer(tempComplaint);

    final newComplaint = Complaint(
      id: tempComplaint.id,
      userId: tempComplaint.userId,
      citizenName: tempComplaint.citizenName,
      citizenPhone: tempComplaint.citizenPhone,
      category: tempComplaint.category,
      description: tempComplaint.description,
      latitude: tempComplaint.latitude,
      longitude: tempComplaint.longitude,
      wardId: tempComplaint.wardId,
      wardName: tempComplaint.wardName,
      villageName: tempComplaint.villageName,
      mandalName: tempComplaint.mandalName,
      address: tempComplaint.address,
      assignedOfficerId: assignedOfficer?.id,
      imageUrl: finalImageUrl,
      status: ComplaintStatus.submitted,
      priority: ComplaintPriority.low,
      deviceInfo: systemInfo,
      createdAt: tempComplaint.createdAt,
    );
    if (isSupabaseConnected) {
      await SupabaseService.submitComplaint(newComplaint);
      // Update local state instantly so UI updates without waiting for Realtime stream
      final index = _complaints.indexWhere((c) => c.id == newComplaint.id);
      if (index == -1) {
        _complaints = [newComplaint, ..._complaints];
        notifyListeners();
      }
    } else {
      // Offline queue storage
      final box = Hive.box('local_complaints');
      await box.put(newComplaint.id, newComplaint.toMap());

      // Update local state temporarily so user sees it in list
      _complaints = [newComplaint, ..._complaints];
      notifyListeners();
    }
  }

  // ─── Caching Auto-Sync Queue ────────────────────────────────────────────────
  Future<void> syncOfflineComplaints() async {
    final box = Hive.box('local_complaints');
    if (box.isEmpty) return;

    final keys = List<String>.from(box.keys);
    int syncCount = 0;
    for (final key in keys) {
      try {
        final data = Map<String, dynamic>.from(box.get(key));
        final complaint = Complaint.fromMap(data);

        // Upload images/videos to Firebase Storage if they are local paths
        String? cloudImageUrl = complaint.imageUrl;
        if (complaint.imageUrl != null &&
            (complaint.imageUrl!.startsWith('local:') ||
                complaint.imageUrl!.startsWith('local_video:'))) {
          final isVideo = complaint.imageUrl!.startsWith('local_video:');
          final localPath = complaint.imageUrl!.substring(
            isVideo ? 'local_video:'.length : 'local:'.length,
          );
          final file = File(localPath);
          if (file.existsSync()) {
            final cloudUrl = await SupabaseService.uploadComplaintImage(
              file,
              complaint.id,
            );
            if (cloudUrl != null) {
              cloudImageUrl = cloudUrl;
            }
          }
        }

        String? cloudResolvedImageUrl = complaint.resolvedImageUrl;
        if (complaint.resolvedImageUrl != null &&
            (complaint.resolvedImageUrl!.startsWith('local:') ||
                complaint.resolvedImageUrl!.startsWith('local_video:'))) {
          final isVideo = complaint.resolvedImageUrl!.startsWith(
            'local_video:',
          );
          final localPath = complaint.resolvedImageUrl!.substring(
            isVideo ? 'local_video:'.length : 'local:'.length,
          );
          final file = File(localPath);
          if (file.existsSync()) {
            final cloudUrl = await SupabaseService.uploadResolvedComplaintImage(
              file,
              complaint.id,
            );
            if (cloudUrl != null) {
              cloudResolvedImageUrl = cloudUrl;
            }
          }
        }

        final syncedComplaint = Complaint(
          id: complaint.id,
          userId: complaint.userId,
          citizenName: complaint.citizenName,
          citizenPhone: complaint.citizenPhone,
          category: complaint.category,
          description: complaint.description,
          imageUrl: cloudImageUrl,
          resolvedImageUrl: cloudResolvedImageUrl,
          latitude: complaint.latitude,
          longitude: complaint.longitude,
          wardId: complaint.wardId,
          wardName: complaint.wardName,
          villageName: complaint.villageName,
          mandalName: complaint.mandalName,
          address: complaint.address,
          assignedOfficerId: complaint.assignedOfficerId,
          deviceInfo: complaint.deviceInfo,
          status: complaint.status,
          priority: complaint.priority,
          createdAt: complaint.createdAt,
          resolvedAt: complaint.resolvedAt,
          feedbackRating: complaint.feedbackRating,
          isClosed: complaint.isClosed,
        );

        await SupabaseService.submitComplaint(syncedComplaint);
        await box.delete(key);
        syncCount++;
      } catch (e) {
        debugPrint('Failed to sync offline complaint $key: $e');
      }
    }

    if (syncCount > 0) {
      debugPrint('Synchronized $syncCount complaints.');
    }
  }

  Future<void> syncOfflineBroadcasts() async {
    final box = Hive.box('local_broadcasts');
    final keys = box.keys
        .where((k) => k.toString().startsWith('queue_'))
        .toList();
    if (keys.isEmpty) return;

    int syncCount = 0;
    for (final key in keys) {
      try {
        final data = Map<String, dynamic>.from(box.get(key));
        var alert = BroadcastAlert.fromMap(data);

        if (alert.audioUrl != null && !alert.audioUrl!.startsWith('https://')) {
          final audioFile = File(alert.audioUrl!);
          if (audioFile.existsSync()) {
            debugPrint(
              '[OFFLINE_SYNC] Found local offline audio path: ${audioFile.path}. Uploading to Storage...',
            );
            final cloudUrl = await SupabaseService.uploadBroadcastAudio(
              audioFile,
              alert.id,
            );
            if (cloudUrl != null) {
              debugPrint(
                '[OFFLINE_SYNC] Firebase upload success. Download URL: $cloudUrl',
              );
              alert = BroadcastAlert(
                id: alert.id,
                title: alert.title,
                description: alert.description,
                wardId: alert.wardId,
                wardName: alert.wardName,
                createdBy: alert.createdBy,
                createdByRole: alert.createdByRole,
                createdAt: alert.createdAt,
                targetAudience: alert.targetAudience,
                audioUrl: cloudUrl,
              );
            } else {
              debugPrint(
                '[OFFLINE_SYNC] Storage upload failed. Stripping local path to prevent leakage.',
              );
              alert = BroadcastAlert(
                id: alert.id,
                title: alert.title,
                description: alert.description,
                wardId: alert.wardId,
                wardName: alert.wardName,
                createdBy: alert.createdBy,
                createdByRole: alert.createdByRole,
                createdAt: alert.createdAt,
                targetAudience: alert.targetAudience,
                audioUrl: null,
              );
            }
          } else {
            debugPrint(
              '[OFFLINE_SYNC] Offline audio file missing from disk: ${audioFile.path}. Stripping URL.',
            );
            alert = BroadcastAlert(
              id: alert.id,
              title: alert.title,
              description: alert.description,
              wardId: alert.wardId,
              wardName: alert.wardName,
              createdBy: alert.createdBy,
              createdByRole: alert.createdByRole,
              createdAt: alert.createdAt,
              targetAudience: alert.targetAudience,
              audioUrl: null,
            );
          }
        }

        // Ultimate Sync Safeguard: Firestore broadcast documents must store ONLY valid remote HTTPS URLs
        if (alert.audioUrl != null && !alert.audioUrl!.startsWith('https://')) {
          debugPrint(
            '[OFFLINE_SYNC] ULTIMATE SAFEGUARD: Stripping invalid audioUrl (${alert.audioUrl}) before Firestore submission.',
          );
          alert = BroadcastAlert(
            id: alert.id,
            title: alert.title,
            description: alert.description,
            wardId: alert.wardId,
            wardName: alert.wardName,
            createdBy: alert.createdBy,
            createdByRole: alert.createdByRole,
            createdAt: alert.createdAt,
            targetAudience: alert.targetAudience,
            audioUrl: null,
          );
        }

        debugPrint(
          '[OFFLINE_SYNC] Submitting broadcast to Firestore. Saved URL: ${alert.audioUrl}',
        );
        await SupabaseService.submitBroadcast(alert);
        await box.delete(key);
        await box.put('broadcast_${alert.id}', alert.toMap());
        syncCount++;
      } catch (e) {
        debugPrint('Failed to sync offline broadcast $key: $e');
      }
    }
    if (syncCount > 0) {
      debugPrint('Synchronized $syncCount broadcasts.');
    }
  }

  Future<void> submitBroadcast(BroadcastAlert alert) async {
    BroadcastAlert finalAlert = alert;
    if (alert.audioUrl != null && !alert.audioUrl!.startsWith('https://')) {
      final audioFile = File(alert.audioUrl!);
      debugPrint(
        '[BROADCAST_FLOW] Local recording path detected: ${audioFile.path}',
      );
      if (audioFile.existsSync()) {
        if (isSupabaseConnected) {
          debugPrint(
            '[BROADCAST_FLOW] Uploading local audio: ${audioFile.path}',
          );
          final cloudUrl = await SupabaseService.uploadBroadcastAudio(
            audioFile,
            alert.id,
          );
          if (cloudUrl != null) {
            debugPrint(
              '[BROADCAST_FLOW] Firebase upload success. Download URL: $cloudUrl',
            );
            finalAlert = BroadcastAlert(
              id: alert.id,
              title: alert.title,
              description: alert.description,
              wardId: alert.wardId,
              wardName: alert.wardName,
              createdBy: alert.createdBy,
              createdByRole: alert.createdByRole,
              createdAt: alert.createdAt,
              targetAudience: alert.targetAudience,
              audioUrl: cloudUrl,
            );
          } else {
            debugPrint(
              '[BROADCAST_FLOW] Cloud upload failed. Stripping local path to prevent leakage.',
            );
            finalAlert = BroadcastAlert(
              id: alert.id,
              title: alert.title,
              description: alert.description,
              wardId: alert.wardId,
              wardName: alert.wardName,
              createdBy: alert.createdBy,
              createdByRole: alert.createdByRole,
              createdAt: alert.createdAt,
              targetAudience: alert.targetAudience,
              audioUrl: null,
            );
          }
        }
      } else {
        debugPrint(
          '[BROADCAST_FLOW] Audio file does not exist locally or is invalid mock: ${audioFile.path}. Stripping path.',
        );
        finalAlert = BroadcastAlert(
          id: alert.id,
          title: alert.title,
          description: alert.description,
          wardId: alert.wardId,
          wardName: alert.wardName,
          createdBy: alert.createdBy,
          createdByRole: alert.createdByRole,
          createdAt: alert.createdAt,
          targetAudience: alert.targetAudience,
          audioUrl: null,
        );
      }
    }

    // Create a safe copy specifically for Firestore. The Firestore document MUST strictly have a secure HTTPS URL.
    // If the audio URL is a local path (because the app is offline), we do NOT write the local path to Firestore.
    // However, we preserve the local path inside local memory list and local Hive caches so offline playback and queue sync succeed!
    if (isSupabaseConnected) {
      BroadcastAlert firestoreAlert = finalAlert;
      if (firestoreAlert.audioUrl != null &&
          !firestoreAlert.audioUrl!.startsWith('https://')) {
        debugPrint(
          '[BROADCAST_FLOW] FIRESTORE SAFEGUARD: Stripping local audioUrl path before cloud submission.',
        );
        firestoreAlert = BroadcastAlert(
          id: finalAlert.id,
          title: finalAlert.title,
          description: finalAlert.description,
          wardId: finalAlert.wardId,
          wardName: finalAlert.wardName,
          createdBy: finalAlert.createdBy,
          createdByRole: finalAlert.createdByRole,
          createdAt: finalAlert.createdAt,
          targetAudience: finalAlert.targetAudience,
          audioUrl: null,
        );
      }

      debugPrint(
        '[BROADCAST_FLOW] Submitting broadcast to Firestore. Saved URL: ${firestoreAlert.audioUrl}',
      );
      await SupabaseService.submitBroadcast(firestoreAlert);
      debugPrint(
        '[BROADCAST_FLOW] Firestore submit confirmed. Stream will update local state.',
      );
      // Cache in Hive for persistence
      final box = Hive.box('local_broadcasts');
      box.put('broadcast_${finalAlert.id}', finalAlert.toMap());

      // Update local state instantly so it appears immediately!
      _broadcasts.insert(0, finalAlert);
      notifyListeners();
    } else {
      debugPrint(
        '[BROADCAST_FLOW] Offline. Storing in Hive local queue with local audio path: ${finalAlert.audioUrl}',
      );
      final box = Hive.box('local_broadcasts');
      await box.put('queue_${finalAlert.id}', finalAlert.toMap());

      // Update local state instantly to reflect immediately on citizen and admin dashboard without lag!
      _broadcasts.insert(0, finalAlert);
      notifyListeners();
    }

    // Generate notifications for targeted ward admins
    if (finalAlert.targetAudience == 'admins') {
      final targetAdmins = _users.where((u) {
        if (u.role != UserRole.wardAdmin) return false;
        if (alert.wardId == 'global') return true;
        return u.wardId == alert.wardId;
      }).toList();

      for (final admin in targetAdmins) {
        debugPrint(
          '[BROADCAST_FLOW] Sending FCM/local notification to admin: ${admin.id}',
        );
        await addNotificationForUser(
          userId: admin.id,
          title: '📢 Broadcast from Super Admin',
          body: '${alert.title}: ${alert.description}',
          type: 'broadcast',
        );
        debugPrint('[BROADCAST_FLOW] Notification sent successfully.');
      }
    }

    // Generate notifications for targeted citizens
    if (finalAlert.targetAudience == 'citizens' ||
        finalAlert.targetAudience.isEmpty) {
      final targetCitizens = _users
          .where((u) => u.role == UserRole.citizen)
          .toList();

      for (final citizen in targetCitizens) {
        debugPrint(
          '[BROADCAST_FLOW] Sending FCM/local notification to citizen: ${citizen.id}',
        );
        await addNotificationForUser(
          userId: citizen.id,
          title: alert.wardId == 'global'
              ? '📢 Municipal Broadcast Alert'
              : '📢 Ward Announcement Alert',
          body: '${alert.title}: ${alert.description}',
          type: 'broadcast',
        );
        debugPrint('[BROADCAST_FLOW] Notification sent successfully.');
      }
    }
  }

  void _loadLocalBroadcasts() {
    final box = Hive.box('local_broadcasts');
    final List<BroadcastAlert> loaded = [];
    for (final key in box.keys) {
      if (key.toString().startsWith('broadcast_') ||
          key.toString().startsWith('queue_')) {
        final map = Map<String, dynamic>.from(box.get(key));
        loaded.add(BroadcastAlert.fromMap(map));
      }
    }
    loaded.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _broadcasts = loaded;
    notifyListeners();
  }

  void _checkAndNotifyResolved(List<Complaint> complaintsList) {
    final settingsBox = Hive.box('app_settings');
    final notifiedList =
        settingsBox.get('notified_resolved_ids', defaultValue: [])
            as List<dynamic>;
    final notifiedIds = List<String>.from(notifiedList);
    bool changed = false;

    for (final c in complaintsList) {
      // Notify the complaint owner regardless of who is currently logged in
      if (c.status == ComplaintStatus.resolved && !c.isClosed) {
        if (!notifiedIds.contains(c.id)) {
          _addNotificationForComplaintOwner(c);
          notifiedIds.add(c.id);
          changed = true;
        }
      }
    }

    if (changed) {
      settingsBox.put('notified_resolved_ids', notifiedIds);
    }
  }

  // ─── Complaint Updates ──────────────────────────────────────────────────────
  Future<void> updateComplaintStatus(
    String complaintId,
    ComplaintStatus newStatus, {
    String? resolvedImageUrl,
  }) async {
    // Optimistically update local state for immediate UI feedback
    final index = _complaints.indexWhere((c) => c.id == complaintId);
    Complaint? updatedComplaint;
    if (index != -1) {
      final existing = _complaints[index];
      updatedComplaint = Complaint(
        id: existing.id,
        userId: existing.userId,
        citizenName: existing.citizenName,
        citizenPhone: existing.citizenPhone,
        category: existing.category,
        description: existing.description,
        latitude: existing.latitude,
        longitude: existing.longitude,
        wardId: existing.wardId,
        wardName: existing.wardName,
        villageName: existing.villageName,
        assignedOfficerId: existing.assignedOfficerId,
        address: existing.address,
        imageUrl: existing.imageUrl,
        resolvedImageUrl: resolvedImageUrl ?? existing.resolvedImageUrl,
        status: newStatus,
        priority: existing.priority,
        createdAt: existing.createdAt,
        resolvedAt: newStatus == ComplaintStatus.resolved
            ? DateTime.now()
            : existing.resolvedAt,
        deviceInfo: existing.deviceInfo,
        feedbackRating: existing.feedbackRating,
        isClosed: existing.isClosed,
      );
      _complaints[index] = updatedComplaint;
      notifyListeners();
    }

    if (isSupabaseConnected) {
      await SupabaseService.updateComplaintStatus(
        complaintId,
        newStatus,
        resolvedImageUrl: resolvedImageUrl,
      );
    } else if (updatedComplaint != null) {
      final box = Hive.box('local_complaints');
      await box.put(complaintId, updatedComplaint.toMap());
    }

    if (updatedComplaint != null &&
        newStatus == ComplaintStatus.resolved &&
        _complaints[index].status != ComplaintStatus.resolved) {
      final settingsBox = Hive.box('app_settings');
      final notifiedList =
          settingsBox.get('notified_resolved_ids', defaultValue: [])
              as List<dynamic>;
      final notifiedIds = List<String>.from(notifiedList);
      if (!notifiedIds.contains(updatedComplaint.id)) {
        _addNotificationForComplaintOwner(updatedComplaint);

        // Trigger immediate push notification
        triggerInAppPushNotification(
          title: _isTelugu ? 'ఫిర్యాదు పరిష్కరించబడింది' : 'Complaint Resolved',
          body: _isTelugu
              ? 'మీ ఫిర్యాదు #${updatedComplaint.id.substring(0, 5)} పరిష్కరించబడింది.'
              : 'Your complaint #${updatedComplaint.id.substring(0, 5)} has been resolved.',
        );

        notifiedIds.add(updatedComplaint.id);
        settingsBox.put('notified_resolved_ids', notifiedIds);
      }
    }
  }

  Future<void> updateComplaintPriority(
    String complaintId,
    ComplaintPriority newPriority,
  ) async {
    if (isSupabaseConnected) {
      await SupabaseService.updateComplaintPriority(complaintId, newPriority);
    } else {
      final index = _complaints.indexWhere((c) => c.id == complaintId);
      if (index != -1) {
        final existing = _complaints[index];
        final updated = Complaint(
          id: existing.id,
          userId: existing.userId,
          citizenName: existing.citizenName,
          citizenPhone: existing.citizenPhone,
          category: existing.category,
          description: existing.description,
          latitude: existing.latitude,
          longitude: existing.longitude,
          wardId: existing.wardId,
          wardName: existing.wardName,
          villageName: existing.villageName,
          assignedOfficerId: existing.assignedOfficerId,
          address: existing.address,
          imageUrl: existing.imageUrl,
          resolvedImageUrl: existing.resolvedImageUrl,
          status: existing.status,
          priority: newPriority,
          createdAt: existing.createdAt,
          resolvedAt: existing.resolvedAt,
          deviceInfo: existing.deviceInfo,
          feedbackRating: existing.feedbackRating,
          isClosed: existing.isClosed,
        );
        _complaints[index] = updated;

        final box = Hive.box('local_complaints');
        await box.put(complaintId, updated.toMap());

        notifyListeners();
      }
    }
  }

  Future<void> forwardComplaint(String complaintId, String targetRole) async {
    // Optimistic local update
    final index = _complaints.indexWhere((c) => c.id == complaintId);
    if (index != -1) {
      final existing = _complaints[index];
      final updated = Complaint(
        id: existing.id,
        userId: existing.userId,
        citizenName: existing.citizenName,
        citizenPhone: existing.citizenPhone,
        category: existing.category,
        description: existing.description,
        latitude: existing.latitude,
        longitude: existing.longitude,
        wardId: existing.wardId,
        wardName: existing.wardName,
        villageName: existing.villageName,
        assignedOfficerId: existing.assignedOfficerId,
        address: existing.address,
        imageUrl: existing.imageUrl,
        resolvedImageUrl: existing.resolvedImageUrl,
        status: existing.status,
        priority: existing.priority,
        createdAt: existing.createdAt,
        resolvedAt: existing.resolvedAt,
        deviceInfo: existing.deviceInfo,
        feedbackRating: existing.feedbackRating,
        isClosed: existing.isClosed,
        isPushed: true,
        pushedTo: targetRole,
      );
      _complaints[index] = updated;

      final box = Hive.box('local_complaints');
      await box.put(complaintId, updated.toMap());
      notifyListeners();
    }

    if (isSupabaseConnected) {
      await SupabaseService.forwardComplaint(complaintId, targetRole);
    }
  }

  Future<void> escalateComplaint(String complaintId, String targetRole) async {
    // Optimistic local update
    final index = _complaints.indexWhere((c) => c.id == complaintId);
    if (index != -1) {
      final existing = _complaints[index];
      final updated = Complaint(
        id: existing.id,
        userId: existing.userId,
        citizenName: existing.citizenName,
        citizenPhone: existing.citizenPhone,
        category: existing.category,
        description: existing.description,
        latitude: existing.latitude,
        longitude: existing.longitude,
        wardId: existing.wardId,
        wardName: existing.wardName,
        villageName: existing.villageName,
        assignedOfficerId: existing.assignedOfficerId,
        address: existing.address,
        imageUrl: existing.imageUrl,
        resolvedImageUrl: existing.resolvedImageUrl,
        status: existing.status,
        priority: ComplaintPriority.high,
        createdAt: existing.createdAt,
        resolvedAt: existing.resolvedAt,
        deviceInfo: existing.deviceInfo,
        feedbackRating: existing.feedbackRating,
        isClosed: existing.isClosed,
        isPushed: true,
        pushedTo: targetRole,
      );
      _complaints[index] = updated;

      final box = Hive.box('local_complaints');
      await box.put(complaintId, updated.toMap());
      notifyListeners();
    }

    if (isSupabaseConnected) {
      await SupabaseService.escalateComplaint(complaintId, targetRole);
    }
  }

  Future<void> submitComplaintFeedback(
    String complaintId,
    String rating,
  ) async {
    if (isSupabaseConnected) {
      await SupabaseService.submitComplaintFeedback(complaintId, rating);
    } else {
      final index = _complaints.indexWhere((c) => c.id == complaintId);
      if (index != -1) {
        final existing = _complaints[index];
        final updated = Complaint(
          id: existing.id,
          userId: existing.userId,
          citizenName: existing.citizenName,
          citizenPhone: existing.citizenPhone,
          category: existing.category,
          description: existing.description,
          latitude: existing.latitude,
          longitude: existing.longitude,
          wardId: existing.wardId,
          wardName: existing.wardName,
          villageName: existing.villageName,
          assignedOfficerId: existing.assignedOfficerId,
          address: existing.address,
          imageUrl: existing.imageUrl,
          resolvedImageUrl: existing.resolvedImageUrl,
          status: existing.status,
          priority: existing.priority,
          createdAt: existing.createdAt,
          resolvedAt: existing.resolvedAt,
          deviceInfo: existing.deviceInfo,
          feedbackRating: rating,
          isClosed: true,
        );
        _complaints[index] = updated;

        final box = Hive.box('local_complaints');
        await box.put(complaintId, updated.toMap());

        notifyListeners();
      }
    }
  }

  // ─── Notifications Logic ─────────────────────────────────────────────────────
  void _loadNotifications() {
    if (_currentUser == null) {
      _notifications = [];
      notifyListeners();
      return;
    }
    // Seed from Hive cache first (offline support)
    final box = Hive.box('local_notifications');
    _notifications =
        box.values
            .map((e) => AppNotification.fromMap(Map<String, dynamic>.from(e)))
            .where((n) => n.userId == _currentUser!.id)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    notifyListeners();

    // Then start Supabase realtime subscription (will overwrite Hive data)
    if (isSupabaseConnected) {
      _startNotificationsStream(_currentUser!.id);
    }
  }

  Future<void> addNotification({
    required String title,
    required String body,
    String? complaintId,
    String? type,
  }) async {
    if (_currentUser == null) return;
    final notif = AppNotification(
      id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
      userId: _currentUser!.id,
      title: title,
      body: body,
      createdAt: DateTime.now(),
      isRead: false,
      complaintId: complaintId,
      type: type,
    );
    _notifications.insert(0, notif);
    final box = Hive.box('local_notifications');
    await box.put(notif.id, notif.toMap());
    notifyListeners();
  }

  /// Add a notification for a specific user (not necessarily the current user).
  /// This is used to notify complaint owners and ward admins.
  Future<void> addNotificationForUser({
    required String userId,
    required String title,
    required String body,
    String? complaintId,
    String? type,
  }) async {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final notif = AppNotification(
      id: 'notif_${ts}_${userId.hashCode}',
      userId: userId,
      title: title,
      body: body,
      createdAt: DateTime.now(),
      isRead: false,
      complaintId: complaintId,
      type: type,
    );
    // Store in Hive so it persists for that user when they log in
    final box = Hive.box('local_notifications');
    await box.put(notif.id, notif.toMap());
    // If the target user is currently logged in, also update live list
    if (_currentUser != null && _currentUser!.id == userId) {
      _notifications.insert(0, notif);
      notifyListeners();
    }
  }

  Future<void> markNotificationAsRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index].isRead = true;
      _notifications[index].readAt = DateTime.now();
      // Persist to Hive cache
      final box = Hive.box('local_notifications');
      await box.put(id, _notifications[index].toMap());
      notifyListeners();
    }
    // Update Supabase (trigger will sync announcement_reads if applicable)
    if (isSupabaseConnected) {
      await SupabaseService.markNotificationRead(id);
    }
  }

  Future<void> markAllNotificationsAsRead() async {
    final box = Hive.box('local_notifications');
    for (var n in _notifications) {
      n.isRead = true;
      n.readAt = DateTime.now();
      await box.put(n.id, n.toMap());
    }
    notifyListeners();
    if (isSupabaseConnected && _currentUser != null) {
      await SupabaseService.markAllNotificationsRead(_currentUser!.id);
    }
  }

  Future<void> clearNotifications() async {
    _notifications.clear();
    final box = Hive.box('local_notifications');
    await box.clear();
    notifyListeners();
  }

  /// Creates a resolve notification for the complaint owner (not the current user).
  void _addNotificationForComplaintOwner(Complaint complaint) {
    addNotificationForUser(
      userId: complaint.userId,
      title: 'Complaint Resolved! 🎉',
      body:
          'Your complaint regarding "${complaint.category}" has been resolved by ${complaint.wardName} officer. Please check and provide your valuable feedback.',
      complaintId: complaint.id,
      type: 'complaint_status',
    );
  }

  // ─── Admin Management ───────────────────────────────────────────────────────
  Future<bool> createWardAdmin({
    required String name,
    required String phone,
    required String password,
    required String wardId,
    String? wardName,
    String? mandalName,
    String? villageName,
    required String postId,
  }) async {
    final String resolvedWardName =
        wardName ??
        (_wards.isNotEmpty
            ? _wards
                  .firstWhere((w) => w.id == wardId, orElse: () => _wards.first)
                  .name
            : 'Ward ${wardId.replaceAll('ward_', '')}');

    if (isSupabaseConnected) {
      // Find existing admins for this ward and delete them
      final existingAdmins = _users
          .where((u) => u.wardId == wardId && u.role == UserRole.wardAdmin)
          .toList();
      for (final oldAdmin in existingAdmins) {
        await SupabaseService.deleteUser(oldAdmin.id);
      }

      final newId = await SupabaseService.createWardAdmin(
        name: name,
        phone: phone,
        password: password,
        wardId: wardId,
        wardName: resolvedWardName,
        mandalName: mandalName,
        villageName: villageName,
        postId: postId,
      );

      if (newId != null) {
        final wardIndex = _wards.indexWhere((w) => w.id == wardId);
        final updatedWard = Ward(
          id: wardId,
          name: resolvedWardName,
          adminId: newId,
          adminName: name,
          centerLatitude: wardIndex != -1
              ? _wards[wardIndex].centerLatitude
              : 0.0,
          centerLongitude: wardIndex != -1
              ? _wards[wardIndex].centerLongitude
              : 0.0,
          minLat: wardIndex != -1 ? _wards[wardIndex].minLat : 0.0,
          maxLat: wardIndex != -1 ? _wards[wardIndex].maxLat : 0.0,
          minLng: wardIndex != -1 ? _wards[wardIndex].minLng : 0.0,
          maxLng: wardIndex != -1 ? _wards[wardIndex].maxLng : 0.0,
        );

        if (wardIndex != -1) {
          _wards[wardIndex] = updatedWard;
        } else {
          // Insert at the top so it appears immediately in the lists
          _wards.insert(0, updatedWard);
        }
        // Optimistically update _users
        _users.insert(
          0,
          User(
            id: newId,
            name: name,
            phoneNumber: phone,
            password: password,
            role: UserRole.wardAdmin,
            wardId: wardId,
            wardName: resolvedWardName,
            mandalName: mandalName,
            villageName: villageName,
            officerRole: postId,
            createdAt: DateTime.now(),
          ),
        );
        notifyListeners();
        return true;
      }
      return false;
    } else {
      if (_users.any((u) => u.phoneNumber == phone)) return false;
      final newAdmin = User(
        id: 'user_admin_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        phoneNumber: phone,
        password: password,
        role: UserRole.wardAdmin,
        wardId: wardId,
        wardName: resolvedWardName,
        mandalName: mandalName,
        villageName: villageName,
        officerRole: postId,
        createdAt: DateTime.now(),
      );
      _users.add(newAdmin);

      final wardIndex = _wards.indexWhere((w) => w.id == wardId);
      if (wardIndex != -1) {
        _wards[wardIndex] = Ward(
          id: _wards[wardIndex].id,
          name: _wards[wardIndex].name,
          adminId: newAdmin.id,
          adminName: newAdmin.name,
          centerLatitude: _wards[wardIndex].centerLatitude,
          centerLongitude: _wards[wardIndex].centerLongitude,
          minLat: _wards[wardIndex].minLat,
          maxLat: _wards[wardIndex].maxLat,
          minLng: _wards[wardIndex].minLng,
          maxLng: _wards[wardIndex].maxLng,
        );
      }
      notifyListeners();
      return true;
    }
  }

  Future<bool> createCategoryOfficer({
    required String name,
    required String phone,
    required String password,
    required String wardId,
    required String officerRole,
    String? mandalName,
    String? villageName,
    String? wardName,
  }) async {
    final String resolvedWardName =
        wardName ??
        (_wards.isNotEmpty
            ? _wards
                  .firstWhere((w) => w.id == wardId, orElse: () => _wards.first)
                  .name
            : 'Ward ${wardId.replaceAll('ward_', '')}');

    if (isSupabaseConnected) {
      final newId = await SupabaseService.createCategoryOfficer(
        name: name,
        phone: phone,
        password: password,
        wardId: wardId,
        wardName: resolvedWardName,
        mandalName: mandalName,
        villageName: villageName,
        officerRole: officerRole,
      );
      if (newId != null) {
        _users.insert(
          0,
          User(
            id: newId,
            name: name,
            phoneNumber: phone,
            password: password,
            role: UserRole.categoryOfficer,
            wardId: wardId,
            wardName: resolvedWardName,
            mandalName: mandalName,
            villageName: villageName,
            officerRole: officerRole,
            createdAt: DateTime.now(),
          ),
        );
        notifyListeners();
      }
      return newId != null;
    } else {
      if (_users.any((u) => u.phoneNumber == phone)) return false;
      final newOfficer = User(
        id: 'user_officer_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        phoneNumber: phone,
        password: password,
        role: UserRole.categoryOfficer,
        wardId: wardId,
        wardName: resolvedWardName,
        mandalName: mandalName,
        villageName: villageName,
        officerRole: officerRole,
        createdAt: DateTime.now(),
      );
      _users.add(newOfficer);
      notifyListeners();
      return true;
    }
  }

  Future<bool> createMandalOfficer({
    required String name,
    required String phone,
    required String password,
    String? mandalName,
    String? villageName,
    required String officerRole,
  }) async {
    if (isSupabaseConnected) {
      final newId = await SupabaseService.createMandalOfficer(
        name: name,
        phone: phone,
        password: password,
        mandalName: mandalName,
        villageName: villageName,
        officerRole: officerRole,
      );
      if (newId != null) {
        _users.insert(
          0,
          User(
            id: newId,
            name: name,
            phoneNumber: phone,
            password: password,
            role: UserRole.mandalOfficer,
            mandalName: mandalName,
            villageName: villageName,
            officerRole: officerRole,
            createdAt: DateTime.now(),
          ),
        );
        notifyListeners();
      }
      return newId != null;
    } else {
      if (_users.any((u) => u.phoneNumber == phone)) return false;
      final newOfficer = User(
        id: 'user_mandal_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        phoneNumber: phone,
        password: password,
        role: UserRole.mandalOfficer,
        mandalName: mandalName,
        villageName: villageName,
        officerRole: officerRole,
        createdAt: DateTime.now(),
      );
      _users.add(newOfficer);
      notifyListeners();
      return true;
    }
  }

  /// Permanently deletes a user (officer/admin) from the system.
  Future<void> deleteUser(String userId) async {
    if (isSupabaseConnected) {
      await SupabaseService.deleteUser(userId);
    }
    _users.removeWhere((u) => u.id == userId);
    notifyListeners();
  }

  /// Updates an existing officer's role without deleting them.
  Future<void> updateOfficerRole(String userId, String newRole) async {
    final index = _users.indexWhere((u) => u.id == userId);
    if (index == -1) return;

    final existing = _users[index];
    final updated = User(
      id: existing.id,
      name: existing.name,
      phoneNumber: existing.phoneNumber,
      password: existing.password,
      role: existing.role,
      wardId: existing.wardId,
      wardName: existing.wardName,
      mandalName: existing.mandalName,
      villageName: existing.villageName,
      officerRole: newRole,
      createdAt: existing.createdAt,
      profilePhotoUrl: existing.profilePhotoUrl,
      profileImageUrl: existing.profileImageUrl,
      fcmToken: existing.fcmToken,
      isEmployed: existing.isEmployed,
      education: existing.education,
    );

    if (isSupabaseConnected) {
      await SupabaseService.updateUser(updated);
    }
    _users[index] = updated;
    notifyListeners();
  }
}
