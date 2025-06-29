// api/notify-customer.js
import admin from 'firebase-admin';

// Initialize Firebase Admin (only once)
if (!admin.apps.length) {
  const serviceAccount = {
    type: "service_account",
    project_id: process.env.FIREBASE_PROJECT_ID,
    private_key_id: process.env.FIREBASE_PRIVATE_KEY_ID,
    private_key: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
    client_email: process.env.FIREBASE_CLIENT_EMAIL,
    client_id: process.env.FIREBASE_CLIENT_ID,
    auth_uri: "https://accounts.google.com/o/oauth2/auth",
    token_uri: "https://oauth2.googleapis.com/token",
    auth_provider_x509_cert_url: "https://www.googleapis.com/oauth2/v1/certs",
    client_x509_cert_url: process.env.FIREBASE_CERT_URL
  };

  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
}

const db = admin.firestore();
const messaging = admin.messaging();

export default async function handler(req, res) {
  // Enable CORS
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  if (req.method !== 'POST') {
    return res.status(405).json({
      success: false,
      error: 'Method not allowed. Use POST.'
    });
  }

  try {
    console.log('📱 Customer notification request received:', req.body);

    const { title, body, data, userId } = req.body;

    if (!title || !body) {
      return res.status(400).json({
        success: false,
        error: 'Missing required fields: title and body',
        example: {
          title: 'Order Confirmed',
          body: 'Your order #12345 has been confirmed!',
          data: { orderId: '12345', type: 'order_confirmation' },
          userId: 'optional-user-id'
        }
      });
    }

    console.log('📱 Processing customer notification:', { title, body, data, userId });

    const notificationData = {
      ...data,
      timestamp: new Date().toISOString(),
      type: 'customer'
    };

    let response;

    if (userId) {
      // Send to specific user
      const userDoc = await db.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        return res.status(404).json({
          success: false,
          error: 'User not found'
        });
      }

      const userData = userDoc.data();
      const userToken = userData.fcmToken;

      if (!userToken) {
        return res.status(400).json({
          success: false,
          error: 'User has no FCM token'
        });
      }

      const message = {
        notification: { title, body },
        data: notificationData,
        token: userToken,
        android: {
          notification: {
            channelId: 'order_notifications',
            priority: 'high',
            sound: 'default'
          }
        },
        apns: {
          payload: {
            aps: {
              alert: { title, body },
              badge: 1,
              sound: 'default'
            }
          }
        }
      };

      response = await messaging.send(message);
      console.log('✅ Customer notification sent to specific user:', response);

    } else {
      // Send to all customers via topic
      const message = {
        notification: { title, body },
        data: notificationData,
        topic: 'customers',
        android: {
          notification: {
            channelId: 'general_notifications',
            priority: 'default',
            sound: 'default'
          }
        },
        apns: {
          payload: {
            aps: {
              alert: { title, body },
              badge: 1,
              sound: 'default'
            }
          }
        }
      };

      response = await messaging.send(message);
      console.log('✅ Customer notification sent to topic:', response);
    }

    return res.status(200).json({
      success: true,
      messageId: response,
      message: 'Customer notification sent successfully',
      sentTo: userId ? 'specific_user' : 'all_customers',
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('❌ Error sending customer notification:', error);
    return res.status(500).json({
      success: false,
      error: 'Failed to send customer notification',
      details: error.message,
      timestamp: new Date().toISOString()
    });
  }
}