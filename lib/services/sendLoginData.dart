import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> sendLoginData(String email, String deviceId, String deviceModel) async {
  final String glpiUrl = 'http://localhost:8888/glpi/apirest.php/Computer'; 
  final String appToken = 'sQtgkB5VdTuH0EKD6p830GWXEuAsntN3osiGW5OS';
  final String sessionToken = 'cj4lmi3j2lqpl37q55ceedsqtc'; 

  final Map<String, dynamic> data = {
    'input': {
      'name': 'Device from Flutter',
      'serial': deviceId,
      'model': deviceModel,
      'email': email,
      'loginTimestamp': DateTime.now().toIso8601String(), 
    }
  };

  final response = await http.post(
    Uri.parse('$glpiUrl?app_token=$appToken&session_token=$sessionToken'),
    headers: {
      'Content-Type': 'application/json',
    },
    body: jsonEncode(data),
  );

  if (response.statusCode == 200) {
    print('Data posted successfully: ${response.body}');
  } else {
    print('Failed to post data: ${response.statusCode} - ${response.body}');
  }
}
