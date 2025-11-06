import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'group_chat_page.dart';

class GroupsTab extends StatefulWidget {
  const GroupsTab({super.key});

  @override
  State<GroupsTab> createState() => _GroupsTabState();
}

class _GroupsTabState extends State<GroupsTab> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _groupNameController = TextEditingController();
  List<Map<String, dynamic>> _members = [];
  List<String> _selectedMembers = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchMembers();
  }

  Future<void> _fetchMembers() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'Member')
          .limit(100)
          .get();

      setState(() {
        _members = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'uid': doc.id,
            'name': data['name'] ?? 'Unknown Member',
            'email': data['email'] ?? 'No email',
          };
        }).toList();
      });
    } catch (e) {
      print('Error fetching members: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Header
              Card(
                color: Colors.grey[900],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.group, color: Colors.green, size: 28),
                      const SizedBox(width: 12),
                      const Text(
                        'Group Management',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.add, color: Colors.green),
                        onPressed: _showCreateGroupDialog,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Groups List
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore.collection('groups').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Colors.green));
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Text(
                          'No groups found',
                          style: TextStyle(color: Colors.white),
                        ),
                      );
                    }

                    final groups = snapshot.data!.docs;

                    return ListView.builder(
                      itemCount: groups.length,
                      itemBuilder: (context, index) {
                        final group = groups[index].data() as Map<String, dynamic>;
                        final groupId = groups[index].id;
                        final members = List<String>.from(group['members'] ?? []);
                        final memberNames = List<String>.from(group['memberNames'] ?? []);

                        return Card(
                          color: Colors.grey[800],
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.green.withOpacity(0.2),
                              child: const Icon(Icons.group, color: Colors.green),
                            ),
                            title: Text(
                              group['name'] ?? 'No Name',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${members.length} members',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                                if (memberNames.isNotEmpty)
                                  Text(
                                    'Members: ${memberNames.take(3).join(', ')}${memberNames.length > 3 ? '...' : ''}',
                                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                                  ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.chat, color: Colors.green),
                                  onPressed: () => _navigateToGroupChat(groupId, group['name']),
                                ),
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert, color: Colors.grey),
                                  onSelected: (value) {
                                    if (value == 'edit') {
                                      _showEditGroupDialog(groupId, group, members);
                                    } else if (value == 'delete') {
                                      _deleteGroup(groupId);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit, color: Colors.blue),
                                          SizedBox(width: 8),
                                          Text('Edit Group'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete, color: Colors.red),
                                          SizedBox(width: 8),
                                          Text('Delete Group'),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            // trailing: PopupMenuButton<String>(
                            //
                            //   icon: const Icon(Icons.more_vert, color: Colors.grey),
                            //   onSelected: (value) {
                            //     if (value == 'edit') {
                            //       _showEditGroupDialog(groupId, group, members);
                            //     } else if (value == 'delete') {
                            //       _deleteGroup(groupId);
                            //     }
                            //   },
                            //   itemBuilder: (context) => [
                            //     const PopupMenuItem(
                            //       value: 'edit',
                            //       child: Row(
                            //         children: [
                            //           Icon(Icons.edit, color: Colors.blue),
                            //           SizedBox(width: 8),
                            //           Text('Edit Group'),
                            //         ],
                            //       ),
                            //     ),
                            //     const PopupMenuItem(
                            //       value: 'delete',
                            //       child: Row(
                            //         children: [
                            //           Icon(Icons.delete, color: Colors.red),
                            //           SizedBox(width: 8),
                            //           Text('Delete Group'),
                            //         ],
                            //       ),
                            //     ),
                            //   ],
                            // ),
                            //


                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  void _navigateToGroupChat(String groupId, String groupName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroupChatPage(
          groupId: groupId,
          groupName: groupName,
        ),
      ),
    );
  }

  // void _showCreateGroupDialog() {
  //   _selectedMembers.clear();
  //   _groupNameController.clear();
  //
  //   showDialog(
  //     context: context,
  //     builder: (context) => StatefulBuilder(
  //       builder: (context, setDialogState) {
  //         return AlertDialog(
  //           backgroundColor: Colors.grey[900],
  //           title: const Text(
  //             'Create New Group',
  //             style: TextStyle(color: Colors.green),
  //           ),
  //           content: SingleChildScrollView(
  //             child: Column(
  //               mainAxisSize: MainAxisSize.min,
  //               children: [
  //                 TextField(
  //                   controller: _groupNameController,
  //                   decoration: const InputDecoration(
  //                     labelText: 'Group Name',
  //                     labelStyle: TextStyle(color: Colors.grey),
  //                     border: OutlineInputBorder(),
  //                     focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.green)),
  //                   ),
  //                   style: const TextStyle(color: Colors.white),
  //                 ),
  //                 const SizedBox(height: 16),
  //                 const Text(
  //                   'Select Members:',
  //                   style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
  //                 ),
  //                 const SizedBox(height: 8),
  //                 Flexible(
  //                   child: Container(
  //                     constraints: const BoxConstraints(maxHeight: 200),
  //                     child: ListView.builder(
  //                       shrinkWrap: true,
  //                       itemCount: _members.length,
  //                       itemBuilder: (context, index) {
  //                         final member = _members[index];
  //                         final isSelected = _selectedMembers.contains(member['uid']);
  //
  //                         return CheckboxListTile(
  //                           value: isSelected,
  //                           onChanged: (value) {
  //                             setDialogState(() {
  //                               if (value == true) {
  //                                 _selectedMembers.add(member['uid']);
  //                               } else {
  //                                 _selectedMembers.remove(member['uid']);
  //                               }
  //                             });
  //                           },
  //                           title: Text(
  //                             member['name'],
  //                             style: const TextStyle(color: Colors.white),
  //                           ),
  //                           subtitle: Text(
  //                             member['email'],
  //                             style: const TextStyle(color: Colors.grey),
  //                           ),
  //                           checkColor: Colors.white,
  //                           activeColor: Colors.green,
  //                         );
  //                       },
  //                     ),
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ),
  //           actions: [
  //             TextButton(
  //               onPressed: () => Navigator.pop(context),
  //               child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
  //             ),
  //             ElevatedButton(
  //               onPressed: _selectedMembers.isEmpty ? null : _createGroup,
  //               style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
  //               child: const Text('Create Group'),
  //             ),
  //           ],
  //         );
  //       },
  //     ),
  //   );
  // }
  void _showCreateGroupDialog() {
    _selectedMembers.clear();
    _groupNameController.clear();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: Colors.grey[900],
            title: const Text(
              'Create New Group',
              style: TextStyle(color: Colors.green),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Group Name Input
                TextField(
                  controller: _groupNameController,
                  decoration: const InputDecoration(
                    labelText: 'Group Name',
                    labelStyle: TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.green)),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 16),

                // Members Selection Label
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Select Members:',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),

                // Members List
                SizedBox(
                  height: 300, // Fixed height to prevent freeze on desktop
                  width: double.maxFinite,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _members.length,
                    itemBuilder: (context, index) {
                      final member = _members[index];
                      final isSelected = _selectedMembers.contains(member['uid']);

                      return CheckboxListTile(
                        value: isSelected,
                        onChanged: (value) {
                          setDialogState(() {
                            if (value == true) {
                              _selectedMembers.add(member['uid']);
                            } else {
                              _selectedMembers.remove(member['uid']);
                            }
                          });
                        },
                        title: Text(member['name'],
                            style: const TextStyle(color: Colors.white)),
                        subtitle: Text(member['email'],
                            style: const TextStyle(color: Colors.grey)),
                        checkColor: Colors.white,
                        activeColor: Colors.green,
                      );
                    },
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: _selectedMembers.isEmpty ? null : _createGroup,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('Create Group'),
              ),
            ],
          );
        },
      ),
    );
  }

  // void _showEditGroupDialog(String groupId, Map<String, dynamic> group, List<String> currentMembers) {
  //   _selectedMembers = List.from(currentMembers);
  //   _groupNameController.text = group['name'] ?? '';
  //
  //   showDialog(
  //     context: context,
  //     builder: (context) => StatefulBuilder(
  //       builder: (context, setDialogState) {
  //         return AlertDialog(
  //           backgroundColor: Colors.grey[900],
  //           title: const Text(
  //             'Edit Group',
  //             style: TextStyle(color: Colors.green),
  //           ),
  //           content: SingleChildScrollView(
  //             child: Column(
  //               mainAxisSize: MainAxisSize.min,
  //               children: [
  //                 TextField(
  //                   controller: _groupNameController,
  //                   decoration: const InputDecoration(
  //                     labelText: 'Group Name',
  //                     labelStyle: TextStyle(color: Colors.grey),
  //                     border: OutlineInputBorder(),
  //                     focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.green)),
  //                   ),
  //                   style: const TextStyle(color: Colors.white),
  //                 ),
  //                 const SizedBox(height: 16),
  //                 const Text(
  //                   'Select Members:',
  //                   style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
  //                 ),
  //                 const SizedBox(height: 8),
  //                 Container(
  //                   constraints: const BoxConstraints(maxHeight: 200),
  //                   child: ListView.builder(
  //                     shrinkWrap: true,
  //                     itemCount: _members.length,
  //                     itemBuilder: (context, index) {
  //                       final member = _members[index];
  //                       final isSelected = _selectedMembers.contains(member['uid']);
  //
  //                       return CheckboxListTile(
  //                         value: isSelected,
  //                         onChanged: (value) {
  //                           setDialogState(() {
  //                             if (value == true) {
  //                               _selectedMembers.add(member['uid']);
  //                             } else {
  //                               _selectedMembers.remove(member['uid']);
  //                             }
  //                           });
  //                         },
  //                         title: Text(
  //                           member['name'],
  //                           style: const TextStyle(color: Colors.white),
  //                         ),
  //                         subtitle: Text(
  //                           member['email'],
  //                           style: const TextStyle(color: Colors.grey),
  //                         ),
  //                         checkColor: Colors.white,
  //                         activeColor: Colors.green,
  //                       );
  //                     },
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ),
  //           actions: [
  //             TextButton(
  //               onPressed: () => Navigator.pop(context),
  //               child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
  //             ),
  //             ElevatedButton(
  //               onPressed: _selectedMembers.isEmpty ? null : () => _updateGroup(groupId),
  //               style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
  //               child: const Text('Update Group'),
  //             ),
  //           ],
  //         );
  //       },
  //     ),
  //   );
  // }
  void _showEditGroupDialog(String groupId, Map<String, dynamic> group, List<String> currentMembers) {
    _selectedMembers = List.from(currentMembers);
    _groupNameController.text = group['name'] ?? '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: Colors.grey[900],
            title: const Text(
              'Edit Group',
              style: TextStyle(color: Colors.green),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Group Name Input
                TextField(
                  controller: _groupNameController,
                  decoration: const InputDecoration(
                    labelText: 'Group Name',
                    labelStyle: TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.green)),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 16),

                // Members Selection Label
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Select Members:',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),

                // Members List
                SizedBox(
                  height: 300, // Fixed height for desktop & mobile safe scrolling
                  width: double.maxFinite,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _members.length,
                    itemBuilder: (context, index) {
                      final member = _members[index];
                      final isSelected = _selectedMembers.contains(member['uid']);

                      return CheckboxListTile(
                        value: isSelected,
                        onChanged: (value) {
                          setDialogState(() {
                            if (value == true) {
                              _selectedMembers.add(member['uid']);
                            } else {
                              _selectedMembers.remove(member['uid']);
                            }
                          });
                        },
                        title: Text(member['name'],
                            style: const TextStyle(color: Colors.white)),
                        subtitle: Text(member['email'],
                            style: const TextStyle(color: Colors.grey)),
                        checkColor: Colors.white,
                        activeColor: Colors.green,
                      );
                    },
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: _selectedMembers.isEmpty ? null : () => _updateGroup(groupId),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('Update Group'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _createGroup() async {
    if (_groupNameController.text.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final selectedMemberNames = _members
          .where((member) => _selectedMembers.contains(member['uid']))
          .map((member) => member['name'])
          .toList();

      await _firestore.collection('groups').add({
        'name': _groupNameController.text,
        'members': _selectedMembers,
        'memberNames': selectedMemberNames,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      _groupNameController.clear();
      _selectedMembers.clear();
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Group created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating group: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateGroup(String groupId) async {
    if (_groupNameController.text.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final selectedMemberNames = _members
          .where((member) => _selectedMembers.contains(member['uid']))
          .map((member) => member['name'])
          .toList();

      await _firestore.collection('groups').doc(groupId).update({
        'name': _groupNameController.text,
        'members': _selectedMembers,
        'memberNames': selectedMemberNames,
        'updatedAt': Timestamp.now(),
      });

      _groupNameController.clear();
      _selectedMembers.clear();
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Group updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating group: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteGroup(String groupId) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Delete Group', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to delete this group?', style: TextStyle(color: Colors.grey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _firestore.collection('groups').doc(groupId).delete();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Group deleted successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error deleting group: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}