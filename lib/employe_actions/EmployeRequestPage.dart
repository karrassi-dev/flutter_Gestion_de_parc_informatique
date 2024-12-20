import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class EmployRequestsPage extends StatefulWidget {
  @override
  _EmployRequestsPageState createState() => _EmployRequestsPageState();
}

class _EmployRequestsPageState extends State<EmployRequestsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();

  String currentUserName = "";
  String currentEmail = "";
  String equipmentType = "Scanner";
  String department = "";
  String site = '';
  String utilisateur = "";
  String additionalDetails = "";
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchCurrentUserDetails();
  }

  Future<void> fetchCurrentUserDetails() async {
    try {
      var currentUser = _auth.currentUser;

      if (currentUser != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

        if (userDoc.exists) {
          setState(() {
            currentUserName = userDoc['name'] ?? "User";
            currentEmail = currentUser.email ?? "No Email";
            isLoading = false;
          });
        }
      } else {
        setState(() {
          currentUserName = "Unknown";
          currentEmail = "No Email";
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching user details: $e");
      setState(() {
        currentUserName = "Error";
        currentEmail = "Error";
        isLoading = false;
      });
    }
  }

  void showLoaderDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text("Submitting request...", style: TextStyle(fontSize: 16)),
              ],
            ),
          ),
        );
      },
    );
  }

  void hideLoaderDialog(BuildContext context) {
    Navigator.of(context).pop();
  }

  Future<void> submitRequest() async {
    if (_formKey.currentState!.validate()) {
      showLoaderDialog(context);

      // Submit request to Firestore
      await FirebaseFirestore.instance.collection('equipmentRequests').add({
        'name': currentUserName,
        'email': currentEmail,
        'equipmentType': equipmentType,
        'utilisateur': utilisateur,
        'department': department,
        'site': site,
        'additionalDetails': additionalDetails,
        'requester': currentEmail,
        'isRead': false,
        'status': 'Pending',
        'requestDate': DateTime.now(),
      });

      // Fetch admin emails
      QuerySnapshot adminSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'Admin')
          .get();

      List<String> adminEmails = adminSnapshot.docs
          .map((doc) => doc['email'] as String)
          .toList();

      // Send email notification to backend
      final notificationBody = {
        'admins': adminEmails,
        'requesterName': currentUserName,
        'requesterEmail': currentEmail,
        'equipmentType': equipmentType,
        'utilisateur': utilisateur,
        'department': department,
        'site': site,
        'additionalDetails': additionalDetails,
      };

      final response = await http.post(
        Uri.parse('http://54.166.39.114:4000/send-email'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(notificationBody),
      );

      if (response.statusCode == 200) {
        print("Email notifications sent successfully");
      } else {
        print("Failed to send email notifications: ${response.body}");
      }

      // Fetch all FCM tokens from adminFcmToken collection
      QuerySnapshot fcmTokenSnapshot = await FirebaseFirestore.instance
          .collection('adminFcmToken')
          .get();

      List<String> fcmTokens = fcmTokenSnapshot.docs
          .map((doc) => doc['fcmToken'] as String)
          .toList();

      // Prepare the notification message
      final String notificationMessage =
          "New Equipment Request submitted by $currentUserName for $equipmentType.";

      // Send notification to each FCM token
      for (String token in fcmTokens) {
        await sendNotification(token, notificationMessage);
      }

      hideLoaderDialog(context);

      // Success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Request Submitted Successfully")),
      );

      // Reset the form
      _formKey.currentState!.reset();
      setState(() {
        additionalDetails = "";
      });
    }
  }

  Future<void> sendNotification(String token, String message) async {
    final response = await http.post(
      Uri.parse('http://54.166.39.114:3000/send-notification'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'tokens': [token],
        'message': message,
      }),
    );

    if (response.statusCode == 200) {
      print("Notification sent successfully");
    } else {
      print("Failed to send notification: ${response.body}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Employee Requests"),
        backgroundColor: Color(0xFF467F67),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    Card(
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Welcome, $currentUserName",
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                "Email: $currentEmail",
                                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                              ),
                              SizedBox(height: 20),

                              // Equipment type dropdown
                              DropdownButtonFormField<String>(
                                value: equipmentType,
                                items: [
                                  'Imprimante', 'Avaya', 'Point d’access', 'Switch', 'DVR', 'TV', 'Scanner',
                                  'Routeur', 'Balanceur', 'Standard Téléphonique', 'Data Show', 'Desktop', 'Laptop','Notebook'
                                ].map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                                onChanged: (newValue) {
                                  setState(() {
                                    equipmentType = newValue!;
                                  });
                                },
                                decoration: InputDecoration(
                                  labelText: 'Type of Equipment',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              SizedBox(height: 20),

                              // Utilisateur text field
                              TextFormField(
                                decoration: InputDecoration(
                                  labelText: 'Utilisateur',
                                  hintText: 'Entrez le nom et prénom',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter the name of the user who will use the equipment';
                                  }
                                  return null;
                                },
                                onChanged: (value) {
                                  setState(() {
                                    utilisateur = value;
                                  });
                                },
                              ),
                              SizedBox(height: 20),

                              // Department dropdown
                              DropdownButtonFormField<String>(
                                value: department.isEmpty
                                    ? null
                                    : department, // Initial value is null
                                items: [
                                  'Maintenance',
                                  'Qualité',
                                  'Administration',
                                  'Commercial',
                                  'Caisse',
                                  'Chef d’agence',
                                  'ADV',
                                  'DOSI',
                                  'DRH',
                                  'Logistique',
                                  'Contrôle de gestion',
                                  'Moyens généraux',
                                  'GRC',
                                  'Production',
                                  'Comptabilité',
                                  'Achat',
                                  'Audit'
                                ].map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                                onChanged: (newValue) {
                                  setState(() {
                                    department = newValue!;
                                  });
                                },
                                decoration: InputDecoration(
                                  labelText: 'Department',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please select a department';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 20),
                              // Site dropdown
                              DropdownButtonFormField<String>(
                                value: site.isEmpty
                                    ? null
                                    : site, // Initial value is null
                                items: [
                                  'Agence Oujda',
                                  'Agence Agadir',
                                  'Agence Marrakech',
                                  'Canal Food',
                                  'Agence Beni Melal',
                                  'Agence El Jadida',
                                  'Agence Fes',
                                  'Agence Tanger',
                                  'BMZ',
                                  'STLZ',
                                  'Zine Céréales',
                                  'Manafid Al Houboub',
                                  'CALZ',
                                  'LGMZL',
                                  'LGSZ',
                                  'LGMZB',
                                  'LGMC',
                                  'Savola',
                                  'Siège'
                                ].map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                                onChanged: (newValue) {
                                  setState(() {
                                    site = newValue!;
                                  });
                                },
                                decoration: InputDecoration(
                                  labelText: 'Site',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please select a site';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 20),

                              TextFormField(
                                decoration: InputDecoration(
                                  labelText: 'Additional Details',
                                  hintText: 'Provide any extra details here',
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    additionalDetails = value;
                                  });
                                },
                              ),
                              SizedBox(height: 20),
                              Container(
                                width: double.infinity, 
                                child: ElevatedButton(
                                  onPressed: submitRequest,
                                  child: Text(
                                    "Submit Request",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xff012F97),
                                    padding: EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18.0),
                                    ),
                                    textStyle: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
