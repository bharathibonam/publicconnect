import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/mla_broadcast.dart';

class SocialPublisherService {
  static final _supabase = Supabase.instance.client;

  // Stream for logging real HTTP logs live to the screen
  static final StreamController<String> _logController = StreamController<String>.broadcast();
  static Stream<String> get logStream => _logController.stream;

  static void addLog(String message) {
    _logController.add(message);
    debugPrint('[SOCIAL_PUBLISHER] $message');
  }

  /// Securely initiates real platform publications with automatic OAuth token refresh support
  static Future<Map<String, dynamic>> publishToAllPlatforms({
    required MLABroadcast broadcast,
    required List<String> platforms,
  }) async {
    final Map<String, dynamic> results = {};
    addLog('Initiating secure social media publishing pipeline with automatic token refresh...');

    for (var platform in platforms) {
      addLog('\n----------------------------------------');
      addLog('Processing platform: ${platform.toUpperCase()}...');
      
      try {
        // Automatic Token Refresh Check before execution
        await refreshSocialToken(platform);

        Map<String, dynamic> publishResult;
        
        switch (platform) {
          case 'instagram':
            publishResult = await _publishToInstagram(broadcast);
            break;
          case 'youtube':
            publishResult = await _publishToYouTube(broadcast);
            break;
          case 'twitter':
            publishResult = await _publishToX(broadcast);
            break;
          case 'facebook':
            publishResult = await _publishToFacebook(broadcast);
            break;
          default:
            throw Exception('Unsupported platform: $platform');
        }

        // Retry once on HTTP 401 Unauthorized after forcing a refresh
        if (publishResult['success'] == false && publishResult['status_code'] == 401) {
          addLog('Received HTTP 401 (Expired Token). Attempting immediate token refresh and retry...');
          final refreshed = await refreshSocialToken(platform, force: true);
          if (refreshed) {
            addLog('Retrying publishing operation for ${platform.toUpperCase()}...');
            switch (platform) {
              case 'instagram':
                publishResult = await _publishToInstagram(broadcast);
                break;
              case 'youtube':
                publishResult = await _publishToYouTube(broadcast);
                break;
              case 'twitter':
                publishResult = await _publishToX(broadcast);
                break;
              case 'facebook':
                publishResult = await _publishToFacebook(broadcast);
                break;
            }
          }
        }

        results[platform] = publishResult;
        
        // Save publish log to Supabase
        await _savePublishLog(
          broadcastId: broadcast.id,
          platform: platform,
          success: publishResult['success'] == true,
          statusCode: publishResult['status_code'] ?? 500,
          responseBody: publishResult['response_body'] ?? '',
          postId: publishResult['post_id'],
          postUrl: publishResult['post_url'],
          errorMessage: publishResult['error_message'],
        );

        if (publishResult['success'] != true) {
          addLog('❌ [${platform.toUpperCase()}] Publishing Failed: ${publishResult['error_message']}');
        } else {
          addLog('✅ [${platform.toUpperCase()}] Published Successfully! URL: ${publishResult['post_url']}');
        }
      } catch (e) {
        addLog('❌ [${platform.toUpperCase()}] Execution Error: $e');
        results[platform] = {
          'success': false,
          'status_code': 500,
          'error_message': e.toString(),
        };
      }
    }

    return results;
  }

  /// Automatically refreshes OAuth tokens for the given platform
  static Future<bool> refreshSocialToken(String platform, {bool force = false}) async {
    addLog('Checking OAuth token status for ${platform.toUpperCase()}...');
    try {
      final tokenRecord = await _supabase
          .from('mla_social_tokens')
          .select('*')
          .eq('platform', platform)
          .maybeSingle();

      if (tokenRecord == null) {
        addLog('No token credentials record found in database for $platform.');
        return false;
      }

      final DateTime? expiresAt = tokenRecord['expires_at'] != null 
          ? DateTime.tryParse(tokenRecord['expires_at']) 
          : null;
      
      final bool isExpired = expiresAt != null && expiresAt.isBefore(DateTime.now().add(const Duration(minutes: 5)));
      
      if (!isExpired && !force) {
        addLog('Existing access token is still valid. Skipping refresh.');
        return true;
      }

      addLog('Refreshing OAuth access token for ${platform.toUpperCase()}...');
      final String refreshToken = tokenRecord['refresh_token'] ?? '';
      final String clientId = tokenRecord['client_id'] ?? '';
      final String clientSecret = tokenRecord['client_secret'] ?? '';
      final String currentAccessToken = tokenRecord['access_token'] ?? '';

      if (refreshToken.isEmpty && clientId.isEmpty) {
        addLog('Missing refresh token and client secrets. Refresh skipped.');
        return false;
      }

      http.Response response;
      String newAccessToken = '';
      int expiresInSeconds = 3600;

      switch (platform) {
        case 'instagram':
        case 'facebook':
          // Meta Long-Lived Token Refresh Flow
          addLog('GET https://graph.facebook.com/v20.0/oauth/client_code');
          response = await http.get(
            Uri.parse('https://graph.facebook.com/v20.0/oauth/client_code?client_id=$clientId&client_secret=$clientSecret&access_token=$currentAccessToken'),
          );
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            final String code = data['code'] ?? '';
            
            // Exchange code for fresh long-lived token
            response = await http.get(
              Uri.parse('https://graph.facebook.com/v20.0/oauth/access_token?client_id=$clientId&redirect_uri=https://dummy.co&client_secret=$clientSecret&code=$code'),
            );
            if (response.statusCode == 200) {
              final exchangeData = jsonDecode(response.body);
              newAccessToken = exchangeData['access_token'] ?? '';
              expiresInSeconds = exchangeData['expires_in'] ?? 5184000; // 60 days
            }
          }
          break;

        case 'youtube':
          // Google OAuth2 Token Refresh Flow
          addLog('POST https://oauth2.googleapis.com/token');
          response = await http.post(
            Uri.parse('https://oauth2.googleapis.com/token'),
            body: {
              'client_id': clientId,
              if (clientSecret.isNotEmpty) 'client_secret': clientSecret,
              'refresh_token': refreshToken,
              'grant_type': 'refresh_token',
            },
          );
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            newAccessToken = data['access_token'] ?? '';
            expiresInSeconds = data['expires_in'] ?? 3600;
          }
          break;

        case 'twitter':
          // X OAuth2 User Context Refresh Flow
          addLog('POST https://api.twitter.com/2/oauth2/token');
          final basicAuth = 'Basic ' + base64Encode(utf8.encode('$clientId:$clientSecret'));
          response = await http.post(
            Uri.parse('https://api.twitter.com/2/oauth2/token'),
            headers: {
              'Authorization': basicAuth,
              'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: {
              'refresh_token': refreshToken,
              'grant_type': 'refresh_token',
              'client_id': clientId,
            },
          );
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            newAccessToken = data['access_token'] ?? '';
            expiresInSeconds = data['expires_in'] ?? 7200;
            // X also rotates refresh tokens
            final newRefreshToken = data['refresh_token'];
            if (newRefreshToken != null) {
              await _supabase.from('mla_social_tokens').update({
                'refresh_token': newRefreshToken,
              }).eq('platform', platform);
            }
          }
          break;

        default:
          return false;
      }

      if (newAccessToken.isNotEmpty) {
        final newExpiry = DateTime.now().add(Duration(seconds: expiresInSeconds));
        await _supabase.from('mla_social_tokens').update({
          'access_token': newAccessToken,
          'expires_at': newExpiry.toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('platform', platform);
        addLog('Token refreshed successfully. Expires at: $newExpiry');
        return true;
      } else {
        addLog('Token refresh failed. Platform response: ${response.body}');
        return false;
      }
    } catch (e) {
      addLog('Error refreshing token for $platform: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>> _publishToInstagram(MLABroadcast broadcast) async {
    final token = await _getAccessToken('instagram');
    final businessAccountId = await _getAccountId('instagram');
    
    final bool isVideo = broadcast.mediaType == 'reel';
    final mediaUrl = isVideo ? (broadcast.videoUrl ?? '') : (broadcast.photoUrl ?? '');

    if (mediaUrl.isEmpty) {
      return {
        'success': false,
        'status_code': 400,
        'error_message': 'No media URL found for the selected broadcast type.',
      };
    }

    addLog('POST https://graph.facebook.com/v20.0/$businessAccountId/media');
    
    final containerResponse = await http.post(
      Uri.parse('https://graph.facebook.com/v20.0/$businessAccountId/media'),
      body: {
        if (isVideo) 'media_type': 'REELS',
        if (isVideo) 'video_url': mediaUrl,
        if (!isVideo) 'image_url': mediaUrl,
        'caption': broadcast.description,
        'access_token': token,
      },
    );

    addLog('Status Code: ${containerResponse.statusCode}');
    if (containerResponse.statusCode != 200) {
      return _errorMap(containerResponse);
    }

    final containerData = jsonDecode(containerResponse.body);
    final String containerId = containerData['id'];
    addLog('Container ID Created: $containerId');

    bool isFinished = false;
    int polls = 0;
    while (!isFinished && polls < 30) {
      polls++;
      addLog('GET https://graph.facebook.com/v20.0/$containerId?fields=status_code');
      final statusResponse = await http.get(
        Uri.parse('https://graph.facebook.com/v20.0/$containerId?fields=status_code&access_token=$token'),
      );
      
      if (statusResponse.statusCode == 200) {
        final statusData = jsonDecode(statusResponse.body);
        final String statusCode = statusData['status_code'];
        addLog('Container status check $polls: $statusCode');
        if (statusCode == 'FINISHED') {
          isFinished = true;
        } else if (statusCode == 'ERROR') {
          return {
            'success': false,
            'status_code': 400,
            'error_message': 'Instagram media processing failed.',
            'response_body': statusResponse.body,
          };
        }
      }
      await Future.delayed(const Duration(seconds: 3));
    }

    if (!isFinished) {
      return {
        'success': false,
        'status_code': 400,
        'error_message': 'Instagram media encoding timed out. Please try again.',
      };
    }

    addLog('POST https://graph.facebook.com/v20.0/$businessAccountId/media_publish');
    final publishResponse = await http.post(
      Uri.parse('https://graph.facebook.com/v20.0/$businessAccountId/media_publish'),
      body: {
        'creation_id': containerId,
        'access_token': token,
      },
    );

    addLog('Status Code: ${publishResponse.statusCode}');
    if (publishResponse.statusCode != 200) {
      return _errorMap(publishResponse);
    }

    final publishData = jsonDecode(publishResponse.body);
    final String reelId = publishData['id'] ?? '';
    final String reelUrl = 'https://www.instagram.com/reel/$reelId/';

    return {
      'success': true,
      'status_code': 200,
      'post_id': reelId,
      'post_url': reelUrl,
      'response_body': publishResponse.body,
    };
  }

  static Future<Map<String, dynamic>> _publishToYouTube(MLABroadcast broadcast) async {
    final token = await _getAccessToken('youtube');
    final videoUrl = broadcast.videoUrl ?? '';

    if (videoUrl.isEmpty) {
      return {
        'success': false,
        'status_code': 400,
        'error_message': 'No video URL found for YouTube upload.',
      };
    }

    addLog('Downloading video binary from Supabase storage...');
    final videoResponse = await http.get(Uri.parse(videoUrl));
    if (videoResponse.statusCode != 200) {
      return {
        'success': false,
        'status_code': videoResponse.statusCode,
        'error_message': 'Failed to download video asset for YouTube upload.',
      };
    }

    addLog('POST https://www.googleapis.com/upload/youtube/v3/videos?uploadType=multipart&part=snippet,status');
    
    final boundary = 'boundary_smart_gov_${DateTime.now().millisecondsSinceEpoch}';
    final metadata = jsonEncode({
      'snippet': {
        'title': broadcast.title,
        'description': broadcast.description,
        'categoryId': '22',
      },
      'status': {
        'privacyStatus': 'public',
        'selfDeclaredMadeForKids': false,
      }
    });

    final List<int> bodyBytes = [];
    bodyBytes.addAll(utf8.encode('--$boundary\r\n'));
    bodyBytes.addAll(utf8.encode('Content-Type: application/json; charset=UTF-8\r\n\r\n'));
    bodyBytes.addAll(utf8.encode('$metadata\r\n'));
    bodyBytes.addAll(utf8.encode('--$boundary\r\n'));
    bodyBytes.addAll(utf8.encode('Content-Type: video/mp4\r\n\r\n'));
    bodyBytes.addAll(videoResponse.bodyBytes);
    bodyBytes.addAll(utf8.encode('\r\n--$boundary--\r\n'));

    final response = await http.post(
      Uri.parse('https://www.googleapis.com/upload/youtube/v3/videos?uploadType=multipart&part=snippet,status'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'multipart/related; boundary=$boundary',
        'Content-Length': bodyBytes.length.toString(),
      },
      body: bodyBytes,
    );

    addLog('Status Code: ${response.statusCode}');
    if (response.statusCode != 200 && response.statusCode != 201) {
      return _errorMap(response);
    }

    final data = jsonDecode(response.body);
    final String videoId = data['id'] ?? '';
    final String youtubeUrl = 'https://www.youtube.com/watch?v=$videoId';

    return {
      'success': true,
      'status_code': response.statusCode,
      'post_id': videoId,
      'post_url': youtubeUrl,
      'response_body': response.body,
    };
  }

  static Future<Map<String, dynamic>> _publishToX(MLABroadcast broadcast) async {
    final token = await _getAccessToken('twitter');
    
    addLog('POST https://api.twitter.com/2/tweets');
    
    final response = await http.post(
      Uri.parse('https://api.twitter.com/2/tweets'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'text': '${broadcast.title}\n${broadcast.description}\nWatch: ${broadcast.videoUrl ?? ''}',
      }),
    );

    addLog('Status Code: ${response.statusCode}');
    if (response.statusCode != 200 && response.statusCode != 201) {
      return _errorMap(response);
    }

    final data = jsonDecode(response.body);
    final String tweetId = data['data']?['id'] ?? '';
    final String tweetUrl = 'https://twitter.com/mla_updates/status/$tweetId';

    return {
      'success': true,
      'status_code': response.statusCode,
      'post_id': tweetId,
      'post_url': tweetUrl,
      'response_body': response.body,
    };
  }

  static Future<Map<String, dynamic>> _publishToFacebook(MLABroadcast broadcast) async {
    final token = await _getAccessToken('facebook');
    final pageId = await _getAccountId('facebook');

    final String fullCaption = broadcast.title.isNotEmpty && broadcast.description.isNotEmpty
        ? '${broadcast.title}\n\n${broadcast.description}'
        : (broadcast.title.isNotEmpty ? broadcast.title : broadcast.description);

    final bool isVideo = broadcast.mediaType == 'reel' ||
        (broadcast.videoUrl != null &&
            broadcast.videoUrl!.isNotEmpty &&
            broadcast.videoUrl!.toLowerCase().contains('.mp4'));
    final bool isPhoto = !isVideo &&
        (broadcast.photoUrl != null && broadcast.photoUrl!.isNotEmpty);

    if (isVideo) {
      final videoUrl = broadcast.videoUrl ?? '';
      if (videoUrl.isEmpty) {
        return {
          'success': false,
          'status_code': 400,
          'error_message': 'No video URL provided for Facebook video publishing.',
        };
      }

      addLog('POST https://graph.facebook.com/v20.0/$pageId/videos');
      final response = await http.post(
        Uri.parse('https://graph.facebook.com/v20.0/$pageId/videos'),
        body: {
          'file_url': videoUrl,
          'description': fullCaption,
          'access_token': token,
        },
      );

      addLog('Status Code: ${response.statusCode}');
      if (response.statusCode != 200) {
        return _errorMap(response);
      }

      final data = jsonDecode(response.body);
      final String videoId = data['id'] ?? '';
      addLog('Facebook Video ID Created: $videoId');

      // Poll Meta Graph API to ensure video processing completes before returning success
      bool isReady = false;
      int polls = 0;
      String permalinkUrl = '';

      while (!isReady && polls < 20) {
        polls++;
        await Future.delayed(const Duration(seconds: 3));
        addLog('Checking Facebook video processing status (Attempt $polls)...');

        final statusResponse = await http.get(
          Uri.parse(
              'https://graph.facebook.com/v20.0/$videoId?fields=status,permalink_url&access_token=$token'),
        );

        if (statusResponse.statusCode == 200) {
          final statusData = jsonDecode(statusResponse.body);
          final statusMap = statusData['status'];
          if (statusData['permalink_url'] != null &&
              (statusData['permalink_url'] as String).isNotEmpty) {
            permalinkUrl = statusData['permalink_url'];
          }

          if (statusMap != null) {
            final String videoStatus = statusMap['video_status'] ?? '';
            addLog('Facebook video status check $polls: $videoStatus');
            if (videoStatus == 'ready') {
              isReady = true;
            } else if (videoStatus == 'error') {
              return {
                'success': false,
                'status_code': 400,
                'error_message':
                    'Facebook video processing failed on Meta servers.',
                'response_body': statusResponse.body,
              };
            }
          } else {
            isReady = true;
          }
        }
      }

      if (permalinkUrl.startsWith('/')) {
        permalinkUrl = 'https://www.facebook.com$permalinkUrl';
      } else if (permalinkUrl.isEmpty) {
        permalinkUrl = 'https://www.facebook.com/watch/?v=$videoId';
      }

      addLog('✅ [FACEBOOK] Video Published Successfully! URL: $permalinkUrl');

      return {
        'success': true,
        'status_code': 200,
        'post_id': videoId,
        'post_url': permalinkUrl,
        'response_body': response.body,
      };
    } else if (isPhoto) {
      final photoUrl = broadcast.photoUrl ?? '';
      addLog('POST https://graph.facebook.com/v20.0/$pageId/photos');
      final response = await http.post(
        Uri.parse('https://graph.facebook.com/v20.0/$pageId/photos'),
        body: {
          'url': photoUrl,
          'caption': fullCaption,
          'access_token': token,
        },
      );

      addLog('Status Code: ${response.statusCode}');
      if (response.statusCode != 200) {
        return _errorMap(response);
      }

      final data = jsonDecode(response.body);
      final String photoId = data['id'] ?? '';
      final String postId = data['post_id'] ?? photoId;
      final String postUrl = 'https://www.facebook.com/$postId';

      addLog('✅ [FACEBOOK] Photo Published Successfully! URL: $postUrl');

      return {
        'success': true,
        'status_code': 200,
        'post_id': postId,
        'post_url': postUrl,
        'response_body': response.body,
      };
    } else {
      addLog('POST https://graph.facebook.com/v20.0/$pageId/feed');
      final response = await http.post(
        Uri.parse('https://graph.facebook.com/v20.0/$pageId/feed'),
        body: {
          'message': fullCaption,
          'access_token': token,
        },
      );

      addLog('Status Code: ${response.statusCode}');
      if (response.statusCode != 200) {
        return _errorMap(response);
      }

      final data = jsonDecode(response.body);
      final String postId = data['id'] ?? '';
      final String postUrl = 'https://www.facebook.com/$postId';

      addLog('✅ [FACEBOOK] Feed Post Published Successfully! URL: $postUrl');

      return {
        'success': true,
        'status_code': 200,
        'post_id': postId,
        'post_url': postUrl,
        'response_body': response.body,
      };
    }
  }

  static Future<String> _getAccessToken(String platform) async {
    try {
      final res = await _supabase
          .from('mla_social_tokens')
          .select('access_token')
          .eq('platform', platform)
          .maybeSingle();
      return res?['access_token'] ?? 'invalid_token_no_credentials_found';
    } catch (e) {
      return 'invalid_token_error';
    }
  }

  static Future<String> _getAccountId(String platform) async {
    try {
      final res = await _supabase
          .from('mla_social_accounts')
          .select('account_name')
          .eq('platform', platform)
          .maybeSingle();
      return res?['account_name'] ?? 'official_account_id';
    } catch (e) {
      return 'official_account_id';
    }
  }

  static Map<String, dynamic> _errorMap(http.Response response) {
    String message = 'API request failed';
    try {
      final bodyData = jsonDecode(response.body);
      message = bodyData['error']?['message'] ?? bodyData['message'] ?? 'API Error';
    } catch (_) {}

    return {
      'success': false,
      'status_code': response.statusCode,
      'error_message': message,
      'response_body': response.body,
    };
  }

  static Future<void> _savePublishLog({
    required String broadcastId,
    required String platform,
    required bool success,
    required int statusCode,
    required String responseBody,
    String? postId,
    String? postUrl,
    String? errorMessage,
  }) async {
    try {
      await _supabase.from('mla_publish_logs').insert({
        'broadcast_id': broadcastId,
        'request_id': 'req_' + DateTime.now().millisecondsSinceEpoch.toString(),
        'platform': platform,
        'status_code': statusCode,
        'response_body': responseBody,
        'platform_post_id': postId,
        'published_url': postUrl,
        'error_message': errorMessage,
        'completed_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error saving publish log to Supabase: $e');
    }
  }
}
