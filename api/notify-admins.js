// api/notify-admins.js
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
    const { orderId, orderData } = req.body;

    console.log(`📦 Processing new order notification: ${orderId}`);

    // Get all active admin tokens
    const adminTokensSnapshot = await db.collection('admin_tokens')
      .where('isActive', '==', true)
      .get();

    if (adminTokensSnapshot.empty) {
      console.log('⚠️ No active admin tokens found');
      return res.status(200).json({ 
        success: true, 
        message: 'No active admin tokens found' 
      });
    }

    const adminTokens = [];
    adminTokensSnapshot.forEach((doc) => {
      const data = doc.data();
      if (data.token) {
        adminTokens.push(data.token);
      }
    });

    console.log(`📋 Found ${adminTokens.length} admin tokens`);

    if (adminTokens.length === 0) {
      return res.status(200).json({ 
        success: true, 
        message: 'No valid admin tokens found' 
      });
    }

    // Prepare notification data
    const totalPrice = orderData.totalPrice || 0;
    const itemCount = orderData.items ? orderData.items.length : 0;
    const customerEmail = orderData.userEmail || 'Unknown Customer';
    const orderIdShort = orderId.substring(0, 8).toUpperCase();

    const notification = {
      title: '🛒 New Order Received!',
      body: `Order #${orderIdShort}\nCustomer: ${customerEmail}\nTotal: EGP ${totalPrice.toFixed(2)}\nItems: ${itemCount}`
    };

    const data = {
      type: 'admin',
      action: 'new_order',
      orderId: orderId,
      customerEmail: customerEmail,
      totalPrice: totalPrice.toString(),
      itemCount: itemCount.toString(),
      orderStatus: orderData.orderStatus || 'Pending'
    };

    // Send multicast message to all admin tokens
    const message = {
      notification: notification,
      data: data,
      tokens: adminTokens,
      android: {
        notification: {
          channelId: 'admin_notifications',
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

    const response = await messaging.sendMulticast(message);

    console.log(`✅ Notification sent: ${response.successCount} successful, ${response.failureCount} failed`);

    // Handle failures and clean up invalid tokens
    if (response.failureCount > 0) {
      const invalidTokens = [];
      response.responses.forEach((resp, idx) => {
        if (!resp.success) {
          console.error(`❌ Failed to send to token ${adminTokens[idx]}: ${resp.error}`);
          if (resp.error && resp.error.code === 'messaging/registration-token-not-registered') {
            invalidTokens.push(adminTokens[idx]);
          }
        }
      });

      // Clean up invalid tokens
      if (invalidTokens.length > 0) {
        console.log(`🗑️ Cleaning up ${invalidTokens.length} invalid tokens`);
        await cleanupInvalidTokens(invalidTokens);
      }
    }

    return res.status(200).json({
      success: true,
      message: 'Admin notifications sent successfully',
      successCount: response.successCount,
      failureCount: response.failureCount
    });

  } catch (error) {
    console.error('❌ Error sending admin notification:', error);
    return res.status(500).json({
      success: false,
      error: 'Failed to send notifications',
      details: error.message
    });
  }
}

// Helper function to clean up invalid tokens
async function cleanupInvalidTokens(invalidTokens) {
  const batch = db.batch();

  for (const token of invalidTokens) {
    // Find and delete documents with invalid tokens
    const adminTokenQuery = await db.collection('admin_tokens')
      .where('token', '==', token)
      .get();

    adminTokenQuery.forEach((doc) => {
      batch.delete(doc.ref);
    });

    // Also clean up from users collection
    const userQuery = await db.collection('users')
      .where('fcmToken', '==', token)
      .get();

    userQuery.forEach((doc) => {
      batch.update(doc.ref, {
        fcmToken: admin.firestore.FieldValue.delete(),
        tokenUpdatedAt: admin.firestore.FieldValue.delete()
      });
    });
  }

  await batch.commit();
  console.log(`✅ Cleaned up ${invalidTokens.length} invalid tokens`);
}