import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/app_state.dart';
import '../../models/mla_broadcast.dart';
import '../../themes/theme_provider.dart';
import '../../l10n/app_localizations.dart';

class MLAUpdatesFeed extends StatefulWidget {
  const MLAUpdatesFeed({super.key});

  @override
  State<MLAUpdatesFeed> createState() => _MLAUpdatesFeedState();
}

class _MLAUpdatesFeedState extends State<MLAUpdatesFeed> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final themeConfig = Provider.of<ThemeProvider>(context).activeParty;
    final loc = AppLocalizations.of(context);
    final broadcasts = appState.mlaBroadcasts;

    final reels = broadcasts.where((b) => b.type == BroadcastMediaType.reel).toList();
    final photos = broadcasts.where((b) => b.type == BroadcastMediaType.photo).toList();
    final documents = broadcasts.where((b) => b.type == BroadcastMediaType.document).toList();

    final titleText = loc?.mlaUpdatesAndReels ?? 'MLA Updates & Reels';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          titleText,
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: const BackButton(color: Color(0xFF0F172A)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: themeConfig.primaryColor,
          unselectedLabelColor: Colors.grey.shade600,
          indicatorColor: themeConfig.primaryColor,
          indicatorWeight: 3,
          tabs: const [
            Tab(icon: Icon(Icons.video_library), text: 'Reels'),
            Tab(icon: Icon(Icons.photo_library), text: 'Photos'),
            Tab(icon: Icon(Icons.description), text: 'GOs / Docs'),
          ],
        ),
      ),
      body: Container(
        color: Colors.white,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildReelsView(reels, themeConfig.primaryColor),
            _buildPhotosView(photos, themeConfig.primaryColor),
            _buildDocsView(documents, themeConfig.primaryColor),
          ],
        ),
      ),
    );
  }

  Widget _buildReelsView(List<MLABroadcast> reels, Color primaryColor) {
    if (reels.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.video_library_outlined, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text('No reels uploaded yet.', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
          ],
        ),
      );
    }

    return Container(
      color: Colors.white,
      child: PageView.builder(
        scrollDirection: Axis.vertical,
        itemCount: reels.length,
        itemBuilder: (context, index) {
          final reel = reels[index];
          return ReelPlayerWidget(reel: reel);
        },
      ),
    );
  }

  Widget _buildPhotosView(List<MLABroadcast> photos, Color primaryColor) {
    if (photos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library_outlined, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text('No photos uploaded yet.', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
          ],
        ),
      );
    }

    return Container(
      color: Colors.white,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.8,
        ),
        itemCount: photos.length,
        itemBuilder: (context, index) {
          final photo = photos[index];
          return Card(
            elevation: 2,
            color: Colors.white,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  photo.mediaUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, _, __) => Container(
                    color: Colors.grey.shade100,
                    child: Icon(Icons.image, color: Colors.grey.shade400, size: 40),
                  ),
                ),
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.8),
                          Colors.black.withOpacity(0.0),
                        ],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          photo.title,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (photo.description.isNotEmpty)
                          Text(
                            photo.description,
                            style: const TextStyle(color: Colors.white70, fontSize: 10),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDocsView(List<MLABroadcast> docs, Color primaryColor) {
    if (docs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.description_outlined, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text('No government orders or documents uploaded yet.', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
          ],
        ),
      );
    }

    return Container(
      color: Colors.white,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: docs.length,
        itemBuilder: (context, index) {
          final doc = docs[index];
          return Card(
            color: Colors.white,
            elevation: 1,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.picture_as_pdf, color: Color(0xFFEF4444)),
              ),
              title: Text(
                doc.title,
                style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 14),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(doc.description, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  if (doc.syndicatedPlatforms.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: doc.syndicatedPlatforms.map((p) {
                        return Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            p,
                            style: TextStyle(color: primaryColor, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
              trailing: IconButton(
                icon: const Icon(Icons.download, color: Colors.green),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Downloading: ${doc.title}...')),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class ReelPlayerWidget extends StatefulWidget {
  final MLABroadcast reel;
  const ReelPlayerWidget({super.key, required this.reel});

  @override
  State<ReelPlayerWidget> createState() => _ReelPlayerWidgetState();
}

class _ReelPlayerWidgetState extends State<ReelPlayerWidget> {
  VideoPlayerController? _controller;
  bool _isPlaying = false;
  bool _isError = false;
  bool _liked = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
    _checkLikedState();
  }

  void _checkLikedState() async {
    final appState = Provider.of<AppState>(context, listen: false);
    final isLiked = await appState.isMLABroadcastLiked(widget.reel.id);
    if (mounted) {
      setState(() {
        _liked = isLiked;
      });
    }
  }

  void _showCommentsSheet(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final commentController = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return FutureBuilder<List<Map<String, dynamic>>>(
              future: appState.fetchCommentsForMLABroadcast(widget.reel.id),
              builder: (context, snapshot) {
                final comments = snapshot.data ?? [];
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Comments (${comments.length})',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                        const Divider(),
                        Expanded(
                          child: comments.isEmpty
                              ? const Center(child: Text('No comments yet. Be the first to comment!'))
                              : ListView.builder(
                                  itemCount: comments.length,
                                  itemBuilder: (context, idx) {
                                    final c = comments[idx];
                                    final date = c['created_at'] != null ? DateTime.parse(c['created_at']) : DateTime.now();
                                    return ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: CircleAvatar(
                                        backgroundColor: Colors.grey.shade100,
                                        child: Text(c['user_name'] != null && c['user_name'].isNotEmpty ? c['user_name'][0].toUpperCase() : 'U'),
                                      ),
                                      title: Text(c['user_name'] ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                      subtitle: Text(c['comment_text'] ?? '', style: const TextStyle(fontSize: 12)),
                                      trailing: Text('${date.day}/${date.month}', style: TextStyle(color: Colors.grey.shade400, fontSize: 10)),
                                    );
                                  },
                                ),
                        ),
                        const Divider(),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: commentController,
                                decoration: const InputDecoration(
                                  hintText: 'Add a comment...',
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.send, color: Colors.blue),
                              onPressed: () async {
                                if (commentController.text.trim().isNotEmpty) {
                                  await appState.addCommentToMLABroadcast(widget.reel.id, commentController.text);
                                  commentController.clear();
                                  setModalState(() {});
                                  if (mounted) {
                                    setState(() {});
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _initializeVideo() {
    if (widget.reel.mediaUrl.startsWith('http') || widget.reel.mediaUrl.contains('://')) {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.reel.mediaUrl));
    } else {
      _controller = VideoPlayerController.asset(widget.reel.mediaUrl);
    }

    _controller!.initialize().then((_) {
      if (mounted) {
        setState(() {
          _controller!.setLooping(true);
          _controller!.play();
          _isPlaying = true;
        });
      }
    }).catchError((error) {
      debugPrint('Video initialization error: $error');
      if (mounted) {
        setState(() {
          _isError = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (_controller != null && _controller!.value.isInitialized)
          GestureDetector(
            onTap: () {
              setState(() {
                if (_controller!.value.isPlaying) {
                  _controller!.pause();
                  _isPlaying = false;
                } else {
                  _controller!.play();
                  _isPlaying = true;
                }
              });
            },
            child: VideoPlayer(_controller!),
          )
        else if (_isError)
          Container(
            color: Colors.black,
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.video_camera_back_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('Unable to load video.', style: TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          )
        else
          const Center(child: CircularProgressIndicator(color: Colors.white)),

        // Vertical Reels Sidebar Options
        Positioned(
          right: 16, bottom: 80,
          child: Column(
            children: [
              GestureDetector(
                onTap: () async {
                  final appState = Provider.of<AppState>(context, listen: false);
                  await appState.toggleLikeMLABroadcast(widget.reel.id);
                  setState(() {
                    _liked = !_liked;
                  });
                },
                child: _sideIcon(
                  Icons.favorite,
                  widget.reel.likes.toString(),
                  _liked ? Colors.red : Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => _showCommentsSheet(context),
                child: _sideIcon(Icons.comment, widget.reel.shares.toString(), Colors.white),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () {
                  Share.share('${widget.reel.title}\n${widget.reel.description}\nWatch at: ${widget.reel.mediaUrl}');
                },
                child: _sideIcon(Icons.share, 'Share', Colors.white),
              ),
            ],
          ),
        ),

        // Caption & Description
        Positioned(
          bottom: 24, left: 16, right: 80,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.reel.title,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 4),
              Text(
                widget.reel.description,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),

        // Play/Pause Floating Overlay
        if (!_isPlaying && !_isError && _controller != null && _controller!.value.isInitialized)
          Center(
            child: Icon(Icons.play_arrow, size: 80, color: Colors.white.withOpacity(0.7)),
          ),
      ],
    );
  }

  Widget _sideIcon(IconData icon, String label, Color color) {
    return Column(
      children: [
        CircleAvatar(
          backgroundColor: Colors.black.withOpacity(0.4),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
