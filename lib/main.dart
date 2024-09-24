import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:firebase_messaging/firebase_messaging.dart';

import 'login.dart';
import 'Admin.dart'; 
import 'Employe.dart'; 

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();


  await FirebaseMessaging.instance.subscribeToTopic("sample");
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Colors.blue[900],
      ),
      home: _handleAuthState(), 
    );
  }

  
  Widget _handleAuthState() {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
    
      return FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator()); 
          }
          if (snapshot.hasError) {
            return const Center(child: Text("Error loading user data")); 
          }
          if (snapshot.hasData) {
            
            String? role = snapshot.data!.get('role');

            if (role == 'Admin') {
              return Admin(); 
            } else if (role == 'employe') {
              return Employe(); 
            } else {
              //return const Center(child: Text("Unknown role")); admin
            }
          }
          return LoginPage(); 
        },
      );
    } else {
      
      return LoginPage();
    }
  }
}
