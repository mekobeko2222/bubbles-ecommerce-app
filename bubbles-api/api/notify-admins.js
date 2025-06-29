// api/notify-admins.js
import admin from 'firebase-admin';

// Initialize Firebase Admin (only once)
if (!admin.apps.length) {
  try {
    // Use Application Default Credentials if available, otherwise use service account
    if (process.env.FIREBASE_PROJECT_ID && process.env.FIREBASE_PRIVATE_KEY && process.env.FIREBASE_CLIENT_EMAIL) {
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
        credential: admin.credential.cert(serviceAccount),
        projectId: process.env.FIREBASE_PROJECT_ID
      });
    } else {
      // Fallback to default credentials
      admin.initializeApp();
    }
    console.log('✅ Firebase Admin initialized successfully');
  } catch (error) {
    console.error('❌ Firebase Admin initialization failed:', error);
  }
}

const db = admin.firestore();
const messaging = admin.messaging();

// Helper function to safely extract order data
function extractOrderData(reqBody) {
  console.log('🔍 Extracting order data from request body:', JSON.stringify(reqBody, null, 2));

  // Format 1: Direct notification (from test/general use)
  if (reqBody.title && reqBody.body) {
    return {
      title: reqBody.title,
      body: reqBody.body,
      notificationData: reqBody.data || {}
    };
  }

  // Format 2: Order notification (from order system) - Handle multiple possible structures
  if (reqBody.orderId) {
    const orderId = reqBody.orderId;
    let orderData = reqBody.orderData || reqBody.data || {};

    // If orderData is missing, try to get it from root level
    if (!orderData || Object.keys(orderData).length === 0) {
      orderData = {
        totalPrice: reqBody.totalPrice || reqBody.total || 0,
        userEmail: reqBody.userEmail || reqBody.customerEmail || 'Unknown Customer',
        items: reqBody.items || [],
        orderStatus: reqBody.orderStatus || 'Pending'
      };
    }

    // Simple notification - just notify about new order
    const title = '🛒 New Order!';
    const messageBody = 'You have received a new order. Check your admin panel for details.';
    const notificationData = {
      type: 'admin',
      action: 'new_order',
      orderId: orderId,
      orderStatus: 'Pending'
    };

    return { title, body: messageBody, notificationData };
  }

  // Format 3: ApiNotificationService format
  if (reqBody.data && reqBody.data.orderData) {
    const title = '🛒 New Order!';
    const messageBody = 'You have received a new order. Check your admin panel for details.';
    const notificationData = {
      type: 'admin',
      action: 'new_order',
      orderId: reqBody.data.orderId || 'unknown',
      orderStatus: 'Pending'
    };

    return { title, body: messageBody, notificationData };
  }

  // If nothing matches, return error info
  throw new Error(`Unable to parse order data. Received keys: ${Object.keys(reqBody).join(', ')}`);
}

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
    console.log('📧 Admin notification request received:', JSON.stringify(req.body, null, 2));

    let title, messageBody, notificationData;

    try {
      const extracted = extractOrderData(req.body);
      title = extracted.title;
      messageBody = extracted.body;
      notificationData = extracted.notificationData;
    } catch (parseError) {
      console.error('❌ Error parsing order data:', parseError.message);
      return res.status(400).json({
        success: false,
        error: 'Invalid request format',
        details: parseError.message,
        received: req.body,
        expectedFormats: [
          '1. {title, body, data}',
          '2. {orderId, orderData: {totalPrice, userEmail, items, orderStatus}}',
          '3. {data: {orderId, customerName, customerEmail, total, itemCount, orderData}}'
        ]
      });
    }

    console.log(`📦 Processing admin notification: ${title}`);
    console.log(`📦 Notification body: ${messageBody}`);
    console.log(`📦 Notification data:`, notificationData);

    // Get all active admin tokens
    const adminTokensSnapshot = await db.collection('admin_tokens')
      .where('isActive', '==', true)
      .get();

    if (adminTokensSnapshot.empty) {
      console.log('⚠️ No active admin tokens found');
      return res.status(200).json({
        success: true,
        message: 'No active admin tokens found',
        adminCount: 0
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
        message: 'No valid admin tokens found',
        adminCount: 0
      });
    }

    // Send notifications one by one instead of batch (more reliable)
    const results = [];
    let successCount = 0;
    let failureCount = 0;

    for (const token of adminTokens) {
      try {
        const message = {
          notification: {
            title: title,
            body: messageBody
          },
          data: {
            ...notificationData,
            timestamp: new Date().toISOString()
          },
          token: token,
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
                  title: title,
                  body: messageBody
                },
                badge: 1,
                sound: 'default'
              }
            }
          }
        };

        const response = await messaging.send(message);
        results.push({ token: token.substring(0, 20) + '...', success: true, messageId: response });
        successCount++;
        console.log(`✅ Sent to admin token: ${token.substring(0, 20)}...`);
      } catch (error) {
        results.push({ token: token.substring(0, 20) + '...', success: false, error: error.message });
        failureCount++;
        console.error(`❌ Failed to send to token ${token.substring(0, 20)}...:`, error.message);

        // Clean up invalid tokens
        if (error.code === 'messaging/registration-token-not-registered') {
          await cleanupInvalidToken(token);
        }
      }
    }

    console.log(`📊 Final results: ${successCount} successful, ${failureCount} failed`);

    return res.status(200).json({
      success: true,
      message: 'Admin notifications processed',
      successCount: successCount,
      failureCount: failureCount,
      adminCount: adminTokens.length,
      results: results
    });

  } catch (error) {
    console.error('❌ Error sending admin notification:', error);
    return res.status(500).json({
      success: false,
      error: 'Failed to send notifications',
      details: error.message,
      stack: error.stack
    });
  }
}

// Helper function to clean up a single invalid token
async function cleanupInvalidToken(invalidToken) {
  try {
    const batch = db.batch();

    // Find and delete documents with invalid tokens
    const adminTokenQuery = await db.collection('admin_tokens')
      .where('token', '==', invalidToken)
      .get();

    adminTokenQuery.forEach((doc) => {
      batch.delete(doc.ref);
    });

    // Also clean up from users collection
    const userQuery = await db.collection('users')
      .where('fcmToken', '==', invalidToken)
      .get();

    userQuery.forEach((doc) => {
      batch.update(doc.ref, {
        fcmToken: admin.firestore.FieldValue.delete(),
        tokenUpdatedAt: admin.firestore.FieldValue.delete()
      });
    });

    await batch.commit();
    console.log(`✅ Cleaned up invalid token: ${invalidToken.substring(0, 20)}...`);
  } catch (error) {
    console.error(`❌ Error cleaning up token:`, error);
  }
}