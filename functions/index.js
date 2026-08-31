const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

/**
 * Firestore trigger: whenever a reminder document is created
 * Send FCM notification immediately if `sendAt` <= now
 */
exports.onReminderCreated = functions.firestore
  .document('reminders/{reminderId}')
  .onCreate(async (snap, context) => {
    const reminder = snap.data();
    if (!reminder) return null;

    const { user_id, title, message, sendAt, reference_id = '', type = 'reminder' } = reminder;

    const now = admin.firestore.Timestamp.now();
    if (sendAt.toMillis() > now.toMillis()) {
      console.log(`Reminder ${context.params.reminderId} is scheduled for future. Skipping.`);
      return null;
    }

    try {
      const userDoc = await db.collection('users').doc(user_id).get();
      if (!userDoc.exists) {
        console.log('No user doc for', user_id);
        await snap.ref.update({ sent: true });
        return null;
      }

      const token = userDoc.get('fcm_token');
      if (!token) {
        console.log('No FCM token for', user_id);
        await snap.ref.update({ sent: true });
        return null;
      }

      const payload = {
        notification: { title, body: message },
        data: { reference_id, type }
      };

      await messaging.sendToDevice(token, payload);

      // Save notification history
      await db.collection('notifications').add({
        user_id,
        type,
        title,
        message,
        reference_id,
        status: 'unread',
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Mark reminder as sent
      await snap.ref.update({
        sent: true,
        sentAt: admin.firestore.FieldValue.serverTimestamp()
      });

    } catch (err) {
      console.error('Error sending reminder:', err);
      await snap.ref.update({
        sent: true,
        error: err.toString()
      });
    }

    return null;
  });


exports.onNotificationCreated = functions.firestore
  .document('notifications/{notifId}')
  .onCreate(async (snap, context) => {
    const data = snap.data();
    if (!data) return null;

    const userId = data.user_id;
    const userDoc = await db.collection('users').doc(userId).get();
    if (!userDoc.exists) return null;

    const token = userDoc.get('fcm_token');
    if (!token) return null;

    const payload = {
      notification: { title: data.title, body: data.message },
      data: { reference_id: data.reference_id || '', type: data.type || '' }
    };

    try {
      await messaging.sendToDevice(token, payload);
    } catch (err) {
      console.error('FCM send error:', err);
    }

    return null;
    
  });

exports.onVisitCreatedDelayedReminder = functions.firestore
  .document('visit_record/{visitId}')
  .onCreate(async (snap, context) => {
    const data = snap.data();
    if (!data) return null;

    const studentId = data.student_id;
    const visitId = context.params.visitId;

    await new Promise(resolve => setTimeout(resolve, 30000));

    console.log(` 30 seconds passed — sending delayed reminder to ${studentId}`);

    try {
   
      const userDoc = await db.collection('users').doc(studentId).get();
      if (!userDoc.exists) {
        console.log("No user doc for", studentId);
        return null;
      }

      const token = userDoc.get('fcm_token');
      if (!token) {
        console.log(" No FCM token for", studentId);
        return null;
      }

      const payload = {
        notification: {
          title: "Visit Reminder",
          body: "This is your reminder for the recent visit."
        },
        data: {
          reference_id: visitId,
          type: "visit_reminder"
        }
      };

      await messaging.sendToDevice(token, payload);

    

  
      await db.collection('notifications').add({
        user_id: studentId,
        type: "visit_reminder",
        title: "Visit Reminder",
        message: "This is your reminder for the recent visit.",
        reference_id: visitId,
        status: "unread",
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });

    } catch (err) {
      console.error(" Error sending delayed reminder:", err);
    }

    return null;
  });