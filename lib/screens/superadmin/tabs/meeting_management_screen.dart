
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class MeetingManagementScreen extends StatefulWidget {
  const MeetingManagementScreen({super.key});

  @override
  State<MeetingManagementScreen> createState() =>
      _MeetingManagementScreenState();
}

class _MeetingManagementScreenState extends State<MeetingManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  DateTime _meetingDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  TimeOfDay _endTime =
  TimeOfDay(hour: TimeOfDay.now().hour + 1, minute: TimeOfDay.now().minute);
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _members = [];
  bool _isLoading = false;
  final TextEditingController _meetingTitleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    try {
      final snapshot = await _firestore.collection('users').get();
      _users = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'uid': doc.id,
          'name': data['name'] ?? 'Unknown User',
          'email': data['email'] ?? 'No email',
          'role': data['role'] ?? 'Member',
        };
      }).toList();

      // Filter only members
      _members = _users.where((user) => user['role'] == 'Member').toList();
    } catch (e) {
      _showError('Failed to fetch users: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _meetingDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _meetingDate) {
      setState(() => _meetingDate = picked);
    }
  }

  Future<void> _selectStartTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (picked != null && picked != _startTime) {
      setState(() => _startTime = picked);
    }
  }

  Future<void> _selectEndTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );
    if (picked != null && picked != _endTime) {
      setState(() => _endTime = picked);
    }
  }

  void _navigateToAttendanceSheet() {
    if (_meetingTitleController.text.isEmpty) {
      _showError('Please enter a meeting title');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AttendanceSheetScreen(
          meetingTitle: _meetingTitleController.text,
          meetingDate: _meetingDate,
          startTime: _startTime,
          endTime: _endTime,
          members: _members,
        ),
      ),
    );
  }

  void _resetForm() {
    _meetingTitleController.clear();
    setState(() {
      _meetingDate = DateTime.now();
      _startTime = TimeOfDay.now();
      _endTime = TimeOfDay(
          hour: TimeOfDay.now().hour + 1, minute: TimeOfDay.now().minute);
    });
    _showSuccess('Form reset successfully!');
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isSmallScreen = constraints.maxHeight < 600;
            final padding = isSmallScreen ? 12.0 : 16.0;

            return Padding(
              padding: EdgeInsets.all(padding),
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Column(
                  children: [
                    // Meeting Details Card
                    Card(
                      elevation: 6,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(isSmallScreen ? 16.0 : 20.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Header with Icon
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.meeting_room,
                                    color: Colors.green,
                                    size: isSmallScreen ? 20 : 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Meeting Details',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 18 : 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: isSmallScreen ? 16 : 20),

                            // Meeting Title Field
                            TextField(
                              controller: _meetingTitleController,
                              decoration: InputDecoration(
                                labelText: 'Meeting Title',
                                labelStyle: const TextStyle(color: Colors.grey),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Colors.grey),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Colors.grey),
                                ),
                                prefixIcon:
                                const Icon(Icons.title, color: Colors.black),
                                filled: true,
                                fillColor: Colors.grey[50],
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: isSmallScreen ? 12 : 16,
                                ),
                              ),
                            ),
                            SizedBox(height: isSmallScreen ? 16 : 20),

                            // Date and Time Section
                            LayoutBuilder(
                              builder: (context, innerConstraints) {
                                final isWide = innerConstraints.maxWidth > 600;
                                return isWide
                                    ? _buildWideDateTimeSection(isSmallScreen)
                                    : _buildNarrowDateTimeSection(isSmallScreen);
                              },
                            ),
                            SizedBox(height: isSmallScreen ? 20 : 24),

                            // Action Buttons
                            LayoutBuilder(
                              builder: (context, innerConstraints) {
                                final isWide = innerConstraints.maxWidth > 500;
                                return isWide
                                    ? _buildWideActionButtons(isSmallScreen)
                                    : _buildNarrowActionButtons(isSmallScreen);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 16 : 20),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildWideDateTimeSection(bool isSmallScreen) {
    return Row(
      children: [
        Expanded(
          child: _buildDateTile(isSmallScreen),
        ),
        SizedBox(width: isSmallScreen ? 12 : 16),
        Expanded(
          child: _buildTimeSection(isSmallScreen),
        ),
      ],
    );
  }

  Widget _buildNarrowDateTimeSection(bool isSmallScreen) {
    return Column(
      children: [
        _buildDateTile(isSmallScreen),
        SizedBox(height: isSmallScreen ? 12 : 16),
        _buildTimeSection(isSmallScreen),
      ],
    );
  }

  Widget _buildDateTile(bool isSmallScreen) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.calendar_today,
              color: Colors.black,
              size: isSmallScreen ? 18 : 20),
        ),
        title: Text(
          'Meeting Date',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: isSmallScreen ? 14 : 16,
          ),
        ),
        subtitle: Text(
          DateFormat('EEEE, MMMM dd, yyyy').format(_meetingDate),
          style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
        ),
        trailing: const Icon(Icons.arrow_drop_down, color: Colors.grey),
        onTap: () => _selectDate(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 12 : 16,
          vertical: isSmallScreen ? 8 : 12,
        ),
      ),
    );
  }

  Widget _buildTimeSection(bool isSmallScreen) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          // Start Time
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.play_arrow,
                  color: Colors.green,
                  size: isSmallScreen ? 18 : 20),
            ),
            title: Text(
              'Start Time',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: isSmallScreen ? 14 : 16,
              ),
            ),
            subtitle: Text(
              _startTime.format(context),
              style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
            ),
            trailing: const Icon(Icons.arrow_drop_down, color: Colors.grey),
            onTap: () => _selectStartTime(context),
            contentPadding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 12 : 16,
              vertical: isSmallScreen ? 8 : 12,
            ),
          ),
          // Divider
          Container(
            height: 1,
            color: Colors.grey[300],
            margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12 : 16),
          ),
          // End Time
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.stop,
                  color: Colors.red,
                  size: isSmallScreen ? 18 : 20),
            ),
            title: Text(
              'End Time',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: isSmallScreen ? 14 : 16,
              ),
            ),
            subtitle: Text(
              _endTime.format(context),
              style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
            ),
            trailing: const Icon(Icons.arrow_drop_down, color: Colors.grey),
            onTap: () => _selectEndTime(context),
            contentPadding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 12 : 16,
              vertical: isSmallScreen ? 8 : 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWideActionButtons(bool isSmallScreen) {
    return Row(
      children: [
        Expanded(
          child: _buildMemberAttendanceButton(isSmallScreen),
        ),
        SizedBox(width: isSmallScreen ? 8 : 12),
        _buildResetButton(isSmallScreen),
      ],
    );
  }

  Widget _buildNarrowActionButtons(bool isSmallScreen) {
    return Column(
      children: [
        _buildMemberAttendanceButton(isSmallScreen),
        SizedBox(height: isSmallScreen ? 8 : 12),
        _buildResetButton(isSmallScreen),
      ],
    );
  }

  Widget _buildMemberAttendanceButton(bool isSmallScreen) {
    return SizedBox(
      height: isSmallScreen ? 48 : 54,
      child: ElevatedButton.icon(
        icon: Icon(Icons.people_alt,
            color: Colors.white,
            size: isSmallScreen ? 20 : 22),
        label: Text(
          'Member Attendance',
          style: TextStyle(
            color: Colors.white,
            fontSize: isSmallScreen ? 14 : 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        onPressed: _navigateToAttendanceSheet,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
          shadowColor: Colors.blue.withOpacity(0.3),
        ),
      ),
    );
  }

  Widget _buildResetButton(bool isSmallScreen) {
    return SizedBox(
      height: isSmallScreen ? 48 : 54,
      child: ElevatedButton.icon(
        icon: Icon(Icons.refresh,
            color: Colors.white,
            size: isSmallScreen ? 20 : 22),
        label: Text(
          'Reset',
          style: TextStyle(
            color: Colors.white,
            fontSize: isSmallScreen ? 14 : 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        onPressed: _resetForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
          shadowColor: Colors.grey.withOpacity(0.3),
        ),
      ),
    );
  }
}

// Enhanced Attendance Sheet Screen
class AttendanceSheetScreen extends StatefulWidget {
  final String meetingTitle;
  final DateTime meetingDate;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final List<Map<String, dynamic>> members;

  const AttendanceSheetScreen({
    super.key,
    required this.meetingTitle,
    required this.meetingDate,
    required this.startTime,
    required this.endTime,
    required this.members,
  });

  @override
  State<AttendanceSheetScreen> createState() => _AttendanceSheetScreenState();
}

class _AttendanceSheetScreenState extends State<AttendanceSheetScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, Map<String, bool>> _attendanceData = {};
  bool _isLoading = false;
  bool _isSaving = false;
  String _searchQuery = '';
  List<Map<String, dynamic>> _filteredMembers = [];

  @override
  void initState() {
    super.initState();
    _initializeAttendanceData();
    _filteredMembers = widget.members;
  }

  void _initializeAttendanceData() {
    _attendanceData.clear();
    for (var member in widget.members) {
      _attendanceData[member['uid']] = {
        'start': false,
        'end': false,
      };
    }
  }

  void _filterMembers(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredMembers = widget.members;
      } else {
        _filteredMembers = widget.members.where((member) {
          final name = member['name']?.toLowerCase() ?? '';
          final email = member['email']?.toLowerCase() ?? '';
          return name.contains(query.toLowerCase()) ||
              email.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  String _calculateAttendancePercentage(String uid) {
    final attendance = _attendanceData[uid]!;
    if (attendance['start']! && attendance['end']!) {
      return '100%';
    } else if (attendance['start']! || attendance['end']!) {
      return '50%';
    } else {
      return '0%';
    }
  }

  Color _getPercentageColor(String percentage) {
    switch (percentage) {
      case '100%':
        return Colors.green;
      case '50%':
        return Colors.orange;
      case '0%':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getAttendanceStatus(String percentage) {
    switch (percentage) {
      case '100%':
        return 'Full';
      case '50%':
        return 'Half';
      case '0%':
        return 'Absent';
      default:
        return '-';
    }
  }

  Future<void> _saveMeetingAttendance() async {
    setState(() => _isSaving = true);
    try {
      final meetingId =
          '${DateFormat('yyyy-MM-dd').format(widget.meetingDate)}-${widget.startTime.hour}${widget.startTime.minute}';

      // Save meeting details
      await _firestore.collection('meetings').doc(meetingId).set({
        'id': meetingId,
        'title': widget.meetingTitle,
        'date': widget.meetingDate,
        'startTime':
        '${widget.startTime.hour}:${widget.startTime.minute.toString().padLeft(2, '0')}',
        'endTime':
        '${widget.endTime.hour}:${widget.endTime.minute.toString().padLeft(2, '0')}',
        'createdAt': FieldValue.serverTimestamp(),
        'totalParticipants': widget.members.length,
        'presentCount': _attendanceData.values
            .where((v) => v['start']! || v['end']!)
            .length,
      });

      // Save attendance records
      final batch = _firestore.batch();
      for (var entry in _attendanceData.entries) {
        final uid = entry.key;
        final attendance = entry.value;
        final percentage = _calculateAttendancePercentage(uid);

        final docRef = _firestore
            .collection('meetings')
            .doc(meetingId)
            .collection('attendance')
            .doc(uid);

        batch.set(docRef, {
          'userId': uid,
          'userName': widget.members.firstWhere((u) => u['uid'] == uid)['name'],
          'startAttended': attendance['start']!,
          'endAttended': attendance['end']!,
          'attendancePercentage': percentage,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      _showSuccess('Meeting attendance saved successfully!');
      Navigator.pop(context); // Go back to previous screen
    } catch (e) {
      _showError('Failed to save meeting: ${e.toString()}');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _resetAttendance() {
    setState(() {
      _initializeAttendanceData();
    });
    _showSuccess('Attendance sheet reset!');
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _selectAllStart() {
    setState(() {
      _attendanceData.updateAll(
            (key, value) => {'start': true, 'end': value['end']!},
      );
    });
    _showSuccess('All "Start" attendances marked!');
  }

  void _selectAllEnd() {
    setState(() {
      _attendanceData.updateAll(
            (key, value) => {'start': value['start']!, 'end': true},
      );
    });
    _showSuccess('All "End" attendances marked!');
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Sheet'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetAttendance,
            tooltip: 'Reset Attendance',
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isSmallScreen = constraints.maxHeight < 600;
            final padding = isSmallScreen ? 12.0 : 16.0;

            return Column(
              children: [
                // Meeting Info Header
                Card(
                  margin: EdgeInsets.all(padding),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(isSmallScreen ? 16.0 : 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.meeting_room,
                                  color: Colors.green,
                                  size: isSmallScreen ? 18 : 20),
                            ),
                            SizedBox(width: isSmallScreen ? 8 : 12),
                            Expanded(
                              child: Text(
                                widget.meetingTitle,
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 16 : 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: isSmallScreen ? 8 : 12),
                        LayoutBuilder(
                          builder: (context, innerConstraints) {
                            final isWide = innerConstraints.maxWidth > 500;
                            return isWide
                                ? _buildWideMeetingInfo(isSmallScreen)
                                : _buildNarrowMeetingInfo(isSmallScreen);
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // Search Bar
                Padding(
                  padding: EdgeInsets.all(padding),
                  child: Card(
                    color: Colors.grey[900],
                    child: Padding(
                      padding: const EdgeInsets.all(0),
                      child: TextField(
                        onChanged: _filterMembers,
                        decoration: InputDecoration(
                          labelText: 'Search members...',
                          labelStyle: const TextStyle(color: Colors.black),
                          prefixIcon: const Icon(Icons.search, color: Colors.black),
                           border: OutlineInputBorder(
                             borderRadius: BorderRadius.circular(8),
                           ),
                          focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.green),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        style: const TextStyle(color: Colors.black),
                      ),
                    ),
                  ),
                ),

                // Attendance Stats + Select All Buttons
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: padding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row: Title + Counter
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Member Attendance',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 14 : 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isSmallScreen ? 12 : 16,
                              vertical: isSmallScreen ? 4 : 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.blue.withOpacity(0.3)),
                            ),
                            child: Text(
                              '${_attendanceData.values.where((v) => v['start']! || v['end']!).length} / ${widget.members.length} Present',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                                fontSize: isSmallScreen ? 11 : 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Select All Buttons Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _selectAllStart,
                              icon: const Icon(Icons.check_circle, color: Colors.white, size: 18),
                              label: const Text(
                                'Select All Start',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 10 : 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 3,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _selectAllEnd,
                              icon: const Icon(Icons.done_all, color: Colors.white, size: 18),
                              label: const Text(
                                'Select All End',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 10 : 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: isSmallScreen ? 8 : 12),

                SizedBox(height: isSmallScreen ? 8 : 12),

                // Attendance List
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: double.infinity,
                      minHeight: double.infinity,
                    ),
                    child: _filteredMembers.isEmpty
                        ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            _searchQuery.isEmpty
                                ? 'No members available'
                                : 'No members found for "$_searchQuery"',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    )
                        : _buildAttendanceList(isSmallScreen),
                  ),
                ),

                // Save Button
                Container(
                  padding: EdgeInsets.all(padding),
                  child: _isSaving
                      ? const CircularProgressIndicator()
                      : SizedBox(
                    width: double.infinity,
                    height: isSmallScreen ? 48 : 54,
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.save,
                          color: Colors.white,
                          size: isSmallScreen ? 20 : 22),
                      label: Text(
                        'Save Attendance',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isSmallScreen ? 14 : 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onPressed: _saveMeetingAttendance,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                        shadowColor: Colors.green.withOpacity(0.3),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildWideMeetingInfo(bool isSmallScreen) {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Icon(Icons.calendar_today,
                  size: isSmallScreen ? 14 : 16,
                  color: Colors.grey),
              SizedBox(width: isSmallScreen ? 6 : 8),
              Text(
                DateFormat('MMM dd, yyyy').format(widget.meetingDate),
                style: TextStyle(
                    fontSize: isSmallScreen ? 12 : 14,
                    color: Colors.grey
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Icon(Icons.access_time,
                  size: isSmallScreen ? 14 : 16,
                  color: Colors.grey),
              SizedBox(width: isSmallScreen ? 6 : 8),
              Text(
                '${widget.startTime.format(context)} - ${widget.endTime.format(context)}',
                style: TextStyle(
                    fontSize: isSmallScreen ? 12 : 14,
                    color: Colors.grey
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNarrowMeetingInfo(bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.calendar_today,
                size: isSmallScreen ? 14 : 16,
                color: Colors.grey),
            SizedBox(width: isSmallScreen ? 6 : 8),
            Text(
              DateFormat('MMM dd, yyyy').format(widget.meetingDate),
              style: TextStyle(
                  fontSize: isSmallScreen ? 12 : 14,
                  color: Colors.grey
              ),
            ),
          ],
        ),
        SizedBox(height: isSmallScreen ? 6 : 8),
        Row(
          children: [
            Icon(Icons.access_time,
                size: isSmallScreen ? 14 : 16,
                color: Colors.grey),
            SizedBox(width: isSmallScreen ? 6 : 8),
            Text(
              '${widget.startTime.format(context)} - ${widget.endTime.format(context)}',
              style: TextStyle(
                  fontSize: isSmallScreen ? 12 : 14,
                  color: Colors.grey
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAttendanceList(bool isSmallScreen) {
    return ListView.builder(
      itemCount: _filteredMembers.length,
      itemBuilder: (context, index) {
        final member = _filteredMembers[index];
        final attendance = _attendanceData[member['uid']]!;
        final percentage = _calculateAttendancePercentage(member['uid']);

        return Card(
          margin: EdgeInsets.symmetric(
              vertical: isSmallScreen ? 4 : 6,
              horizontal: isSmallScreen ? 12 : 16
          ),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 500;
                return isWide
                    ? _buildWideAttendanceRow(member, attendance, percentage, isSmallScreen)
                    : _buildNarrowAttendanceRow(member, attendance, percentage, isSmallScreen);
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildWideAttendanceRow(Map<String, dynamic> member,
      Map<String, bool> attendance, String percentage, bool isSmallScreen) {
    return Row(
      children: [
        // User Avatar and Info
        Expanded(
          flex: 3,
          child: Row(
            children: [
              CircleAvatar(
                radius: isSmallScreen ? 18 : 20,
                backgroundColor: Colors.green,
                child: Text(
                  member['name'][0].toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    fontSize: isSmallScreen ? 12 : 14,
                  ),
                ),
              ),
              SizedBox(width: isSmallScreen ? 12 : 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member['name'],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isSmallScreen ? 14 : 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: isSmallScreen ? 2 : 4),
                    Text(
                      member['email'],
                      style: TextStyle(
                        fontSize: isSmallScreen ? 10 : 12,
                        color: Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Attendance Checkboxes
        Expanded(
          flex: 2,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
            ),
            padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 6 : 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAttendanceCheckbox('Start', attendance['start']!, () {
                  setState(() {
                    _attendanceData[member['uid']]!['start'] =
                    !attendance['start']!;
                  });
                }, isSmallScreen),
                _buildAttendanceCheckbox('End', attendance['end']!, () {
                  setState(() {
                    _attendanceData[member['uid']]!['end'] =
                    !attendance['end']!;
                  });
                }, isSmallScreen),
              ],
            ),
          ),
        ),

        // Percentage Display
        Expanded(
          flex: 1,
          child: Container(
            padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
            decoration: BoxDecoration(
              color: _getPercentageColor(percentage),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  percentage,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: isSmallScreen ? 12 : 14,
                  ),
                ),
                SizedBox(height: isSmallScreen ? 1 : 2),
                Text(
                  _getAttendanceStatus(percentage),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isSmallScreen ? 8 : 10,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNarrowAttendanceRow(Map<String, dynamic> member,
      Map<String, bool> attendance, String percentage, bool isSmallScreen) {
    return Column(
      children: [
        // User Info
        Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.black,
              radius: isSmallScreen ? 16 : 20,
              child: Text(
                member['name'][0].toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontSize: isSmallScreen ? 10 : 12,
                ),
              ),
            ),
            SizedBox(width: isSmallScreen ? 8 : 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member['name'],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: isSmallScreen ? 12 : 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    member['email'],
                    style: TextStyle(
                      fontSize: isSmallScreen ? 9 : 11,
                      color: Colors.grey[600],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 6 : 8,
                  vertical: isSmallScreen ? 3 : 4
              ),
              decoration: BoxDecoration(
                color: _getPercentageColor(percentage),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                percentage,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: isSmallScreen ? 10 : 12,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: isSmallScreen ? 8 : 12),
        // Checkboxes
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildAttendanceCheckbox('Start', attendance['start']!, () {
              setState(() {
                _attendanceData[member['uid']]!['start'] =
                !attendance['start']!;
              });
            }, isSmallScreen),
            _buildAttendanceCheckbox('End', attendance['end']!, () {
              setState(() {
                _attendanceData[member['uid']]!['end'] = !attendance['end']!;
              });
            }, isSmallScreen),
          ],
        ),
      ],
    );
  }

  Widget _buildAttendanceCheckbox(
      String label, bool value, VoidCallback onChanged, bool isSmallScreen) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isSmallScreen ? 10 : 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: isSmallScreen ? 2 : 4),
        Transform.scale(
          scale: isSmallScreen ? 1.1 : 1.2,
          child: Checkbox(
            value: value,
            onChanged: (bool? newValue) => onChanged(),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ],
    );
  }
}
