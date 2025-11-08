import 'package:flutter/material.dart';
import 'package:kafela/services/update_service.dart';

class EditProfile extends StatefulWidget {
  final Function()? onProfileUpdated; // Callback to notify parent

  const EditProfile({Key? key, this.onProfileUpdated}) : super(key: key);

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final UpdateService _updateService = UpdateService();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _needsReauth = false;
  Map<String, dynamic> _userProfile = {};

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final profile = await _updateService.getUserProfile();
      setState(() {
        _userProfile = profile;
        _nameController.text = profile['displayName'] ?? '';
        _emailController.text = profile['email'] ?? '';
      });
    } catch (e) {
      _showErrorDialog('Failed to load profile: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final String newName = _nameController.text.trim();
      final String newEmail = _emailController.text.trim();
      bool nameUpdated = false;
      bool emailUpdated = false;

      // Update display name
      if (newName != _userProfile['displayName']) {
        await _updateService.updateUserProfile(displayName: newName);
        nameUpdated = true;
      }

      // Update email if changed
      if (newEmail != _userProfile['email']) {
        // If re-authentication is needed
        if (_needsReauth) {
          final String password = _passwordController.text.trim();
          await _updateService.reauthenticateUser(password);
        }

        await _updateService.updateUserEmail(newEmail);
        emailUpdated = true;

        // Show success message for email verification
        _showSuccessDialog(
          'Verification Email Sent',
          'A verification email has been sent to $newEmail. '
              'Please verify your new email address to complete the update.',
        );
      } else if (nameUpdated) {
        // Only name was updated
        _showSuccessDialog('Profile Updated', 'Your profile has been updated successfully!');
      }

      // Notify parent widget about profile update
      if (widget.onProfileUpdated != null) {
        widget.onProfileUpdated!();
      }

      // Reload profile data with fresh data
      await _loadUserProfile();
      setState(() {
        _needsReauth = false;
        _passwordController.clear();
      });

    } catch (e) {
      if (e.toString().contains('re-authenticate')) {
        setState(() {
          _needsReauth = true;
        });
        _showErrorDialog('Security verification required. Please enter your password to continue.');
      } else {
        _showErrorDialog('Failed to update profile: $e');
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSuccessDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              // Also pop the edit profile screen if only name was updated
              if (!message.contains('verification email')) {
                Navigator.pop(context);
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Profile'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          // Close button to go back to profile
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: _isLoading && _userProfile.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Current User Info
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SizedBox(
                      height: 110,
                      width: double.infinity,
                      child: Center(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Current Profile',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text('Name: ${_userProfile['displayName'] ?? 'Not set'}'),
                            Text('Email: ${_userProfile['email'] ?? 'Not set'}'),

                            const SizedBox(height: 10),
                            Text(
                              'Email Verified: ${_userProfile['emailVerified'] == true ? 'Yes' : 'No'}',
                              style: TextStyle(
                                color: _userProfile['emailVerified'] == true
                                    ? Colors.green
                                    : Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Name Field
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Display Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Email Field
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),

                // Re-authentication Field (shown when needed)
                if (_needsReauth) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Current Password',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (_needsReauth && (value == null || value.isEmpty)) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Security verification required to update email',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 12,
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Update Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _updateProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                        : const Text(
                      'Update Profile',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),

                // Info Text
                const SizedBox(height: 16),
                const Card(
                  color: Colors.white,
                  child: Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Text(
                      'Note: Changing your email will require verification. '
                          'A verification email will be sent to your new email address. '
                          'Please logout and login again to see changing',

                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}