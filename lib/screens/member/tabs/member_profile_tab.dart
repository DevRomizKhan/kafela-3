import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:kafela/screens/member/profile/bug_report_suggestion.dart';
import 'package:kafela/screens/member/profile/edit_profile.dart';
import 'package:kafela/screens/member/profile/notification.dart';

class MemberProfileTab extends StatefulWidget {
  const MemberProfileTab({super.key});

  @override
  State<MemberProfileTab> createState() => _MemberProfileTabState();
}

class _MemberProfileTabState extends State<MemberProfileTab> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, dynamic>? _memberData;
  bool _isLoading = true;

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
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error fetching member data: $e');
      setState(() => _isLoading = false);
    }
  }

  String _formatJoinDate(dynamic createdAt) {
    if (createdAt == null) return 'Unknown';

    try {
      if (createdAt is Timestamp) {
        return DateFormat('MMM dd, yyyy').format(createdAt.toDate());
      } else if (createdAt is String) {
        return createdAt;
      } else {
        return 'Unknown';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  Future<void> _logout(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Row(
          children: [
            Icon(Icons.logout, color: Colors.red),
            SizedBox(width: 8),
            Text('Confirm Logout', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _auth.signOut();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Logged out successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Logout failed: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.green),
        ),
      );
    }

    final userName = _memberData?['displayName']?.toString() ?? 'Member';
    final userEmail = _memberData?['email']?.toString() ?? 'No email';
    final createdAt = _memberData?['createdAt'];

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Profile Header
              Card(
                color: Colors.grey[900],
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(
                    height: 230,
                    width: double.infinity,
                    child: Center(
                      child: Column(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.green.withOpacity(0.2),
                            radius: 50,
                            child: const Icon(
                              Icons.person,
                              color: Colors.green,
                              size: 40,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            userName,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            userEmail,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Member',
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Personal Information
              Card(
                color: Colors.grey[900],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Personal Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildInfoItem('Member Since', _formatJoinDate(createdAt),
                          Icons.calendar_today),
                      _buildInfoItem('Role', 'Member', Icons.person),
                      _buildInfoItem('Status', 'Active', Icons.circle,
                          color: Colors.green),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Settings & Actions
              Card(
                color: Colors.grey[900],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Settings',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildSettingOption(
                        'Edit Profile',
                        Icons.edit,
                        Colors.green,
                        () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const EditProfile()));
                        },
                      ),
                      _buildSettingOption(
                        'Notification Settings',
                        Icons.notifications,
                        Colors.orange,
                        () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const Notifications()));
                        },
                      ),
                      _buildSettingOption(
                        'Bug Reports & Suggestions',
                        Icons.bug_report,
                        Colors.teal,
                        () {

                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const BugReport()));

                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Logout Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.logout, color: Colors.white),
                  label: const Text(
                    'Logout',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () => _logout(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(String title, String value, IconData icon,
      {Color color = Colors.green}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildProfileStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.green, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.green,
            fontSize: 18,
            fontWeight: FontWeight.bold,
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

  Widget _buildSettingOption(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing:
          const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
      onTap: onTap,
    );
  }
}

// photo uploaded related part 

// import 'dart:io';
//
// import 'package:flutter/material.dart';
// import 'package:kafela/services/update_service.dart';
//
// import '../profile/edit_profile.dart';
// class ProfileTab extends StatefulWidget {
//   const ProfileTab({Key? key}) : super(key: key);
//
//   @override
//   State<ProfileTab> createState() => _ProfileTabState();
// }
//
// class _ProfileTabState extends State<ProfileTab> {
//   final UpdateService _updateService = UpdateService();
//   Map<String, dynamic> _userProfile = {};
//   bool _isUploading = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _loadUserProfile();
//   }
//
//   Future<void> _loadUserProfile() async {
//     try {
//       final profile = _updateService.getCurrentUserData();
//       setState(() {
//         _userProfile = profile;
//       });
//     } catch (e) {
//       print('Error loading profile: $e');
//     }
//   }
//
//   void _onProfileUpdated() {
//     _loadUserProfile();
//     setState(() {});
//   }
//
//   void _navigateToEditProfile() {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => EditProfile(onProfileUpdated: _onProfileUpdated),
//       ),
//     ).then((_) {
//       _loadUserProfile();
//     });
//   }
//
//   // Show bottom sheet for photo options
//   void _showPhotoOptions() {
//     showModalBottomSheet(
//       context: context,
//       builder: (context) => SafeArea(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             ListTile(
//               leading: const Icon(Icons.photo_library),
//               title: const Text('Choose from Gallery'),
//               onTap: () {
//                 Navigator.pop(context);
//                 _pickImageFromGallery();
//               },
//             ),
//             ListTile(
//               leading: const Icon(Icons.photo_camera),
//               title: const Text('Take Photo'),
//               onTap: () {
//                 Navigator.pop(context);
//                 _pickImageFromCamera();
//               },
//             ),
//             if (_userProfile['photoURL'] != null) ...[
//               const Divider(),
//               ListTile(
//                 leading: const Icon(Icons.delete, color: Colors.red),
//                 title: const Text('Remove Photo', style: TextStyle(color: Colors.red)),
//                 onTap: () {
//                   Navigator.pop(context);
//                   _deletePhoto();
//                 },
//               ),
//             ],
//           ],
//         ),
//       ),
//     );
//   }
//
//   // Pick image from gallery
//   Future<void> _pickImageFromGallery() async {
//     try {
//       setState(() {
//         _isUploading = true;
//       });
//
//       final File? imageFile = await _updateService.pickImageFromGallery();
//
//       if (imageFile != null) {
//         await _updateService.uploadProfilePhoto(imageFile);
//         await _loadUserProfile();
//         _showSuccessSnackBar('Profile photo updated successfully!');
//       }
//     } catch (e) {
//       _showErrorSnackBar('Failed to upload photo: ${e.toString().replaceAll('Exception: ', '')}');
//     } finally {
//       setState(() {
//         _isUploading = false;
//       });
//     }
//   }
//
//   // Pick image from camera
//   Future<void> _pickImageFromCamera() async {
//     try {
//       setState(() {
//         _isUploading = true;
//       });
//
//       final File? imageFile = await _updateService.pickImageFromCamera();
//
//       if (imageFile != null) {
//         await _updateService.uploadProfilePhoto(imageFile);
//         await _loadUserProfile();
//         _showSuccessSnackBar('Profile photo updated successfully!');
//       }
//     } catch (e) {
//       _showErrorSnackBar('Failed to upload photo: ${e.toString().replaceAll('Exception: ', '')}');
//     } finally {
//       setState(() {
//         _isUploading = false;
//       });
//     }
//   }
//
//   // Delete photo - USING SAFE DELETE
//   Future<void> _deletePhoto() async {
//     try {
//       setState(() {
//         _isUploading = true;
//       });
//
//       // Use the safe delete method that doesn't try to delete from storage
//       await _updateService.safeDeleteProfilePhoto();
//       await _loadUserProfile();
//       _showSuccessSnackBar('Profile photo removed successfully!');
//     } catch (e) {
//       _showErrorSnackBar('Failed to remove photo: ${e.toString().replaceAll('Exception: ', '')}');
//     } finally {
//       setState(() {
//         _isUploading = false;
//       });
//     }
//   }
//
//   void _showSuccessSnackBar(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.green,
//         duration: const Duration(seconds: 3),
//       ),
//     );
//   }
//
//   void _showErrorSnackBar(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.red,
//         duration: const Duration(seconds: 4),
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: RefreshIndicator(
//         onRefresh: _loadUserProfile,
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             children: [
//               // User Profile Card with Photo
//               Card(
//                 child: Padding(
//                   padding: const EdgeInsets.all(20.0),
//                   child: Column(
//                     children: [
//                       Stack(
//                         alignment: Alignment.bottomRight,
//                         children: [
//                           // Profile Photo
//                           Container(
//                             width: 100,
//                             height: 100,
//                             decoration: BoxDecoration(
//                               shape: BoxShape.circle,
//                               border: Border.all(
//                                 color: Colors.grey[300]!,
//                                 width: 2,
//                               ),
//                             ),
//                             child: _isUploading
//                                 ? const Center(
//                               child: CircularProgressIndicator(),
//                             )
//                                 : ClipOval(
//                               child: _userProfile['photoURL'] != null &&
//                                   _userProfile['photoURL']!.isNotEmpty
//                                   ? Image.network(
//                                 _userProfile['photoURL']!,
//                                 width: 100,
//                                 height: 100,
//                                 fit: BoxFit.cover,
//                                 loadingBuilder: (context, child, loadingProgress) {
//                                   if (loadingProgress == null) return child;
//                                   return Center(
//                                     child: CircularProgressIndicator(
//                                       value: loadingProgress.expectedTotalBytes != null
//                                           ? loadingProgress.cumulativeBytesLoaded /
//                                           loadingProgress.expectedTotalBytes!
//                                           : null,
//                                     ),
//                                   );
//                                 },
//                                 errorBuilder: (context, error, stackTrace) {
//                                   // If image fails to load, show default icon
//                                   return const Icon(
//                                     Icons.person,
//                                     size: 50,
//                                     color: Colors.grey,
//                                   );
//                                 },
//                               )
//                                   : const Icon(
//                                 Icons.person,
//                                 size: 50,
//                                 color: Colors.grey,
//                               ),
//                             ),
//                           ),
//
//                           // Edit Photo Button
//                           Container(
//                             decoration: BoxDecoration(
//                               color: Colors.green,
//                               shape: BoxShape.circle,
//                               border: Border.all(
//                                 color: Colors.white,
//                                 width: 2,
//                               ),
//                             ),
//                             child: IconButton(
//                               icon: const Icon(
//                                 Icons.camera_alt,
//                                 color: Colors.white,
//                                 size: 18,
//                               ),
//                               onPressed: _isUploading ? null : _showPhotoOptions,
//                             ),
//                           ),
//                         ],
//                       ),
//
//                       const SizedBox(height: 16),
//
//                       Text(
//                         _userProfile['displayName'] ?? 'No Name',
//                         style: const TextStyle(
//                           fontSize: 24,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//
//                       const SizedBox(height: 8),
//
//                       Text(
//                         _userProfile['email'] ?? 'No Email',
//                         style: TextStyle(
//                           fontSize: 16,
//                           color: Colors.grey[600],
//                         ),
//                       ),
//
//                       const SizedBox(height: 8),
//
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Icon(
//                             Icons.verified,
//                             color: _userProfile['emailVerified'] == true
//                                 ? Colors.green
//                                 : Colors.orange,
//                             size: 16,
//                           ),
//                           const SizedBox(width: 4),
//                           Text(
//                             _userProfile['emailVerified'] == true
//                                 ? 'Verified'
//                                 : 'Not Verified',
//                             style: TextStyle(
//                               color: _userProfile['emailVerified'] == true
//                                   ? Colors.green
//                                   : Colors.orange,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//
//               const SizedBox(height: 20),
//
//               // Edit Profile Button
//               SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton.icon(
//                   onPressed: _navigateToEditProfile,
//                   icon: const Icon(Icons.edit),
//                   label: const Text('Edit Profile'),
//                   style: ElevatedButton.styleFrom(
//                     padding: const EdgeInsets.symmetric(vertical: 12),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }