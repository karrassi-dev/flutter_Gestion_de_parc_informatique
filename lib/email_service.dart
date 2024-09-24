import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class Email_Service {
  static Future<void> sendEmail(String toEmail, String subject, String body) async {
    final smtpServer = gmail('karrassihamza0508@gmail.com', 'ejuu ezyn zapq ribj');
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
