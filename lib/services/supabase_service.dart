import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../models/complaint.dart';
import '../models/user.dart';
import '../models/ward.dart';
import '../models/broadcast_alert.dart';
import '../models/chat_message.dart';
import '../models/app_config.dart';
import '../models/announcement.dart';
import '../models/announcement_read.dart';
import '../models/work_update.dart';
import '../models/app_notification.dart';
import '../models/completed_work.dart';
import '../models/meeting.dart';
class SupabaseService {
  static SupabaseClient get _db => Supabase.instance.client;

  // ───────────────── CONNECTION CHECK ─────────────────

  static Future<bool> checkConnection() async {
    try {
      // Wards is a seeded table that always exists, making this a reliable health check!
      await _db
          .from('wards')
          .select('id')
          .limit(1)
          .timeout(const Duration(seconds: 15)); // Increased to 15s to prevent cold-start offline drops

      return true;
    } catch (e) {
      debugPrint('Database connection check failed: $e');
      return false;
    }
  }

  // ───────────────── APP CONFIG ─────────────────

  static Future<AppConfig?> getAppConfig(String partyId) async {
    try {
      final data = await _db
          .from('app_config')
          .select()
          .eq('id', partyId)
          .maybeSingle();

      if (data != null) {
        return AppConfig.fromJson(data);
      }
    } catch (e) {
      debugPrint('Error fetching app config: $e');
    }
    return null;
  }

  static Future<void> updateAppConfig(AppConfig config) async {
    try {
      final data = config.toJson();
      data['updatedAt'] = DateTime.now().toIso8601String();
      await _db.from('app_config').upsert(data);
    } catch (e) {
      debugPrint('Error updating app config: $e');
    }
  }

  // ───────────────── WARDS ─────────────────

  static Stream<List<Ward>> streamWards() {
    return _db.from('wards').stream(primaryKey: ['id']).map((List<Map<String, dynamic>> data) {
      return data.map((d) {
        return Ward(
          id: d['id'] as String,
          name: d['name'] as String? ?? '',
          adminId: d['adminId'] as String? ?? '',
          adminName: d['adminName'] as String? ?? '',
          centerLatitude: (d['centerLatitude'] as num? ?? 0.0).toDouble(),
          centerLongitude: (d['centerLongitude'] as num? ?? 0.0).toDouble(),
          minLat: (d['minLat'] as num? ?? 0.0).toDouble(),
          maxLat: (d['maxLat'] as num? ?? 0.0).toDouble(),
          minLng: (d['minLng'] as num? ?? 0.0).toDouble(),
          maxLng: (d['maxLng'] as num? ?? 0.0).toDouble(),
        );
      }).toList();
    });
  }

  static Future<void> seedWardsIfEmpty(List<Ward> wards) async {
    try {
      final response = await _db.from('wards').select('id').limit(1);
      if (response.isEmpty) {
        final List<Map<String, dynamic>> maps = wards.map((w) => {
          'id': w.id,
          'name': w.name,
          'adminId': w.adminId,
          'adminName': w.adminName,
          'centerLatitude': w.centerLatitude,
          'centerLongitude': w.centerLongitude,
          'minLat': w.minLat,
          'maxLat': w.maxLat,
          'minLng': w.minLng,
          'maxLng': w.maxLng,
        }).toList();

        await _db.from('wards').insert(maps);
      }
    } catch (e) {
      debugPrint('Error seeding wards: $e');
    }
  }

  // ───────────────── USERS ─────────────────

  static Future<Map<String, dynamic>?> getUserMapByPhone(String phone) async {
    try {
      final res = await _db.from('users').select().eq('phoneNumber', phone.trim()).limit(1);
      if (res.isNotEmpty) return res.first;
      return null;
    } catch (e) {
      debugPrint('getUserMapByPhone error: $e');
      return null;
    }
  }

  // Returns: User on success, null on failure
  // Throws: Exception with specific message for wrong password vs not found
  static Future<User?> loginUser(
    String phone,
    String password,
  ) async {
    try {
      final trimmedPhone = phone.trim();
      final trimmedPassword = password.trim();

      // Step 1: Find by phone number only
      final phoneResponse = await _db
          .from('users')
          .select()
          .eq('phoneNumber', trimmedPhone)
          .limit(1);

      if (phoneResponse.isEmpty) {
        debugPrint('loginUser: phone $trimmedPhone not found in DB');
        return null;
      }

      // Step 2: Check password
      final userMap = phoneResponse.first;
      final storedPassword = userMap['password']?.toString() ?? '';

      if (storedPassword.trim() != trimmedPassword) {
        debugPrint('loginUser: phone found but password mismatch');
        return null;
      }

      return User.fromMap(userMap);
    } catch (e) {
      debugPrint('loginUser error: $e');
      return null;
    }
  }

  static Future<bool> phoneExists(String phone) async {
    try {
      final response = await _db.from('users').select('id').eq('phoneNumber', phone).limit(1);
      return (response as List).isNotEmpty;
    } catch (e) {
      debugPrint('phoneExists error: $e');
      // If there's an error, assume it exists to prevent creating duplicates just in case,
      // UNLESS it's a network error. But usually, if it fails, returning true blocks creation.
      // But let's return false for now but log it.
      return false;
    }
  }

  static Future<User?> registerUser(
    String name,
    String phone,
    String password,
    bool isEmployed,
    String education,
  ) async {
    final cleanPhone = phone.trim();
    final cleanPassword = password.trim();
    final cleanName = name.trim();

    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(cleanPhone)) return null;
    final hasUpper = RegExp(r'[A-Z]').hasMatch(cleanPassword);
    final hasLower = RegExp(r'[a-z]').hasMatch(cleanPassword);
    final hasDigit = RegExp(r'\d').hasMatch(cleanPassword);
    final hasSpecial = RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(cleanPassword);
    if (cleanPassword.length < 8 || !hasUpper || !hasLower || !hasDigit || !hasSpecial) return null;
    if (cleanName.isEmpty) return null;

    try {
      final exists = await phoneExists(cleanPhone);

      if (exists) return null;

      // simpler way to generate ID:
      final newId = DateTime.now().millisecondsSinceEpoch.toString();

      final newUser = User(
        id: newId,
        name: cleanName,
        phoneNumber: cleanPhone,
        password: cleanPassword,
        role: UserRole.citizen,
        createdAt: DateTime.now(),
        isEmployed: isEmployed,
        education: education,
      );

      await _db.from('users').insert(newUser.toMap());

      return newUser;
    } catch (_) {
      return null;
    }
  }

  static Future<String?> createWardAdmin({
    required String name,
    required String phone,
    required String password,
    required String wardId,
    required String wardName,
    String? mandalName,
    String? villageName,
    required String postId,
  }) async {
    try {
      final exists = await phoneExists(phone);

      if (exists) return null;

      final newId = DateTime.now().millisecondsSinceEpoch.toString();

      await _db.from('users').insert({
        'id': newId,
        'name': name,
        'phoneNumber': phone,
        'password': password,
        'role': 'wardAdmin',
        'wardId': wardId,
        'wardName': wardName,
        'mandalName': mandalName,
        'villageName': villageName,
        'officerRole': postId,
        'createdAt': DateTime.now().toIso8601String(),
      });

      // Upsert the ward, so it dynamically appears across the app
      await _db.from('wards').upsert({
        'id': wardId,
        'name': wardName,
        'adminId': newId,
        'adminName': name,
        'centerLatitude': 0.0,
        'centerLongitude': 0.0,
        'minLat': 0.0,
        'maxLat': 0.0,
        'minLng': 0.0,
        'maxLng': 0.0,
      });

      return newId;
    } catch (e) {
      debugPrint('createWardAdmin error: $e');
      throw Exception(e.toString());
    }
  }

  static Future<String?> createCategoryOfficer({
    required String name,
    required String phone,
    required String password,
    required String wardId,
    required String wardName,
    String? mandalName,
    String? villageName,
    required String officerRole,
  }) async {
    try {
      final exists = await phoneExists(phone);

      if (exists) return null;

      final newId = DateTime.now().millisecondsSinceEpoch.toString();

      await _db.from('users').insert({
        'id': newId,
        'name': name,
        'phoneNumber': phone,
        'password': password,
        'role': 'categoryOfficer',
        'wardId': wardId,
        'wardName': wardName,
        'mandalName': mandalName,
        'villageName': villageName,
        'officerRole': officerRole,
        'createdAt': DateTime.now().toIso8601String(),
      });

      return newId;
    } catch (e) {
      debugPrint('createCategoryOfficer error: $e');
      throw Exception(e.toString());
    }
  }

  static Future<String?> createMandalOfficer({
    required String name,
    required String phone,
    required String password,
    String? mandalName,
    String? villageName,
    required String officerRole,
  }) async {
    try {
      final exists = await phoneExists(phone);

      if (exists) return null;

      final newId = DateTime.now().millisecondsSinceEpoch.toString();

      await _db.from('users').insert({
        'id': newId,
        'name': name,
        'phoneNumber': phone,
        'password': password,
        'role': 'mandalOfficer',
        'mandalName': mandalName,
        'villageName': villageName,
        'officerRole': officerRole,
        'createdAt': DateTime.now().toIso8601String(),
      });

      return newId;
    } catch (e) {
      debugPrint('createMandalOfficer error: $e');
      throw Exception(e.toString());
    }
  }

  static Future<void> deleteUser(String userId) async {
    try {
      await _db.from('users').delete().eq('id', userId);
    } catch (e) {
      debugPrint('Error deleting user: $e');
    }
  }

  static Future<void> updateUser(User user) async {
    try {
      await _db.from('users').update(user.toMap()).eq('id', user.id);
    } catch (e) {
      debugPrint('Error updating user: $e');
    }
  }

  static Stream<List<User>> streamUsers() {
    return _db.from('users').stream(primaryKey: ['id']).map((List<Map<String, dynamic>> data) {
      return data.map((d) => User.fromMap(d)).toList();
    });
  }

  static Future<void> seedUsersIfEmpty(List<User> users) async {
    try {
      final response = await _db.from('users').select('id').limit(1);

      if (response.isEmpty) {
        final maps = users.map((u) => u.toMap()).toList();
        await _db.from('users').insert(maps);
      }
    } catch (e) {
      debugPrint('Error seeding users: $e');
    }
  }

  // ───────────────── COMPLAINTS ─────────────────

  static Stream<List<Complaint>> streamComplaints() {
    return _db
        .from('complaints')
        .stream(primaryKey: ['id'])
        .order('createdAt')
        .map((List<Map<String, dynamic>> data) {
      // Map and sort locally to simulate descending order since stream.order is ascending by default for realtime
      var list = data.map((d) => Complaint.fromMap(d)).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  static Future<void> submitComplaint(
    Complaint complaint,
  ) async {
    // Dynamically upsert the ward to prevent Foreign Key constraint crashes
    // when citizens type in new/unregistered wards.
    await _db.from('wards').upsert({
      'id': complaint.wardId,
      'name': complaint.wardName,
      'centerLatitude': 0.0,
      'centerLongitude': 0.0,
      'minLat': 0.0,
      'maxLat': 0.0,
      'minLng': 0.0,
      'maxLng': 0.0,
    });

    try {
      await _db.from('complaints').upsert(complaint.toMap());
    } on PostgrestException catch (e) {
      if (e.code == '23503' && e.message.contains('assignedOfficerId')) {
        // The assigned officer ID does not exist in the users table (stale cache).
        // Nullify it and retry!
        final map = complaint.toMap();
        map['assignedOfficerId'] = null;
        await _db.from('complaints').upsert(map);
      } else {
        rethrow;
      }
    }
  }

  static Future<void> updateComplaintStatus(
    String id,
    ComplaintStatus status, {
    String? resolvedImageUrl,
  }) async {
    final data = <String, dynamic>{
      'status': status.toString().split('.').last,
    };

    if (status == ComplaintStatus.resolved) {
      data['resolvedAt'] = DateTime.now().toIso8601String();

      if (resolvedImageUrl != null) {
        data['resolvedImageUrl'] = resolvedImageUrl;
      }
    }

    await _db.from('complaints').update(data).eq('id', id);
  }

  static Future<Map<String, dynamic>?> getComplaintById(String id) async {
    try {
      final res = await _db.from('complaints').select().eq('id', id).maybeSingle();
      return res;
    } catch (e) {
      debugPrint('getComplaintById error: $e');
      return null;
    }
  }

  static Future<void> submitComplaintFeedback(
    String id,
    String rating,
  ) async {
    await _db.from('complaints').update({
      'feedbackRating': rating,
      'isClosed': true,
    }).eq('id', id);
  }

  static Future<void> escalateComplaintInDb(String complaintId, String pushedTo) async {
    try {
      await _db.from('complaints').update({
        'isPushed': true,
        'pushedTo': pushedTo,
        'status': 'inProgress',
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', complaintId);
    } catch (e) {
      debugPrint('escalateComplaintInDb error: $e');
    }
  }

  static Future<void> updateComplaintPriority(
    String id,
    ComplaintPriority priority,
  ) async {
    await _db.from('complaints').update({
      'priority': priority.toString().split('.').last,
    }).eq('id', id);
  }

  static Future<void> forwardComplaint(
    String id,
    String targetRole,
  ) async {
    await _db.from('complaints').update({
      'isPushed': true,
      'pushedTo': targetRole,
    }).eq('id', id);
  }

  static Future<void> escalateComplaint(
    String id,
    String targetRole,
  ) async {
    await _db.from('complaints').update({
      'isPushed': true,
      'pushedTo': targetRole,
      'priority': 'high',
    }).eq('id', id);
  }

  static Future<void> seedComplaintsIfEmpty(
    List<Complaint> complaints,
  ) async {
    try {
      final response = await _db.from('complaints').select('id').limit(1);

      if (response.isEmpty) {
        final maps = complaints.map((c) => c.toMap()).toList();
        await _db.from('complaints').insert(maps);
      }
    } catch (e) {
      debugPrint('Error seeding complaints: $e');
    }
  }

  // ───────────────── IMAGE UPLOAD & STORAGE ─────────────────

  static Future<String?> _uploadFileToStorage(
    File file,
    String bucketName,
    String destinationPath,
    String contentType,
  ) async {
    if (!file.existsSync()) {
      debugPrint('[STORAGE] File does not exist locally: ${file.path}');
      return null;
    }

    final size = file.lengthSync();
    debugPrint('[STORAGE] File size to upload: $size bytes');
    if (size == 0) {
      debugPrint('[STORAGE] Warning: Local file is empty! Aborting upload.');
      return null;
    }

    try {
      final storage = _db.storage.from(bucketName);
      await storage.upload(
        destinationPath,
        file,
        fileOptions: FileOptions(upsert: true, contentType: contentType),
      );
      
      final url = storage.getPublicUrl(destinationPath);
      debugPrint('[STORAGE] Upload succeeded. URL: $url');
      return url;
    } catch (e) {
      debugPrint('[STORAGE] Error uploading to Supabase: $e');
      return null;
    }
  }

  static Future<String?> _uploadBytesToStorage(
    Uint8List bytes,
    String bucketName,
    String destinationPath,
    String contentType,
  ) async {
    try {
      final storage = _db.storage.from(bucketName);
      await storage.uploadBinary(
        destinationPath,
        bytes,
        fileOptions: FileOptions(upsert: true, contentType: contentType),
      );
      
      final url = storage.getPublicUrl(destinationPath);
      debugPrint('[STORAGE] Upload bytes succeeded. URL: $url');
      return url;
    } catch (e) {
      debugPrint('[STORAGE] Error uploading bytes to Supabase: $e');
      return null;
    }
  }

  static Future<String?> uploadComplaintImage(
    File imageFile,
    String complaintId,
  ) async {
    return _uploadFileToStorage(
      imageFile,
      'complaints',
      '$complaintId/image.jpg',
      'image/jpeg',
    );
  }

  static Future<String?> uploadComplaintBytes(
    Uint8List bytes,
    String complaintId, {
    bool isVideo = false,
  }) async {
    return _uploadBytesToStorage(
      bytes,
      'complaints',
      '$complaintId/evidence.${isVideo ? 'mp4' : 'jpg'}',
      isVideo ? 'video/mp4' : 'image/jpeg',
    );
  }

  static Future<String?> uploadComplaintBytesCustom(
    Uint8List bytes,
    String destinationPath,
    String contentType,
  ) async {
    return _uploadBytesToStorage(
      bytes,
      'complaints',
      destinationPath,
      contentType,
    );
  }

  static Future<String?> uploadResolvedComplaintImage(
    File imageFile,
    String complaintId,
  ) async {
    return _uploadFileToStorage(
      imageFile,
      'complaints',
      '$complaintId/resolved_image.jpg',
      'image/jpeg',
    );
  }

  static Future<String?> uploadProfileImage(
    File imageFile,
    String userId,
  ) async {
    return _uploadFileToStorage(
      imageFile,
      'profiles',
      '$userId/profile.jpg',
      'image/jpeg',
    );
  }

  static Future<String?> uploadProfileImageBytes(
    Uint8List bytes,
    String userId,
  ) async {
    return _uploadBytesToStorage(
      bytes,
      'profiles',
      '$userId/profile.jpg',
      'image/jpeg',
    );
  }

  static Future<String?> uploadBroadcastAudio(
    File audioFile,
    String broadcastId,
  ) async {
    return _uploadFileToStorage(
      audioFile,
      'broadcast_audio',
      '$broadcastId.wav',
      'audio/wav',
    );
  }

  static Future<String?> uploadAppAssetImage(
    File imageFile,
    String assetName,
  ) async {
    return _uploadFileToStorage(
      imageFile,
      'app_assets',
      '$assetName.jpg',
      'image/jpeg',
    );
  }

  static Future<String?> uploadAppAssetImageBytes(
    Uint8List bytes,
    String assetName,
  ) async {
    return _uploadBytesToStorage(
      bytes,
      'app_assets',
      '$assetName.jpg',
      'image/jpeg',
    );
  }

  // ───────────────── BROADCASTS ─────────────────

  static Stream<List<BroadcastAlert>> streamBroadcasts() {
    return _db
        .from('broadcast_alerts')
        .stream(primaryKey: ['id'])
        .order('createdAt')
        .map((List<Map<String, dynamic>> data) {
      var list = data.map((d) => BroadcastAlert.fromMap(d)).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  static Future<void> submitBroadcast(BroadcastAlert alert) async {
    await _db
        .from('broadcast_alerts')
        .upsert(alert.toMap());
  }

  static Future<void> seedBroadcastsIfEmpty(List<BroadcastAlert> alerts) async {
    try {
      final response = await _db.from('broadcast_alerts').select('id').limit(1);
      if (response.isEmpty) {
        final maps = alerts.map((a) => a.toMap()).toList();
        await _db.from('broadcast_alerts').insert(maps);
      }
    } catch (e) {
      debugPrint('Error seeding broadcasts: $e');
    }
  }

  static Future<void> deleteBroadcast(String id) async {
    await _db.from('broadcast_alerts').delete().eq('id', id);
  }

  // ───────────────── CHAT ─────────────────

  static Stream<List<ChatMessage>> streamChatMessages(String complaintId) {
    return _db
        .from('chat_messages')
        .stream(primaryKey: ['id'])
        .eq('complaintId', complaintId)
        .order('createdAt', ascending: true)
        .map((List<Map<String, dynamic>> data) {
      return data.map((d) => ChatMessage.fromMap(d)).toList();
    });
  }

  static Future<void> sendMessage(ChatMessage message) async {
    await _db.from('chat_messages').insert(message.toMap());
    
    // Upsert complaint_chat metadata
    try {
      await _db.from('complaint_chats').upsert({
        'id': 'chat_${message.complaintId}',
        'complaint_id': message.complaintId,
        'last_message_at': message.createdAt.toUtc().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error upserting complaint_chat: $e');
    }
  }

  static Future<void> markMessagesAsRead(String complaintId, String userId) async {
    // No-op as is_read column is not present in supabase schema
  }

  // ───────────────── ANNOUNCEMENTS ─────────────────

  static Future<String?> uploadAnnouncementImageBytes(Uint8List bytes, String announcementId) async {
    return _uploadBytesToStorage(bytes, 'government-files', 'announcements/images/$announcementId.jpg', 'image/jpeg');
  }

  static Future<String?> uploadAnnouncementVoiceBytes(Uint8List bytes, String announcementId) async {
    return _uploadBytesToStorage(bytes, 'government-files', 'announcements/voice/$announcementId.m4a', 'audio/mp4');
  }

  static Future<String?> uploadAnnouncementPdfBytes(Uint8List bytes, String announcementId) async {
    return _uploadBytesToStorage(bytes, 'government-files', 'announcements/pdf/$announcementId.pdf', 'application/pdf');
  }

  static Stream<List<Announcement>> streamAnnouncements() {
    return _db
        .from('announcements')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((List<Map<String, dynamic>> data) {
      return data.map((d) => Announcement.fromMap(d)).toList();
    });
  }

  /// Inserts announcement into Supabase.
  /// The PostgreSQL trigger auto_create_announcement_notifications handles
  /// bulk notification creation — Flutter must NOT insert notifications manually.
  static Future<void> createAnnouncement(Announcement announcement) async {
    await _db.from('announcements').insert(announcement.toMap());
  }

  static Future<Announcement?> getAnnouncementById(String id) async {
    try {
      final data = await _db
          .from('announcements')
          .select()
          .eq('id', id)
          .maybeSingle();
      if (data != null) return Announcement.fromMap(data);
    } catch (e) {
      debugPrint('getAnnouncementById error: $e');
    }
    return null;
  }

  static Future<void> markAnnouncementAsRead(AnnouncementRead readData) async {
    try {
      await _db.from('announcement_reads').upsert(readData.toMap());
    } catch (e) {
      debugPrint('Error marking announcement as read: $e');
    }
  }

  static Future<int> getAnnouncementReadCount(String announcementId) async {
    try {
      final response = await _db
          .from('announcement_reads')
          .select('id')
          .eq('announcement_id', announcementId);
      return (response as List).length;
    } catch (e) {
      debugPrint('Error getting read count: $e');
      return 0;
    }
  }

  /// Returns broadcast history with read statistics for a sender.
  /// Uses the v_broadcast_stats view for efficient server-side aggregation.
  static Future<List<Map<String, dynamic>>> getBroadcastStats(String senderId) async {
    try {
      final response = await _db
          .from('v_broadcast_stats')
          .select()
          .eq('sender_id', senderId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('getBroadcastStats error: $e');
      return [];
    }
  }

  // ───────────────── REALTIME NOTIFICATIONS ─────────────────

  /// Streams notifications for the logged-in user from Supabase in real-time.
  /// The DB trigger populates this table; Flutter only reads it.
  static Stream<List<AppNotification>> streamNotificationsForUser(String userId) {
    return _db
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('userId', userId)
        .order('createdAt', ascending: false)
        .map((List<Map<String, dynamic>> data) {
      return data.map((d) => AppNotification.fromMap(d)).toList();
    });
  }

  /// Marks a single notification as read in Supabase.
  /// The DB trigger sync_announcement_reads_on_read will automatically
  /// upsert into announcement_reads if it's an announcement notification.
  static Future<void> markNotificationRead(String notifId) async {
    try {
      await _db.from('notifications').update({
        'isRead': true,
        'read_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', notifId);
    } catch (e) {
      debugPrint('markNotificationRead error: $e');
    }
  }

  /// Marks all unread notifications for a user as read.
  static Future<void> markAllNotificationsRead(String userId) async {
    try {
      await _db.from('notifications').update({
        'isRead': true,
        'read_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('userId', userId).eq('isRead', false);
    } catch (e) {
      debugPrint('markAllNotificationsRead error: $e');
    }
  }

  // ───────────────── ANNOUNCEMENT MEDIA UPLOADS ─────────────────

  static Future<String?> uploadAnnouncementImage(
    File imageFile,
    String announcementId,
  ) async {
    return _uploadFileToStorage(
      imageFile,
      'government-files',
      'announcements/images/$announcementId.jpg',
      'image/jpeg',
    );
  }

  static Future<String?> uploadAnnouncementVoice(
    File voiceFile,
    String announcementId,
  ) async {
    return _uploadFileToStorage(
      voiceFile,
      'government-files',
      'announcements/voice/$announcementId.m4a',
      'audio/m4a',
    );
  }

  static Future<String?> uploadAnnouncementPdf(
    File pdfFile,
    String announcementId,
  ) async {
    return _uploadFileToStorage(
      pdfFile,
      'government-files',
      'announcements/pdf/$announcementId.pdf',
      'application/pdf',
    );
  }

  // ───────────────── WARD UPDATES ─────────────────

  static Stream<List<WorkUpdate>> streamWardUpdates() {
    return _db
        .from('ward_updates')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((List<Map<String, dynamic>> data) {
      return data.map((d) => WorkUpdate.fromMap(d)).toList();
    });
  }

  static Future<void> submitWorkUpdate(WorkUpdate update) async {
    try {
      await _db.from('ward_updates').upsert(update.toMap());
    } catch (e) {
      debugPrint('Error submitting work update: $e');
      rethrow;
    }
  }

  static Future<String?> uploadWorkUpdateImage(
    File imageFile,
    String updateId,
    int index,
  ) async {
    return _uploadFileToStorage(
      imageFile,
      'work_updates',
      '$updateId/image_$index.jpg',
      'image/jpeg',
    );
  }

  // ───────────────── COMPLETED WORKS ─────────────────

  static Stream<List<CompletedWork>> streamCompletedWorks() {
    return _db
        .from('completed_works')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((List<Map<String, dynamic>> data) {
      return data.map((d) => CompletedWork.fromMap(d)).toList();
    });
  }

  static Future<void> submitCompletedWork(CompletedWork work) async {
    try {
      await _db.from('completed_works').upsert(work.toMap());
    } catch (e) {
      debugPrint('Error submitting completed work: $e');
      rethrow;
    }
  }

  static Future<String?> uploadCompletedWorkBytes(
    Uint8List bytes,
    String workId,
    String type, // 'before', 'after', 'video', 'pdf', 'voice'
    String extension,
    String mimeType,
  ) async {
    return _uploadBytesToStorage(
      bytes,
      'completed-works',
      '$type/${workId}_$type.$extension',
      mimeType,
    );
  }

  // ───────────────── NOTIFICATIONS (Flutter-created — for non-announcement types) ─────────────────

  /// Used ONLY for complaint-resolved and ward-update notifications.
  /// Announcement notifications are created automatically by PostgreSQL trigger.
  static Future<void> batchInsertNotifications(List<AppNotification> notifications) async {
    if (notifications.isEmpty) return;
    try {
      final maps = notifications.map((n) => n.toMap()).toList();
      await _db.from('notifications').insert(maps);
    } catch (e) {
      debugPrint('Error batch inserting notifications: $e');
    }
  }

  // ───────────────── MEETINGS ─────────────────
  
  static Future<Meeting> createMeeting(Meeting meeting) async {
    final Map<String, dynamic> meetingData = meeting.toJson();
    meetingData.remove('id'); // DB will generate it
    
    final response = await _db.from('meetings').insert(meetingData).select().single();
    final newMeeting = Meeting.fromJson(response);
    
    // Insert targets
    if (meeting.targetRoles.isNotEmpty) {
      final targets = meeting.targetRoles.map((role) => {
        'meeting_id': newMeeting.id,
        'target_role': role,
      }).toList();
      await _db.from('meeting_targets').insert(targets);
      
      // Also create notifications for the target roles
      // Usually you'd do this via a trigger, but if we want it here:
      final List<Map<String, dynamic>> notifications = [];
      // Fetch users belonging to targetRoles to send notification to them.
      // (This is a simplified approach; a real app might use a trigger or Edge Function)
      // Since it's requested to create push notifications exactly like Broadcast, 
      // we'll rely on the existing batchInsertNotifications.
      final dateStr = DateFormat('MMM dd, yyyy').format(newMeeting.date);
      final venueStr = (newMeeting.venue != null && newMeeting.venue!.isNotEmpty) ? ' | Venue: ${newMeeting.venue}' : '';
      final bodyStr = '${newMeeting.title}\nDate: $dateStr | Time: ${newMeeting.startTime}$venueStr';

      final usersResponse = await _db.from('users').select('id, role');
      for (var u in usersResponse) {
        if (meeting.targetRoles.contains('All Users') || meeting.targetRoles.any((r) => SupabaseService._matchRole(r, u['role'].toString()))) {
          notifications.add({
            'id': 'notif_${DateTime.now().millisecondsSinceEpoch}_${u['id'].hashCode}',
            'userId': u['id'],
            'title': 'New Meeting Scheduled',
            'body': bodyStr,
            'type': 'meeting',
            'reference_id': newMeeting.id,
            'isRead': false,
            'createdAt': DateTime.now().toUtc().toIso8601String()
          });
        }
      }
      if (notifications.isNotEmpty) {
        await _db.from('notifications').insert(notifications);
      }
    }
    
    return Meeting(
      id: newMeeting.id,
      title: newMeeting.title,
      date: newMeeting.date,
      startTime: newMeeting.startTime,
      endTime: newMeeting.endTime,
      createdBy: newMeeting.createdBy,
      createdAt: newMeeting.createdAt,
      description: newMeeting.description,
      purpose: newMeeting.purpose,
      venue: newMeeting.venue,
      meetLink: newMeeting.meetLink,
      location: newMeeting.location,
      agenda: newMeeting.agenda,
      attachmentUrl: newMeeting.attachmentUrl,
      imageUrl: newMeeting.imageUrl,
      priority: newMeeting.priority,
      isReminderEnabled: newMeeting.isReminderEnabled,
      status: newMeeting.status,
      targetRoles: meeting.targetRoles,
    );
  }

  static Future<List<Meeting>> fetchMeetings(String userId, String userRole) async {
    final List<Map<String, dynamic>> response = await _db
        .from('meetings')
        .select('*, meeting_targets(target_role)')
        .order('date', ascending: true);
        
    final allMeetings = response.map((json) => Meeting.fromJson(json)).toList();
    
    if (userRole.toLowerCase() == 'superadmin' || userRole.toLowerCase() == 'super admin') return allMeetings;
    
    return allMeetings.where((m) {
      return m.createdBy == userId || 
             m.targetRoles.any((r) => SupabaseService._matchRole(r, userRole)) ||
             m.targetRoles.contains('All Users');
    }).toList();
  }
  
  static Stream<List<Meeting>> streamMeetings(String userId, String userRole) {
    return _db.from('meetings').stream(primaryKey: ['id']).order('date', ascending: true).asyncMap((event) async {
      // Need to fetch targets and attendance since stream doesn't join
      final targetsResponse = await _db.from('meeting_targets').select();
      final attendanceResponse = await _db.from('meeting_attendance').select();
      
      return event.map((json) {
        final meetingId = json['id'] as String;
        final meetingTargets = targetsResponse.where((t) => t['meeting_id'] == meetingId).toList();
        final meetingAttendance = attendanceResponse.where((a) => a['meeting_id'] == meetingId).toList();
        json['meeting_targets'] = meetingTargets;
        json['meeting_attendance'] = meetingAttendance;
        return Meeting.fromJson(json);
      }).where((m) {
        if (userRole.toLowerCase() == 'superadmin' || userRole.toLowerCase() == 'super admin') return true;
        return m.createdBy == userId || 
               m.targetRoles.any((r) => SupabaseService._matchRole(r, userRole)) ||
               m.targetRoles.contains('All Users');
      }).toList();
    });
  }

  static Future<void> updateMeeting(Meeting meeting) async {
    final Map<String, dynamic> meetingData = meeting.toJson();
    meetingData.remove('id'); // don't update ID
    
    await _db.from('meetings').update(meetingData).eq('id', meeting.id);
    
    // update targets
    await _db.from('meeting_targets').delete().eq('meeting_id', meeting.id);
    if (meeting.targetRoles.isNotEmpty) {
      final targets = meeting.targetRoles.map((role) => {
        'meeting_id': meeting.id,
        'target_role': role,
      }).toList();
      await _db.from('meeting_targets').insert(targets);
    }
  }

  static Future<void> deleteMeeting(String meetingId) async {
    await _db.from('meetings').delete().eq('id', meetingId);
  }

  static Future<void> updateMeetingStatus(String meetingId, String status, {List<String>? targetRoles, String? meetingTitle}) async {
    await _db.from('meetings').update({'status': status, 'updated_at': DateTime.now().toUtc().toIso8601String()}).eq('id', meetingId);

    if (targetRoles != null && meetingTitle != null && (status == 'cancelled' || status == 'completed')) {
      final List<Map<String, dynamic>> notifications = [];
      final usersResponse = await _db.from('users').select('id, role');
      
      final title = status == 'cancelled' ? 'Meeting Cancelled' : 'Meeting Completed';
      final body = status == 'cancelled' ? 'The meeting "$meetingTitle" has been cancelled.' : 'The meeting "$meetingTitle" has been marked as completed.';
      
      for (var u in usersResponse) {
        if (targetRoles.contains('All Users') || targetRoles.any((r) => SupabaseService._matchRole(r, u['role'].toString()))) {
          notifications.add({
            'id': 'notif_${DateTime.now().millisecondsSinceEpoch}_${u['id'].hashCode}',
            'userId': u['id'],
            'title': title,
            'body': body,
            'type': 'meeting',
            'reference_id': meetingId,
            'isRead': false,
            'createdAt': DateTime.now().toUtc().toIso8601String()
          });
        }
      }
      
      if (notifications.isNotEmpty) {
        await _db.from('notifications').insert(notifications);
      }
    }
  }

  static Future<void> updateMeetingAttendance(String meetingId, String userId, String status) async {
    final response = await _db.from('meeting_attendance').select().eq('meeting_id', meetingId).eq('user_id', userId).maybeSingle();
    
    if (response != null) {
      await _db.from('meeting_attendance').update({
        'status': status,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', response['id']);
    } else {
      await _db.from('meeting_attendance').insert({
        'meeting_id': meetingId,
        'user_id': userId,
        'status': status,
      });
    }
    
    // Touch the meeting to trigger a realtime update on the meetings stream
    await _db.from('meetings').update({'updated_at': DateTime.now().toUtc().toIso8601String()}).eq('id', meetingId);
  }

  static Future<String?> uploadMeetingAttachment(File file, String filename) async {
    try {
      final ext = file.path.split('.').last;
      final uniqueName = '${filename}_${DateTime.now().millisecondsSinceEpoch}.$ext';
      await _db.storage.from('app_assets').upload('meetings/$uniqueName', file);
      return _db.storage.from('app_assets').getPublicUrl('meetings/$uniqueName');
    } catch (e) {
      debugPrint('Error uploading meeting attachment: $e');
      return null;
    }
  }

  static String normalizeRole(String role) {
    String normalized = role.trim().toLowerCase().replaceAll(' ', '').replaceAll('_', '');
    if (normalized == 'wardadmin') return 'wardmember';
    return normalized;
  }

  static bool _matchRole(String targetRole, String userRole) {
    if (targetRole.toLowerCase().replaceAll(' ', '') == 'allusers') return true;
    return normalizeRole(targetRole) == normalizeRole(userRole);
  }

  static Future<void> createNotifications(List<Map<String, dynamic>> notifications) async {
    try {
      await _db.from('notifications').insert(notifications);
    } catch (e) {
      debugPrint('Error creating notifications: $e');
    }
  }

  // ───────────────── ELECTION RESULTS ─────────────────

  /// Fetch election results for polling stations in Rajahmundry.
  /// Optionally filter by [assemblySegment] (e.g. 'Gopalapuram', 'Kovvur', 'Rajahmundry Rural').
  static Future<List<Map<String, dynamic>>> getElectionResults({String? assemblySegment}) async {
    try {
      var query = _db.from('election_results').select('*');
      if (assemblySegment != null && assemblySegment.isNotEmpty && assemblySegment != 'ALL') {
        final cleanSeg = assemblySegment.replaceAll(RegExp(r'^\d+\s*'), '').trim();
        query = query.or('assembly_segment.ilike.%$cleanSeg%,assembly_segment_code.ilike.%$cleanSeg%');
      }
      final response = await query.range(0, 5000).order('polling_station_number', ascending: true);
      return List<Map<String, dynamic>>.from(response);


    } catch (e) {
      debugPrint('Error fetching election results: $e');
      return [];
    }
  }
}

