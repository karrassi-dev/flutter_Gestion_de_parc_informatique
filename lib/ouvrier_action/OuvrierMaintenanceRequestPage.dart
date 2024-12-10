import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class OuvrierMaintenanceRequestPage extends StatefulWidget {
  @override
  _OuvrierMaintenanceRequestPageState createState() =>
      _OuvrierMaintenanceRequestPageState();
}

class _OuvrierMaintenanceRequestPageState
    extends State<OuvrierMaintenanceRequestPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String currentUserName = "";
  String currentUserEmail = "";
  Map<String, dynamic>? selectedEquipment; // Selected equipment details
  String siteFromFirestore = ""; // Site fetched dynamically
  String additionalDetails = ""; // Additional details from the user
  List<Map<String, dynamic>> equipmentList = []; // Equipment associated with the current user

  @override
  void initState() {
    super.initState();
    fetchCurrentUserDetails();
  }

  Future<void> fetchCurrentUserDetails() async {
    try {
      final currentUser = _auth.currentUser;

      if (currentUser != null) {
        DocumentSnapshot userDoc = await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .get();

        if (userDoc.exists) {
          final userName = userDoc['name'] ?? "Unknown";
          final userEmail = currentUser.email ?? "No Email";

          setState(() {
            currentUserName = userName;
            currentUserEmail = userEmail;
          });

          // Fetch equipment associated with the current user's name
          fetchEquipmentForUser(userName);
        }
      }
    } catch (e) {
      print("Error fetching user details: $e");
    }
  }

  // Fetch equipment for the current user's name
  Future<void> fetchEquipmentForUser(String userName) async {
    try {
      final snapshot = await _firestore
          .collection('equipment')
          .where('user', isEqualTo: userName)
          .get();

      final equipment = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          "id": doc.id,
          "name": data['brand'] ?? "N/A",
          "type": data['type'] ?? "N/A",
          "serialNumber": doc.id, // Serial number matches document ID
        };
      }).toList();

      setState(() {
        equipmentList = equipment;
        selectedEquipment = null;
      });
    } catch (e) {
      print("Error fetching equipment for user $userName: $e");
    }
  }

  // Fetch the site dynamically based on the selected equipment's serial number
  Future<void> fetchSiteForSelectedEquipment(String serialNumber) async {
    try {
      DocumentSnapshot equipmentDoc =
      await _firestore.collection('equipment').doc(serialNumber).get();

      if (equipmentDoc.exists) {
        setState(() {
          siteFromFirestore = equipmentDoc['site'] ?? "Unknown Site"; // Fetch site
        });
      } else {
        setState(() {
          siteFromFirestore = "Site not found";
        });
      }
    } catch (e) {
      print("Error fetching site for equipment: $e");
    }
  }

  // Submit maintenance request
  Future<void> submitRequest() async {
    if (selectedEquipment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez sélectionner un équipement.")),
      );
      return;
    }

    try {
      // Prepare request data
      final equipmentData = {
        "utilisateur": currentUserName,
        "status": "en_maintenance",
        "site": siteFromFirestore, // Use dynamically fetched site
        "equipmentSerial": selectedEquipment!['serialNumber'],
        "requester": currentUserEmail,
        "requestDate": FieldValue.serverTimestamp(),
        "name": selectedEquipment!['name'],
        "equipmentType": selectedEquipment!['type'],
        "maintenanceType": true,
        "additionalDetails": additionalDetails, // Include additional details
      };

      // Add to Firestore
      await _firestore.collection('equipmentRequests').add(equipmentData);

      // Fetch admin emails
      QuerySnapshot adminSnapshot = await _firestore
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
        'requesterEmail': currentUserEmail,
        'equipmentType': selectedEquipment!['type'],
        'site': siteFromFirestore,
        'additionalDetails': additionalDetails,
      };

      final emailResponse = await http.post(
        Uri.parse('http://54.166.39.114:4000/send-email'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(notificationBody),
      );

      if (emailResponse.statusCode == 200) {
        print("Email notifications sent successfully");
      } else {
        print("Failed to send email notifications: ${emailResponse.body}");
      }

      // Fetch all FCM tokens from adminFcmToken collection
      QuerySnapshot fcmTokenSnapshot = await _firestore
          .collection('adminFcmToken')
          .get();

      List<String> fcmTokens = fcmTokenSnapshot.docs
          .map((doc) => doc['fcmToken'] as String)
          .toList();

      // Prepare the notification message
      final String notificationMessage =
          "Maintenance request submitted by $currentUserName for ${selectedEquipment!['name']} (${selectedEquipment!['type']}).";

      // Send notification to each FCM token
      for (String token in fcmTokens) {
        await sendNotification(token, notificationMessage);
      }

      // Reset form
      setState(() {
        selectedEquipment = null;
        additionalDetails = "";
        siteFromFirestore = "";
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Demande de maintenance soumise.")),
      );
    } catch (e) {
      print("Error submitting maintenance request: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur lors de la soumission.")),
      );
    }
  }

  // Send push notification
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
        title: const Text("Demande Maintenance"),
        backgroundColor: Color(0xFF467F67),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "Demande de Maintenance",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // User details
              TextFormField(
                initialValue: "$currentUserName ($currentUserEmail)",
                enabled: false,
                decoration: InputDecoration(
                  labelText: currentUserEmail,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 20),

              // Equipment dropdown
              equipmentList.isEmpty
                  ? const Text(
                'Aucun équipement disponible pour cet utilisateur.',
                textAlign: TextAlign.center,
              )
                  : DropdownButtonFormField<Map<String, dynamic>>(
                value: selectedEquipment,
                hint: const Text("Choisir un équipement"),
                items: equipmentList.map((equipment) {
                  return DropdownMenuItem(
                    value: equipment,
                    child: Text(
                        "${equipment['name']} (${equipment['type']}) - Serial: ${equipment['serialNumber']}"),
                  );
                }).toList(),
                onChanged: (value) async {
                  setState(() {
                    selectedEquipment = value;
                    siteFromFirestore = ""; // Reset site
                  });

                  if (value != null) {
                    await fetchSiteForSelectedEquipment(
                        value['serialNumber']);
                  }
                },
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              // Display site
              siteFromFirestore.isEmpty
                  ? const SizedBox()
                  : Text(
                "Site: $siteFromFirestore",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // Additional Details
              TextFormField(
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: "Détails supplémentaires",
                  hintText: "Ajouter des informations sur la demande...",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                onChanged: (value) {
                  setState(() {
                    additionalDetails = value;
                  });
                },
              ),
              const SizedBox(height: 20),

              // Submit button
              ElevatedButton(
                onPressed: submitRequest,
                child: const Text("Soumettre",style: TextStyle(color: Colors.white),),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  backgroundColor: Color(0xff012F97),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18.0),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
