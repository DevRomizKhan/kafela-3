// class UserModel {
//   final String uid;
//   final String email;
//   final String role;
//   final bool approved;
//
//   UserModel({
//     required this.uid,
//     required this.email,
//     required this.role,
//     required this.approved,
//   });
//
//   Map<String, dynamic> toMap() => {
//     'uid': uid,
//     'email': email,
//     'role': role,
//     'approved': approved,
//   };
//
//   factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
//     uid: map['uid'],
//     email: map['email'],
//     role: map['role'],
//     approved: map['approved'],
//   );
// }


import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String name;
  final String role;
  final DateTime createdAt;
  final bool isActive;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    required this.createdAt,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'role': role,
      'createdAt': createdAt,
      'isActive': isActive,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      role: map['role'] ?? 'Member',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      isActive: map['isActive'] ?? true,
    );
  }
}
