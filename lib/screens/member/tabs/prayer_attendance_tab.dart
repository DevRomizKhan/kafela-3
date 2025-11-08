import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class PrayerAttendanceTab extends StatefulWidget {
  const PrayerAttendanceTab({super.key});

  @override
  State<PrayerAttendanceTab> createState() => _PrayerAttendanceTabState();
}

class _PrayerAttendanceTabState extends State<PrayerAttendanceTab> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<PrayerTime> _prayerTimes = [];
  bool _isLoading = true;
  int _markedCount = 0;

  @override
  void initState() {
    super.initState();
    _initializePrayerTimes();
    _fetchTodayAttendance();
  }

  void _initializePrayerTimes() {
    setState(() {
      _prayerTimes = [
        PrayerTime(name: 'Fajr', time: '5:30 AM', isMarked: false),
        PrayerTime(name: 'Dhuhr', time: '1:00 PM', isMarked: false),
        PrayerTime(name: 'Asr', time: '4:30 PM', isMarked: false),
        PrayerTime(name: 'Maghrib', time: '6:45 PM', isMarked: false),
        PrayerTime(name: 'Isha', time: '8:00 PM', isMarked: false),
      ];
    });
  }

  Future<void> _fetchTodayAttendance() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
        final doc = await _firestore
            .collection('prayer_attendance')
            .doc(user.uid)
            .collection('records')
            .doc(today)
            .get();

        if (doc.exists) {
          final data = doc.data()!;
          setState(() {
            for (var prayer in _prayerTimes) {
              final prayerKey = prayer.name.toLowerCase();
              if (data.containsKey(prayerKey) && data[prayerKey] == true) {
                prayer.isMarked = true;
              }
            }
            _markedCount = _prayerTimes.where((p) => p.isMarked).length;
          });
        }
      }
    } catch (e) {
      print('Error fetching prayer attendance: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = DateFormat('EEEE, MMMM dd, yyyy').format(DateTime.now());

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Prayer Attendance',
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            Text(
              today,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
        centerTitle: false,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.green),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress Card
              Card(
                color: Colors.grey[900],
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      // Progress Circle
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 80,
                            height: 80,
                            child: CircularProgressIndicator(
                              value: _markedCount / 5,
                              backgroundColor: Colors.grey[800],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _getProgressColor(_markedCount),
                              ),
                              strokeWidth: 8,
                            ),
                          ),
                          Column(
                            children: [
                              Text(
                                '$_markedCount',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: _getProgressColor(_markedCount),
                                ),
                              ),
                              Text(
                                '/5',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getProgressMessage(_markedCount),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Mark your daily prayers using the checkboxes below',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Prayer Times List
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.green))
                    : ListView.builder(
                  itemCount: _prayerTimes.length,
                  itemBuilder: (context, index) {
                    final prayer = _prayerTimes[index];
                    return _buildPrayerCard(prayer, index);
                  },
                ),
              ),

              // Quick Actions
              Card(
                color: Colors.grey[900],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildActionButton(
                        'Mark All',
                        Icons.checklist,
                        Colors.green,
                        _markAllPrayers,
                      ),
                      _buildActionButton(
                        'Clear All',
                        Icons.clear_all,
                        Colors.white,
                        _clearAllPrayers,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrayerCard(PrayerTime prayer, int index) {
    return Card(
      color: prayer.isMarked
          ? Colors.green.withOpacity(0.1)
          : Colors.grey[800],
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: prayer.isMarked
              ? Colors.green.withOpacity(0.5)
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: ListTile(
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: prayer.isMarked
                ? Colors.green.withOpacity(0.2)
                : Colors.grey[700],
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.mosque,
            color: prayer.isMarked ? Colors.green : Colors.grey[400],
            size: 30,
          ),
        ),
        title: Text(
          prayer.name,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
            decoration: prayer.isMarked ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text(
          prayer.time,
          style: TextStyle(
            color: prayer.isMarked ? Colors.green : Colors.grey[400],
            fontSize: 14,
          ),
        ),
        trailing: Transform.scale(
          scale: 1.3,
          child: Checkbox(
            value: prayer.isMarked,
            onChanged: (value) => _togglePrayerAttendance(index, value ?? false),
            activeColor: Colors.green,
            checkColor: Colors.white,
            side: BorderSide(
              color: Colors.grey[400]!,
              width: 2,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  Widget _buildActionButton(String title, IconData icon, Color color, VoidCallback onTap) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: color, size: 24),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _togglePrayerAttendance(int index, bool isMarked) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final prayer = _prayerTimes[index];
        final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

        await _firestore
            .collection('prayer_attendance')
            .doc(user.uid)
            .collection('records')
            .doc(today)
            .set({
          prayer.name.toLowerCase(): isMarked,
          'date': today,
          'timestamp': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        }, SetOptions(merge: true));

        setState(() {
          _prayerTimes[index].isMarked = isMarked;
          _markedCount = _prayerTimes.where((p) => p.isMarked).length;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isMarked
                  ? '${prayer.name} marked as prayed!'
                  : '${prayer.name} attendance removed',
            ),
            backgroundColor: isMarked ? Colors.green : Colors.red.withOpacity(0.2),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating attendance: $e'),
          backgroundColor: Colors.red.withOpacity(0.2),
        ),
      );
    }
  }

  Future<void> _markAllPrayers() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
        final Map<String, dynamic> attendanceData = {
          'date': today,
          'timestamp': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        };

        for (var prayer in _prayerTimes) {
          attendanceData[prayer.name.toLowerCase()] = true;
        }

        await _firestore
            .collection('prayer_attendance')
            .doc(user.uid)
            .collection('records')
            .doc(today)
            .set(attendanceData);

        setState(() {
          for (var prayer in _prayerTimes) {
            prayer.isMarked = true;
          }
          _markedCount = 5;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All prayers marked as prayed!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error marking all prayers: $e'),
          backgroundColor: Colors.red.withOpacity(0.2),
        ),
      );
    }
  }

  Future<void> _clearAllPrayers() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

        await _firestore
            .collection('prayer_attendance')
            .doc(user.uid)
            .collection('records')
            .doc(today)
            .delete();

        setState(() {
          for (var prayer in _prayerTimes) {
            prayer.isMarked = false;
          }
          _markedCount = 0;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All prayers cleared!'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error clearing prayers: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Color _getProgressColor(int count) {
    if (count == 5) return Colors.green;
    if (count >= 3) return Colors.red.withOpacity(0.3);
    return Colors.red.withOpacity(0.3);
  }

  String _getProgressMessage(int count) {
    switch (count) {
      case 0:
        return 'Start your day with prayers';
      case 1:
      case 2:
        return 'Keep going!';
      case 3:
      case 4:
        return 'Almost there!';
      case 5:
        return 'Perfect! All prayers completed';
      default:
        return 'Track your prayers';
    }
  }
}

class PrayerTime {
  final String name;
  final String time;
  bool isMarked;

  PrayerTime({
    required this.name,
    required this.time,
    required this.isMarked,
  });
}