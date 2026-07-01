import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'dart:io';

import 'package:flutter/foundation.dart';

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
    try {
      final exists = await phoneExists(phone);

      if (exists) return null;


      // simpler way to generate ID:
      final newId = DateTime.now().millisecondsSinceEpoch.toString();

      final newUser = User(
        id: newId,
        name: name,
        phoneNumber: phone,
        password: password,
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

  static Future<void> submitComplaintFeedback(
    String id,
    String rating,
  ) async {
    await _db.from('complaints').update({
      'feedbackRating': rating,
      'isClosed': true,
    }).eq('id', id);
  }

  static Future<void> updateComplaintPriority(
    String id,
    ComplaintPriority priority,
  ) async {
    await _db.from('complaints').update({
      'priority': priority.toString().split('.').last,
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
}
