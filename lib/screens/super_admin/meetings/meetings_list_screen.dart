import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../themes/theme_provider.dart';
import 'create_meeting_screen.dart';
import 'meeting_details_screen.dart';
import 'package:intl/intl.dart';
import '../../../services/app_state.dart';
import '../../../models/user.dart';
import '../../../models/meeting.dart';

class MeetingsListScreen extends StatefulWidget {
  const MeetingsListScreen({super.key});

  @override
  State<MeetingsListScreen> createState() => _MeetingsListScreenState();
}

class _MeetingsListScreenState extends State<MeetingsListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isCalendarView = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeConfig = Provider.of<ThemeProvider>(context).activeParty;
    final appState = Provider.of<AppState>(context);
    final user = appState.currentUser;
    
    bool canCreateMeeting = user != null && (user.role == UserRole.superAdmin || user.role == UserRole.wardAdmin);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black87),
        title: const Text('Meetings & Events', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black87),
            onPressed: () {
              // Search meetings
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.black87),
            onPressed: () {
              // Filter meetings
            },
          ),
          IconButton(
            icon: Icon(_isCalendarView ? Icons.list : Icons.calendar_month, color: Colors.black87),
            onPressed: () {
              setState(() {
                _isCalendarView = !_isCalendarView;
              });
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: themeConfig.primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: themeConfig.primaryColor,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Today'),
            Tab(text: 'Completed'),
            Tab(text: 'Cancelled'),
            Tab(text: 'My Meetings'),
          ],
        ),
      ),
      body: _isCalendarView
          ? _buildCalendarView(themeConfig)
          : TabBarView(
              controller: _tabController,
              children: [
                _buildMeetingList('upcoming', themeConfig, appState),
                _buildMeetingList('today', themeConfig, appState),
                _buildMeetingList('completed', themeConfig, appState),
                _buildMeetingList('cancelled', themeConfig, appState),
                _buildMeetingList('my_meetings', themeConfig, appState),
              ],
            ),
      floatingActionButton: canCreateMeeting ? FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateMeetingScreen()));
        },
        backgroundColor: themeConfig.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Meeting', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ) : null,
    );
  }

  Widget _buildCalendarView(dynamic themeConfig) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_month, size: 64, color: themeConfig.primaryColor.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          const Text('Calendar View Active', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Events will appear here in a calendar format.', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildMeetingList(String filter, dynamic themeConfig, AppState appState) {
    List<Meeting> allMeetings = appState.meetings;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    List<Meeting> filtered = allMeetings.where((m) {
      final meetDate = DateTime(m.date.year, m.date.month, m.date.day);
      if (filter == 'upcoming') return m.status == 'upcoming' && meetDate.isAfter(today);
      if (filter == 'today') return m.status == 'upcoming' && meetDate.isAtSameMomentAs(today);
      if (filter == 'completed') return m.status == 'completed';
      if (filter == 'cancelled') return m.status == 'cancelled';
      if (filter == 'my_meetings') return m.createdBy == appState.currentUser?.id;
      return true;
    }).toList();
    
    if (filtered.isEmpty) {
      return const Center(child: Text('No meetings found.', style: TextStyle(color: Colors.grey)));
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final meeting = filtered[index];
        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.only(bottom: 16),
          color: Colors.white,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => MeetingDetailsScreen(
                meeting: meeting,
                themeConfig: themeConfig,
              )));
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: meeting.status == 'completed' ? Colors.green.shade50 : (meeting.status == 'cancelled' ? Colors.red.shade50 : Colors.blue.shade50),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          meeting.status.toUpperCase(),
                          style: TextStyle(
                            color: meeting.status == 'completed' ? Colors.green : (meeting.status == 'cancelled' ? Colors.red : Colors.blue),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Icon(Icons.more_vert, color: Colors.grey),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    meeting.title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(DateFormat('MMM dd, yyyy').format(meeting.date), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(width: 16),
                      const Icon(Icons.access_time, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text('${meeting.startTime} - ${meeting.endTime}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(child: Text(meeting.venue ?? meeting.meetLink ?? 'No Location', style: const TextStyle(fontSize: 12, color: Colors.grey), overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: themeConfig.primaryColor.withValues(alpha: 0.2),
                            child: Icon(Icons.person, size: 14, color: themeConfig.primaryColor),
                          ),
                          const SizedBox(width: 8),
                          const Text('Organizer', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => MeetingDetailsScreen(
                            meeting: meeting,
                            themeConfig: themeConfig,
                          )));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeConfig.primaryColor.withValues(alpha: 0.1),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text('View Details', style: TextStyle(color: themeConfig.primaryColor, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
