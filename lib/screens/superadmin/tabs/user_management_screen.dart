import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../../services/auth_service.dart';
import '../../admin/tabs/reports_tab.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final List<String> roleFilters = ['All', 'Admin', 'Member'];
  bool _isLoading = false;
  String _searchQuery = '';
  String _selectedRoleFilter = 'All';

  // Controllers for the add user dialog
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _selectedNewUserRole = 'Member';
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _addNewUser() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Validate inputs
      if (_nameController.text.isEmpty ||
          _emailController.text.isEmpty ||
          _passwordController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fill in all fields'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Create user in Firebase Authentication using a separate Firebase instance
      // This prevents auto-login in the main app
      final FirebaseApp tempApp = await Firebase.initializeApp(
        name: 'TempAuth',
        options: Firebase.app().options,
      );

      final FirebaseAuth tempAuth = FirebaseAuth.instanceFor(app: tempApp);

      try {
        final UserCredential userCredential = await tempAuth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        final String userId = userCredential.user!.uid;

        // Add user to Firestore with additional details
        await _firestore.collection('users').doc(userId).set({
          'uid': userId,
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'role': _selectedNewUserRole,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User added successfully with Firebase Authentication!'),
            backgroundColor: Colors.green,
          ),
        );

      } finally {
        // Always delete the temporary app to clean up
        await tempApp.delete();
      }

      // Clear controllers and reset form for next user
      _nameController.clear();
      _emailController.clear();
      _passwordController.clear();
      _selectedNewUserRole = 'Member';
      _isPasswordVisible = false;

      // Close the dialog - stay on current page
      if (mounted) {
        Navigator.of(context).pop();
      }

    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Failed to create user: ';
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage += 'Email is already registered';
          break;
        case 'invalid-email':
          errorMessage += 'Invalid email address';
          break;
        case 'weak-password':
          errorMessage += 'Password is too weak';
          break;
        default:
          errorMessage += e.message ?? 'Unknown error occurred';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add user: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  void _showAddUserDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            'Add New User',
            style: TextStyle(color: Colors.green),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Name Field
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    labelStyle: TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.green),
                    ),
                    prefixIcon: Icon(Icons.person, color: Colors.green),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 16),

                // Email Field
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    labelStyle: TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.green),
                    ),
                    prefixIcon: Icon(Icons.email, color: Colors.green),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 16),

                // Password Field with visibility toggle
                TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: const TextStyle(color: Colors.grey),
                    border: const OutlineInputBorder(),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.green),
                    ),
                    prefixIcon: const Icon(Icons.lock, color: Colors.green),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors.green,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),
                  obscureText: !_isPasswordVisible,
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 16),

                // Role Dropdown
                Row(
                  children: [
                    const Text(
                      'Role:',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.green),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedNewUserRole,
                            dropdownColor: Colors.grey[800],
                            style: const TextStyle(color: Colors.white),
                            items: ['Member', 'Admin'].map((String role) {
                              return DropdownMenuItem<String>(
                                value: role,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: Text(role),
                                ),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _selectedNewUserRole = newValue;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              onPressed: _isLoading ? null : _addNewUser,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
                  : const Text(
                'Add User',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateUserRole(String uid, String newRole) async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.updateUserRole(uid, newRole);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('User role updated to $newRole'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update role: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'Admin':
        return Colors.green;
      case 'Member':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'Admin':
        return Icons.manage_accounts;
      case 'Member':
        return Icons.person;
      default:
        return Icons.person;
    }
  }

  // Function to show member reports using the ReportsTab
  void _showMemberReports(BuildContext context, String userId, String userName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.grey[900],
            title: Text(
              '$userName - Reports',
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
            iconTheme: const IconThemeData(color: Colors.green),
          ),
          body: ReportsTab(
            selectedMemberId: userId,
            selectedMemberName: userName,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.grey[900],
        title: const Text(
          'User Management',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.green),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Search and Filter Section
              Card(
                elevation: 4,
                color: Colors.grey[900],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Search Field
                      TextField(
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Search users...',
                          labelStyle: const TextStyle(color: Colors.grey),
                          prefixIcon: const Icon(Icons.search, color: Colors.green),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.green),
                          ),
                          filled: true,
                          fillColor: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Role Filter and Add User Button
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isWideScreen = constraints.maxWidth > 600;

                          return isWideScreen
                              ? _buildWideFilterRow()
                              : _buildNarrowFilterColumn();
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // User List Section
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: double.infinity,
                    minHeight: double.infinity,
                  ),
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _firestore.collection('users').snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: Colors.green));
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(
                          child: Text(
                            'No users found',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        );
                      }

                      // Filter users based on selected role and search query
                      final users = snapshot.data!.docs.where((doc) {
                        final userData = doc.data() as Map<String, dynamic>;
                        final role = userData['role'] as String? ?? 'Member';
                        final name = userData['name'] as String? ?? '';
                        final email = userData['email'] as String? ?? '';

                        // Role filter
                        if (_selectedRoleFilter != 'All' && role != _selectedRoleFilter) {
                          return false;
                        }

                        // Search filter
                        if (_searchQuery.isNotEmpty) {
                          final query = _searchQuery.toLowerCase();
                          return name.toLowerCase().contains(query) ||
                              email.toLowerCase().contains(query);
                        }

                        return true;
                      }).toList();

                      if (users.isEmpty) {
                        return const Center(
                          child: Text(
                            'No users match your filters',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: users.length,
                        itemBuilder: (context, index) {
                          final user = users[index].data() as Map<String, dynamic>;
                          final userId = users[index].id;
                          final userName = user['name'] ?? 'Unknown User';
                          final userEmail = user['email'] ?? 'No email';
                          final userRole = user['role'] ?? 'Member';

                          return Card(
                            elevation: 2,
                            color: Colors.grey[800],
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              leading: GestureDetector(
                                onTap: userRole == 'Member'
                                    ? () => _showMemberReports(context, userId, userName)
                                    : null,
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: userRole == 'Member'
                                          ? Colors.green
                                          : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                  child: CircleAvatar(
                                    backgroundColor: _getRoleColor(userRole),
                                    child: Icon(
                                      _getRoleIcon(userRole),
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                              title: Text(
                                userName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    userEmail,
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getRoleColor(userRole).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: _getRoleColor(userRole).withOpacity(0.3),
                                      ),
                                    ),
                                    child: Text(
                                      userRole,
                                      style: TextStyle(
                                        color: _getRoleColor(userRole),
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              trailing: LayoutBuilder(
                                builder: (context, constraints) {
                                  final isWide = constraints.maxWidth > 400;

                                  return isWide
                                      ? _buildWideTrailing(userId, userRole)
                                      : _buildNarrowTrailing(userId, userRole);
                                },
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWideFilterRow() {
    return Row(
      children: [
        const Text(
          'Filter by role:',
          style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey),
        ),
        const SizedBox(width: 12),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.green),
            borderRadius: BorderRadius.circular(4),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedRoleFilter,
              dropdownColor: Colors.grey[800],
              style: const TextStyle(color: Colors.white),
              items: roleFilters.map((String role) {
                return DropdownMenuItem<String>(
                  value: role,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(role),
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedRoleFilter = newValue;
                  });
                }
              },
            ),
          ),
        ),
        const Spacer(),
        ElevatedButton.icon(
          onPressed: () {
            _showAddUserDialog(context);
          },
          icon: const Icon(Icons.person_add, size: 20, color: Colors.white),
          label: const Text('Add User', style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNarrowFilterColumn() {
    return Column(
      children: [
        Row(
          children: [
            const Text(
              'Filter by role:',
              style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green),
                borderRadius: BorderRadius.circular(4),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedRoleFilter,
                  dropdownColor: Colors.grey[800],
                  style: const TextStyle(color: Colors.white),
                  items: roleFilters.map((String role) {
                    return DropdownMenuItem<String>(
                      value: role,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(role),
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedRoleFilter = newValue;
                      });
                    }
                  },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              _showAddUserDialog(context);
            },
            icon: const Icon(Icons.person_add, size: 20, color: Colors.white),
            label: const Text('', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWideTrailing(String userId, String userRole) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Role Change Dropdown
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.green),
            borderRadius: BorderRadius.circular(6),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: userRole,
              dropdownColor: Colors.grey[800],
              style: const TextStyle(color: Colors.white),
              items: <String>['Member', 'Admin'].map((String role) {
                return DropdownMenuItem<String>(
                  value: role,
                  child: Text(role),
                );
              }).toList(),
              onChanged: (String? newRole) {
                if (newRole != null) {
                  _updateUserRole(userId, newRole);
                }
              },
              underline: const SizedBox(),
              icon: const Icon(Icons.arrow_drop_down, size: 20, color: Colors.green),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Delete Button
        IconButton(
          icon: const Icon(Icons.delete, color: Colors.red, size: 20),
          onPressed: () {
            _showDeleteConfirmationDialog(context, userId);
          },
        ),
      ],
    );
  }

  Widget _buildNarrowTrailing(String userId, String userRole) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Colors.green),
      color: Colors.grey[800],
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'change_role',
          child: Row(
            children: [
              const Icon(Icons.swap_horiz, size: 20, color: Colors.green),
              const SizedBox(width: 8),
              const Text('Change Role', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              const Icon(Icons.delete, color: Colors.red, size: 20),
              const SizedBox(width: 8),
              const Text('Delete User', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        if (value == 'change_role') {
          _showRoleChangeDialog(context, userId, userRole);
        } else if (value == 'delete') {
          _showDeleteConfirmationDialog(context, userId);
        }
      },
    );
  }

  void _showRoleChangeDialog(BuildContext context, String userId, String currentRole) {
    String newRole = currentRole;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            'Change User Role',
            style: TextStyle(color: Colors.green),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select new role for this user:',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.green),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: newRole,
                    dropdownColor: Colors.grey[800],
                    style: const TextStyle(color: Colors.white),
                    items: <String>['Member', 'Admin'].map((String role) {
                      return DropdownMenuItem<String>(
                        value: role,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(role),
                        ),
                      );
                    }).toList(),
                    onChanged: (String? value) {
                      if (value != null) {
                        newRole = value;
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Update', style: TextStyle(color: Colors.white)),
              onPressed: () {
                _updateUserRole(userId, newRole);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Function to show delete confirmation dialog
  void _showDeleteConfirmationDialog(BuildContext context, String userId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            'Delete User',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Are you sure you want to delete this user? This action cannot be undone.',
            style: TextStyle(color: Colors.grey),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
              onPressed: () async {
                try {
                  // Delete from Firebase Authentication first
                  await _auth.currentUser?.delete();

                  // Then delete from Firestore
                  await _firestore.collection('users').doc(userId).delete();

                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('User deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (error) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete user: $error'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }
}