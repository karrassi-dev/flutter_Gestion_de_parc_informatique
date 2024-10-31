import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:badges/badges.dart' as badges;
import 'admincrud/RegisterEquipment.dart';
import 'admincrud/UpdaterEquipement.dart';
import 'admincrud/QRCodeScannerPage.dart';
import 'login.dart';
import 'employe_actions/RequestsPage.dart';
import 'admincrud/AddUserForm.dart';
import './admincrud/EquipmentHistoryPage.dart';
import './admincrud/DashboardPage.dart';

class Admin extends StatefulWidget {
  const Admin({super.key});

  @override
  State<Admin> createState() => _AdminState();
}

class _AdminState extends State<Admin> {
  int unreadCount = 0;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchUnreadNotificationsCount();
  }

  Future<void> _fetchUnreadNotificationsCount() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('equipmentRequests')
        .where('isRead', isEqualTo: false)
        .get();

    setState(() {
      unreadCount = snapshot.docs.length;
    });
  }

  // This function is used to update the index when a button is tapped.
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Define each page corresponding to the button in the bottom bar.
    final List<Widget> _pages = [
      DashboardPage(),          // 0: Dashboard with charts
      RegisterEquipment(),      // 1: Register Equipment
      UpdaterEquipment(),       // 2: Update & Delete Equipment
      AddUserForm(),            // 3: Add New User
      EquipmentHistoryPage(),   // 4: View Equipment History
      QRCodeScannerPage(),      // 5: Scan QR Code
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Admin Dashboard",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.deepPurple,
        actions: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('equipmentRequests')
                .where('isRead', isEqualTo: false)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                unreadCount = snapshot.data!.docs.length;
              }

              return IconButton(
                icon: badges.Badge(
                  badgeStyle: badges.BadgeStyle(
                    badgeColor: Colors.red,
                    borderRadius: BorderRadius.circular(8),
                    padding: const EdgeInsets.all(5),
                  ),
                  badgeAnimation: const badges.BadgeAnimation.scale(),
                  badgeContent: Text(
                    unreadCount.toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  showBadge: unreadCount > 0,
                  child: const Icon(Icons.notifications),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RequestsPage(),
                    ),
                  );
                },
                tooltip: "Notifications",
              );
            },
          ),
          IconButton(
            onPressed: () {
              logout(context);
            },
            icon: const Icon(
              Icons.logout,
              color: Colors.white,
            ),
            tooltip: "Logout",
          ),
        ],
      ),
      body: Center(
        // Displays the currently selected page from the bottom navigation bar.
        child: _pages.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: 'Register Equipment',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.update),
            label: 'Update Equipment',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_add),
            label: 'Add User',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner),
            label: 'Scan QR',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }

  Future<void> logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Logged out successfully!"),
        duration: Duration(seconds: 2),
      ),
    );
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => LoginPage(),
      ),
    );
  }
}
