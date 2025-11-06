import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class TasksTab extends StatefulWidget {
  const TasksTab({super.key});

  @override
  State<TasksTab> createState() => _TasksTabState();
}

class _TasksTabState extends State<TasksTab> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  DateTime _dueDate = DateTime.now();
  String _selectedMember = '';
  List<Map<String, dynamic>> _members = [];
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
          };
        }).toList();

        if (_members.isNotEmpty) {
          _selectedMember = _members.first['uid'];
        }
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
                      const Icon(Icons.assignment, color: Colors.green, size: 28),
                      const SizedBox(width: 12),
                      const Text(
                        'Task Management',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.add, color: Colors.green),
                        onPressed: _showAddTaskDialog,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Tasks List
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore.collection('tasks').orderBy('dueDate').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Colors.green));
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Text(
                          'No tasks found',
                          style: TextStyle(color: Colors.white),
                        ),
                      );
                    }

                    final tasks = snapshot.data!.docs;

                    return ListView.builder(
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
                        final task = tasks[index].data() as Map<String, dynamic>;
                        final taskId = tasks[index].id;
                        final dueDate = (task['dueDate'] as Timestamp).toDate();
                        final isOverdue = dueDate.isBefore(DateTime.now()) && task['status'] != 'completed';

                        return Card(
                          color: Colors.grey[800],
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Icon(
                              task['status'] == 'completed' ? Icons.check_circle : Icons.radio_button_unchecked,
                              color: task['status'] == 'completed' ? Colors.green : Colors.orange,
                            ),
                            title: Text(
                              task['title'] ?? 'No Title',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                decoration: task['status'] == 'completed' ? TextDecoration.lineThrough : null,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  task['description'] ?? 'No description',
                                  style: const TextStyle(color: Colors.grey),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Due: ${DateFormat('MMM dd, yyyy').format(dueDate)}',
                                  style: TextStyle(
                                    color: isOverdue ? Colors.red : Colors.grey,
                                    fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                                Text(
                                  'Assigned to: ${task['assignedToName'] ?? 'Unknown'}',
                                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (task['status'] != 'completed')
                                  IconButton(
                                    icon: const Icon(Icons.check, color: Colors.green),
                                    onPressed: () => _updateTaskStatus(taskId, 'completed'),
                                  ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteTask(taskId),
                                ),
                              ],
                            ),
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

  void _showAddTaskDialog() {
    String searchQuery = '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          // Filter members based on search query
          final filteredMembers = searchQuery.isEmpty
              ? _members
              : _members.where((member) =>
              (member['name'] ?? '').toLowerCase().contains(searchQuery.toLowerCase())).toList();

          return AlertDialog(
            backgroundColor: Colors.grey[900],
            title: const Text(
              'Assign New Task',
              style: TextStyle(color: Colors.green),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Task Title
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Task Title',
                        labelStyle: TextStyle(color: Colors.grey),
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.green),
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 12),

                    // Description
                    TextField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        labelStyle: TextStyle(color: Colors.grey),
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.green),
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 12),

                    // Search for Members
                    TextField(
                      onChanged: (value) {
                        setDialogState(() {
                          searchQuery = value;
                        });
                      },
                      decoration: const InputDecoration(
                        labelText: 'Search Members...',
                        labelStyle: TextStyle(color: Colors.grey),
                        prefixIcon: Icon(Icons.search, color: Colors.green),
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.green),
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 12),

                    // Selected Member Display
                    if (_selectedMember.isNotEmpty)
                      Card(
                        color: Colors.green.withOpacity(0.1),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.green,
                            child: Text(
                              _members
                                  .firstWhere((m) => m['uid'] == _selectedMember)['name'][0]
                                  .toUpperCase(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(
                            _members.firstWhere((m) => m['uid'] == _selectedMember)['name'],
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          subtitle: const Text(
                            'Selected for task assignment',
                            style: TextStyle(color: Colors.grey),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.clear, color: Colors.red),
                            onPressed: () {
                              setDialogState(() {
                                _selectedMember = '';
                              });
                            },
                          ),
                        ),
                      ),

                    // Members List
                    if (searchQuery.isNotEmpty || _selectedMember.isEmpty)
                      Container(
                        constraints: const BoxConstraints(maxHeight: 200),
                        child: filteredMembers.isEmpty
                            ? const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            'No members found',
                            style: TextStyle(color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        )
                            : ListView.builder(
                          shrinkWrap: true,
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: filteredMembers.length,
                          itemBuilder: (context, index) {
                            final member = filteredMembers[index];
                            final isSelected = member['uid'] == _selectedMember;

                            return Card(
                              color: isSelected
                                  ? Colors.green.withOpacity(0.2)
                                  : Colors.grey[800],
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: isSelected ? Colors.green : Colors.grey,
                                  child: Text(
                                    (member['name'] ?? '')[0].toUpperCase(),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                title: Text(
                                  member['name'] ?? 'Unknown',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                                subtitle: Text(
                                  member['email'] ?? 'No email',
                                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                                trailing: isSelected
                                    ? const Icon(Icons.check_circle, color: Colors.green)
                                    : null,
                                onTap: () {
                                  setDialogState(() {
                                    _selectedMember = member['uid'] as String;
                                  });
                                },
                              ),
                            );
                          },
                        ),
                      ),

                    const SizedBox(height: 12),

                    // Due Date
                    Card(
                      color: Colors.grey[800],
                      child: ListTile(
                        leading: const Icon(Icons.calendar_today, color: Colors.green),
                        title: const Text('Due Date', style: TextStyle(color: Colors.grey)),
                        subtitle: Text(
                          DateFormat('MMM dd, yyyy').format(_dueDate),
                          style: const TextStyle(color: Colors.white),
                        ),
                        trailing: const Icon(Icons.arrow_drop_down, color: Colors.green),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _dueDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2100),
                          );
                          if (date != null) {
                            setDialogState(() {
                              _dueDate = date;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  _selectedMember = ''; // Reset selection when canceling
                  Navigator.pop(context);
                },
                child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: _selectedMember.isNotEmpty && _titleController.text.isNotEmpty
                    ? _addTask
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  disabledBackgroundColor: Colors.grey,
                ),
                child: const Text('Assign Task', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }


  Future<void> _addTask() async {
    if (_titleController.text.isEmpty || _selectedMember.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final member = _members.firstWhere((m) => m['uid'] == _selectedMember);

      await _firestore.collection('tasks').add({
        'title': _titleController.text,
        'description': _descriptionController.text,
        'assignedTo': _selectedMember,
        'assignedToName': member['name'],
        'dueDate': Timestamp.fromDate(_dueDate),
        'status': 'pending',
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      _titleController.clear();
      _descriptionController.clear();
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task assigned successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error assigning task: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateTaskStatus(String taskId, String status) async {
    try {
      await _firestore.collection('tasks').doc(taskId).update({
        'status': status,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating task: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteTask(String taskId) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Delete Task', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to delete this task?', style: TextStyle(color: Colors.grey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _firestore.collection('tasks').doc(taskId).delete();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Task deleted successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error deleting task: $e'),
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