import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:kafela/screens/member/tabs/prayer_attendance_tab.dart';
import 'package:kafela/screens/member/tabs/tasks_tab.dart';

import 'class_routine_tab.dart';
import 'groups_tab.dart';

class MemberDashboardTab extends StatefulWidget {
  const MemberDashboardTab({super.key});

  @override
  State<MemberDashboardTab> createState() => _MemberDashboardTabState();
}

class _MemberDashboardTabState extends State<MemberDashboardTab> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Map<String, dynamic>? _memberData;
  int _totalTasks = 0;
  int _completedTasks = 0;
  int _pendingTasks = 0;
  int _totalGroups = 0;
  double _attendanceRate = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Fetch member data
        final memberDoc = await _firestore.collection('users').doc(user.uid).get();
        if (memberDoc.exists) {
          setState(() {
            _memberData = memberDoc.data()!;
          });
        }

        // Fetch task statistics
        final tasksSnapshot = await _firestore
            .collection('tasks')
            .where('assignedTo', isEqualTo: user.uid)
            .get();

        setState(() {
          _totalTasks = tasksSnapshot.docs.length;
          _completedTasks = tasksSnapshot.docs
              .where((doc) => doc['status'] == 'completed')
              .length;
          _pendingTasks = _totalTasks - _completedTasks;
        });

        // Fetch group count
        final groupsSnapshot = await _firestore
            .collection('groups')
            .where('members', arrayContains: user.uid)
            .get();

        setState(() {
          _totalGroups = groupsSnapshot.docs.length;
        });

        // Fetch attendance rate (simplified calculation)
        final meetingsSnapshot = await _firestore
            .collection('meetings')
            .orderBy('date', descending: true)
            .limit(10)
            .get();

        int totalMeetings = meetingsSnapshot.docs.length;
        int attendedMeetings = 0;

        for (var meeting in meetingsSnapshot.docs) {
          final attendance = await _firestore
              .collection('meetings')
              .doc(meeting.id)
              .collection('attendance')
              .doc(user.uid)
              .get();

          if (attendance.exists) {
            attendedMeetings++;
          }
        }

        setState(() {
          _attendanceRate = totalMeetings > 0 ? (attendedMeetings / totalMeetings) * 100 : 0.0;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching dashboard data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final formattedDate = DateFormat('EEEE, MMMM dd, yyyy').format(now);
    final formattedTime = DateFormat('hh:mm a').format(now);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Header
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: Colors.grey[900],
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                       const Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 4),
                                Center(
                                  child: Text(
                                    'Member Dashboard',
                                    style: TextStyle(
                                      fontSize: 24,
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildDateTimeSection(formattedDate, formattedTime),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Quick Stats
              _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.green))
                  : _buildQuickStats(),

              const SizedBox(height: 20),

              const SizedBox(height: 20),

              // Quick Actions
              _buildQuickActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateTimeSection(String date, String time) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              const Icon(Icons.calendar_today, color: Colors.green, size: 20),
              const SizedBox(height: 4),
              Text(
                date.split(',')[0], // Day only
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              Text(
                date.split(',')[1].trim(), // Date only
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 10,
                ),
              ),
            ],
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.green.withOpacity(0.3),
          ),
          Column(
            children: [
              const Icon(Icons.access_time, color: Colors.green, size: 20),
              const SizedBox(height: 4),
              Text(
                time,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              Text(
                'Current Time',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(
          child: Text(
            'Quick Stats',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.2,
          children: [
            _buildStatCard(
              'Tasks',
              '$_completedTasks/$_totalTasks',
              Icons.assignment_turned_in,
              Colors.green,
            ),
            _buildStatCard(
              'Attendance',
              '${_attendanceRate.toStringAsFixed(1)}%',
              Icons.analytics,
              _getPerformanceColor(_attendanceRate),
            ),
            _buildStatCard(
              'Groups',
              '$_totalGroups',
              Icons.group,
              Colors.orange,
            ),
            _buildStatCard(
              'Pending',
              '$_pendingTasks',
              Icons.pending_actions,
              Colors.yellow,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Colors.grey[900],
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
              child: Icon(icon, color: color, size: 20),
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
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildScheduleItem(String title, String time, String location) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$time • $location',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.notifications_none, color: Colors.green.withOpacity(0.7)),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Card(
      color: Colors.grey[900],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    'Mark Prayer',
                    Icons.mosque,
                    Colors.green,
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => PrayerAttendanceTab()),
                          );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    'View Tasks',
                    Icons.assignment,
                    Colors.green,
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const MemberTasksTab()),
                          );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    'My Groups',
                    Icons.group,
                    Colors.green,
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const MemberGroupsTab()),
                          );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    'Routine',
                    Icons.schedule,
                    Colors.green,
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ClassRoutineTab()),
                          );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String title, IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getPerformanceColor(double percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 60) return Colors.orange;
    return Colors.red;
  }
}