import 'package:http/http.dart' as http;
import 'dart:convert';

class GlpiService {
  final String apiUrl = 'http://localhost:8888/glpi/apirest.php'; // Replace with your GLPI URL
  final String apiToken = 'your_glpi_api_token'; // Replace with your API token

  Future<void> sendDeviceDetailsToGLPI(String email, String deviceName, String serialNumber) async {
    // Set up headers for the API call
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'user_token $apiToken',
      'App-Token': apiToken
    };

    // Build the JSON body
    final body = jsonEncode({
      "input": {
        "email": email,
        "device_name": deviceName,
        "serial_number": serialNumber,
      }
    });

    // Make the POST request to send device details
    final response = await http.post(
      Uri.parse('$apiUrl/device'),
      headers: headers,
      body: body,
    );

    if (response.statusCode == 201) {
      print('Device details sent to GLPI successfully!');
    } else {
      print('Failed to send device details. Status code: ${response.statusCode}');
    }
  }
}
