// lib/user_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Method to fetch and print users with fcmToken
  Future<void> printUsersWithFcmToken() async {
    try {
      QuerySnapshot querySnapshot = await _firestore.collection('users').get();

      for (var doc in querySnapshot.docs) {
        Map<String, dynamic>? userData = doc.data() as Map<String, dynamic>?;

        // Check if fcmToken exists
        if (userData != null && userData.containsKey('fcmToken') && userData['fcmToken'] != null) {
          String email = userData['email'] ?? 'No email';
          String fcmToken = userData['fcmToken'];
          print('User Email: $email, FCM Token: $fcmToken');
        }
      }
    } catch (e) {
      print('Error retrieving users: $e');
    }
  }
}
