import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/database_service.dart';

class DashboardHome extends StatelessWidget {
  const DashboardHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section - Simplified
            _buildHeader(context),
            const SizedBox(height: 32),

            // Detailed Statistics Grid Only
            _buildDetailedStats(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final now = DateTime.now();
    final formattedDate = '${_getWeekday(now.weekday)}, ${now.day} ${_getMonth(now.month)} ${now.year}';
    final formattedTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Overview',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
                fontSize: 28,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Organization performance summary',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue.shade100,
                Colors.purple.shade100,
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.blue[800]),
                  const SizedBox(width: 8),
                  Text(
                    formattedDate,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.blue[800],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: Colors.purple[800]),
                  const SizedBox(width: 8),
                  Text(
                    formattedTime,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.purple[800],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailedStats(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.analytics, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              'Detailed Statistics',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
                fontSize: 22,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('users').snapshots(),
          builder: (context, userSnapshot) {
            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('meetings').snapshots(),
              builder: (context, meetingSnapshot) {
                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collectionGroup('attendance')
                      .snapshots(),
                  builder: (context, attendanceSnapshot) {

                    // Calculate all statistics
                    final totalUsers = userSnapshot.data?.docs.length ?? 0;
                    final totalMeetings = meetingSnapshot.data?.docs.length ?? 0;

                    int superAdmins = 0;
                    int admins = 0;
                    int members = 0;
                    int totalPresentCount = 0;
                    int totalPossibleAttendance = 0;

                    if (userSnapshot.hasData) {
                      for (var doc in userSnapshot.data!.docs) {
                        final role = doc['role'] as String?;
                        switch (role) {
                          case 'SuperAdmin':
                            superAdmins++;
                            break;
                          case 'Admin':
                            admins++;
                            break;
                          case 'Member':
                            members++;
                            break;
                        }
                      }
                    }

                    // Calculate attendance rate
                    if (attendanceSnapshot.hasData && meetingSnapshot.hasData) {
                      final attendanceDocs = attendanceSnapshot.data!.docs;
                      totalPresentCount = attendanceDocs.fold(0, (sum, doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final startAttended = data['startAttended'] as bool? ?? false;
                        final endAttended = data['endAttended'] as bool? ?? false;
                        return sum + (startAttended || endAttended ? 1 : 0);
                      });

                      totalPossibleAttendance = totalMeetings * totalUsers;
                    }

                    final attendanceRate = totalPossibleAttendance > 0
                        ? ((totalPresentCount / totalPossibleAttendance) * 100).round()
                        : 0;

                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final crossAxisCount = _getCrossAxisCount(constraints.maxWidth);
                        final childAspectRatio = _getChildAspectRatio(constraints.maxWidth);

                        return GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: crossAxisCount,
                          childAspectRatio: childAspectRatio,
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 20,
                          children: [
                            _buildModernStatsCard(
                              title: 'Total Users',
                              value: totalUsers,
                              subtitle: 'All platform users',
                              icon: Icons.people_outline,
                              color: Colors.blue,
                              context: context,
                            ),
                            _buildModernStatsCard(
                              title: 'Total Meetings',
                              value: totalMeetings,
                              subtitle: 'Meetings conducted',
                              icon: Icons.video_library,
                              color: Colors.green,
                              context: context,
                            ),
                            _buildModernStatsCard(
                              title: 'Super Admins',
                              value: superAdmins,
                              subtitle: 'Platform administrators',
                              icon: Icons.security,
                              color: Colors.purple,
                              context: context,
                            ),
                            _buildModernStatsCard(
                              title: 'Admins',
                              value: admins,
                              subtitle: 'Organization admins',
                              icon: Icons.admin_panel_settings,
                              color: Colors.orange,
                              context: context,
                            ),
                            _buildModernStatsCard(
                              title: 'Members',
                              value: members,
                              subtitle: 'Organization members',
                              icon: Icons.person,
                              color: Colors.teal,
                              context: context,
                            ),
                            _buildModernStatsCard(
                              title: 'Attendance Rate',
                              value: attendanceRate,
                              subtitle: 'Average participation',
                              icon: Icons.list_alt_outlined,
                              color: Colors.red,
                              context: context,
                              isPercentage: true,
                            ),
                          ],
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        ),
      ],
    );
  }

  int _getCrossAxisCount(double width) {
    if (width > 1200) return 4;
    if (width > 900) return 3;
    if (width > 600) return 2;
    return 1;
  }

  double _getChildAspectRatio(double width) {
    if (width > 1200) return 1.4;
    if (width > 900) return 1.3;
    if (width > 600) return 1.2;
    return 1.1;
  }

  Widget _buildModernStatsCard({
    required String title,
    required int value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required BuildContext context,
    bool isPercentage = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 25,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 28, color: color),
                ),
                if (isPercentage && value > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getPerformanceColor(value).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _getPerformanceColor(value).withOpacity(0.3)),
                    ),
                    child: Text(
                      _getPerformanceText(value),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: _getPerformanceColor(value),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              isPercentage ? '$value%' : _formatNumber(value),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
                fontSize: 32,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
                fontSize: 14,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Color _getPerformanceColor(int percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 60) return Colors.lightGreen;
    if (percentage >= 40) return Colors.orange;
    if (percentage >= 20) return Colors.orangeAccent;
    return Colors.red;
  }

  String _getPerformanceText(int percentage) {
    if (percentage >= 80) return 'Excellent';
    if (percentage >= 60) return 'Good';
    if (percentage >= 40) return 'Average';
    if (percentage >= 20) return 'Poor';
    return 'Very Poor';
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  String _getWeekday(int weekday) {
    switch (weekday) {
      case 1: return 'Monday';
      case 2: return 'Tuesday';
      case 3: return 'Wednesday';
      case 4: return 'Thursday';
      case 5: return 'Friday';
      case 6: return 'Saturday';
      case 7: return 'Sunday';
      default: return '';
    }
  }

  String _getMonth(int month) {
    switch (month) {
      case 1: return 'January';
      case 2: return 'February';
      case 3: return 'March';
      case 4: return 'April';
      case 5: return 'May';
      case 6: return 'June';
      case 7: return 'July';
      case 8: return 'August';
      case 9: return 'September';
      case 10: return 'October';
      case 11: return 'November';
      case 12: return 'December';
      default: return '';
    }
  }
}