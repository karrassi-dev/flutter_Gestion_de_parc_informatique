import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RegisterEquipment extends StatefulWidget {
  const RegisterEquipment({super.key});

  @override
  _RegisterEquipmentState createState() => _RegisterEquipmentState();
}

class _RegisterEquipmentState extends State<RegisterEquipment> {
  final PageController _pageController = PageController();
  final _formKey = GlobalKey<FormState>();

  // Controllers for all fields
  final TextEditingController startTimeController = TextEditingController();
  final TextEditingController endTimeController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  //final TextEditingController siteController = TextEditingController();
  final TextEditingController typeController = TextEditingController();
  final TextEditingController userController = TextEditingController();
  final TextEditingController brandController = TextEditingController();
  final TextEditingController referenceController = TextEditingController();
  final TextEditingController serialNumberController = TextEditingController();
  final TextEditingController processorController = TextEditingController();
  final TextEditingController osController = TextEditingController();
  final TextEditingController ramController = TextEditingController();
  final TextEditingController externalScreenController = TextEditingController();
  final TextEditingController screenBrandController = TextEditingController();
  final TextEditingController screenSerialNumberController = TextEditingController();
  final TextEditingController inventoryNumberEcrController = TextEditingController();
  //final TextEditingController departmentController = TextEditingController();
  final TextEditingController statusController = TextEditingController();
  final TextEditingController inventoryNumberLptController = TextEditingController();

  int currentPageIndex = 0;
  bool _isWirelessMouse = false;

  final CollectionReference equipmentCollection = FirebaseFirestore.instance.collection('equipment');

  final List<String> typeOptions = [
    'imprimante', 'avaya', 'point d’access', 'switch', 'DVR', 'TV',
    'scanner', 'routeur', 'balanceur', 'standard téléphonique',
    'data show', 'desktop', 'laptop'
  ];
/*
  final List<String> departmentOptions = [
    'maintenance', 'qualité', 'administration', 'commercial', 'caisse',
    'chef d’agence', 'ADV', 'DOSI', 'DRH', 'logistique', 'contrôle de gestion',
    'moyens généraux', 'GRC', 'production', 'comptabilité', 'achat', 'audit'
  ];
*/
  Future<void> registerEquipment() async {
    if (_formKey.currentState!.validate()) {
      User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        Map<String, dynamic> equipmentData = {
          'start_time': startTimeController.text,
          'end_time': endTimeController.text,
          'email': emailController.text,
          'name': nameController.text,
          //'site': siteController.text,
          'type': typeController.text,
          'user': userController.text,
          'brand': brandController.text,
          'reference': referenceController.text,
          'serial_number': serialNumberController.text,
          'processor': processorController.text,
          'os': osController.text,
          'ram': ramController.text,
          'wireless_mouse': _isWirelessMouse ? 'Oui' : 'Non',
          if (typeController.text == 'desktop') ...{
            'external_screen': externalScreenController.text,
            'screen_brand': screenBrandController.text,
            'screen_serial_number': screenSerialNumberController.text,
            'inventory_number_ecr': inventoryNumberEcrController.text,
          },
          /*
          'department': departmentController.text,
          'status': statusController.text,
          'inventory_number_lpt': inventoryNumberLptController.text,
          'added_by': currentUser.uid,
          'timestamp': FieldValue.serverTimestamp(),
          */
        };

        try {
          await equipmentCollection.add(equipmentData);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Equipment registered successfully!")),
          );
          _clearFields();
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to register equipment: $e")),
          );
        }
      }
    }
  }

  void _clearFields() {
    startTimeController.clear();
    endTimeController.clear();
    emailController.clear();
    nameController.clear();
    //siteController.clear();
    typeController.clear();
    userController.clear();
    brandController.clear();
    referenceController.clear();
    serialNumberController.clear();
    processorController.clear();
    osController.clear();
    ramController.clear();
    externalScreenController.clear();
    screenBrandController.clear();
    screenSerialNumberController.clear();
    inventoryNumberEcrController.clear();
    //departmentController.clear();
    statusController.clear();
    inventoryNumberLptController.clear();
  }

  void nextPage() {
    if (currentPageIndex < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        currentPageIndex++;
      });
    }
  }

  void previousPage() {
    if (currentPageIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        currentPageIndex--;
      });
    }
  }

  Widget buildTextField(TextEditingController controller, String hintText, IconData icon) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      validator: (value) {
        if (value!.isEmpty) {
          return 'Please enter $hintText';
        }
        return null;
      },
    );
  }

  Widget buildDropdown(List<String> options, TextEditingController controller, String hintText) {
    return DropdownButtonFormField<String>(
      value: controller.text.isEmpty ? null : controller.text,
      decoration: InputDecoration(
        hintText: hintText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      items: options.map((String option) {
        return DropdownMenuItem<String>(
          value: option,
          child: Text(option),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          controller.text = value!;
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select $hintText';
        }
        return null;
      },
    );
  }

  Widget buildCheckbox(String hintText) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(hintText),
        Checkbox(
          value: _isWirelessMouse,
          onChanged: (bool? value) {
            setState(() {
              _isWirelessMouse = value!;
            });
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Register Equipment",style: TextStyle(fontWeight: FontWeight.bold),),
        backgroundColor: Colors.deepPurple,
      ),
      body: Form(
        key: _formKey,
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(), 
          children: [
            // Page 1
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  buildTextField(startTimeController, "heure de debut", Icons.access_time),
                  const SizedBox(height: 20),
                  buildTextField(endTimeController, "heure de fin", Icons.access_time_filled),
                  const SizedBox(height: 20),
                  buildTextField(emailController, "Address de messagerie", Icons.email),
                  const SizedBox(height: 20),
                  buildTextField(nameController, "nom", Icons.person),
                  /*
                  const SizedBox(height: 20),
                  buildTextField(siteController, "Site/agence", Icons.location_on),
                  */
                  const SizedBox(height: 20),
                  buildDropdown(typeOptions, typeController, "Type"),
                ],
              ),
            ),
            // Page 2
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  buildTextField(userController, "utilisateur", Icons.person_outline),
                  const SizedBox(height: 20),
                  buildTextField(brandController, "marque", Icons.branding_watermark),
                  const SizedBox(height: 20),
                  buildTextField(referenceController, "Reference", Icons.book),
                  const SizedBox(height: 20),
                  buildTextField(serialNumberController, "numero de serie", Icons.confirmation_number),
                  const SizedBox(height: 20),
                  buildTextField(processorController, "composant - processeur", Icons.memory),
                  const SizedBox(height: 20),
                  buildTextField(osController, "system d'exploitation", Icons.computer),
                  const SizedBox(height: 20),
                  buildTextField(ramController, "RAM (en Go)", Icons.memory),
                  const SizedBox(height: 20),
                  buildCheckbox("Souris sans fil"),
                ],
              ),
            ),
            // Page 3  for desktop)
Padding(
  padding: const EdgeInsets.all(20.0),
  child: Column(
    children: [
      if (typeController.text == 'desktop') ...[
        buildTextField(externalScreenController, "Ecran externe", Icons.desktop_windows),
        const SizedBox(height: 20),
        buildTextField(screenBrandController, "Marque de l'ecran", Icons.tv),
        const SizedBox(height: 20),
        buildTextField(screenSerialNumberController, "Numéro de série de l'écran", Icons.confirmation_number),
        const SizedBox(height: 20),
        buildTextField(inventoryNumberEcrController, "N° inventaire ECR", Icons.category),
        const SizedBox(height: 20),
      ],
      /*
      buildDropdown(departmentOptions, departmentController, "Département"), // Use the dropdown here
      const SizedBox(height: 20),
      */
      buildTextField(statusController, "État", Icons.assignment_turned_in),
      const SizedBox(height: 20),
      buildTextField(inventoryNumberLptController, "N° inventaire LPT", Icons.category),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (currentPageIndex > 0)
            Padding(
              padding: const EdgeInsets.only(
                  left: 38.0), 
              child: FloatingActionButton(
                onPressed: previousPage,
                child: const Icon(Icons.arrow_back),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                left: 38.0),
                child:FloatingActionButton(
            onPressed: currentPageIndex == 2 ? registerEquipment : nextPage,
            child: currentPageIndex == 2
                ? const Icon(Icons.save)
                : const Icon(Icons.arrow_forward),
          ),
              ),
          
        ],
      ),
    );
  }
}
