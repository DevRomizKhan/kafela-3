import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class GroupChatPage extends StatefulWidget {
  final String groupId;
  final String groupName;

  const GroupChatPage({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  State<GroupChatPage> createState() => _GroupChatPageState();
}

class _GroupChatPageState extends State<GroupChatPage> {
  // final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // final FirebaseStorage _storage = FirebaseStorage.instance;
  // final FirebaseAuth _auth = FirebaseAuth.instance; // FirebaseAuth add korun
  // final TextEditingController _messageController = TextEditingController();
  // final ScrollController _scrollController = ScrollController();
  // File? _imageFile;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance; // FirebaseAuth add korun
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  File? _imageFile;
  String _currentUserName = 'User'; // Default name
  String _currentUserEmail = 'user@example.com'; // Default email
  @override
  void initState() {
    super.initState();
    _fetchCurrentUserData();
  }
  Future<void> _fetchCurrentUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        // User-er UID diye Firestore theke data fetch korun
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          setState(() {
            _currentUserName = userDoc['name'] ?? 'Unknown User';
            _currentUserEmail = userDoc['email'] ?? 'unknown@example.com';
          });
        } else {
          // Jodi user document na thake, tahole default value set korun
          setState(() {
            _currentUserName = 'Unknown User';
            _currentUserEmail = 'unknown@example.com';
          });
        }
      } catch (e) {
        print('Error fetching user data: $e');
        // Error holeo default value set korun
        setState(() {
          _currentUserName = 'Unknown User';
          _currentUserEmail = 'unknown@example.com';
        });
      }
    } else {
      // Jodi user null hoy, tahole default value set korun
      setState(() {
        _currentUserName = 'Unknown User';
        _currentUserEmail = 'unknown@example.com';
      });
    }
  }

  // Future<void> _fetchCurrentUserData() async {
  //   final user = _auth.currentUser;
  //   if (user != null) {
  //     final userDoc = await _firestore.collection('users').doc(user.uid).get();
  //     if (userDoc.exists) {
  //       setState(() {
  //         _currentUserName = userDoc['name'] ?? 'User';
  //         _currentUserEmail = userDoc['email'] ?? 'user@example.com';
  //       });
  //     }
  //   }
  // }


  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }
  // Future<void> _sendMessage() async {
  //   if (_messageController.text.isEmpty && _imageFile == null) return;
  //
  //   String? imageUrl;
  //   if (_imageFile != null) {
  //     final ref = _storage.ref().child('group_messages/${DateTime.now().millisecondsSinceEpoch}.jpg');
  //     await ref.putFile(_imageFile!);
  //     imageUrl = await ref.getDownloadURL();
  //   }
  //
  //   // await _firestore.collection('groups/${widget.groupId}/messages').add({
  //   //   'text': _messageController.text,
  //   //   'imageUrl': imageUrl,
  //   //   'senderId': _auth.currentUser?.uid ?? 'unknown', // Current user UID
  //   //   'senderName': _currentUserName, // Current user name
  //   //   'senderEmail': _currentUserEmail, // Current user email
  //   //   'timestamp': Timestamp.now(),
  //   // });
  //   await _firestore.collection('groups/${widget.groupId}/messages').add({
  //     'text': _messageController.text,
  //     'imageUrl': imageUrl,
  //     'senderId': _auth.currentUser?.uid ?? 'unknown',
  //     'senderName': _currentUserName.isNotEmpty ? _currentUserName : 'User',
  //     'senderEmail': _currentUserEmail.isNotEmpty ? _currentUserEmail : 'user@example.com',
  //     'timestamp': Timestamp.now(),
  //   });
  //
  //   _messageController.clear();
  //   setState(() => _imageFile = null);
  //   _scrollController.animateTo(
  //     _scrollController.position.maxScrollExtent,
  //     duration: const Duration(milliseconds: 300),
  //     curve: Curves.easeOut,
  //   );
  // }


  // Future<void> _sendMessage() async {
  //   if (_messageController.text.isEmpty && _imageFile == null) return;
  //
  //   String? imageUrl;
  //   if (_imageFile != null) {
  //     final ref = _storage.ref().child('group_messages/${DateTime.now().millisecondsSinceEpoch}.jpg');
  //     await ref.putFile(_imageFile!);
  //     imageUrl = await ref.getDownloadURL();
  //   }
  //
  //   await _firestore.collection('groups/${widget.groupId}/messages').add({
  //     'text': _messageController.text,
  //     'imageUrl': imageUrl,
  //     'senderId': 'admin',
  //     'senderName': 'Admin',
  //     'timestamp': Timestamp.now(),
  //   });
  //
  //   _messageController.clear();
  //   setState(() => _imageFile = null);
  //   _scrollController.animateTo(
  //     _scrollController.position.maxScrollExtent,
  //     duration: const Duration(milliseconds: 300),
  //     curve: Curves.easeOut,
  //   );
  // }
  Future<void> _sendMessage() async {
    if (_messageController.text.isEmpty && _imageFile == null) return;

    String? imageUrl;
    if (_imageFile != null) {
      final ref = _storage.ref().child('group_messages/${DateTime.now().millisecondsSinceEpoch}.jpg');
      await ref.putFile(_imageFile!);
      imageUrl = await ref.getDownloadURL();
    }

    await _firestore.collection('groups/${widget.groupId}/messages').add({
      'text': _messageController.text,
      'imageUrl': imageUrl,
      'senderId': _auth.currentUser?.uid ?? 'unknown',
      'senderName': _currentUserName, // Dynamic user name
      'senderEmail': _currentUserEmail, // Dynamic user email
      'timestamp': Timestamp.now(),
    });

    _messageController.clear();
    setState(() => _imageFile = null);
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.groupName),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
      ),
      backgroundColor: Colors.grey[900],
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('groups/${widget.groupId}/messages')
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data!.docs;
                return ListView.builder(
                  controller: _scrollController,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index].data() as Map<String, dynamic>;
                    return _buildMessageBubble(message);
                  },
                );
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }


  Widget _buildMessageBubble(Map<String, dynamic> message) {
    bool isCurrentUser = message['senderId'] == _auth.currentUser?.uid;
    String senderName = message['senderName'] ?? 'Unknown User';
    String senderEmail = message['senderEmail'] ?? 'unknown@example.com';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        mainAxisAlignment: isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isCurrentUser)
            CircleAvatar(
              backgroundColor: Colors.deepPurple,
              child: Text(senderName.isNotEmpty ? senderName[0].toUpperCase() : 'U'),
            ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: isCurrentUser
                    ? const LinearGradient(
                  colors: [Colors.green, Colors.lightGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
                    : const LinearGradient(
                  colors: [Colors.grey, Colors.black54],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isCurrentUser ? 16 : 0),
                  bottomRight: Radius.circular(isCurrentUser ? 0 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 4,
                    offset: const Offset(2, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message['imageUrl'] != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        message['imageUrl'],
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  if (message['text'] != null && message['text'] != '')
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        message['text'],
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    senderName,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  Text(
                    senderEmail,
                    style: const TextStyle(color: Colors.white54, fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (isCurrentUser)
            CircleAvatar(
              backgroundColor: Colors.green,
              child: Text(senderName.isNotEmpty ? senderName[0].toUpperCase() : 'U'),
            ),
        ],
      ),
    );
  }

  // Widget _buildMessageBubble(Map<String, dynamic> message) {
  //   bool isCurrentUser = message['senderId'] == _auth.currentUser?.uid;
  //   String senderName = message['senderName'] ?? 'Unknown';
  //   String senderEmail = message['senderEmail'] ?? 'unknown@example.com';
  //
  //   return Padding(
  //     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  //     child: Row(
  //       mainAxisAlignment: isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
  //       children: [
  //         if (!isCurrentUser)
  //           CircleAvatar(
  //             backgroundColor: Colors.deepPurple,
  //             child: Text(senderName.isNotEmpty ? senderName[0].toUpperCase() : 'U'),
  //           ),
  //         const SizedBox(width: 8),
  //         Flexible(
  //           child: Container(
  //             padding: const EdgeInsets.all(12),
  //             decoration: BoxDecoration(
  //               gradient: isCurrentUser
  //                   ? const LinearGradient(
  //                 colors: [Colors.green, Colors.lightGreen],
  //                 begin: Alignment.topLeft,
  //                 end: Alignment.bottomRight,
  //               )
  //                   : const LinearGradient(
  //                 colors: [Colors.grey, Colors.black54],
  //                 begin: Alignment.topLeft,
  //                 end: Alignment.bottomRight,
  //               ),
  //               borderRadius: BorderRadius.only(
  //                 topLeft: const Radius.circular(16),
  //                 topRight: const Radius.circular(16),
  //                 bottomLeft: Radius.circular(isCurrentUser ? 16 : 0),
  //                 bottomRight: Radius.circular(isCurrentUser ? 0 : 16),
  //               ),
  //               boxShadow: [
  //                 BoxShadow(
  //                   color: Colors.black.withOpacity(0.4),
  //                   blurRadius: 4,
  //                   offset: const Offset(2, 2),
  //                 ),
  //               ],
  //             ),
  //             child: Column(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 if (message['imageUrl'] != null)
  //                   ClipRRect(
  //                     borderRadius: BorderRadius.circular(12),
  //                     child: Image.network(
  //                       message['imageUrl'],
  //                       height: 200,
  //                       width: double.infinity,
  //                       fit: BoxFit.cover,
  //                     ),
  //                   ),
  //                 if (message['text'] != null && message['text'] != '')
  //                   Padding(
  //                     padding: const EdgeInsets.only(top: 6),
  //                     child: Text(
  //                       message['text'],
  //                       style: const TextStyle(color: Colors.white, fontSize: 16),
  //                     ),
  //                   ),
  //                 const SizedBox(height: 4),
  //                 Text(
  //                   senderName,
  //                   style: const TextStyle(color: Colors.white70, fontSize: 12),
  //                 ),
  //                 Text(
  //                   senderEmail,
  //                   style: const TextStyle(color: Colors.white54, fontSize: 10),
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ),
  //         const SizedBox(width: 8),
  //         if (isCurrentUser)
  //           CircleAvatar(
  //             backgroundColor: Colors.green,
  //             child: Text(senderName.isNotEmpty ? senderName[0].toUpperCase() : 'U'),
  //           ),
  //       ],
  //     ),
  //   );
  // }

  // Widget _buildMessageBubble(Map<String, dynamic> message) {
  //   bool isAdmin = message['senderId'] == 'admin';
  //   return Padding(
  //     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  //     child: Row(
  //       mainAxisAlignment:
  //       isAdmin ? MainAxisAlignment.end : MainAxisAlignment.start,
  //       children: [
  //         if (!isAdmin)
  //           CircleAvatar(
  //             backgroundColor: Colors.deepPurple,
  //             child: Text(message['senderName'][0].toUpperCase()),
  //           ),
  //         const SizedBox(width: 8),
  //         Flexible(
  //           child: Container(
  //             padding: const EdgeInsets.all(12),
  //             decoration: BoxDecoration(
  //               gradient: isAdmin
  //                   ? const LinearGradient(
  //                   colors: [Colors.green, Colors.lightGreen],
  //                   begin: Alignment.topLeft,
  //                   end: Alignment.bottomRight)
  //                   : const LinearGradient(
  //                   colors: [Colors.grey, Colors.black54],
  //                   begin: Alignment.topLeft,
  //                   end: Alignment.bottomRight),
  //               borderRadius: BorderRadius.only(
  //                 topLeft: const Radius.circular(16),
  //                 topRight: const Radius.circular(16),
  //                 bottomLeft: Radius.circular(isAdmin ? 16 : 0),
  //                 bottomRight: Radius.circular(isAdmin ? 0 : 16),
  //               ),
  //               boxShadow: [
  //                 BoxShadow(
  //                   color: Colors.black.withOpacity(0.4),
  //                   blurRadius: 4,
  //                   offset: const Offset(2, 2),
  //                 ),
  //               ],
  //             ),
  //             child: Column(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 if (message['imageUrl'] != null)
  //                   ClipRRect(
  //                     borderRadius: BorderRadius.circular(12),
  //                     child: Image.network(
  //                       message['imageUrl'],
  //                       height: 200,
  //                       width: double.infinity,
  //                       fit: BoxFit.cover,
  //                     ),
  //                   ),
  //                 if (message['text'] != null && message['text'] != '')
  //                   Padding(
  //                     padding: const EdgeInsets.only(top: 6),
  //                     child: Text(
  //                       message['text'],
  //                       style: const TextStyle(color: Colors.white, fontSize: 16),
  //                     ),
  //                   ),
  //                 const SizedBox(height: 4),
  //                 Text(
  //                   message['senderName'],
  //                   style: const TextStyle(color: Colors.white70, fontSize: 12),
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ),
  //         const SizedBox(width: 8),
  //         if (isAdmin)
  //           CircleAvatar(
  //             backgroundColor: Colors.green,
  //             child: Text(message['senderName'][0].toUpperCase()),
  //           ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.image, color: Colors.green, size: 28),
            onPressed: _pickImage,
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[800],
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.green, size: 28),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }
}
