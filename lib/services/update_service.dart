// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
//
// class UpdateService {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//
//   // Get current user
//   User? get currentUser => _auth.currentUser;
//
//   // Update user profile (display name and photo URL)
//   Future<void> updateUserProfile({
//     required String displayName,
//     String? photoURL,
//   }) async {
//     try {
//       final User? user = _auth.currentUser;
//
//       if (user == null) {
//         throw Exception('No user logged in');
//       }
//
//       // Update profile in Firebase Auth
//       await user.updateDisplayName(displayName);
//       if (photoURL != null) {
//         await user.updatePhotoURL(photoURL);
//       }
//
//       // Optional: Update in Firestore if you store user data there
//       await _updateUserInFirestore(displayName, photoURL);
//
//       // Reload user to get updated data
//       await user.reload();
//
//     } on FirebaseAuthException catch (e) {
//       throw _handleAuthError(e);
//     } catch (e) {
//       throw Exception('Failed to update profile: $e');
//     }
//   }
//
//   // Update user email with verification
//   Future<void> updateUserEmail(String newEmail) async {
//     try {
//       final User? user = _auth.currentUser;
//
//       if (user == null) {
//         throw Exception('No user logged in');
//       }
//
//       // Check if email is already in use
//       await _checkEmailAvailability(newEmail);
//
//       // Send verification email to the new address
//       await user.verifyBeforeUpdateEmail(newEmail);
//
//       // Optional: Update email in Firestore
//       await _updateEmailInFirestore(newEmail);
//
//     } on FirebaseAuthException catch (e) {
//       throw _handleAuthError(e);
//     } catch (e) {
//       throw Exception('Failed to update email: $e');
//     }
//   }
//
//   // Re-authenticate user (required for sensitive operations)
//   Future<void> reauthenticateUser(String password) async {
//     try {
//       final User? user = _auth.currentUser;
//
//       if (user == null || user.email == null) {
//         throw Exception('No user logged in');
//       }
//
//       // Create credential
//       final AuthCredential credential = EmailAuthProvider.credential(
//         email: user.email!,
//         password: password,
//       );
//
//       // Re-authenticate
//       await user.reauthenticateWithCredential(credential);
//
//     } on FirebaseAuthException catch (e) {
//       throw _handleAuthError(e);
//     }
//   }
//
//   // Check if email is available
//   Future<void> _checkEmailAvailability(String email) async {
//     try {
//       final methods = await _auth.fetchSignInMethodsForEmail(email);
//       if (methods.isNotEmpty) {
//         throw Exception('Email is already in use by another account');
//       }
//     } on FirebaseAuthException catch (e) {
//       if (e.code == 'invalid-email') {
//         throw Exception('Invalid email address');
//       }
//       rethrow;
//     }
//   }
//
//   // Update user data in Firestore (optional)
//   Future<void> _updateUserInFirestore(String displayName, String? photoURL) async {
//     final User? user = _auth.currentUser;
//     if (user != null) {
//       await _firestore.collection('users').doc(user.uid).set({
//         'displayName': displayName,
//         'photoURL': photoURL,
//         'updatedAt': FieldValue.serverTimestamp(),
//       }, SetOptions(merge: true));
//     }
//   }
//
//   // Update email in Firestore (optional)
//   Future<void> _updateEmailInFirestore(String newEmail) async {
//     final User? user = _auth.currentUser;
//     if (user != null) {
//       await _firestore.collection('users').doc(user.uid).set({
//         'email': newEmail,
//         'emailVerified': false,
//         'updatedAt': FieldValue.serverTimestamp(),
//       }, SetOptions(merge: true));
//     }
//   }
//
//   // Handle Firebase Auth errors
//   String _handleAuthError(FirebaseAuthException e) {
//     switch (e.code) {
//       case 'requires-recent-login':
//         return 'Please re-authenticate to update your email';
//       case 'email-already-in-use':
//         return 'Email is already in use by another account';
//       case 'invalid-email':
//         return 'Invalid email address';
//       case 'weak-password':
//         return 'Password is too weak';
//       case 'user-not-found':
//         return 'User not found';
//       case 'wrong-password':
//         return 'Incorrect password';
//       case 'network-request-failed':
//         return 'Network error. Please check your connection';
//       default:
//         return 'An error occurred: ${e.message}';
//     }
//   }
//
//   // Get user profile data
//   Future<Map<String, dynamic>> getUserProfile() async {
//     final User? user = _auth.currentUser;
//
//     if (user == null) {
//       throw Exception('No user logged in');
//     }
//
//     return {
//       'uid': user.uid,
//       'email': user.email,
//       'displayName': user.displayName,
//       'photoURL': user.photoURL,
//       'emailVerified': user.emailVerified,
//     };
//   }
// }

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class UpdateService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Update user profile (display name and photo URL)
  Future<void> updateUserProfile({
    required String displayName,
    String? photoURL,
  }) async {
    try {
      final User? user = _auth.currentUser;

      if (user == null) {
        throw Exception('No user logged in');
      }

      // Update profile in Firebase Auth
      await user.updateDisplayName(displayName);
      if (photoURL != null) {
        await user.updatePhotoURL(photoURL);
      }

      // Update in Firestore for consistency
      await _updateUserInFirestore(displayName, photoURL);

      // Reload user to get updated data immediately
      await user.reload();

    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  // Update user email with verification
  Future<void> updateUserEmail(String newEmail) async {
    try {
      final User? user = _auth.currentUser;

      if (user == null) {
        throw Exception('No user logged in');
      }

      // Check if email is already in use
      await _checkEmailAvailability(newEmail);

      // Send verification email to the new address
      await user.verifyBeforeUpdateEmail(newEmail);

      // Update email in Firestore
      await _updateEmailInFirestore(newEmail);

      // Reload user data
      await user.reload();

    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      throw Exception('Failed to update email: $e');
    }
  }

  // Re-authenticate user (required for sensitive operations)
  Future<void> reauthenticateUser(String password) async {
    try {
      final User? user = _auth.currentUser;

      if (user == null || user.email == null) {
        throw Exception('No user logged in');
      }

      // Create credential
      final AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );

      // Re-authenticate
      await user.reauthenticateWithCredential(credential);

    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Check if email is available
  Future<void> _checkEmailAvailability(String email) async {
    try {
      final methods = await _auth.fetchSignInMethodsForEmail(email);
      if (methods.isNotEmpty) {
        throw Exception('Email is already in use by another account');
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-email') {
        throw Exception('Invalid email address');
      }
      rethrow;
    }
  }

  // Update user data in Firestore
  Future<void> _updateUserInFirestore(String displayName, String? photoURL) async {
    final User? user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).set({
        'displayName': displayName,
        'photoURL': photoURL,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  // Update email in Firestore
  Future<void> _updateEmailInFirestore(String newEmail) async {
    final User? user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).set({
        'email': newEmail,
        'emailVerified': false,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  // Get user profile data - ALWAYS FETCH FRESH DATA
  Future<Map<String, dynamic>> getUserProfile() async {
    final User? user = _auth.currentUser;

    if (user == null) {
      throw Exception('No user logged in');
    }



    // Always get fresh data from Firebase Auth
    await user.reload();
    final User refreshedUser = _auth.currentUser!;

    return {
      'uid': refreshedUser.uid,
      'email': refreshedUser.email,
      'displayName': refreshedUser.displayName,
      'photoURL': refreshedUser.photoURL,
      'emailVerified': refreshedUser.emailVerified,
    };
  }


  Future<String> uploadProfilePhoto(File imageFile) async {
    try {
      final User? user = _auth.currentUser;

      if (user == null) {
        throw Exception('No user logged in');
      }

      // Create reference to Firebase Storage
      final Reference storageRef = _storage
          .ref()
          .child('profile_photos')
          .child('${user.uid}.jpg');

      // Upload file to Firebase Storage with error handling
      try {
        final UploadTask uploadTask = storageRef.putFile(imageFile);
        final TaskSnapshot snapshot = await uploadTask;

        // Get download URL
        final String downloadURL = await snapshot.ref.getDownloadURL();

        // Update user profile with new photo URL
        await user.updatePhotoURL(downloadURL);

        // Update in Firestore
        await _updatePhotoInFirestore(downloadURL);

        // Reload user to get updated data
        await user.reload();

        return downloadURL;
      } on FirebaseException catch (e) {
        throw Exception('Upload failed: ${e.message}');
      }

    } catch (e) {
      throw Exception('Failed to upload photo: $e');
    }
  }

  // Pick image from gallery
  Future<File?> pickImageFromGallery() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to pick image: $e');
    }
  }

  // Pick image from camera
  Future<File?> pickImageFromCamera() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to capture image: $e');
    }
  }

  // Delete profile photo - FIXED VERSION
  Future<void> deleteProfilePhoto() async {
    try {
      final User? user = _auth.currentUser;

      if (user == null) {
        throw Exception('No user logged in');
      }

      // Check if photo exists in Firebase Auth
      final bool hasPhotoInAuth = user.photoURL != null && user.photoURL!.isNotEmpty;

      // Delete from Firebase Storage only if we know the file exists
      if (hasPhotoInAuth) {
        try {
          final Reference storageRef = _storage
              .ref()
              .child('profile_photos')
              .child('${user.uid}.jpg');

          // Check if file exists before trying to delete
          try {
            // This will throw an exception if file doesn't exist
            final String existingUrl = await storageRef.getDownloadURL();

            // If we get here, file exists - so delete it
            await storageRef.delete();
            print('Photo deleted from storage successfully');
          } on FirebaseException catch (e) {
            if (e.code == 'object-not-found') {
              print('Photo not found in storage, continuing with profile update');
            } else {
              print('Error checking storage: ${e.message}');
              // Don't throw, continue with profile update
            }
          }
        } catch (e) {
          print('Error during storage deletion: $e');
          // Continue with profile update even if storage deletion fails
        }
      }

      // Always remove photo URL from user profile (this is the main operation)
      await user.updatePhotoURL(null);

      // Update in Firestore
      await _updatePhotoInFirestore(null);

      // Reload user
      await user.reload();

      print('Profile photo removed successfully');

    } on FirebaseAuthException catch (e) {
      throw Exception('Failed to update profile: ${e.message}');
    } catch (e) {
      throw Exception('Failed to delete photo: $e');
    }
  }

  // Safe delete method - alternative approach
  Future<void> safeDeleteProfilePhoto() async {
    try {
      final User? user = _auth.currentUser;

      if (user == null) {
        throw Exception('No user logged in');
      }

      // Simply update the user profile to remove photo URL
      // Don't worry about storage cleanup for now
      await user.updatePhotoURL(null);
      await _updatePhotoInFirestore(null);
      await user.reload();

    } catch (e) {
      throw Exception('Failed to remove photo: $e');
    }
  }

  // Check if photo exists in storage
  Future<bool> checkPhotoExists() async {
    try {
      final User? user = _auth.currentUser;

      if (user == null) return false;

      final Reference storageRef = _storage
          .ref()
          .child('profile_photos')
          .child('${user.uid}.jpg');

      // Try to get download URL - if it succeeds, file exists
      await storageRef.getDownloadURL();
      return true;
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') {
        return false;
      }
      rethrow;
    }
  }

  // Update photo in Firestore
  Future<void> _updatePhotoInFirestore(String? photoURL) async {
    final User? user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).set({
        'photoURL': photoURL,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  // Get fresh user data without reloading (for real-time updates)
  Map<String, dynamic> getCurrentUserData() {
    final User? user = _auth.currentUser;

    if (user == null) {
      throw Exception('No user logged in');
    }

    return {
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName,
      'photoURL': user.photoURL,
      'emailVerified': user.emailVerified,
    };
  }

  // Handle Firebase Auth errors
  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'requires-recent-login':
        return 'Please re-authenticate to update your email';
      case 'email-already-in-use':
        return 'Email is already in use by another account';
      case 'invalid-email':
        return 'Invalid email address';
      case 'weak-password':
        return 'Password is too weak';
      case 'user-not-found':
        return 'User not found';
      case 'wrong-password':
        return 'Incorrect password';
      case 'network-request-failed':
        return 'Network error. Please check your connection';
      default:
        return 'An error occurred: ${e.message}';
    }
  }




}