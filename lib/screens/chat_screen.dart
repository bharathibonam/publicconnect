import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/complaint.dart';
import '../models/chat_message.dart';
import '../models/user.dart';
import '../services/app_state.dart';
import '../services/supabase_service.dart';

class ChatScreen extends StatefulWidget {
  final Complaint complaint;

  const ChatScreen({super.key, required this.complaint});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late Stream<List<ChatMessage>> _messagesStream;
  final List<ChatMessage> _optimisticMessages = [];

  @override
  void initState() {
    super.initState();
    _messagesStream = SupabaseService.streamChatMessages(widget.complaint.id);
    
    // Mark messages as read when opening chat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = Provider.of<AppState>(context, listen: false);
      final currentUser = appState.currentUser;
      if (currentUser != null) {
        SupabaseService.markMessagesAsRead(widget.complaint.id, currentUser.id);
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _getReceiverId(AppState appState) {
    final complaint = widget.complaint;
    final currentUser = appState.currentUser;

    if (currentUser == null) return '';

    // Calculate time since complaint was created
    final hoursSinceCreated = DateTime.now().difference(complaint.createdAt).inHours;
    final isResolved = complaint.status == ComplaintStatus.resolved;
    final isEscalated = !isResolved && hoursSinceCreated >= 24;

    // If current user is citizen
    if (currentUser.role == UserRole.citizen) {
      if (isEscalated) {
        // Send to Ward Admin
        // The Ward Admin ID is accessible through the appState's wards if we lookup the ward
        final ward = appState.wards.firstWhere(
          (w) => w.id == complaint.wardId,
          orElse: () => appState.wards.first,
        );
        return ward.adminId;
      } else {
        // Dynamically find the officer (Category Officer, fallback to Ward Admin, fallback to Super Admin)
        final dynamicOfficer = appState.getDynamicAssignedOfficer(complaint);
        if (dynamicOfficer != null) {
          return dynamicOfficer.id;
        }
        return 'unassigned';
      }
    }

    // If current user is an officer (category or ward), they reply back to the citizen
    return complaint.userId;
  }

  String _getChatTitle(AppState appState) {
    final complaint = widget.complaint;
    final currentUser = appState.currentUser;

    if (currentUser?.role == UserRole.citizen) {
      final hoursSinceCreated = DateTime.now().difference(complaint.createdAt).inHours;
      final isResolved = complaint.status == ComplaintStatus.resolved;
      final isEscalated = !isResolved && hoursSinceCreated >= 24;

      if (isEscalated) {
        return 'Chat with Ward Officer';
      } else {
        return 'Chat with Category Officer';
      }
    } else {
      return 'Chat with Citizen';
    }
  }

  Future<void> _sendMessage(AppState appState) async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    
    final currentUser = appState.currentUser;
    if (currentUser == null) return;

    final receiverId = _getReceiverId(appState);

    final message = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      complaintId: widget.complaint.id,
      senderId: currentUser.id,
      receiverId: receiverId,
      message: text,
      createdAt: DateTime.now().toUtc(),
    );

    _messageController.clear();
    
    setState(() {
      _optimisticMessages.add(message);
    });
    
    // Scroll down immediately for optimistic message
    Future.delayed(const Duration(milliseconds: 50), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    try {
      await SupabaseService.sendMessage(message);
      // Remove optimistic since the stream will bring it back
      setState(() {
        _optimisticMessages.remove(message);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
        setState(() {
          _optimisticMessages.remove(message);
        });
      }
    }
  }

  bool _isReadOnly(AppState appState) {
    final currentUser = appState.currentUser;
    if (currentUser == null) return true;

    if (currentUser.role == UserRole.wardAdmin) {
      final hoursSinceCreated = DateTime.now().difference(widget.complaint.createdAt).inHours;
      final isResolved = widget.complaint.status == ComplaintStatus.resolved;
      if (!isResolved && hoursSinceCreated < 24) {
        return true;
      }
    }
    
    // If complaint is resolved, maybe disable chat? (Optional, let's keep it open for now or block it if needed. Prompt doesn't specify blocking after resolution, but implies it's open. We'll leave it open).
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final currentUser = appState.currentUser;

    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text('Not logged in')));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_getChatTitle(appState)),
      ),
      body: Column(
        children: [
          if (_isReadOnly(appState))
            Container(
              padding: const EdgeInsets.all(12),
              width: double.infinity,
              color: Colors.amber.shade100,
              child: Text(
                appState.isTelugu ? 'SLA (24 గంటలు) ఇంకా ముగియలేదు. వీక్షించడానికి మాత్రమే.' : 'SLA (24h) not expired. View only.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.brown),
              ),
            ),
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: _messagesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final streamMessages = snapshot.data ?? [];
                
                final arrivedIds = streamMessages.map((m) => m.id).toSet();
                final pendingOptimistic = _optimisticMessages.where((m) => !arrivedIds.contains(m.id)).toList();
                
                final messages = [...streamMessages, ...pendingOptimistic];
                messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));

                if (messages.isEmpty) {
                  return const Center(child: Text('No messages yet. Start the conversation!'));
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == currentUser.id;

                    bool showHeader = false;
                    if (index == 0) {
                      showHeader = true;
                    } else {
                      final prevMessage = messages[index - 1];
                      final prevDate = prevMessage.createdAt.toLocal();
                      final currDate = message.createdAt.toLocal();
                      if (prevDate.year != currDate.year ||
                          prevDate.month != currDate.month ||
                          prevDate.day != currDate.day) {
                        showHeader = true;
                      }
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (showHeader) _buildDateHeader(message.createdAt.toLocal()),
                        _buildMessageBubble(message, isMe),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          _buildMessageInput(appState),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isMe) {
    final align = isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final color = isMe ? Colors.blue.shade100 : Colors.grey.shade200;
    final radius = const Radius.circular(16);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: align,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.only(
                topLeft: radius,
                topRight: radius,
                bottomLeft: isMe ? radius : Radius.zero,
                bottomRight: isMe ? Radius.zero : radius,
              ),
            ),
            child: Text(
              message.message,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                DateFormat('h:mm a').format(message.createdAt.toLocal()),
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              if (isMe) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.check,
                  size: 14,
                  color: Colors.grey.shade600,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final msgDate = DateTime(date.year, date.month, date.day);

    String dateString;
    if (msgDate == today) {
      dateString = 'Today';
    } else if (msgDate == yesterday) {
      dateString = 'Yesterday';
    } else {
      dateString = DateFormat('MMM d, yyyy').format(date);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            dateString,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade800,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageInput(AppState appState) {
    if (_isReadOnly(appState)) {
      return const SizedBox.shrink();
    }
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: appState.isTelugu ? 'సందేశం టైప్ చేయండి...' : 'Type a message...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                ),
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _sendMessage(appState),
              ),
            ),
            const SizedBox(width: 8),
            FloatingActionButton(
              onPressed: () => _sendMessage(appState),
              elevation: 0,
              mini: true,
              child: const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }
}
