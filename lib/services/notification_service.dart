import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:googleapis/servicecontrol/v1.dart' as servicecontrol;
import 'package:googleapis_auth/auth_io.dart' as auth;



class PushNotificationService {
  static const String staticDeviceToken = "cdN5lwiPSueEPDn7boPQv2:APA91bF3FZPl1sy4oZY9TE9R7GSxTEsWFSpCVbf8kAyhRnPI7wXJ5iJpd23MQox5_vINANfBjFfUi-VA_YdNqOnHX3jAVYLwIyRUmeGGd1NIXKU7a0PGXKIEwhYAnGUpxzwIqIvqQJKf";

  static Future<String> _getAccessToken() async {


    final serviceAccountJson = {
      "type": "service_account",
      "project_id": "flutter-gpi",
      "private_key_id": "8f131c8d88cc68908b2ae4926f5cfac0caf9f8e4",
      "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQCguVf331RObQGG\noP9OR9PRfth2QtTfSxPLfwpi3xRo5zTLi71p54Qp6sTcWwBNZluBiGriByTzWuAm\n8Mrbp8Oxyx7I0/Fw1178O31pdtL5dCReMEwT6T0eGKpOY3UuHj4Cv9FADmCvlbGX\nLYKdle6W8hiJXyT81tKa4iiE9wzGkxTDWrFev+DEVKop7UjNC6QNCF/2crPQwEbI\nMYKgbBpKwZ1HaWKLMcuTCHX5LVBTjy8yaP+fTsNHjYJRZwTGOCC97nMFg30PtoyN\nLJ5h2ismZu7R+Gyj2JWARestemf6Po6gClfsM1qvrLdIJ0mm5/UPzhrJbXQFcul6\nE8ob1Nn9AgMBAAECggEADO71QP1P+bKkY4rLmKdHiI1ySkv0+NYADQlXUt78M7fd\nQ/7l+mJ2vG/HsSrCgrf4p5sMbM1h4BJhRMjuLhBZO1Kq0sLZZDj0jAwWerjk382E\niq7MxHJpqGUYOVAgExq8Zzi71DGD/sUnQhDXuKoixbNMHavSHGWGE5Ac7hw6QzVc\nktaV9z15aBX7hpF63qA2sRDErmrkgJsduXmHEqQLOLfwrmOZQVQAykTekbamwb+9\n7s1omJTsLuZ+X75uw1sfVuwVvDRv14fXhorUu67vOU3K+XtDIdpW1KpNbSTjhNa0\n8ZySFnQlSENjCjv/vbhg2f5SlfUOoMsxLgvvt4/OeQKBgQDTkJJuPEnV0xa0wtW1\nBL0M8kxn0QQstlVJiaaWve142WXrBIkkxCbVSFxQVfC2HKzIfwmqoWmirt4J07W4\nxZlD/Wg1xexz/7QE8of71JilBdWlfuqsq6RQbcoNhA6Q5LG/jAikvLOlfyinx1/z\nXYcx8JhkxTq0liPczB2h0/C5aQKBgDCeynLEtuP1g00XyrTyuAtcESLEyPM/fdk\n2nwW5a4+xJBhucdkjeJEB/ey52Q9Fz86wW7e1xvbqa3FP8Yrc/NUHYwX1R3AC1pg\nXP08TxCrrN26H5l5MHQ3I+2oH0p702NXDdEZc2wodSiasTW5NIkPm0aG7c0YlwmJ\nySbYOPaVdQKBgQC5JgqgIm7TjDqQ0vnHw2/XRq0LJearYp5dDvQVc/3BBzCkboG/\nBVKe0QbI340bMxkbFeJVy5Dw6Gw02WxtWbB5yelLNf1qvtrCgaX0A+fac7K3dMzX\ndBcGtC5hibJdp2bPJTPjR6lIKnJf8qHMD4vjbpVPizOHGuYjsxYzq5E+EQKBgEON\nXFr5VeKES1nhpJKkaXHfCS/1mf3eSUxyx598cCXFSRFo4mV/ExTmX5d44EyIAqJ6\nBfTJaxfFvGJDYKY/REn3aW3tzMOkLeRC6INGQ1geV3YK+9goiHWOuUIofEq+hkb6\nuaLJgMwcxdnVq/+EzAbrvHepqg/chqehgyifwKbxAoGAZi3il7BJ14OVMyKA1pJ/\ncyS639d/Pt5P+UfQl6zNGmK3nG3N3WQBqBAj2VS4dBHnYjk4q7flNrFNZvX7SvlU\n1oC6woqUInEB8UpiHuai3RXjSrjIRG65z4VdGPkiWbMQb7SOYrltGyRD9P3GGxgf\nmmnfN3W7+yTEEmzQXJUt93g=\n-----END PRIVATE KEY-----\n",
      "client_email": "firebase-adminsdk-yc1bb@flutter-gpi.iam.gserviceaccount.com",
      "client_id": "111927764583564699256",
      "auth_uri": "https://accounts.google.com/o/oauth2/auth",
      "token_uri": "https://oauth2.googleapis.com/token",
      "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
      "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-yc1bb%40flutter-gpi.iam.gserviceaccount.com",
      "universe_domain": "googleapis.com"
    };

    List<String> scopes = [
      'https://www.googleapis.com/auth/userinfo.email',
      'https://www.googleapis.com/auth/firebase.database',
      'https://www.googleapis.com/auth/firebase.messaging',
    ];

    var client = await auth.clientViaServiceAccount(
      auth.ServiceAccountCredentials.fromJson(serviceAccountJson),
      scopes,
    );


    var credentials = await client.credentials;
    return credentials.accessToken.data;
  
  }

  static sendNotificationToEmployee(BuildContext context) async {
    String serverAccessToken = await _getAccessToken();
    String endpointFirebaseCloudMessaging = "https://fcm.googleapis.com/v1/projects/flutter-gpi/messages:send";

    final Map<String, dynamic> message = {
      'message': {
        'token': staticDeviceToken, 
        'notification': {
          'title': 'Equipment Request Submitted',
          'body': 'Your equipment request has been successfully submitted.'
        }
      }
    };

    final http.Response response = await http.post(
      Uri.parse(endpointFirebaseCloudMessaging),
      headers: <String, String>{
        'Authorization': 'Bearer $serverAccessToken',
        'Content-Type': 'application/json'
      },
      body: jsonEncode(message),
    );

    if (response.statusCode == 200) {
      print("Notification sent successfully to $staticDeviceToken");
    } else {
      print("Failed to send notification to $staticDeviceToken with status code ${response.statusCode}");
    }
  }
}

/*
class PushNotificationService {
  static Future<String> _getAccessToken() async {
    final serviceAccountJson = {
      "type": "service_account",
      "project_id": "flutter-gpi",
      "private_key_id": "8f131c8d88cc68908b2ae4926f5cfac0caf9f8e4",
      "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQCguVf331RObQGG\noP9OR9PRfth2QtTfSxPLfwpi3xRo5zTLi71p54Qp6sTcWwBNZluBiGriByTzWuAm\n8Mrbp8Oxyx7I0/Fw1178O31pdtL5dCReMEwT6T0eGKpOY3UuHj4Cv9FADmCvlbGX\nLYKdle6W8hiJXyT81tKa4iiE9wzGkxTDWrFev+DEVKop7UjNC6QNCF/2crPQwEbI\nMYKgbBpKwZ1HaWKLMcuTCHX5LVBTjy8yaP+fTsNHjYJRZwTGOCC97nMFg30PtoyN\nLJ5h2ismZu7R+Gyj2JWARestemf6Po6gClfsM1qvrLdIJ0mm5/UPzhrJbXQFcul6\nE8ob1Nn9AgMBAAECggEADO71QP1P+bKkY4rLmKdHiI1ySkv0+NYADQlXUt78M7fd\nQ/7l+mJ2vG/HsSrCgrf4p5sMbM1h4BJhRMjuLhBZO1Kq0sLZZDj0jAwWerjk382E\niq7MxHJpqGUYOVAgExq8Zzi71DGD/sUnQhDXuKoixbNMHavSHGWGE5Ac7hw6QzVc\nktaV9z15aBX7hpF63qA2sRDErmrkgJsduXmHEqQLOLfwrmOZQVQAykTekbamwb+9\n7s1omJTsLuZ+X75uw1sfVuwVvDRv14fXhorUu67vOU3K+XtDIdpW1KpNbSTjhNa0\n8ZySFnQlSENjCjv/vbhg2f5SlfUOoMsxLgvvt4/OeQKBgQDTkJJuPEnV0xa0wtW1\nBL0M8kxn0QQstlVJiaaWve142WXrBIkkxCbVSFxQVfC2HKzIfwmqoWmirt4J07W4\nxZlD/Wg1xexz/7QE8of71JilBdWlfuqsq6RQbcoNhA6Q5LG/jAikvLOlfyinx1/z\nXYcx8JhkxTq0liPczB2h0/C5aQKBgDCeynLEtuP1g00XyrTyuAtcESLEyPM/fdk\n2nwW5a4+xJBhucdkjeJEB/ey52Q9Fz86wW7e1xvbqa3FP8Yrc/NUHYwX1R3AC1pg\nXP08TxCrrN26H5l5MHQ3I+2oH0p702NXDdEZc2wodSiasTW5NIkPm0aG7c0YlwmJ\nySbYOPaVdQKBgQC5JgqgIm7TjDqQ0vnHw2/XRq0LJearYp5dDvQVc/3BBzCkboG/\nBVKe0QbI340bMxkbFeJVy5Dw6Gw02WxtWbB5yelLNf1qvtrCgaX0A+fac7K3dMzX\ndBcGtC5hibJdp2bPJTPjR6lIKnJf8qHMD4vjbpVPizOHGuYjsxYzq5E+EQKBgEON\nXFr5VeKES1nhpJKkaXHfCS/1mf3eSUxyx598cCXFSRFo4mV/ExTmX5d44EyIAqJ6\nBfTJaxfFvGJDYKY/REn3aW3tzMOkLeRC6INGQ1geV3YK+9goiHWOuUIofEq+hkb6\nuaLJgMwcxdnVq/+EzAbrvHepqg/chqehgyifwKbxAoGAZi3il7BJ14OVMyKA1pJ/\ncyS639d/Pt5P+UfQl6zNGmK3nG3N3WQBqBAj2VS4dBHnYjk4q7flNrFNZvX7SvlU\n1oC6woqUInEB8UpiHuai3RXjSrjIRG65z4VdGPkiWbMQb7SOYrltGyRD9P3GGxgf\nmmnfN3W7+yTEEmzQXJUt93g=\n-----END PRIVATE KEY-----\n",
      "client_email": "firebase-adminsdk-yc1bb@flutter-gpi.iam.gserviceaccount.com",
      "client_id": "111927764583564699256",
      "auth_uri": "https://accounts.google.com/o/oauth2/auth",
      "token_uri": "https://oauth2.googleapis.com/token",
      "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
      "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-yc1bb%40flutter-gpi.iam.gserviceaccount.com",
      "universe_domain": "googleapis.com"
    };

    List<String> scopes = [
      'https://www.googleapis.com/auth/userinfo.email',
      'https://www.googleapis.com/auth/firebase.database',
      'https://www.googleapis.com/auth/firebase.messaging',
    ];

    var client = await auth.clientViaServiceAccount(
      auth.ServiceAccountCredentials.fromJson(serviceAccountJson),
      scopes,
    );

    // Get the access token
    var credentials = await client.credentials;
    return credentials.accessToken.data;
  }

  static sendNotificationToEmployee(BuildContext context) async {
    // Set your static device token here
    String staticDeviceToken = "cdN5lwiPSueEPDn7boPQv2:APA91bF3FZPl1sy4oZY9TE9R7GSxTEsWFSpCVbf8kAyhRnPI7wXJ5iJpd23MQox5_vINANfBjFfUi-VA_YdNqOnHX3jAVYLwIyRUmeGGd1NIXKU7a0PGXKIEwhYAnGUpxzwIqIvqQJKf";

    String serverAccessToken = await _getAccessToken();
    String endpointFirebaseCloudMessaging = "https://fcm.googleapis.com/v1/projects/flutter-gpi/messages:send";

    final Map<String, dynamic> message = {
      'message': {
        'token': staticDeviceToken,
        'notification': {
          'title': 'Equipment Request Submitted',
          'body': 'Your equipment request has been successfully submitted.'
        }
      }
    };

    final http.Response response = await http.post(
      Uri.parse(endpointFirebaseCloudMessaging),
      headers: <String, String>{
        'Authorization': 'Bearer $serverAccessToken',
        'Content-Type': 'application/json'
      },
      body: jsonEncode(message),
    );

    if (response.statusCode == 200) {
      print("Notification sent successfully to $staticDeviceToken");
    } else {
      print("Failed to send notification to $staticDeviceToken with status code ${response.statusCode}");
    }
  }
}
*/
