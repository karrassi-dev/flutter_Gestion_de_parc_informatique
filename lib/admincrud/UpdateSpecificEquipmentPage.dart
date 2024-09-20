import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UpdateSpecificEquipmentPage extends StatelessWidget {
  final QueryDocumentSnapshot equipment;

  const UpdateSpecificEquipmentPage(this.equipment, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final equipmentData = equipment.data() as Map<String, dynamic>?; 

    final TextEditingController startTimeController = TextEditingController(
      text: equipmentData?.containsKey('start_time') == true ? equipmentData!['start_time'] : 'N/A',
    );
    final TextEditingController endTimeController = TextEditingController(
      text: equipmentData?.containsKey('end_time') == true ? equipmentData!['end_time'] : 'N/A',
    );
    final TextEditingController emailController = TextEditingController(
      text: equipmentData?.containsKey('email') == true ? equipmentData!['email'] : 'N/A',
    );
    final TextEditingController nameController = TextEditingController(
      text: equipmentData?.containsKey('name') == true ? equipmentData!['name'] : 'N/A',
    );
    final TextEditingController siteController = TextEditingController(
      text: equipmentData?.containsKey('site') == true ? equipmentData!['site'] : 'N/A',
    );
    final TextEditingController typeController = TextEditingController(
      text: equipmentData?.containsKey('type') == true ? equipmentData!['type'] : 'N/A',
    );
    final TextEditingController userController = TextEditingController(
      text: equipmentData?.containsKey('user') == true ? equipmentData!['user'] : 'N/A',
    );
    final TextEditingController brandController = TextEditingController(
      text: equipmentData?.containsKey('brand') == true ? equipmentData!['brand'] : 'N/A',
    );
    final TextEditingController referenceController = TextEditingController(
      text: equipmentData?.containsKey('reference') == true ? equipmentData!['reference'] : 'N/A',
    );
    final TextEditingController serialNumberController = TextEditingController(
      text: equipmentData?.containsKey('serial_number') == true ? equipmentData!['serial_number'] : 'N/A',
    );
    final TextEditingController processorController = TextEditingController(
      text: equipmentData?.containsKey('processor') == true ? equipmentData!['processor'] : 'N/A',
    );
    final TextEditingController osController = TextEditingController(
      text: equipmentData?.containsKey('os') == true ? equipmentData!['os'] : 'N/A',
    );
    final TextEditingController ramController = TextEditingController(
      text: equipmentData?.containsKey('ram') == true ? equipmentData!['ram'] : 'N/A',
    );
    final TextEditingController wirelessMouseController = TextEditingController(
      text: equipmentData?.containsKey('wireless_mouse') == true ? equipmentData!['wireless_mouse'] : 'N/A',
    );
    final TextEditingController externalScreenController = TextEditingController(
      text: equipmentData?.containsKey('external_screen') == true ? equipmentData!['external_screen'] : 'N/A',
    );
    final TextEditingController screenBrandController = TextEditingController(
      text: equipmentData?.containsKey('screen_brand') == true ? equipmentData!['screen_brand'] : 'N/A',
    );
    final TextEditingController screenSerialNumberController = TextEditingController(
      text: equipmentData?.containsKey('screen_serial_number') == true ? equipmentData!['screen_serial_number'] : 'N/A',
    );
    final TextEditingController inventoryNumberEcrController = TextEditingController(
      text: equipmentData?.containsKey('inventory_number_ecr') == true ? equipmentData!['inventory_number_ecr'] : 'N/A',
    );
    final TextEditingController departmentController = TextEditingController(
      text: equipmentData?.containsKey('department') == true ? equipmentData!['department'] : 'N/A',
    );
    final TextEditingController statusController = TextEditingController(
      text: equipmentData?.containsKey('status') == true ? equipmentData!['status'] : 'N/A',
    );
    final TextEditingController inventoryNumberLptController = TextEditingController(
      text: equipmentData?.containsKey('inventory_number_lpt') == true ? equipmentData!['inventory_number_lpt'] : 'N/A',
    );

    final List<String> typeOptions = ['imprimante', 'avaya', 'point d’access', 'switch', 'DVR', 'TV', 'scanner', 'routeur', 'balanceur', 'standard téléphonique', 'data show', 'desktop', 'laptop'];
    final List<String> departmentOptions = ['maintenance', 'qualité', 'administration', 'commercial', 'caisse', 'chef d’agence', 'ADV', 'DOSI', 'DRH', 'logistique', 'contrôle de gestion', 'moyens généraux', 'GRC', 'production', 'comptabilité', 'achat', 'audit'];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Update Equipment"),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              buildTextField("Date de debut", startTimeController),
              buildTextField("Date de fin", endTimeController),
              buildTextField("address de messagerie", emailController),
              buildTextField("Name", nameController),
              buildTextField("Site", siteController),
              buildDropdownField("Type", typeController, typeOptions),
              buildTextField("User", userController),
              buildTextField("Brand", brandController),
              buildTextField("Reference", referenceController),
              buildTextField("Serial Number", serialNumberController),
              buildTextField("Processor", processorController),
              buildTextField("Operating System", osController),
              buildTextField("RAM", ramController),
              buildTextField("Wireless Mouse", wirelessMouseController),
              buildTextField("External Screen", externalScreenController),
              buildTextField("Screen Brand", screenBrandController),
              buildTextField("Screen Serial Number", screenSerialNumberController),
              buildTextField("Inventory Number ECR", inventoryNumberEcrController),
              buildDropdownField("Department", departmentController, departmentOptions),
              buildTextField("Status", statusController),
              buildTextField("Inventory Number LPT", inventoryNumberLptController),

              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  FirebaseFirestore.instance.collection('equipment').doc(equipment.id).update({
                    'start_time': startTimeController.text,
                    'end_time': endTimeController.text,
                    'email': emailController.text,
                    'name': nameController.text,
                    'site': siteController.text,
                    'type': typeController.text,
                    'user': userController.text,
                    'brand': brandController.text,
                    'reference': referenceController.text,
                    'serial_number': serialNumberController.text,
                    'processor': processorController.text,
                    'os': osController.text,
                    'ram': ramController.text,
                    'wireless_mouse': wirelessMouseController.text,
                    'external_screen': externalScreenController.text,
                    'screen_brand': screenBrandController.text,
                    'screen_serial_number': screenSerialNumberController.text,
                    'inventory_number_ecr': inventoryNumberEcrController.text,
                    'department': departmentController.text,
                    'status': statusController.text,
                    'inventory_number_lpt': inventoryNumberLptController.text,
                  }).then((value) {
                    Navigator.pop(context); // Go back after saving
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Equipment updated successfully!")),
                    );
                  });
                },
                child: const Text("Save Changes"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple.withOpacity(0.1),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget buildDropdownField(String label, TextEditingController controller, List<String> options) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: DropdownButtonFormField<String>(
        value: controller.text.isEmpty ? null : controller.text,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        items: options.map((option) {
          return DropdownMenuItem(
            value: option,
            child: Text(option),
          );
        }).toList(),
        onChanged: (newValue) {
          controller.text = newValue!;
        },
      ),
    );
  }
}
