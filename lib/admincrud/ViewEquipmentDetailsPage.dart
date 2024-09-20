import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ViewEquipmentDetailsPage extends StatelessWidget {
  final QueryDocumentSnapshot equipment;

  const ViewEquipmentDetailsPage(this.equipment, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic>? equipmentData = equipment.data() as Map<String, dynamic>?;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Equipment Details"),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailCard("Nom", equipmentData?['name']),
              _buildDetailCard("Address de messagerie", equipmentData?['email']),
              _buildDetailCard("Type", equipmentData?['type']),
              _buildDetailCard("marque", equipmentData?['brand']),
              _buildDetailCard("numero de serie", equipmentData?['serial_number']),
              _buildDetailCard("Processor", equipmentData?['processor']),
              _buildDetailCard("Os", equipmentData?['os']),
              _buildDetailCard("RAM(Gb)", equipmentData?['ram']),
              _buildDetailCard("souris sans fil", equipmentData?['wireless_mouse']),
              _buildDetailCard("ecran extern", equipmentData?['external_screen']),
              _buildDetailCard("marque d'ecran", equipmentData?['screen_brand']),
              _buildDetailCard("S.N d'ecran", equipmentData?['screen_serial_number']),
              _buildDetailCard("numero d'inventaire ECR", equipmentData?['inventory_number_ecr']),
              _buildDetailCard("Departement/Service", equipmentData?['department']),
              _buildDetailCard("Etat", equipmentData?['status']),
              _buildDetailCard("numero d'inventaire LPT", equipmentData?['inventory_number_lpt']),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailCard(String title, String? value) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              value ?? 'N/A',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
