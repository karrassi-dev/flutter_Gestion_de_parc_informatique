import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class OuvrierRequestPage extends StatefulWidget {
  @override
  _OuvrierRequestPageState createState() => _OuvrierRequestPageState();
}

class _OuvrierRequestPageState extends State<OuvrierRequestPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();

  String currentUserName = "";
  String currentEmail = "";
  String equipmentType = "Scanner";
  String department = "DOSI";
  String site = 'Agence Oujda';
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
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
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
        'utilisateur': currentUserName, // Use the current user's name
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
        'utilisateur': currentUserName,
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

      hideLoaderDialog(context);

      // Success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Request Submitted Successfully")),
      );

      // Reset the form
      _formKey.currentState!.reset();
      setState(() {
        additionalDetails = "";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ouvrier Requests"),
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
                                style: const TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                "Email: $currentEmail",
                                style: TextStyle(
                                    fontSize: 16, color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 20),

                              // Equipment type dropdown
                              DropdownButtonFormField<String>(
                                value: equipmentType,
                                items: [
                                  'Imprimante',
                                  'Avaya',
                                  'Point d’access',
                                  'Switch',
                                  'DVR',
                                  'TV',
                                  'Scanner',
                                  'Routeur',
                                  'Balanceur',
                                  'Standard Téléphonique',
                                  'Data Show',
                                  'Desktop',
                                  'Laptop',
                                  'Notebook'
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
                                decoration: const InputDecoration(
                                  labelText: 'Type of Equipment',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Display current user name as "Utilisateur" (non-editable)
                              TextFormField(
                                initialValue: currentUserName,
                                enabled: false,
                                decoration: InputDecoration(
                                  labelText: currentUserName.isNotEmpty
                                      ? currentUserName
                                      : 'Utilisateur', // Fallback if name is not loaded
                                  border: const OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Department dropdown
                              DropdownButtonFormField<String>(
                                value: department,
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
                                decoration: const InputDecoration(
                                  labelText: 'Département/Service',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Site dropdown
                              DropdownButtonFormField<String>(
                                value: site,
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
                                decoration: const InputDecoration(
                                  labelText: 'Site/Agence',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Additional Details text field
                              TextFormField(
                                maxLines: 3,
                                decoration: const InputDecoration(
                                  labelText: 'Additional Details',
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    additionalDetails = value;
                                  });
                                },
                              ),
                              const SizedBox(height: 20),

                              // Submit button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: submitRequest,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xff012F97),
                                    padding: const EdgeInsets.all(15),
                                  ),
                                  child: const Text(
                                    'Submit Request',
                                    style: TextStyle(
                                        fontSize: 18, color: Colors.white),
                                  ),
                                ),
                              ),
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
