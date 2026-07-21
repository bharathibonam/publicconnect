import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/app_state.dart';
import '../../../themes/theme_provider.dart';
import '../../../models/meeting.dart';
import '../../../services/supabase_service.dart';
import 'meeting_details_screen.dart';
import 'package:intl/intl.dart';

class CreateMeetingScreen extends StatefulWidget {
  final Meeting? meeting;
  const CreateMeetingScreen({super.key, this.meeting});

  @override
  State<CreateMeetingScreen> createState() => _CreateMeetingScreenState();
}

class _CreateMeetingScreenState extends State<CreateMeetingScreen> {
  final _formKey = GlobalKey<FormState>();
  String _title = '';
  String _description = '';
  String _meetLink = '';
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  
  bool _targetCitizens = false;
  bool _targetWardMembers = false;
  bool _targetCategoryOfficers = false;
  bool _targetMandalOfficers = false;
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.meeting != null) {
      _title = widget.meeting!.title;
      _description = widget.meeting!.description ?? '';
      _meetLink = widget.meeting!.meetLink ?? '';
      _selectedDate = widget.meeting!.date;
      
      try {
        final timeParts = widget.meeting!.startTime.split(':');
        _selectedTime = TimeOfDay(hour: int.parse(timeParts[0]), minute: int.parse(timeParts[1]));
      } catch (e) {
        _selectedTime = null;
      }
      
      _targetCitizens = widget.meeting!.targetRoles.contains('Citizen');
      _targetWardMembers = widget.meeting!.targetRoles.contains('Ward Member');
      _targetCategoryOfficers = widget.meeting!.targetRoles.contains('Category Officer');
      _targetMandalOfficers = widget.meeting!.targetRoles.contains('Mandal Officer');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeConfig = Provider.of<ThemeProvider>(context).activeParty;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black87),
        title: Text(widget.meeting == null ? 'Create Meeting' : 'Edit Meeting', style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Meeting Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _title,
                decoration: InputDecoration(labelText: 'Meeting Title', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                onSaved: (val) => _title = val ?? '',
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _description,
                maxLines: 3,
                decoration: InputDecoration(labelText: 'Description / Agenda', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                onSaved: (val) => _description = val ?? '',
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final dt = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (dt != null) setState(() => _selectedDate = dt);
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(labelText: 'Date', prefixIcon: const Icon(Icons.calendar_today), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                        child: Text(_selectedDate == null ? 'Select Date' : DateFormat('MMM dd, yyyy').format(_selectedDate!)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (time != null) setState(() => _selectedTime = time);
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(labelText: 'Start Time', prefixIcon: const Icon(Icons.access_time), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                        child: Text(_selectedTime == null ? 'Select Time' : _selectedTime!.format(context)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _meetLink,
                decoration: InputDecoration(labelText: 'Google Meet / Zoom Link', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                onSaved: (val) => _meetLink = val ?? '',
              ),
              const SizedBox(height: 32),
              const Text('Target Audience', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('Citizens'),
                value: _targetCitizens,
                onChanged: (val) => setState(() => _targetCitizens = val!),
                activeColor: themeConfig.primaryColor,
              ),
              CheckboxListTile(
                title: const Text('Ward Members'),
                value: _targetWardMembers,
                onChanged: (val) => setState(() => _targetWardMembers = val!),
                activeColor: themeConfig.primaryColor,
              ),
              CheckboxListTile(
                title: const Text('Category Officers'),
                value: _targetCategoryOfficers,
                onChanged: (val) => setState(() => _targetCategoryOfficers = val!),
                activeColor: themeConfig.primaryColor,
              ),
              CheckboxListTile(
                title: const Text('Mandal Officers'),
                value: _targetMandalOfficers,
                onChanged: (val) => setState(() => _targetMandalOfficers = val!),
                activeColor: themeConfig.primaryColor,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : () async {
                    if (_formKey.currentState!.validate()) {
                      if (_selectedDate == null || _selectedTime == null) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select Date and Time')));
                        return;
                      }
                      
                      _formKey.currentState!.save();
                      setState(() => _isLoading = true);
                      
                      final appState = Provider.of<AppState>(context, listen: false);
                      
                      List<String> targetRoles = [];
                      if (_targetCitizens) targetRoles.add('Citizen');
                      if (_targetWardMembers) targetRoles.add('Ward Member');
                      if (_targetCategoryOfficers) targetRoles.add('Category Officer');
                      if (_targetMandalOfficers) targetRoles.add('Mandal Officer');
                      if (targetRoles.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select at least one Target Audience')));
                        setState(() => _isLoading = false);
                        return;
                      }

                      String formatTime(TimeOfDay t) {
                        return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';
                      }

                      final meetingObj = Meeting(
                        id: widget.meeting?.id ?? '', // use existing id if editing
                        title: _title,
                        description: _description,
                        date: _selectedDate!,
                        startTime: formatTime(_selectedTime!),
                        endTime: formatTime(TimeOfDay(hour: (_selectedTime!.hour + 1) % 24, minute: _selectedTime!.minute)),
                        meetLink: _meetLink,
                        createdBy: widget.meeting?.createdBy ?? appState.currentUser?.id ?? 'system',
                        createdAt: widget.meeting?.createdAt ?? DateTime.now(),
                        targetRoles: targetRoles,
                      );
                      
                      debugPrint('Saving Meeting: ${meetingObj.title}');
                      debugPrint('Target Roles: $targetRoles');
                      
                      try {
                        Meeting finalMeeting;
                        if (widget.meeting != null) {
                          await SupabaseService.updateMeeting(meetingObj);
                          finalMeeting = meetingObj;
                        } else {
                          finalMeeting = await SupabaseService.createMeeting(meetingObj);
                        }
                        
                        debugPrint('Meeting Saved Successfully');
                        debugPrint('Notification Created');
                        debugPrint('Realtime Triggered');
                        
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.meeting == null ? 'Meeting Created Successfully' : 'Meeting Updated Successfully')));
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MeetingDetailsScreen(
                                meeting: finalMeeting,
                                themeConfig: themeConfig,
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        debugPrint('Database Error: $e');
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Database Error: $e')));
                        }
                      } finally {
                        if (mounted) setState(() => _isLoading = false);
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: themeConfig.primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Text(widget.meeting == null ? 'Publish Meeting' : 'Update Meeting', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
