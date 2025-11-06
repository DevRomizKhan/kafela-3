
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Import all the tab screens
import 'tabs/dashboard_tab.dart';
import 'tabs/attendance_tab.dart';
import 'tabs/reports_tab.dart';
import 'tabs/routine_tab.dart';
import 'tabs/tasks_tab.dart';
import 'tabs/groups_tab.dart';
import 'tabs/logout_tab.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  int _currentIndex = 0;

  // List of all tab screens
  final List<Widget> _screens = [
    const DashboardTab(),
    const AttendanceTab(),
    const ReportsTab(selectedMemberId: '',selectedMemberName: '',),
    const RoutineTab(),
    const TasksTab(),
    const GroupsTab(),
    const LogoutTab(),
  ];

  // Navigation bar items
  final List<BottomNavigationBarItem> _navItems = [
    const BottomNavigationBarItem(
      icon: Icon(Icons.dashboard),
      label: 'Dashboard',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.list_alt_outlined),
      label: 'Attendance',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.analytics),
      label: 'Reports',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.schedule),
      label: 'Routine',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.assignment),
      label: 'Tasks',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.group),
      label: 'Groups',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.logout),
      label: 'Logout',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _screens[_currentIndex],
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: const Border(
          top: BorderSide(color: Colors.black, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: kBottomNavigationBarHeight, // Fixed height for navigation bar
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: SizedBox(
              // Set a minimum width that can accommodate all items
              width: _navItems.length * 100.0, // 100px per item (adjust as needed)
              child: BottomNavigationBar(
                currentIndex: _currentIndex,
                onTap: (index) => setState(() => _currentIndex = index),
                type: BottomNavigationBarType.fixed,
                backgroundColor: Colors.transparent, // Make background transparent
                selectedItemColor: Colors.green,
                unselectedItemColor: Colors.grey[400],
                selectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.normal,
                  fontSize: 12,
                ),
                iconSize: 24,
                items: _navItems,
              ),
            ),
          ),
        ),
      ),
    );
  }
}