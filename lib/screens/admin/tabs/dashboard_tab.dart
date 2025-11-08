import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  int _totalMembers = 0;
  double _overallAttendanceRate = 0.0;
  int _totalTasks = 0;
  int _completedTasks = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    try {
      final totalMembers = await _fetchTotalMembers();
      final attendanceRate = await _fetchOverallAttendanceRate();
      final taskStats = await _fetchTaskStats();

      setState(() {
        _totalMembers = totalMembers;
        _overallAttendanceRate = attendanceRate;
        _totalTasks = taskStats['total'] ?? 0;
        _completedTasks = taskStats['completed'] ?? 0;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching dashboard data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<int> _fetchTotalMembers() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'Member')
          .get();
      return snapshot.docs.length;
    } catch (e) {
      print('Error fetching members count: $e');
      return 0;
    }
  }

  Future<double> _fetchOverallAttendanceRate() async {
    try {
      final meetingsSnapshot = await _firestore.collection('meetings').get();
      if (meetingsSnapshot.docs.isEmpty) return 0.0;

      double totalRate = 0;
      int count = 0;

      for (var meetingDoc in meetingsSnapshot.docs) {
        final attendanceSnapshot = await _firestore
            .collection('meetings')
            .doc(meetingDoc.id)
            .collection('attendance')
            .get();

        if (attendanceSnapshot.docs.isNotEmpty) {
          double meetingSum = 0;
          int valid = 0;

          for (var doc in attendanceSnapshot.docs) {
            final data = doc.data();
            final percentage = data['attendancePercentage']?.toString();
            if (percentage != null) {
              final numValue =
                  double.tryParse(percentage.replaceAll('%', '')) ?? 0.0;
              meetingSum += numValue;
              valid++;
            }
          }

          if (valid > 0) {
            totalRate += (meetingSum / valid);
            count++;
          }
        }
      }

      return count > 0 ? totalRate / count : 0.0;
    } catch (e) {
      print('Error fetching attendance rate: $e');
      return 0.0;
    }
  }

  Future<Map<String, int>> _fetchTaskStats() async {
    try {
      final snapshot = await _firestore.collection('tasks').get();
      final total = snapshot.docs.length;
      final completed =
          snapshot.docs.where((doc) => doc['status'] == 'completed').length;
      return {'total': total, 'completed': completed};
    } catch (e) {
      print('Error fetching task stats: $e');
      return {'total': 0, 'completed': 0};
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
        child: RefreshIndicator(
          color: Colors.green,
          onRefresh: _fetchDashboardData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(formattedDate, formattedTime),
                const SizedBox(height: 20),
                _isLoading
                    ? const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 100),
                    child: CircularProgressIndicator(color: Colors.green),
                  ),
                )
                    : LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 600;
                    return isWide
                        ? _buildWideStats()
                        : _buildNarrowStats();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String date, String time) {
    return Card(
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(10),
                child: const Icon(Icons.dashboard, color: Colors.green),
              ),
              const SizedBox(width: 10),
              const Text(
                'Admin Dashboard',
                style: TextStyle(
                    color: Colors.green,
                    fontSize: 22,
                    fontWeight: FontWeight.bold),
              )
            ]),
            const SizedBox(height: 10),
            Text(
              date,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            Text(
              time,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWideStats() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildStatCard('Total Members', _totalMembers, Icons.people)),
            const SizedBox(width: 10),
            Expanded(
                child: _buildStatCard(
                    'Attendance Rate',
                    _overallAttendanceRate,
                    Icons.analytics,
                    isPercentage: true)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _buildStatCard('Total Tasks', _totalTasks, Icons.assignment)),
            const SizedBox(width: 10),
            Expanded(
                child: _buildStatCard(
                    'Completed Tasks', _completedTasks, Icons.check_circle)),
          ],
        ),
      ],
    );
  }

  Widget _buildNarrowStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildStatCard(
          'Total Members',
          _totalMembers,
          Icons.people,
          gradientColors: [Colors.greenAccent.shade400, Colors.green.shade700],

        ),
        const SizedBox(height: 10),
        _buildStatCard(
          'Attendance Rate',
          _overallAttendanceRate,
          Icons.analytics,
          isPercentage: true,
          gradientColors: [Colors.greenAccent.shade400, Colors.green.shade700],
        ),
        const SizedBox(height: 10),
        _buildStatCard(
          'Total Tasks',
          _totalTasks,
          Icons.assignment,
          gradientColors: [Colors.greenAccent.shade400, Colors.green.shade700],
        ),
        const SizedBox(height: 10),
        _buildStatCard(
          'Completed Tasks',
          _completedTasks,
          Icons.check_circle,
          gradientColors: [Colors.greenAccent.shade400, Colors.green.shade700],
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title,
      dynamic value,
      IconData icon, {
        bool isPercentage = false,
        List<Color>? gradientColors,
      }) {
    final gradient = gradientColors ??
        [Colors.greenAccent.shade400, Colors.green.shade700];

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: gradient.last.withOpacity(0.3),
            offset: const Offset(0, 6),
            blurRadius: 10,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left Icon Section
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(14),
              child: Icon(icon, color: Colors.white, size: 32),
            ),
            const SizedBox(width: 20),

            // Text Section
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isPercentage
                        ? '${value.toStringAsFixed(1)}%'
                        : value.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

}
