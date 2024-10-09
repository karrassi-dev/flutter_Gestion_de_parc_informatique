const functions = require("firebase-functions");
const admin = require("firebase-admin");
const axios = require("axios");

admin.initializeApp();

exports.sendDataToGLPI = functions.firestore
  .document('equipmentRequests/{requestId}')
  .onCreate(async (snap, context) => {
    const newValue = snap.data();
    
    const glpiData = {
      // format this according to GLPI's API requirements
      name: newValue.name,
      email: newValue.email,
      equipmentType: newValue.equipmentType,
      utilisateur: newValue.utilisateur,
      department: newValue.department,
      site: newValue.site,
      additionalDetails: newValue.additionalDetails,
      requester: newValue.requester,
      status: newValue.status,
      requestDate: newValue.requestDate,
    };

    try {
      await axios.post('https://your-glpi-instance/api/request', glpiData, {
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer sQtgkB5VdTuH0EKD6p830GWXEuAsntN3osiGW5OSN`,
        },
      });
      console.log('Data sent to GLPI successfully.');
    } catch (error) {
      console.error('Error sending data to GLPI:', error);
    }
  });
