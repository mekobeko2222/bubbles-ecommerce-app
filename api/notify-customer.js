// api/notify-customer.js

const admin = require('firebase-admin');

// Initialize Firebase Admin (only once)
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.applicationDefault(),
  });
}

export default async function handler(req, res) {
  // Handle CORS
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed. Use POST.' });
  }

  try {
    const { title, body, data } = req.body;

    if (!title || !body) {
      return res.status(400).json({ 
        error: 'Title and body are required',
        example: {
          title: 'Order Confirmed',
          body: 'Your order #12345 has been confirmed!',
          data: { orderId: '12345', type: 'order_confirmation' }
        }
      });
    }

    console.log('📱 Sending customer notification:', { title, body, data });

    // Send notification to customers
    const message = {
      notification: {
        title,
        body,
      },
      data: {
        ...data,
        timestamp: new Date().toISOString(),
        notificationType: 'customer',
      },
      topic: 'customers', // Send to all customers subscribed to this topic
    };

    const response = await admin.messaging().send(message);
    
    console.log('✅ Customer notification sent successfully:', response);
    
    res.status(200).json({ 
      success: true, 
      messageId: response,
      message: 'Customer notification sent successfully',
      sentTo: 'customers',
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('❌ Error sending customer notification:', error);
    res.status(500).json({ 
      success: false,
      error: 'Failed to send customer notification', 
      details: error.message,
      timestamp: new Date().toISOString()
    });
  }
}