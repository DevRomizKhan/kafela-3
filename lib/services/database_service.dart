// lib/services/database_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>> getDashboardStats() async {
    final totalUsers = await getTotalUsers();
    final totalMeetings = await getTotalMeetings();
    final roles = await getUsersByRole();

    return {
      'totalUsers': totalUsers,
      'totalMeetings': totalMeetings,
      'superAdmins': roles['SuperAdmin'] ?? 0,
      'admins': roles['Admin'] ?? 0,
      'members': roles['Member'] ?? 0,
    };
  }

  Future<int> getTotalUsers() async {
    final snapshot = await _firestore.collection('users').get();
    return snapshot.size;
  }

  Future<int> getTotalMeetings() async {
    final snapshot = await _firestore.collection('meetings').get();
    return snapshot.size;
  }

  Future<Map<String, int>> getUsersByRole() async {
    final snapshot = await _firestore.collection('users').get();
    final roles = {'SuperAdmin': 0, 'Admin': 0, 'Member': 0};

    for (var doc in snapshot.docs) {
      final role = doc['role'] as String?;
      if (role != null) {
        roles[role] = roles[role]! + 1;
      }
    }

    return roles;
  }

  Stream<QuerySnapshot> getUsersStream() {
    return _firestore.collection('users').snapshots();
  }
}
