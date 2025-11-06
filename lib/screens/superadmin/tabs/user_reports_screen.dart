// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';
//
// class UserReportsScreen extends StatefulWidget {
//   final String userId;
//   final String userName;
//
//   const UserReportsScreen({
//     super.key,
//     required this.userId,
//     required this.userName,
//   });
//
//   @override
//   State<UserReportsScreen> createState() => _UserReportsScreenState();
// }
//
// class _UserReportsScreenState extends State<UserReportsScreen> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   bool _isLoading = false;
//   List<Map<String, dynamic>> _meetingReports = [];
//   List<Map<String, dynamic>> _attendanceReports = [];
//   int _selectedReportType = 0; // 0 = Meetings, 1 = Attendance
//
//   @override
//   void initState() {
//     super.initState();
//     _loadUserReports();
//   }
//
//   Future<void> _loadUserReports() async {
//     setState(() => _isLoading = true);
//     try {
//       await _loadMeetingReports();
//       await _loadAttendanceReports();
//     } catch (e) {
//       _showError('Failed to load reports: ${e.toString()}');
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }
//
//   Future<void> _loadMeetingReports() async {
//     final meetingsSnapshot = await _firestore
//         .collection('meetings')
//         .orderBy('date', descending: true)
//         .get();
//
//     final List<Map<String, dynamic>> reports = [];
//
//     for (var meetingDoc in meetingsSnapshot.docs) {
//       final attendanceDoc = await _firestore
//           .collection('meetings')
//           .doc(meetingDoc.id)
//           .collection('attendance')
//           .doc(widget.userId)
//           .get();
//
//       if (attendanceDoc.exists) {
//         final meetingData = meetingDoc.data();
//         final attendanceData = attendanceDoc.data();
//
//         reports.add({
//           'type': 'meeting',
//           'meetingId': meetingDoc.id,
//           'title': meetingData['title'] ?? 'Meeting',
//           'date': meetingData['date'],
//           'startTime': meetingData['startTime'],
//           'endTime': meetingData['endTime'],
//           'attendancePercentage': attendanceData?['attendancePercentage'] ?? '0%',
//           'startAttended': attendanceData?['startAttended'] ?? false,
//           'endAttended': attendanceData?['endAttended'] ?? false,
//           'timestamp': attendanceData?['timestamp'],
//         });
//       }
//     }
//
//     setState(() => _meetingReports = reports);
//   }
//
//   Future<void> _loadAttendanceReports() async {
//     final attendanceSnapshot = await _firestore
//         .collection('attendance_records')
//         .where('members.${widget.userId}', isNotEqualTo: null)
//         .get();
//
//     final List<Map<String, dynamic>> reports = [];
//
//     for (var doc in attendanceSnapshot.docs) {
//       final data = doc.data();
//       final memberData = data['members'][widget.userId];
//
//       reports.add({
//         'type': 'attendance',
//         'date': data['date'],
//         'status': memberData['status'] ?? 'Absent',
//         'startTime': memberData['start'] ?? false,
//         'endTime': memberData['end'] ?? false,
//         'timestamp': data['timestamp'],
//       });
//     }
//
//     // Sort by date descending
//     reports.sort((a, b) {
//       final dateA = a['date'] is Timestamp ? a['date'].toDate() : DateTime.now();
//       final dateB = b['date'] is Timestamp ? b['date'].toDate() : DateTime.now();
//       return dateB.compareTo(dateA);
//     });
//
//     setState(() => _attendanceReports = reports);
//   }
//
//   Color _getStatusColor(String status) {
//     switch (status) {
//       case 'Full':
//       case '100%':
//         return Colors.green;
//       case 'Partial':
//       case '50%':
//         return Colors.orange;
//       case 'Absent':
//       case '0%':
//         return Colors.red;
//       default:
//         return Colors.grey;
//     }
//   }
//
//   IconData _getStatusIcon(String status) {
//     switch (status) {
//       case 'Full':
//       case '100%':
//         return Icons.check_circle;
//       case 'Partial':
//       case '50%':
//         return Icons.remove_circle;
//       case 'Absent':
//       case '0%':
//         return Icons.cancel;
//       default:
//         return Icons.help;
//     }
//   }
//
//   void _showError(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(message), backgroundColor: Colors.red),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final currentReports = _selectedReportType == 0 ? _meetingReports : _attendanceReports;
//
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('${widget.userName} - Reports'),
//         backgroundColor: Colors.deepPurple,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             onPressed: _loadUserReports,
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           // Report Type Selector
//           Card(
//             margin: const EdgeInsets.all(16),
//             child: Padding(
//               padding: const EdgeInsets.all(8.0),
//               child: Row(
//                 children: [
//                   Expanded(
//                     child: ChoiceChip(
//                       label: const Text('Meeting Reports'),
//                       selected: _selectedReportType == 0,
//                       onSelected: (selected) {
//                         setState(() => _selectedReportType = 0);
//                       },
//                     ),
//                   ),
//                   const SizedBox(width: 8),
//                   Expanded(
//                     child: ChoiceChip(
//                       label: const Text('Attendance Records'),
//                       selected: _selectedReportType == 1,
//                       onSelected: (selected) {
//                         setState(() => _selectedReportType = 1);
//                       },
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//
//           // Statistics Summary
//           if (currentReports.isNotEmpty) ...[
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceAround,
//                 children: [
//                   _buildStatItem(
//                     'Total',
//                     currentReports.length.toString(),
//                     Icons.list,
//                     Colors.blue,
//                   ),
//                   _buildStatItem(
//                     'Present',
//                     currentReports.where((r) =>
//                     r['status'] == 'Full' ||
//                         r['attendancePercentage'] == '100%' ||
//                         r['status'] == 'Present'
//                     ).length.toString(),
//                     Icons.check_circle,
//                     Colors.green,
//                   ),
//                   _buildStatItem(
//                     'Absent',
//                     currentReports.where((r) =>
//                     r['status'] == 'Absent' ||
//                         r['attendancePercentage'] == '0%'
//                     ).length.toString(),
//                     Icons.cancel,
//                     Colors.red,
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 16),
//           ],
//
//           // Reports List
//           Expanded(
//             child: _isLoading
//                 ? const Center(child: CircularProgressIndicator())
//                 : currentReports.isEmpty
//                 ? const Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(Icons.report_problem, size: 64, color: Colors.grey),
//                   SizedBox(height: 16),
//                   Text(
//                     'No reports found',
//                     style: TextStyle(fontSize: 18, color: Colors.grey),
//                   ),
//                 ],
//               ),
//             )
//                 : ListView.builder(
//               itemCount: currentReports.length,
//               itemBuilder: (context, index) {
//                 final report = currentReports[index];
//                 return _buildReportItem(report);
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildStatItem(String title, String value, IconData icon, Color color) {
//     return Column(
//       children: [
//         Container(
//           padding: const EdgeInsets.all(8),
//           decoration: BoxDecoration(
//             color: color.withOpacity(0.1),
//             shape: BoxShape.circle,
//           ),
//           child: Icon(icon, color: color, size: 20),
//         ),
//         const SizedBox(height: 4),
//         Text(
//           value,
//           style: TextStyle(
//             fontSize: 16,
//             fontWeight: FontWeight.bold,
//             color: color,
//           ),
//         ),
//         Text(
//           title,
//           style: const TextStyle(fontSize: 12, color: Colors.grey),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildReportItem(Map<String, dynamic> report) {
//     final isMeetingReport = report['type'] == 'meeting';
//     final date = report['date'] is Timestamp
//         ? report['date'].toDate()
//         : DateTime.now();
//     final status = isMeetingReport
//         ? report['attendancePercentage']
//         : report['status'];
//     final title = isMeetingReport
//         ? report['title']
//         : 'Weekly Attendance';
//
//     return Card(
//       margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
//       child: ListTile(
//         leading: Container(
//           padding: const EdgeInsets.all(8),
//           decoration: BoxDecoration(
//             color: _getStatusColor(status).withOpacity(0.1),
//             shape: BoxShape.circle,
//           ),
//           child: Icon(
//             _getStatusIcon(status),
//             color: _getStatusColor(status),
//           ),
//         ),
//         title: Text(title),
//         subtitle: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(DateFormat('MMM dd, yyyy').format(date)),
//             if (isMeetingReport) ...[
//               Text('Time: ${report['startTime']} - ${report['endTime']}'),
//               Text('Start: ${report['startAttended'] ? '✓' : '✗'} | End: ${report['endAttended'] ? '✓' : '✗'}'),
//             ],
//           ],
//         ),
//         trailing: Container(
//           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//           decoration: BoxDecoration(
//             color: _getStatusColor(status),
//             borderRadius: BorderRadius.circular(16),
//           ),
//           child: Text(
//             status,
//             style: const TextStyle(
//               color: Colors.white,
//               fontWeight: FontWeight.bold,
//               fontSize: 12,
//             ),
//           ),
//         ),
//         onTap: () {
//           _showReportDetails(report);
//         },
//       ),
//     );
//   }
//
//   void _showReportDetails(Map<String, dynamic> report) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text(report['type'] == 'meeting' ? 'Meeting Details' : 'Attendance Details'),
//         content: SingleChildScrollView(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               _buildDetailItem('Title', report['title'] ?? 'Meeting'),
//               _buildDetailItem('Date', DateFormat('MMMM dd, yyyy').format(
//                   report['date'] is Timestamp ? report['date'].toDate() : DateTime.now()
//               )),
//
//               if (report['type'] == 'meeting') ...[
//                 _buildDetailItem('Time', '${report['startTime']} - ${report['endTime']}'),
//                 _buildDetailItem('Start Attended', report['startAttended'] ? 'Yes' : 'No'),
//                 _buildDetailItem('End Attended', report['endAttended'] ? 'Yes' : 'No'),
//                 _buildDetailItem('Attendance', report['attendancePercentage']),
//               ] else ...[
//                 _buildDetailItem('Status', report['status']),
//                 _buildDetailItem('Start Time', report['startTime'] ? 'Present' : 'Absent'),
//                 _buildDetailItem('End Time', report['endTime'] ? 'Present' : 'Absent'),
//               ],
//
//               if (report['timestamp'] != null) ...[
//                 _buildDetailItem(
//                     'Recorded',
//                     DateFormat('MMM dd, yyyy - hh:mm a').format(
//                         report['timestamp'] is Timestamp
//                             ? report['timestamp'].toDate()
//                             : DateTime.now()
//                     )
//                 ),
//               ],
//             ],
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Close'),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildDetailItem(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             '$label: ',
//             style: const TextStyle(fontWeight: FontWeight.bold),
//           ),
//           Expanded(child: Text(value)),
//         ],
//       ),
//     );
//   }
// }