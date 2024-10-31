

import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class Email_Service {
  static Future<void> sendEmail(
      String toEmail, String subject, String body) async {
    final smtpServer =
        gmail('karrassihamza0508@gmail.com', 'ejuu ezyn zapq ribj');
    final message = Message()
      ..from = Address('your-email@gmail.com', 'flutter-GPI')
      ..recipients.add(toEmail)
      ..subject = subject
      ..text = body;

    try {
      await send(message, smtpServer);
    } catch (e) {
      print("Error sending email: $e");
    }
  }
}

/*
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class EmailService {
  static Future<void> sendEmail(
      String toEmail, String subject, String body) async {
    final smtpServer = gmail('karrassihamza0508@gmail.com', 'your_app_password'); // Use your App Password here
    final message = Message()
      ..from = Address('karrassihamza0508@gmail.com', 'flutter-GPI') // Correct sender address
      ..recipients.add(toEmail)
      ..subject = subject
      ..text = body;

    try {
      await send(message, smtpServer);
      print('Email sent to $toEmail');
    } catch (e, stackTrace) {
      print("Error sending email: $e");
      print("Stack trace: $stackTrace");
    }
  }
}
*/



// import 'package:mailer/mailer.dart';
// import 'package:mailer/smtp_server.dart';

// class Email_Service {
//   static Future<void> sendEmail(String toEmail, String subject, String body) async {
//     final String email = 'aziza.elmiri@ump.ac.ma';
//     final String password = 'iajawffdtjwqhcma'; // Your app password (no trailing space)

//     // Setting up the SMTP server
//     final smtpServer = SmtpServer(
//       'smtp.office365.com',
//       port: 587,
//       username: email,
//       password: password,
//       ignoreBadCertificate: true, 
//       allowInsecure: false,
//       ssl: false,
//     );

//     // Creating the email message
//     final message = Message()
//       ..from = Address(email, 'flutter-GPI')
//       ..recipients.add(toEmail)
//       ..subject = subject
//       ..text = body;

//     try {
//       // Sending the email
//       await send(message, smtpServer);
//       print("Email sent successfully to $toEmail");
//     } catch (e) {
//       print("Error sending email: $e");
//     }
//   }
// }


/*
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class Email_Service {
  static Future<void> sendEmail(
      String toEmail, String subject, String body) async {
    // Set up the SMTP server for Outlook
    final smtpServer = SmtpServer('smtp.office365.com',
        port: 587,
        username: 'aziza.elmiri@ump.ac.ma',
        password: 'xvmwprquoxuxnbjt',            
        ignoreBadCertificate: false,
        allowInsecure: false);

    final message = Message()
      ..from = Address('aziza.elmiri@ump.ac.ma', 'flutter-GPI')
      ..recipients.add(toEmail)
      ..subject = subject
      ..text = body;

    try {
      // Send the email
      await send(message, smtpServer);
      print('Email sent!');
    } catch (e) {
      print('Error sending email: $e');
    }
  }
}
*/

/*
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

void main() async {

  String username = 'hamza.karr@outlook.com';
  String password = 'ulvaakjnlurmtxzn';  


  final smtpServer = hotmail(username, password);


  final message = Message()
    ..from = Address(username, 'whiteduck')
    ..recipients.add('hamza.flutter@outlook.com')  
    ..ccRecipients.addAll(['hamza.flutter@outlook.com'])
    ..bccRecipients.add(Address('hamza.flutter@outlook.com'))
    ..subject = 'Test Dart Mailer library :: 😀 :: ${DateTime.now()}'
    ..text = 'This is the plain text.\nThis is line 2 of the text part.'
    ..html = "<h1>Test</h1>\n<p>Hey! Here's some HTML content</p>";

  try {
    // Send the email
    final sendReport = await send(message, smtpServer);
    print('Message sent: ' + sendReport.toString());
  } on MailerException catch (e) {
    print('Message not sent.');
    for (var p in e.problems) {
      print('Problem: ${p.code}: ${p.msg}');
    }
  } catch (e) {
    // Catch any other exceptions
    print('An error occurred: $e');
  }
}


import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

Future<void> sendEmail() async {
  // Outlook SMTP server configuration
  final smtpServer = SmtpServer(
    'smtp.office365.com',  // Outlook SMTP server
    port: 587,             // Port for TLS
    username: 'aylin.pehlivan@outlook.de',
    //password: 'ulvaakjnlurmtxzn',  // Replace with your app password
    password: 'Aykiz1977.',  // Replace with your app password
  );

  // Create the email message
  final message = Message()
    ..from = Address('aylin.pehlivan@outlook.de', 'karrassi')
    ..recipients.add('hamza.flutter@outlook.com')  // Replace with recipient's email
    ..subject = 'Hello from Flutter! :: ${DateTime.now()}'
    ..text = 'This is the plain text body of the email.'
    ..html = '<h1>HTML body of the email</h1>';

  try {
    // Send the email and get the send report
    final sendReport = await send(message, smtpServer);

    // Log the result
    print('Message sent successfully to: ${message.recipients}');
    print('Send report: ${sendReport.toString()}');
    
  } on MailerException catch (e) {
    // Handle specific mailer errors
    print('Email not sent. Problem: ${e.toString()}');
    for (var p in e.problems) {
      print('Problem code: ${p.code}, Problem message: ${p.msg}');
    }
  } catch (e) {
    // Catch any other type of exception
    print('An unexpected error occurred: $e');
  }
}

void main() {
  sendEmail();
}
*/