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
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    const { orderId, userId, newStatus, oldStatus } = req.body;

    console.log(`📦 Processing status update notification: ${orderId} - ${oldStatus} → ${newStatus}`);

    // Only send notification for specific status changes
    if (!['Shipped', 'Delivered', 'Cancelled'].includes(newStatus)) {
      return res.status(200).json({ 
        success: true, 
        message: `No notification needed for status: ${newStatus}` 
      });
    }

    // Get user's FCM token
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
      return res.status(200).json({ 
        success: true, 
        message: 'User does not have FCM token' 
      });
    }

    // Prepare notification based on status
    let notification = {};
    const orderIdShort = orderId.substring(0, 8).toUpperCase();

    switch (newStatus.toLowerCase()) {
      case 'shipped':
        notification = {
          title: '🚚 Order Shipped',
          body: `Your order #${orderIdShort} has been shipped and is on its way!`
        };
        break;
      case 'delivered':
        notification = {
          title: '✅ Order Delivered',
          body: `Your order #${orderIdShort} has been delivered successfully!`
        };
        break;
      case 'cancelled':
        notification = {
          title: '❌ Order Cancelled',
          body: `Your order #${orderIdShort} has been cancelled.`
        };
        break;
      default:
        return res.status(200).json({ 
          success: true, 
          message: 'No notification needed for this status' 
        });
    }

    const data = {
      type: 'order',
      action: 'view_order',
      orderId: orderId,
      newStatus: newStatus
    };

    // Send notification to customer
    const message = {
      notification: notification,
      data: data,
      token: userToken,
      android: {
        notification: {
          channelId: 'order_notifications',
          priority: 'high',
          sound: 'default',
          icon: 'ic_launcher'
        }
      },
      apns: {
        payload: {
          aps: {
            alert: {
              title: notification.title,
              body: notification.body
            },
            badge: 1,
            sound: 'default'
          }
        }
      }
    };

    const response = await messaging.send(message);
    console.log(`✅ Customer notification sent: ${response}`);

    return res.status(200).json({
      success: true,
      message: 'Customer notification sent successfully',
      messageId: response
    });

  } catch (error) {
    console.error('❌ Error sending customer notification:', error);
    return res.status(500).json({
      success: false,
      error: 'Failed to send notification',
      details: error.message
    });
  }
}