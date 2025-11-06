import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ClassRoutineTab extends StatefulWidget {
  const ClassRoutineTab({super.key});

  @override
  State<ClassRoutineTab> createState() => _ClassRoutineTabState();
}

class _ClassRoutineTabState extends State<ClassRoutineTab> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _routines = [];
  bool _isLoading = true;
  String _selectedDay = 'Monday';

  final List<String> _days = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];

  @override
  void initState() {
    super.initState();
    _fetchRoutines();
  }

  Future<void> _fetchRoutines() async {
    try {
      final snapshot = await _firestore
          .collection('routines')
          .where('day', isEqualTo: _selectedDay)
          .orderBy('startTime')
          .get();

      setState(() {
        _routines = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'className': data['className'] ?? 'No Name',
            'instructor': data['instructor'] ?? 'Unknown',
            'room': data['room'] ?? 'N/A',
            'startTime': data['startTime'] ?? 'N/A',
            'endTime': data['endTime'] ?? 'N/A',
            'day': data['day'] ?? 'Monday',
          };
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching routines: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Card(
              color: Colors.grey[900],
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.schedule,
                        color: Colors.green,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Class Routine',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'View your class schedule',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Day Selector
            SizedBox(
              height: 60,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _days.length,
                itemBuilder: (context, index) {
                  final day = _days[index];
                  final isSelected = day == _selectedDay;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedDay = day;
                        _isLoading = true;
                      });
                      _fetchRoutines();
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.green : Colors.grey[800],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          day.substring(0, 3), // Short form
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey[400],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // Routine List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.green))
                  : _routines.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.schedule, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      'No classes scheduled for $_selectedDay', // Fixed: changed $selectedDay to $_selectedDay
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _routines.length,
                itemBuilder: (context, index) {
                  final routine = _routines[index];

                  return Card(
                    color: Colors.grey[800],
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.school,
                          color: Colors.green,
                        ),
                      ),
                      title: Text(
                        routine['className'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${routine['startTime']} - ${routine['endTime']}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                          Text(
                            '${routine['instructor']} • ${routine['room']}',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _isClassNow(routine['startTime'], routine['endTime'])
                              ? Colors.green.withOpacity(0.2)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _isClassNow(routine['startTime'], routine['endTime'])
                                ? Colors.green
                                : Colors.transparent,
                          ),
                        ),
                        child: Text(
                          _isClassNow(routine['startTime'], routine['endTime'])
                              ? 'Now'
                              : 'Upcoming',
                          style: TextStyle(
                            color: _isClassNow(routine['startTime'], routine['endTime'])
                                ? Colors.green
                                : Colors.grey,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isClassNow(String startTime, String endTime) {
    final now = TimeOfDay.now();
    final start = _parseTime(startTime);
    final end = _parseTime(endTime);

    return _isTimeBetween(now, start, end);
  }

  TimeOfDay _parseTime(String timeString) {
    try {
      final parts = timeString.split(' ');
      final timeParts = parts[0].split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      final isPm = parts.length > 1 && parts[1].toUpperCase() == 'PM';

      int adjustedHour = hour;
      if (isPm && hour != 12) adjustedHour = hour + 12;
      if (!isPm && hour == 12) adjustedHour = 0;

      return TimeOfDay(hour: adjustedHour, minute: minute);
    } catch (e) {
      return TimeOfDay.now();
    }
  }

  bool _isTimeBetween(TimeOfDay now, TimeOfDay start, TimeOfDay end) {
    final nowInMinutes = now.hour * 60 + now.minute;
    final startInMinutes = start.hour * 60 + start.minute;
    final endInMinutes = end.hour * 60 + end.minute;

    return nowInMinutes >= startInMinutes && nowInMinutes <= endInMinutes;
  }
}