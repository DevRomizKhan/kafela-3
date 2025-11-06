import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ReportsTab extends StatefulWidget {
  const ReportsTab({super.key, required String selectedMemberId, required String selectedMemberName});

  @override
  State<ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<ReportsTab> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> _members = [];
  bool _isLoading = false;
  String _searchQuery = '';
  Map<String, dynamic>? _selectedUserReport;
  String _selectedReportType = 'overview';
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fetchMembers();
  }

  Future<void> _fetchMembers() async {
    setState(() => _isLoading = true);
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'Member')
          .limit(100)
          .get();

      _members = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'uid': doc.id,
          'name': data['name'] ?? 'Unknown Member',
          'email': data['email'] ?? 'No email',
          'joinDate': data['createdAt'],
        };
      }).toList();
    } catch (e) {
      _showError('Failed to fetch members: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchUserReport(String uid, String userName) async {
    setState(() => _isLoading = true);
    try {
      // Fetch data in parallel for better performance
      final results = await Future.wait([
        _fetchMeetingAttendance(uid),
        _fetchPrayerAttendance(uid),
        _fetchTaskPerformance(uid),
      ]);

      final meetingData = results[0] as Map<String, dynamic>;
      final prayerData = results[1] as Map<String, dynamic>;
      final taskData = results[2] as Map<String, dynamic>;

      setState(() {
        _selectedUserReport = {
          'uid': uid,
          'userName': userName,
          'meetingReport': meetingData['report'],
          'totalMeetings': meetingData['totalMeetings'],
          'attendedMeetings': meetingData['attendedMeetings'],
          'attendanceRate': meetingData['attendanceRate'].toDouble(), // Convert to double
          'prayerStats': prayerData,
          'taskStats': taskData,
          'reportType': _selectedReportType,
          'dateRange': '${DateFormat('MMM dd, yyyy').format(_startDate)} - ${DateFormat('MMM dd, yyyy').format(_endDate)}',
        };
      });
    } catch (e) {
      _showError('Failed to fetch report: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<Map<String, dynamic>> _fetchMeetingAttendance(String uid) async {
    final meetingsSnapshot = await _firestore
        .collection('meetings')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(_startDate))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(_endDate))
        .orderBy('date', descending: true)
        .limit(20)
        .get();

    final report = <String, dynamic>{};
    int totalMeetings = meetingsSnapshot.docs.length;
    int attendedMeetings = 0;

    final futures = meetingsSnapshot.docs.map((meetingDoc) async {
      final meetingId = meetingDoc.id;
      final meetingData = meetingDoc.data();

      try {
        final attendanceDoc = await _firestore
            .collection('meetings')
            .doc(meetingId)
            .collection('attendance')
            .doc(uid)
            .get();

        if (attendanceDoc.exists) {
          final data = attendanceDoc.data() as Map<String, dynamic>;
          report[meetingId] = {
            'title': meetingData['title'] ?? 'No Title',
            'date': meetingData['date'],
            'startTime': meetingData['startTime'] ?? 'N/A',
            'endTime': meetingData['endTime'] ?? 'N/A',
            'attendancePercentage': data['attendancePercentage'],
            'startAttended': data['startAttended'],
            'endAttended': data['endAttended'],
            'timestamp': data['timestamp'],
          };

          if (data['attendancePercentage'] != '0%') {
            attendedMeetings++;
          }
        }
      } catch (e) {
        print('Error fetching attendance for meeting $meetingId: $e');
      }
    }).toList();

    await Future.wait(futures);

    final attendanceRate = totalMeetings > 0 ? (attendedMeetings / totalMeetings) * 100 : 0.0;

    return {
      'report': report,
      'totalMeetings': totalMeetings,
      'attendedMeetings': attendedMeetings,
      'attendanceRate': attendanceRate,
    };
  }

  Future<Map<String, dynamic>> _fetchPrayerAttendance(String uid) async {
    try {
      final prayerSnapshot = await _firestore
          .collection('prayer_attendance')
          .doc(uid)
          .collection('records')
          .where('date', isGreaterThanOrEqualTo: DateFormat('yyyy-MM-dd').format(_startDate))
          .where('date', isLessThanOrEqualTo: DateFormat('yyyy-MM-dd').format(_endDate))
          .get();

      int totalPrayers = 0;
      int completedPrayers = 0;
      final dailyStats = <Map<String, dynamic>>[];

      for (var doc in prayerSnapshot.docs) {
        final data = doc.data();
        int dayPrayers = 0;

        // Count completed prayers for this day
        if (data['fajr'] == true) dayPrayers++;
        if (data['dhuhr'] == true) dayPrayers++;
        if (data['asr'] == true) dayPrayers++;
        if (data['maghrib'] == true) dayPrayers++;
        if (data['isha'] == true) dayPrayers++;

        totalPrayers += 5;
        completedPrayers += dayPrayers;

        dailyStats.add({
          'date': data['date'],
          'completed': dayPrayers,
          'total': 5,
          'percentage': (dayPrayers / 5) * 100,
        });
      }

      final prayerRate = totalPrayers > 0 ? (completedPrayers / totalPrayers) * 100 : 0.0;

      return {
        'totalPrayers': totalPrayers,
        'completedPrayers': completedPrayers,
        'prayerRate': prayerRate,
        'dailyStats': dailyStats,
      };
    } catch (e) {
      return {
        'totalPrayers': 0,
        'completedPrayers': 0,
        'prayerRate': 0.0,
        'dailyStats': [],
      };
    }
  }

  Future<Map<String, dynamic>> _fetchTaskPerformance(String uid) async {
    try {
      final tasksSnapshot = await _firestore
          .collection('tasks')
          .where('assignedTo', isEqualTo: uid)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(_startDate))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(_endDate))
          .get();

      int totalTasks = tasksSnapshot.docs.length;
      int completedTasks = tasksSnapshot.docs
          .where((doc) => doc['status'] == 'completed')
          .length;
      int overdueTasks = tasksSnapshot.docs
          .where((doc) {
        final dueDate = (doc['dueDate'] as Timestamp).toDate();
        return dueDate.isBefore(DateTime.now()) && doc['status'] != 'completed';
      })
          .length;

      final completionRate = totalTasks > 0 ? (completedTasks / totalTasks) * 100 : 0.0;

      // Calculate average completion time
      double avgCompletionTime = 0.0;
      int tasksWithCompletion = 0;

      for (var task in tasksSnapshot.docs) {
        if (task['status'] == 'completed' && task['createdAt'] != null && task['updatedAt'] != null) {
          final created = (task['createdAt'] as Timestamp).toDate();
          final completed = (task['updatedAt'] as Timestamp).toDate();
          final difference = completed.difference(created).inHours.toDouble();
          avgCompletionTime += difference;
          tasksWithCompletion++;
        }
      }

      if (tasksWithCompletion > 0) {
        avgCompletionTime = avgCompletionTime / tasksWithCompletion;
      }

      return {
        'totalTasks': totalTasks,
        'completedTasks': completedTasks,
        'overdueTasks': overdueTasks,
        'completionRate': completionRate,
        'avgCompletionTime': avgCompletionTime,
        'tasks': tasksSnapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'title': data['title'],
            'status': data['status'],
            'dueDate': data['dueDate'],
            'feedback': data['feedback'] ?? '',
          };
        }).toList(),
      };
    } catch (e) {
      return {
        'totalTasks': 0,
        'completedTasks': 0,
        'overdueTasks': 0,
        'completionRate': 0.0,
        'avgCompletionTime': 0.0,
        'tasks': [],
      };
    }
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

  void _showDateRangePicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Select Date Range',
          style: TextStyle(color: Colors.green),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Start Date', style: TextStyle(color: Colors.grey)),
              subtitle: Text(
                DateFormat('MMM dd, yyyy').format(_startDate),
                style: const TextStyle(color: Colors.white),
              ),
              trailing: const Icon(Icons.calendar_today, color: Colors.green),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _startDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (date != null) setState(() => _startDate = date);
              },
            ),
            ListTile(
              title: const Text('End Date', style: TextStyle(color: Colors.grey)),
              subtitle: Text(
                DateFormat('MMM dd, yyyy').format(_endDate),
                style: const TextStyle(color: Colors.white),
              ),
              trailing: const Icon(Icons.calendar_today, color: Colors.green),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _endDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (date != null) setState(() => _endDate = date);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (_selectedUserReport != null) {
                _fetchUserReport(_selectedUserReport!['uid'], _selectedUserReport!['userName']);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Header Section
            Card(
              margin: const EdgeInsets.all(16),
              elevation: 4,
              color: Colors.grey[900],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.analytics,
                            color: Colors.green,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Member Reports',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Report Type Selection
                    DropdownButtonFormField<String>(
                      value: _selectedReportType,
                      dropdownColor: Colors.grey[800],
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Report Type',
                        labelStyle: const TextStyle(color: Colors.grey),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.green),
                        ),
                        filled: true,
                        fillColor: Colors.grey[800],
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'overview',
                          child: Text('Overview Report', style: TextStyle(color: Colors.white)),
                        ),
                        DropdownMenuItem(
                          value: 'attendance',
                          child: Text('Attendance Report', style: TextStyle(color: Colors.white)),
                        ),
                        DropdownMenuItem(
                          value: 'prayer',
                          child: Text('Prayer Report', style: TextStyle(color: Colors.white)),
                        ),
                        DropdownMenuItem(
                          value: 'tasks',
                          child: Text('Tasks Report', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                      onChanged: (value) => setState(() => _selectedReportType = value!),
                    ),

                    const SizedBox(height: 12),

                    // Date Range Selection
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.date_range, color: Colors.green, size: 16),
                            label: Text(
                              '${DateFormat('MMM dd').format(_startDate)} - ${DateFormat('MMM dd, yyyy').format(_endDate)}',
                              style: const TextStyle(color: Colors.green),
                            ),
                            onPressed: _showDateRangePicker,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.green),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Search Bar
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Search members by name or email...',
                        labelStyle: const TextStyle(color: Colors.grey),
                        prefixIcon: const Icon(Icons.search, color: Colors.green),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.green),
                        ),
                        filled: true,
                        fillColor: Colors.grey[800],
                      ),
                      style: const TextStyle(color: Colors.white),
                      onChanged: (value) => setState(() => _searchQuery = value),
                    ),
                  ],
                ),
              ),
            ),

            // Members List or Report
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.green))
                  : _selectedUserReport != null
                  ? _buildUserReport()
                  : _buildMembersList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMembersList() {
    final filteredMembers = _searchQuery.isEmpty
        ? _members
        : _members.where((member) =>
    member['name'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
        member['email'].toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    if (filteredMembers.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No members found',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredMembers.length,
      itemBuilder: (context, index) {
        final member = filteredMembers[index];
        return Card(
          color: Colors.grey[900],
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 2,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.green.withOpacity(0.2),
              child: Text(
                member['name'][0].toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),
            title: Text(
              member['name'],
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              member['email'],
              style: const TextStyle(color: Colors.grey),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.analytics, color: Colors.green, size: 20),
            ),
            onTap: () => _fetchUserReport(member['uid'], member['name']),
          ),
        );
      },
    );
  }

  Widget _buildUserReport() {
    final report = _selectedUserReport!;
    final userName = report['userName'];
    final dateRange = report['dateRange'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Report Header
          _buildReportHeader(userName, dateRange, report),

          const SizedBox(height: 20),

          // Show different reports based on selected type
          if (_selectedReportType == 'overview') _buildOverviewReport(report),
          if (_selectedReportType == 'attendance') _buildAttendanceReport(report),
          if (_selectedReportType == 'prayer') _buildPrayerReport(report),
          if (_selectedReportType == 'tasks') _buildTasksReport(report),
        ],
      ),
    );
  }

  Widget _buildReportHeader(String userName, String dateRange, Map<String, dynamic> report) {
    return Card(
      color: Colors.grey[900],
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.green.withOpacity(0.2),
                  radius: 30,
                  child: Text(
                    userName[0].toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Date Range: $dateRange',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => setState(() => _selectedUserReport = null),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Quick Stats Row
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildQuickStat(
                    'Meetings',
                    '${report['attendedMeetings']}/${report['totalMeetings']}',
                    Icons.meeting_room,
                    _getPerformanceColor(report['attendanceRate']),
                  ),
                  const SizedBox(width: 12),
                  _buildQuickStat(
                    'Prayers',
                    '${report['prayerStats']['completedPrayers']}/${report['prayerStats']['totalPrayers']}',
                    Icons.mosque,
                    _getPerformanceColor(report['prayerStats']['prayerRate']),
                  ),
                  const SizedBox(width: 12),
                  _buildQuickStat(
                    'Tasks',
                    '${report['taskStats']['completedTasks']}/${report['taskStats']['totalTasks']}',
                    Icons.assignment_turned_in,
                    _getPerformanceColor(report['taskStats']['completionRate']),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStat(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewReport(Map<String, dynamic> report) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Performance Overview',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),

        // Performance Cards
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1,
          children: [
            _buildPerformanceCard(
              'Meeting Attendance',
              '${report['attendanceRate'].toStringAsFixed(1)}%',
              Icons.meeting_room,
              _getPerformanceColor(report['attendanceRate']),
              '${report['attendedMeetings']} of ${report['totalMeetings']} meetings',
            ),
            _buildPerformanceCard(
              'Prayer Consistency',
              '${report['prayerStats']['prayerRate'].toStringAsFixed(1)}%',
              Icons.mosque,
              _getPerformanceColor(report['prayerStats']['prayerRate']),
              '${report['prayerStats']['completedPrayers']} of ${report['prayerStats']['totalPrayers']} prayers',
            ),
            _buildPerformanceCard(
              'Task Completion',
              '${report['taskStats']['completionRate'].toStringAsFixed(1)}%',
              Icons.assignment_turned_in,
              _getPerformanceColor(report['taskStats']['completionRate']),
              '${report['taskStats']['completedTasks']} of ${report['taskStats']['totalTasks']} tasks',
            ),
            _buildPerformanceCard(
              'Avg. Task Time',
              '${report['taskStats']['avgCompletionTime'].toStringAsFixed(1)}h',
              Icons.timer,
              Colors.blue,
              'Average completion time',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPerformanceCard(String title, String value, IconData icon, Color color, String subtitle) {
    return Card(
      color: Colors.grey[800],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceReport(Map<String, dynamic> report) {
    final meetingsReport = report['meetingReport'] as Map<String, dynamic>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Meeting Attendance Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),

        if (meetingsReport.isEmpty)
          _buildEmptyState('No meeting records found for this period', Icons.meeting_room)
        else
          ...meetingsReport.entries.map((entry) {
            final data = entry.value as Map<String, dynamic>;
            final date = (data['date'] as Timestamp).toDate();

            return Card(
              color: Colors.grey[800],
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _getPercentageColorFromString(data['attendancePercentage']),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              data['attendancePercentage'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data['title'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('MMM dd, yyyy').format(date),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildAttendanceChip('Start', data['startAttended']),
                        const SizedBox(width: 8),
                        _buildAttendanceChip('End', data['endAttended']),
                        const Spacer(),
                        Chip(
                          label: Text(
                            data['startAttended'] && data['endAttended']
                                ? 'Full'
                                : data['startAttended'] || data['endAttended']
                                ? 'Partial'
                                : 'Absent',
                            style: const TextStyle(color: Colors.white, fontSize: 10),
                          ),
                          backgroundColor: data['startAttended'] && data['endAttended']
                              ? Colors.green
                              : data['startAttended'] || data['endAttended']
                              ? Colors.orange
                              : Colors.red,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
      ],
    );
  }

  Widget _buildPrayerReport(Map<String, dynamic> report) {
    final prayerStats = report['prayerStats'];
    final dailyStats = prayerStats['dailyStats'] as List<Map<String, dynamic>>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Prayer Attendance Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),

        // Prayer Summary Card
        Card(
          color: Colors.grey[800],
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Overall Prayer Performance',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${prayerStats['completedPrayers']} of ${prayerStats['totalPrayers']} prayers completed',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      Text(
                        '${prayerStats['prayerRate'].toStringAsFixed(1)}% consistency rate',
                        style: TextStyle(
                          color: _getPerformanceColor(prayerStats['prayerRate']),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getPerformanceColor(prayerStats['prayerRate']).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.mosque,
                    color: _getPerformanceColor(prayerStats['prayerRate']),
                    size: 30,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        const Text(
          'Daily Prayer Completion',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),

        if (dailyStats.isEmpty)
          _buildEmptyState('No prayer records found for this period', Icons.mosque)
        else
          ...dailyStats.map((day) {
            return Card(
              color: Colors.grey[800],
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getPerformanceColor(day['percentage']).withOpacity(0.2),
                  child: Text(
                    '${day['completed']}',
                    style: TextStyle(
                      color: _getPerformanceColor(day['percentage']),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  day['date'],
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  '${day['completed']}/5 prayers (${day['percentage'].toStringAsFixed(1)}%)',
                  style: TextStyle(
                    color: _getPerformanceColor(day['percentage']),
                  ),
                ),
                trailing: Chip(
                  label: Text(
                    '${day['percentage'].toStringAsFixed(0)}%',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  backgroundColor: _getPerformanceColor(day['percentage']),
                ),
              ),
            );
          }).toList(),
      ],
    );
  }

  Widget _buildTasksReport(Map<String, dynamic> report) {
    final taskStats = report['taskStats'];
    final tasks = taskStats['tasks'] as List<Map<String, dynamic>>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Task Performance Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),

        // Task Summary Card
        Card(
          color: Colors.grey[800],
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTaskStat('Total', '${taskStats['totalTasks']}', Icons.assignment),
                _buildTaskStat('Completed', '${taskStats['completedTasks']}', Icons.check_circle),
                _buildTaskStat('Overdue', '${taskStats['overdueTasks']}', Icons.warning),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        const Text(
          'Task Details',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),

        if (tasks.isEmpty)
          _buildEmptyState('No tasks found for this period', Icons.assignment)
        else
          ...tasks.map((task) {
            final dueDate = (task['dueDate'] as Timestamp).toDate();
            final isOverdue = dueDate.isBefore(DateTime.now()) && task['status'] != 'completed';

            return Card(
              color: Colors.grey[800],
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Icon(
                  task['status'] == 'completed' ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: task['status'] == 'completed' ? Colors.green : Colors.orange,
                ),
                title: Text(
                  task['title'],
                  style: TextStyle(
                    color: Colors.white,
                    decoration: task['status'] == 'completed' ? TextDecoration.lineThrough : null,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Due: ${DateFormat('MMM dd, yyyy').format(dueDate)}',
                      style: TextStyle(
                        color: isOverdue ? Colors.red : Colors.grey,
                      ),
                    ),
                    if (task['feedback'] != null && task['feedback'].isNotEmpty)
                      Text(
                        'Feedback: ${task['feedback']}',
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
                trailing: Chip(
                  label: Text(
                    task['status'] == 'completed' ? 'Done' : 'Pending',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  backgroundColor: task['status'] == 'completed' ? Colors.green : Colors.orange,
                ),
              ),
            );
          }).toList(),
      ],
    );
  }

  Widget _buildTaskStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.green, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Card(
      color: Colors.grey[900],
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(icon, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceChip(String label, bool attended) {
    return Chip(
      label: Text(
        '$label: ${attended ? 'Present' : 'Absent'}',
        style: TextStyle(
          fontSize: 10,
          color: attended ? Colors.white : Colors.black,
        ),
      ),
      backgroundColor: attended ? Colors.green : Colors.grey[300],
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }

  Color _getPerformanceColor(double percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 60) return Colors.orange;
    return Colors.red;
  }

  Color _getPercentageColorFromString(String percentage) {
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
}