import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'Ouvrier.dart';
import 'dart:convert';

import 'email_service.dart';
import 'login.dart';
import 'Admin.dart';
import 'Employe.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await dotenv.load(fileName: ".env");

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _statusMessage = ''; 

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Colors.blue[900],
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('GLPI Integration'),
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_statusMessage, style: TextStyle(color: Colors.green)),
            Expanded(child: _handleAuthState()),
          ],
        ),
      ),
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
            } else if (role == 'Ouvrier') {
              return Ouvrier();
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
  final url = 'https://9d92-154-144-245-220.ngrok-free.app/glpi/apirest.php/Computer';

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

      await storeDataInFirestore(data);
      setState(() {
        _statusMessage = 'Data fetched and stored successfully!'; 
      });
    } else {
      setState(() {
        _statusMessage = 'Failed to fetch data: ${response.statusCode}';
      });
    }
  } catch (error) {
    setState(() {
      _statusMessage = 'Error: $error';
    });
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
      setState(() {
        _statusMessage = 'Error storing data: $error'; 
      });
      print('Error storing data: $error');
    }
  }
}
