class Meeting {
  final String id;
  final String title;
  final String? description;
  final String? purpose;
  final DateTime date;
  final String startTime;
  final String endTime;
  final String? venue;
  final String? meetLink;
  final String? location;
  final String? agenda;
  final String? attachmentUrl;
  final String? imageUrl;
  final String priority;
  final bool isReminderEnabled;
  final String status;
  final String createdBy;
  final DateTime createdAt;
  final List<String> targetRoles;
  final List<Map<String, dynamic>> attendance;

  Meeting({
    required this.id,
    required this.title,
    this.description,
    this.purpose,
    required this.date,
    required this.startTime,
    required this.endTime,
    this.venue,
    this.meetLink,
    this.location,
    this.agenda,
    this.attachmentUrl,
    this.imageUrl,
    this.priority = 'normal',
    this.isReminderEnabled = true,
    this.status = 'upcoming',
    required this.createdBy,
    required this.createdAt,
    this.targetRoles = const [],
    this.attendance = const [],
  });

  factory Meeting.fromJson(Map<String, dynamic> json) {
    return Meeting(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      purpose: json['purpose'] as String?,
      date: DateTime.parse(json['date'] as String),
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      venue: json['venue'] as String?,
      meetLink: json['meet_link'] as String?,
      location: json['location'] as String?,
      agenda: json['agenda'] as String?,
      attachmentUrl: json['attachment_url'] as String?,
      imageUrl: json['image_url'] as String?,
      priority: json['priority'] as String? ?? 'normal',
      isReminderEnabled: json['is_reminder_enabled'] as bool? ?? true,
      status: json['status'] as String? ?? 'upcoming',
      createdBy: json['created_by'] as String? ?? 'system',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
      targetRoles: (json['meeting_targets'] as List<dynamic>?)?.map((e) => e['target_role'] as String).toList() ?? [],
      attendance: (json['meeting_attendance'] as List<dynamic>?)?.map((e) => e as Map<String, dynamic>).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'title': title,
      'description': description,
      'purpose': purpose,
      'date': date.toIso8601String().split('T')[0],
      'start_time': startTime,
      'end_time': endTime,
      'venue': venue,
      'meet_link': meetLink,
      'location': location,
      'agenda': agenda,
      'attachment_url': attachmentUrl,
      'image_url': imageUrl,
      'priority': priority,
      'is_reminder_enabled': isReminderEnabled,
      'status': status,
      'created_by': createdBy,
    };
  }
}
