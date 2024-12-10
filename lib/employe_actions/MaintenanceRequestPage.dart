import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class MaintenanceRequestPage extends StatefulWidget {
  @override
  _MaintenanceRequestPageState createState() => _MaintenanceRequestPageState();
}

class _MaintenanceRequestPageState extends State<MaintenanceRequestPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final FirebaseStorage _firebaseStorage = FirebaseStorage.instance;


  String? selectedUser; // Selected user
  Map<String, dynamic>? selectedEquipment; // Selected equipment details
  String additionalDetails = ""; // Additional details from the user
  List<String> users = []; // List of unique users
  List<Map<String, dynamic>> equipmentList = []; // Equipment associated with the selected user
  String? uploadedFileUrl; // File URL after upload


  @override
  void initState() {
    super.initState();
    fetchUsers(); 
  }


  Future<void> fetchUsers() async {
    try {
      final snapshot = await _firestore.collection('equipment').get();

      if (snapshot.docs.isEmpty) {
        return;
      }

      final uniqueUsers = snapshot.docs
          .map((doc) {
            final user = doc.data()['user'] as String?;
            return user;
          })
          .where((user) => user != null && user.isNotEmpty && user != "N/A")
          .toSet()
          .toList();

      setState(() {
        users = uniqueUsers.cast<String>();
      });
    } catch (e) {
      print("Error fetching users: $e");
    }
  }


  Future<void> fetchEquipmentForUser(String user) async {
    try {
      final snapshot = await _firestore
          .collection('equipment')
          .where('user', isEqualTo: user)
          .get();

      final equipment = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          "id": doc.id,
          "name": data['brand'] ?? "N/A",
          "type": data['type'] ?? "N/A",
          "serialNumber": data['serial_number'] ?? "N/A",
          "site": data['location'] ?? "N/A",
          "department": data['department'] ?? "N/A",
        };
      }).toList();

      setState(() {
        equipmentList = equipment;
        selectedEquipment = null;
      });
    } catch (e) {
      print("Error fetching equipment for user $user: $e");
    }
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      File file = File(result.files.single.path!);

      // Upload file to Firebase Storage
      try {
        // Create a reference to Firebase Storage
        Reference storageRef = _firebaseStorage.ref().child("maintenance_requests/${DateTime.now().millisecondsSinceEpoch}");

        // Upload the file
        await storageRef.putFile(file);

        // Get the file's download URL
        String downloadUrl = await storageRef.getDownloadURL();

        setState(() {
          uploadedFileUrl = downloadUrl;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Fichier téléchargé avec succès")),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur lors du téléchargement du fichier: $e")),
        );
      }
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

              // User Autocomplete
              Autocomplete<String>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return const Iterable<String>.empty();
                  }
                  return users.where((user) => user
                      .toLowerCase()
                      .contains(textEditingValue.text.toLowerCase()));
                },
                onSelected: (String selection) {
                  setState(() {
                    selectedUser = selection;
                    fetchEquipmentForUser(selection);
                  });
                },
                fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                  return TextFormField(
                    controller: textEditingController,
                    focusNode: focusNode,
                    decoration: InputDecoration(
                      labelText: "Choisir un utilisateur",
                      border: OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.person),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),



              // Equipment Dropdown
              selectedUser == null
                  ? const Text('Veuillez sélectionner un utilisateur.')
                  : equipmentList.isEmpty
                      ? const Text('Aucun équipement disponible pour cet utilisateur.')
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
                          onChanged: (value) {
                            setState(() {
                              selectedEquipment = value;
                            });
                          },
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                          ),
                        ),

              const SizedBox(height: 20),

              // Additional Details Field
              TextFormField(
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: "Détails supplémentaires",
                  hintText: "Ajouter des informations sur la demande...",
                  border: OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.description),
                ),
                onChanged: (value) {
                  setState(() {
                    additionalDetails = value;
                  });
                },
              ),

              
              const SizedBox(height: 20),

              // Upload File Button
              ElevatedButton(
                onPressed: _pickFile,
                child: Text(uploadedFileUrl == null ? "Télécharger un fichier" : "Fichier téléchargé"),
              ),


              const SizedBox(height: 20),

              // Submit Button
              ElevatedButton(
                onPressed: () async {
                  if (selectedUser != null && selectedEquipment != null) {
                    try {
                      final currentUser = FirebaseAuth.instance.currentUser;

                      if (currentUser == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Utilisateur non connecté.")),
                        );
                        return;
                      }

                      final userEmail = currentUser.email;
                      final userName = currentUser.displayName ?? "Unknown";

                      final equipmentData = {
                        "utilisateur": selectedUser,
                        "status": "en_maintenance",
                        "site": selectedEquipment!['site'],
                        "requester": userEmail,
                        "requestDate": FieldValue.serverTimestamp(),
                        "name": selectedEquipment!['name'],
                        "equipmentType": selectedEquipment!['type'],
                        "department": selectedEquipment!['department'],
                        "maintenanceType": true,
                        "additionalDetails": additionalDetails, // Include additional details
                      };

                      await _firestore.collection('equipmentRequests').add(equipmentData);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              "Demande soumise pour $selectedUser, Équipement: ${selectedEquipment!['name']} (${selectedEquipment!['type']})"),
                        ),
                      );

                      setState(() {
                        selectedUser = null;
                        selectedEquipment = null;
                        additionalDetails = "";
                      });
                    } catch (e) {
                      print("Error submitting maintenance request: $e");
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Erreur lors de la soumission.")),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Veuillez sélectionner un utilisateur et un équipement."),
                      ),
                    );
                  }
                },
                child: const Text("Soumettre", style: TextStyle(color: Colors.white)),
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
