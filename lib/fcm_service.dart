import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

class FCMService {
  final String _url = 'https://fcm.googleapis.com/v1/projects/flutter-gpi/messages:send';
  final String _serviceAccountJson;

  FCMService(this._serviceAccountJson);

  Future<String> _getAccessToken() async {
    // Load the service account JSON
    final Map<String, dynamic> serviceAccount =
        jsonDecode(await rootBundle.loadString(_serviceAccountJson));

    // Prepare the JWT token request
    final response = await http.post(
      Uri.parse(serviceAccount['token_uri']),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'grant_type': 'urn:ietf:params:oauth:grant-type:jwt-bearer',
        'assertion': await _generateJWT(serviceAccount),
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['access_token'];
    } else {
      throw Exception('Failed to get access token');
    }
  }

  Future<String> _generateJWT(Map<String, dynamic> serviceAccount) async {
    // Create a JWT token
    final jwt = JWT(
      {
        'iss': serviceAccount['client_email'],
        'scope': 'https://www.googleapis.com/auth/firebase.messaging',
        'aud': serviceAccount['token_uri'],
        'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        'exp': (DateTime.now().millisecondsSinceEpoch ~/ 1000) + 3600,
      },
    );

    // Parse the private key
    final privateKeyPem = serviceAccount['private_key'].replaceAll('\\n', '\n');
    
    // Sign the JWT using the private key
    final key = RSAPrivateKey(privateKeyPem);
    final token = jwt.sign(key, algorithm: JWTAlgorithm.RS256);

    return token;
  }

  Future<void> sendMessage(String token, String title, String body) async {
    final accessToken = await _getAccessToken();

    final response = await http.post(
      Uri.parse(_url),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'message': {
          'token': token,
          'notification': {
            'title': title,
            'body': body,
          },
        },
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to send message: ${response.body}');
    }
  }
}
