const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.sendRequestNotification = functions.firestore
  .document('equipment_requests/{requestId}')
  .onCreate(async (snap, context) => {
    const requestData = snap.data();

    // Define the notification content
    const payload = {
      notification: {
        title: 'New Equipment Request',
        body: `${requestData.requester} has requested ${requestData.equipmentName}`,
      },
    };

    // Send the notification to admin (assuming admin is subscribed to a topic)
    try {
      await admin.messaging().sendToTopic('adminNotifications', payload);
      console.log('Notification sent successfully');
    } catch (error) {
      console.log('Error sending notification:', error);
    }

    // Optionally, save the notification in Firestore
    await admin.firestore().collection('notifications').add({
      title: payload.notification.title,
      body: payload.notification.body,
      isRead: false,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });
  });
