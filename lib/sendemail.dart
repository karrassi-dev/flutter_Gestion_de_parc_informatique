import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

Future<void> sendEmail(String toEmail, String subject, String body) async {

  final smtpServer = SmtpServer('smtp.office365.com',
      port: 587,
      username: 'hk.flutter@outlook.com',
      password: 'Hello555@@', 
      ignoreBadCertificate: false,
      allowInsecure: false);
      

  final message = Message()
    ..from = Address('hk.flutter@outlook.com', 'new request')
    ..recipients.add(toEmail)
    ..subject = subject
    ..text = body;

  try {

    await send(message, smtpServer);
    print('Email sent to $toEmail!');
  } catch (e) {
    print('Error sending email: $e');
  }
}
void main() {
  sendEmail('karrassihamza0508@gmail.com', 'Test Subject', 'This is a test email body.');
}