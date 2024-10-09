import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../email_service.dart'; 

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
  String site = 'Agence Oujda'; // Default value for site/agence
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

  // Function to show a loader dialog
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
      // loader when submitting 
      showLoaderDialog(context);

      // Add Firestore
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

      // Fetch admin 
      QuerySnapshot adminSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'Admin')
          .get();

      List<String> adminEmails = adminSnapshot.docs
          .map((doc) => doc['email'] as String)
          .toList();


      for (String adminEmail in adminEmails) {
        await Email_Service.sendEmail(
          adminEmail,  
          'New Equipment Request', 
          'A new equipment request has been made by $currentUserName ($currentEmail) for $equipmentType.\n'
          'User: $utilisateur\n'
          'Department: $department\n'
          'Site/Agence: $site\n'
          'Additional Details: $additionalDetails\n'
        );
      }

      hideLoaderDialog(context);

      // success message
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
                            'Imprimante', 'Avaya', 'Point d’access', 'Switch', 'DVR', 'TV', 'Scanner', 
                            'Routeur', 'Balanceur', 'Standard Téléphonique', 'Data Show', 'Desktop', 'Laptop'
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
                        const SizedBox(height: 20),

                        // Department dropdown
                        DropdownButtonFormField<String>(
                          value: department,
                          items: [
                            'Maintenance', 'Qualité', 'Administration', 'Commercial', 'Caisse', 'Chef d’agence',
                            'ADV', 'DOSI', 'DRH', 'Logistique', 'Contrôle de gestion', 'Moyens généraux', 
                            'GRC', 'Production', 'Comptabilité', 'Achat', 'Audit'
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


                        // Site/Agence dropdown
                        DropdownButtonFormField<String>(
                          value: site,
                          items: [
                            'Agence Oujda', 'Agence Agadir', 'Agence Marrakech', 'Canal Food', 
                            'Agence Beni Melal', 'Agence El Jadida', 'Agence Fes', 'Agence Tanger', 
                            'BMZ', 'STLZ', 'Zine Céréales', 'Manafid Al Houboub', 'CALZ', 'LGMZL', 
                            'LGSZ', 'LGMZB', 'LGMC', 'Savola', 'Siège'
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
                            labelText: 'Site/Agence',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Additional Details text field
                        TextFormField(
                          maxLines: 3,
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

                        // Submit button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: submitRequest,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              padding: EdgeInsets.all(15),
                            ),
                            child: Text('Submit Request', style: TextStyle(fontSize: 18 , color: Colors.white)),
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

