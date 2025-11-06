// // import 'package:flutter/material.dart';
// // import 'package:cloud_firestore/cloud_firestore.dart';
// // import 'package:firebase_auth/firebase_auth.dart';
// // import 'package:intl/intl.dart';
// //
// // class MemberDashboard extends StatefulWidget {
// //   const MemberDashboard({super.key});
// //
// //   @override
// //   State<MemberDashboard> createState() => _MemberDashboardState();
// // }
// //
// // class _MemberDashboardState extends State<MemberDashboard> {
// //   final _firestore = FirebaseFirestore.instance;
// //   final _auth = FirebaseAuth.instance;
// //   final List<String> prayers = ["Fajr", "Dhuhr", "Asr", "Maghrib", "Isha"];
// //   bool _startTime = false;
// //   bool _endTime = false;
// //
// //   /// Record a prayer performance
// //   Future<void> _markPrayer(String prayer, bool jamah) async {
// //     final uid = _auth.currentUser!.uid;
// //     final date = DateFormat('yyyy-MM-dd').format(DateTime.now());
// //     await _firestore
// //         .collection('users')
// //         .doc(uid)
// //         .collection('prayers')
// //         .doc("$date-$prayer")
// //         .set({
// //       'prayer': prayer,
// //       'jamah': jamah,
// //       'timestamp': DateTime.now(),
// //       'date': date,
// //     });
// //     ScaffoldMessenger.of(context).showSnackBar(
// //       SnackBar(content: Text("Recorded $prayer as ${jamah ? 'Jamah' : 'Home'}")),
// //     );
// //   }
// //
// //   /// Mark attendance based on start and end time toggles
// //   Future<void> _markAttendance() async {
// //     final uid = _auth.currentUser!.uid;
// //     final weekStartDate = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
// //     final weekKey = DateFormat('yyyy-MM-dd').format(weekStartDate);
// //     String status;
// //     if (_startTime && _endTime) {
// //       status = "Full";
// //     } else if (_startTime || _endTime) {
// //       status = "Partial";
// //     } else {
// //       status = "Absent";
// //     }
// //     await _firestore
// //         .collection('users')
// //         .doc(uid)
// //         .collection('attendance')
// //         .doc(weekKey)
// //         .set({
// //       'status': status,
// //       'startTime': _startTime,
// //       'endTime': _endTime,
// //       'timestamp': DateTime.now(),
// //     });
// //     ScaffoldMessenger.of(context).showSnackBar(
// //       SnackBar(content: Text("Marked attendance as $status")),
// //     );
// //   }
// //
// //   /// Delete an activity (prayer or attendance)
// //   Future<void> _deleteActivity(String collection, String docId, String title) async {
// //     await _firestore
// //         .collection('users')
// //         .doc(_auth.currentUser!.uid)
// //         .collection(collection)
// //         .doc(docId)
// //         .delete();
// //     ScaffoldMessenger.of(context).showSnackBar(
// //       SnackBar(content: Text("$title deleted.")),
// //     );
// //   }
// //
// //   /// Edit prayer record
// //   Future<void> _editPrayer(String docId, bool newJamah) async {
// //     await _firestore
// //         .collection('users')
// //         .doc(_auth.currentUser!.uid)
// //         .collection('prayers')
// //         .doc(docId)
// //         .update({'jamah': newJamah});
// //     ScaffoldMessenger.of(context).showSnackBar(
// //       const SnackBar(content: Text("Prayer updated.")),
// //     );
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     final uid = _auth.currentUser!.uid;
// //     return Scaffold(
// //       appBar: AppBar(
// //         title: const Text("Member Dashboard"),
// //         centerTitle: true,
// //         backgroundColor: Colors.teal,
// //         actions: [
// //           IconButton(
// //             icon: const Icon(Icons.logout),
// //             onPressed: () async {
// //               await _auth.signOut();
// //               Navigator.of(context).pushNamedAndRemoveUntil(
// //                 '/login',
// //                     (Route<dynamic> route) => false,
// //               );
// //             },
// //           ),
// //         ],
// //       ),
// //       body: LayoutBuilder(
// //         builder: (context, constraints) {
// //           final isWide = constraints.maxWidth > 600;
// //           return SingleChildScrollView(
// //             padding: const EdgeInsets.all(16),
// //             child: Column(
// //               children: [
// //                 // --- Weekly Attendance Section ---
// //                 Card(
// //                   shape: RoundedRectangleBorder(
// //                     borderRadius: BorderRadius.circular(16),
// //                   ),
// //                   elevation: 4,
// //                   child: Padding(
// //                     padding: const EdgeInsets.all(16),
// //                     child: Column(
// //                       crossAxisAlignment: CrossAxisAlignment.start,
// //                       children: [
// //                         const Text(
// //                           "Weekly Meeting Attendance",
// //                           style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
// //                         ),
// //                         const SizedBox(height: 12),
// //                         Text(
// //                           "Meeting held every Friday.\nToggle your attendance:",
// //                           style: TextStyle(color: Colors.grey[700]),
// //                         ),
// //                         const SizedBox(height: 16),
// //                         Row(
// //                           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
// //                           children: [
// //                             Column(
// //                               children: [
// //                                 const Text("Joined at Start"),
// //                                 Switch(
// //                                   value: _startTime,
// //                                   onChanged: (value) {
// //                                     setState(() {
// //                                       _startTime = value;
// //                                     });
// //                                   },
// //                                 ),
// //                               ],
// //                             ),
// //                             Column(
// //                               children: [
// //                                 const Text("Stayed till End"),
// //                                 Switch(
// //                                   value: _endTime,
// //                                   onChanged: (value) {
// //                                     setState(() {
// //                                       _endTime = value;
// //                                     });
// //                                   },
// //                                 ),
// //                               ],
// //                             ),
// //                           ],
// //                         ),
// //                         const SizedBox(height: 16),
// //                         ElevatedButton.icon(
// //                           icon: const Icon(Icons.check_circle),
// //                           onPressed: _markAttendance,
// //                           label: const Text("Mark Attendance"),
// //                           style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
// //                         ),
// //                       ],
// //                     ),
// //                   ),
// //                 ),
// //                 const SizedBox(height: 20),
// //                 // --- Display Weekly Attendance ---
// //                 Card(
// //                   shape: RoundedRectangleBorder(
// //                     borderRadius: BorderRadius.circular(16),
// //                   ),
// //                   elevation: 4,
// //                   child: Padding(
// //                     padding: const EdgeInsets.all(16),
// //                     child: Column(
// //                       crossAxisAlignment: CrossAxisAlignment.start,
// //                       children: [
// //                         const Text(
// //                           "My Weekly Attendance",
// //                           style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
// //                         ),
// //                         const SizedBox(height: 8),
// //                         StreamBuilder<QuerySnapshot>(
// //                           stream: _firestore
// //                               .collection('users')
// //                               .doc(uid)
// //                               .collection('attendance')
// //                               .orderBy('timestamp', descending: true)
// //                               .snapshots(),
// //                           builder: (context, snapshot) {
// //                             if (!snapshot.hasData) {
// //                               return const Center(child: CircularProgressIndicator());
// //                             }
// //                             final docs = snapshot.data!.docs;
// //                             if (docs.isEmpty) {
// //                               return const Padding(
// //                                 padding: EdgeInsets.all(12),
// //                                 child: Text("No attendance recorded yet."),
// //                               );
// //                             }
// //                             return Column(
// //                               children: docs.map((doc) {
// //                                 final data = doc.data() as Map<String, dynamic>;
// //                                 return Card(
// //                                   color: Colors.grey[50],
// //                                   child: ListTile(
// //                                     title: Text("Status: ${data['status']}"),
// //                                     subtitle: Text(
// //                                       DateFormat('MMM d, yyyy – hh:mm a').format(data['timestamp'].toDate()),
// //                                     ),
// //                                   ),
// //                                 );
// //                               }).toList(),
// //                             );
// //                           },
// //                         ),
// //                       ],
// //                     ),
// //                   ),
// //                 ),
// //                 const SizedBox(height: 20),
// //                 // --- Daily Prayer Section ---
// //                 Card(
// //                   shape: RoundedRectangleBorder(
// //                     borderRadius: BorderRadius.circular(16),
// //                   ),
// //                   elevation: 4,
// //                   child: Padding(
// //                     padding: const EdgeInsets.all(16),
// //                     child: Column(
// //                       crossAxisAlignment: CrossAxisAlignment.start,
// //                       children: [
// //                         const Text(
// //                           "Daily Prayer Record",
// //                           style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
// //                         ),
// //                         const SizedBox(height: 8),
// //                         ...prayers.map((prayer) {
// //                           return ListTile(
// //                             title: Text(prayer, style: const TextStyle(fontSize: 16)),
// //                             trailing: Row(
// //                               mainAxisSize: MainAxisSize.min,
// //                               children: [
// //                                 TextButton(
// //                                   onPressed: () => _markPrayer(prayer, true),
// //                                   child: const Text("Jamah", style: TextStyle(color: Colors.green)),
// //                                 ),
// //                                 TextButton(
// //                                   onPressed: () => _markPrayer(prayer, false),
// //                                   child: const Text("Home", style: TextStyle(color: Colors.orange)),
// //                                 ),
// //                               ],
// //                             ),
// //                           );
// //                         }),
// //                       ],
// //                     ),
// //                   ),
// //                 ),
// //                 const SizedBox(height: 20),
// //                 // --- Activity Log ---
// //                 Card(
// //                   shape: RoundedRectangleBorder(
// //                     borderRadius: BorderRadius.circular(16),
// //                   ),
// //                   elevation: 4,
// //                   child: Padding(
// //                     padding: const EdgeInsets.all(16),
// //                     child: Column(
// //                       crossAxisAlignment: CrossAxisAlignment.start,
// //                       children: [
// //                         const Text(
// //                           "My Activity",
// //                           style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
// //                         ),
// //                         const SizedBox(height: 8),
// //                         StreamBuilder<QuerySnapshot>(
// //                           stream: _firestore
// //                               .collection('users')
// //                               .doc(uid)
// //                               .collection('prayers')
// //                               .orderBy('timestamp', descending: true)
// //                               .snapshots(),
// //                           builder: (context, snapshot) {
// //                             if (!snapshot.hasData) {
// //                               return const Center(child: CircularProgressIndicator());
// //                             }
// //                             final docs = snapshot.data!.docs;
// //                             if (docs.isEmpty) {
// //                               return const Padding(
// //                                 padding: EdgeInsets.all(12),
// //                                 child: Text("No activities yet."),
// //                               );
// //                             }
// //                             return ListView.builder(
// //                               shrinkWrap: true,
// //                               physics: const NeverScrollableScrollPhysics(),
// //                               itemCount: docs.length,
// //                               itemBuilder: (context, index) {
// //                                 final doc = docs[index];
// //                                 final data = doc.data() as Map<String, dynamic>;
// //                                 return Card(
// //                                   margin: const EdgeInsets.symmetric(vertical: 4),
// //                                   shape: RoundedRectangleBorder(
// //                                     borderRadius: BorderRadius.circular(12),
// //                                   ),
// //                                   elevation: 2,
// //                                   child: ListTile(
// //                                     leading: CircleAvatar(
// //                                       backgroundColor: data['jamah'] ? Colors.green : Colors.orange,
// //                                       child: Text(
// //                                         data['prayer'][0],
// //                                         style: const TextStyle(color: Colors.white),
// //                                       ),
// //                                     ),
// //                                     title: Text(
// //                                       data['prayer'],
// //                                       style: const TextStyle(fontWeight: FontWeight.bold),
// //                                     ),
// //                                     subtitle: Text(
// //                                       DateFormat('MMM d, yyyy – hh:mm a').format(data['timestamp'].toDate()),
// //                                     ),
// //                                     trailing: PopupMenuButton<String>(
// //                                       onSelected: (value) {
// //                                         if (value == 'edit') {
// //                                           _editPrayer(doc.id, !data['jamah']);
// //                                         } else if (value == 'delete') {
// //                                           _deleteActivity('prayers', doc.id, 'Prayer');
// //                                         }
// //                                       },
// //                                       itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
// //                                         const PopupMenuItem<String>(
// //                                           value: 'edit',
// //                                           child: ListTile(
// //                                             leading: Icon(Icons.edit, color: Colors.blue),
// //                                             title: Text('Edit'),
// //                                           ),
// //                                         ),
// //                                         const PopupMenuItem<String>(
// //                                           value: 'delete',
// //                                           child: ListTile(
// //                                             leading: Icon(Icons.delete, color: Colors.red),
// //                                             title: Text('Delete'),
// //                                           ),
// //                                         ),
// //                                       ],
// //                                     ),
// //                                   ),
// //                                 );
// //                               },
// //                             );
// //                           },
// //                         ),
// //                       ],
// //                     ),
// //                   ),
// //                 ),
// //               ],
// //             ),
// //           );
// //         },
// //       ),
// //     );
// //   }
// // }
//
//
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:intl/intl.dart';
//
// class MemberDashboard extends StatefulWidget {
//   const MemberDashboard({super.key});
//
//   @override
//   State<MemberDashboard> createState() => _MemberDashboardState();
// }
//
// class _MemberDashboardState extends State<MemberDashboard> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final List<String> prayers = ["Fajr", "Dhuhr", "Asr", "Maghrib", "Isha"];
//   bool _startTime = false;
//   bool _endTime = false;
//   String _userName = 'Member';
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchUserData();
//   }
//
//   Future<void> _fetchUserData() async {
//     final uid = _auth.currentUser!.uid;
//     final doc = await _firestore.collection('users').doc(uid).get();
//     if (doc.exists) {
//       setState(() {
//         _userName = doc['name'] ?? 'Member';
//       });
//     }
//   }
//
//   Future<void> _markPrayer(String prayer, bool jamah) async {
//     final uid = _auth.currentUser!.uid;
//     final date = DateFormat('yyyy-MM-dd').format(DateTime.now());
//
//     await _firestore
//         .collection('users')
//         .doc(uid)
//         .collection('prayers')
//         .doc("$date-$prayer")
//         .set({
//       'prayer': prayer,
//       'jamah': jamah,
//       'timestamp': DateTime.now(),
//       'date': date,
//     });
//
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text("Recorded $prayer as ${jamah ? 'Jamah' : 'Home'}"),
//         backgroundColor: Colors.green,
//       ),
//     );
//   }
//
//   Future<void> _markAttendance() async {
//     final uid = _auth.currentUser!.uid;
//     final weekStartDate = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
//     final weekKey = DateFormat('yyyy-MM-dd').format(weekStartDate);
//
//     String status;
//     if (_startTime && _endTime) {
//       status = "Full";
//     } else if (_startTime || _endTime) {
//       status = "Partial";
//     } else {
//       status = "Absent";
//     }
//
//     await _firestore
//         .collection('users')
//         .doc(uid)
//         .collection('attendance')
//         .doc(weekKey)
//         .set({
//       'status': status,
//       'startTime': _startTime,
//       'endTime': _endTime,
//       'timestamp': DateTime.now(),
//       'week': weekKey,
//     });
//
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text("Marked attendance as $status"),
//         backgroundColor: Colors.green,
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final uid = _auth.currentUser!.uid;
//
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Member Dashboard"),
//         centerTitle: true,
//         backgroundColor: Colors.teal,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.logout),
//             onPressed: () async {
//               await _auth.signOut();
//             },
//           ),
//         ],
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             // Welcome Card
//             Card(
//               elevation: 4,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(16),
//               ),
//               child: Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Row(
//                   children: [
//                     const CircleAvatar(
//                       radius: 30,
//                       child: Icon(Icons.person, size: 30),
//                     ),
//                     const SizedBox(width: 16),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             "Welcome, $_userName!",
//                             style: const TextStyle(
//                               fontSize: 20,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                           const SizedBox(height: 4),
//                           const Text(
//                             "Track your prayers and attendance",
//                             style: TextStyle(color: Colors.grey),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//
//             const SizedBox(height: 20),
//
//             // Weekly Attendance Section
//             Card(
//               elevation: 4,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(16),
//               ),
//               child: Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text(
//                       "Weekly Meeting Attendance",
//                       style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                     ),
//                     const SizedBox(height: 12),
//                     const Text(
//                       "Meeting held every Friday. Toggle your attendance:",
//                       style: TextStyle(color: Colors.grey),
//                     ),
//                     const SizedBox(height: 16),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                       children: [
//                         Column(
//                           children: [
//                             const Text("Joined at Start"),
//                             Switch(
//                               value: _startTime,
//                               onChanged: (value) {
//                                 setState(() {
//                                   _startTime = value;
//                                 });
//                               },
//                             ),
//                           ],
//                         ),
//                         Column(
//                           children: [
//                             const Text("Stayed till End"),
//                             Switch(
//                               value: _endTime,
//                               onChanged: (value) {
//                                 setState(() {
//                                   _endTime = value;
//                                 });
//                               },
//                             ),
//                           ],
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 16),
//                     ElevatedButton.icon(
//                       icon: const Icon(Icons.check_circle),
//                       onPressed: _markAttendance,
//                       label: const Text("Mark Attendance"),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.green,
//                         minimumSize: const Size(double.infinity, 50),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//
//             const SizedBox(height: 20),
//
//             // Display Weekly Attendance
//             Card(
//               elevation: 4,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(16),
//               ),
//               child: Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text(
//                       "My Weekly Attendance",
//                       style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                     ),
//                     const SizedBox(height: 12),
//                     StreamBuilder<QuerySnapshot>(
//                       stream: _firestore
//                           .collection('users')
//                           .doc(uid)
//                           .collection('attendance')
//                           .orderBy('timestamp', descending: true)
//                           .snapshots(),
//                       builder: (context, snapshot) {
//                         if (!snapshot.hasData) {
//                           return const Center(child: CircularProgressIndicator());
//                         }
//
//                         final docs = snapshot.data!.docs;
//                         if (docs.isEmpty) {
//                           return const Padding(
//                             padding: EdgeInsets.all(12),
//                             child: Text(
//                               "No attendance recorded yet.",
//                               style: TextStyle(color: Colors.grey),
//                             ),
//                           );
//                         }
//
//                         return Column(
//                           children: docs.map((doc) {
//                             final data = doc.data() as Map<String, dynamic>;
//                             Color statusColor = Colors.grey;
//
//                             switch (data['status']) {
//                               case 'Full':
//                                 statusColor = Colors.green;
//                                 break;
//                               case 'Partial':
//                                 statusColor = Colors.orange;
//                                 break;
//                               case 'Absent':
//                                 statusColor = Colors.red;
//                                 break;
//                             }
//
//                             return Card(
//                               color: Colors.grey[50],
//                               margin: const EdgeInsets.symmetric(vertical: 4),
//                               child: ListTile(
//                                 leading: Icon(
//                                   Icons.calendar_today,
//                                   color: statusColor,
//                                 ),
//                                 title: Text("Status: ${data['status']}"),
//                                 subtitle: Text(
//                                   DateFormat('MMM d, yyyy – hh:mm a').format(
//                                     data['timestamp'].toDate(),
//                                   ),
//                                 ),
//                                 trailing: Chip(
//                                   label: Text(data['status']),
//                                   backgroundColor: statusColor,
//                                   labelStyle: const TextStyle(color: Colors.white),
//                                 ),
//                               ),
//                             );
//                           }).toList(),
//                         );
//                       },
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//
//             const SizedBox(height: 20),
//
//             // Daily Prayer Section
//             Card(
//               elevation: 4,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(16),
//               ),
//               child: Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text(
//                       "Daily Prayer Record",
//                       style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                     ),
//                     const SizedBox(height: 12),
//                     ...prayers.map((prayer) {
//                       return ListTile(
//                         title: Text(prayer, style: const TextStyle(fontSize: 16)),
//                         trailing: Row(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             ElevatedButton(
//                               onPressed: () => _markPrayer(prayer, true),
//                               style: ElevatedButton.styleFrom(
//                                 backgroundColor: Colors.green,
//                               ),
//                               child: const Text("Jamah"),
//                             ),
//                             const SizedBox(width: 8),
//                             ElevatedButton(
//                               onPressed: () => _markPrayer(prayer, false),
//                               style: ElevatedButton.styleFrom(
//                                 backgroundColor: Colors.orange,
//                               ),
//                               child: const Text("Home"),
//                             ),
//                           ],
//                         ),
//                       );
//                     }),
//                   ],
//                 ),
//               ),
//             ),
//
//             const SizedBox(height: 20),
//
//             // Activity Log
//             Card(
//               elevation: 4,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(16),
//               ),
//               child: Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text(
//                       "My Activity Log",
//                       style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                     ),
//                     const SizedBox(height: 12),
//                     StreamBuilder<QuerySnapshot>(
//                       stream: _firestore
//                           .collection('users')
//                           .doc(uid)
//                           .collection('prayers')
//                           .orderBy('timestamp', descending: true)
//                           .limit(10)
//                           .snapshots(),
//                       builder: (context, snapshot) {
//                         if (!snapshot.hasData) {
//                           return const Center(child: CircularProgressIndicator());
//                         }
//
//                         final docs = snapshot.data!.docs;
//                         if (docs.isEmpty) {
//                           return const Padding(
//                             padding: EdgeInsets.all(12),
//                             child: Text(
//                               "No activities recorded yet.",
//                               style: TextStyle(color: Colors.grey),
//                             ),
//                           );
//                         }
//
//                         return ListView.builder(
//                           shrinkWrap: true,
//                           physics: const NeverScrollableScrollPhysics(),
//                           itemCount: docs.length,
//                           itemBuilder: (context, index) {
//                             final doc = docs[index];
//                             final data = doc.data() as Map<String, dynamic>;
//
//                             return Card(
//                               margin: const EdgeInsets.symmetric(vertical: 4),
//                               child: ListTile(
//                                 leading: CircleAvatar(
//                                   backgroundColor: data['jamah'] ? Colors.green : Colors.orange,
//                                   child: Text(
//                                     data['prayer'][0],
//                                     style: const TextStyle(color: Colors.white),
//                                   ),
//                                 ),
//                                 title: Text(
//                                   data['prayer'],
//                                   style: const TextStyle(fontWeight: FontWeight.bold),
//                                 ),
//                                 subtitle: Text(
//                                   DateFormat('MMM d, yyyy – hh:mm a').format(
//                                     data['timestamp'].toDate(),
//                                   ),
//                                 ),
//                                 trailing: Chip(
//                                   label: Text(data['jamah'] ? 'Jamah' : 'Home'),
//                                   backgroundColor: data['jamah'] ? Colors.green : Colors.orange,
//                                   labelStyle: const TextStyle(color: Colors.white),
//                                 ),
//                               ),
//                             );
//                           },
//                         );
//                       },
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//


import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

// Import member tabs
import 'tabs/member_dashboard_tab.dart';
import 'tabs/prayer_attendance_tab.dart';
import 'tabs/class_routine_tab.dart';
import 'tabs/tasks_tab.dart';
import 'tabs/groups_tab.dart';
import 'tabs/activity_tab.dart';
import 'tabs/member_profile_tab.dart';

class MemberDashboard extends StatefulWidget {
  const MemberDashboard({super.key});

  @override
  State<MemberDashboard> createState() => _MemberDashboardState();
}

class _MemberDashboardState extends State<MemberDashboard> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  int _currentIndex = 0;
  Map<String, dynamic>? _memberData;

  @override
  void initState() {
    super.initState();
    _fetchMemberData();
  }

  Future<void> _fetchMemberData() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          setState(() {
            _memberData = doc.data()!;
          });
        }
      }
    } catch (e) {
      print('Error fetching member data: $e');
    }
  }

  // List of all member tab screens
  final List<Widget> _screens = [
    const MemberDashboardTab(),
    const PrayerAttendanceTab(),
    const ClassRoutineTab(),
    const MemberTasksTab(),
    const MemberGroupsTab(),
    const MemberActivityTab(),
    const MemberProfileTab(),
  ];

  // Navigation bar items
  final List<BottomNavigationBarItem> _navItems = [
    const BottomNavigationBarItem(
      icon: Icon(Icons.dashboard),
      label: 'Dashboard',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.mosque),
      label: 'Prayer',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.schedule),
      label: 'Routine',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.assignment),
      label: 'Tasks',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.group),
      label: 'Groups',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.analytics),
      label: 'Activity',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.person),
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _screens[_currentIndex],
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: const Border(
          top: BorderSide(color: Colors.green, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: kBottomNavigationBarHeight,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: SizedBox(
              width: _navItems.length * 100.0,
              child: BottomNavigationBar(
                currentIndex: _currentIndex,
                onTap: (index) => setState(() => _currentIndex = index),
                type: BottomNavigationBarType.fixed,
                backgroundColor: Colors.transparent,
                selectedItemColor: Colors.green,
                unselectedItemColor: Colors.grey[400],
                selectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.normal,
                  fontSize: 12,
                ),
                iconSize: 22,
                items: _navItems,
              ),
            ),
          ),
        ),
      ),
    );
  }
}