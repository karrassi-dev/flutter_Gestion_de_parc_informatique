const functions = require('firebase-functions');
const admin = require('firebase-admin');
const nodemailer = require('nodemailer');

admin.initializeApp();

// Configure the Gmail SMTP transporter
const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: 'karrassihamza0508@gmail.com', // Your Gmail address
    pass: 'ejuu ezyn zapq ribj', // Your Gmail password or App Password
  },
});

exports.sendEmailNotification = functions.firestore
  .document('equipmentRequests/{requestId}')
  .onCreate(async (snap, context) => {
    const requestData = snap.data();

    const mailOptions = {
      from: 'your-email@gmail.com', // Your Gmail address
      to: 'karrassihamza0508@gmail.com', // Admin email address
      subject: 'New Equipment Request',
      text: `New equipment request from: ${requestData.name}\n` +
            `Email: ${requestData.email}\n` +
            `Equipment Type: ${requestData.equipmentType}\n` +
            `Utilisateur: ${requestData.utilisateur}\n` +
            `Department: ${requestData.department}\n` +
            `Additional Details: ${requestData.additionalDetails}\n` +
            `Request Date: ${requestData.requestDate}`,
    };

    try {
      await transporter.sendMail(mailOptions);
      console.log('Email sent successfully');
    } catch (error) {
      console.error('Error sending email:', error);
    }
  });
