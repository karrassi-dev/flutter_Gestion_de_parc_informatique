
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http; 
import 'dart:convert';
import 'fcm_service.dart';

import 'email_service.dart';
import 'login.dart';
import 'Admin.dart';
import 'Employe.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(MyApp());
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle background message
  print('Handling a background message: ${message.messageId}');
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final FCMService fcmService = FCMService('assets/glpi.json');

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
            String apiToken = 'sQtgkB5VdTuH0EKD6p830GWXEuAsntN3osiGW5OS'; 

            // Fetch data from GLPI
            fetchGLPIComputers(apiToken);

            if (role == 'Admin') {
              return Admin();
            } else if (role == 'employe') {
              return Employe();
            }
          }
          return LoginPage();
        },
      );
    } else {
      return LoginPage();
    }
  }

  Future<void> fetchGLPIComputers(String apiToken) async {
    final url = 'http://localhost:8888/glpi/apirest.php/Computer';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $apiToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        storeDataInFirestore(data);
      } else {
        print('Failed to fetch data: ${response.statusCode}');
      }
    } catch (error) {
      print('Error: $error');
    }
  }

  Future<void> storeDataInFirestore(Map<String, dynamic> data) async {
    try {
      final firestore = FirebaseFirestore.instance;

      for (var item in data['data']) { 
        await firestore.collection('computers').add(item);
      }
      print('Data stored successfully in Firestore.');
    } catch (error) {
      print('Error storing data: $error');
    }
  }

  Future<void> sendNotification(String targetDeviceToken, String title, String body) async {
    try {
      await fcmService.sendMessage(targetDeviceToken, title, body);
      print('Notification sent successfully.');
    } catch (error) {
      print('Error sending notification: $error');
    }
  }
}
