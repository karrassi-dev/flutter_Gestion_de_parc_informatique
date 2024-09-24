import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class EmployRequestsPage extends StatefulWidget {
  @override
  _EmployRequestsPageState createState() => _EmployRequestsPageState();
}

class _EmployRequestsPageState extends State<EmployRequestsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();

  String currentUserName = "";
  String currentEmail = "";
  String equipmentType = "Scanner"; // Default value
  String department = "DOSI"; // Default value
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

  void submitRequest() {
    if (_formKey.currentState!.validate()) {

      FirebaseFirestore.instance.collection('equipmentRequests').add({
        'name': currentUserName,
        'email': currentEmail,
        'equipmentType': equipmentType,
        'utilisateur': utilisateur,
        'department': department,
        'additionalDetails': additionalDetails,
        'requester': currentEmail, 
        'isRead': false, 
        'status': 'Pending', 
        'requestDate': DateTime.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Request Submitted Successfully")),
      );


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
        title: const Text("Employee Requests"),
        backgroundColor: Colors.purple,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
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
                        const SizedBox(height: 20),

                        // Equipment type dropdown
                        DropdownButtonFormField<String>(
                          value: equipmentType,
                          items: [
                            'Imprimante', 'Avaya', 'Point d’access', 'Switch', 'DVR', 'TV', 'Scanner', 'Routeur', 'Balanceur', 'Standard Téléphonique', 'Data Show', 'Desktop', 'Laptop'
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
                        const SizedBox(height: 20),

                        // Utilisateur text field
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Utilisateur',
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
                        const SizedBox(height: 20),

                        // Department dropdown
                        DropdownButtonFormField<String>(
                          value: department,
                          items: [
                            'Maintenance', 'Qualité', 'Administration', 'Commercial', 'Caisse', 'Chef d’agence', 'ADV', 'DOSI', 'DRH', 'Logistique', 'Contrôle de gestion', 'Moyens généraux', 'GRC', 'Production', 'Comptabilité', 'Achat', 'Audit'
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
                            labelText: 'Département/Service',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 20),

                        TextFormField(
                          maxLines: 4,
                          decoration: InputDecoration(
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

                        // Submit request button
                        Center(
                          child: ElevatedButton(
                            onPressed: submitRequest,
                            child: const Text("Submit Request", style: TextStyle(color: Colors.black),),
                            
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
