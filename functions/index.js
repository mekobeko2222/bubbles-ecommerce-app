const functions = require("firebase-functions");
const admin = require("firebase-admin");

// Initialize Firebase Admin SDK
admin.initializeApp();

// Get Firestore and Messaging instances
const db = admin.firestore();
const messaging = admin.messaging();

/**
 * Cloud Function triggered when a new order is created
 * Sends notification to all admin devices
 */
exports.notifyAdminsOnNewOrder = functions.firestore
    .document("orders/{orderId}")
    .onCreate(async (snapshot, context) => {
        try {
            const orderId = context.params.orderId;
            const orderData = snapshot.data();

            console.log(`📦 New order created: ${orderId}`);
            console.log("Order data:", orderData);

            // Get all active admin tokens
            const adminTokensSnapshot = await db.collection("admin_tokens")
                .where("isActive", "==", true)
                .get();

            if (adminTokensSnapshot.empty) {
                console.log("⚠️ No active admin tokens found");
                return null;
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
                console.log("⚠️ No valid admin tokens to send notifications to");
                return null;
            }

            // Prepare notification data
            const totalPrice = orderData.totalPrice || 0;
            const itemCount = orderData.items ? orderData.items.length : 0;
            const customerEmail = orderData.userEmail || "Unknown Customer";
            const orderIdShort = orderId.substring(0, 8).toUpperCase();

            // Create notification payload
            const notification = {
                title: "🛒 New Order Received!",
                body: `Order #${orderIdShort}\nCustomer: ${customerEmail}\n` +
                      `Total: EGP ${totalPrice.toFixed(2)}\nItems: ${itemCount}`,
            };

            const data = {
                type: "admin",
                action: "new_order",
                orderId: orderId,
                customerEmail: customerEmail,
                totalPrice: totalPrice.toString(),
                itemCount: itemCount.toString(),
                orderStatus: orderData.orderStatus || "Pending",
            };

            // Send multicast message to all admin tokens
            const message = {
                notification: notification,
                data: data,
                tokens: adminTokens,
                android: {
                    notification: {
                        channelId: "admin_notifications",
                        priority: "high",
                        sound: "default",
                        icon: "ic_launcher",
                    },
                },
                apns: {
                    payload: {
                        aps: {
                            alert: {
                                title: notification.title,
                                body: notification.body,
                            },
                            badge: 1,
                            sound: "default",
                        },
                    },
                },
            };

            // Send the notification
            const response = await messaging.sendMulticast(message);

            console.log(`✅ Notification sent successfully: ` +
                       `${response.successCount} successful, ` +
                       `${response.failureCount} failed`);

            // Log any failures
            if (response.failureCount > 0) {
                response.responses.forEach((resp, idx) => {
                    if (!resp.success) {
                        console.error(`❌ Failed to send to token ` +
                                     `${adminTokens[idx]}: ${resp.error}`);
                    }
                });
            }

            // Clean up invalid tokens
            const invalidTokens = [];
            response.responses.forEach((resp, idx) => {
                if (!resp.success && resp.error &&
                    resp.error.code === "messaging/registration-token-not-registered") {
                    invalidTokens.push(adminTokens[idx]);
                }
            });

            if (invalidTokens.length > 0) {
                console.log(`🗑️ Cleaning up ${invalidTokens.length} invalid tokens`);
                await cleanupInvalidTokens(invalidTokens);
            }

            return null;
        } catch (error) {
            console.error("❌ Error sending admin notification:", error);
            return null;
        }
    });

/**
 * Cloud Function to process notification queue
 * Handles both individual and broadcast notifications
 */
exports.processNotificationQueue = functions.firestore
    .document("notification_queue/{queueId}")
    .onCreate(async (snapshot, context) => {
        try {
            const queueData = snapshot.data();
            const queueId = context.params.queueId;

            console.log(`📤 Processing notification queue item: ${queueId}`);

            if (queueData.processed) {
                console.log("⚠️ Notification already processed, skipping");
                return null;
            }

            const {payload, targetType} = queueData;

            if (targetType === "individual") {
                // Send to specific token
                await sendIndividualNotification(payload);
            } else if (targetType === "all_admins") {
                // Broadcast to all admins
                await broadcastToAllAdmins(payload);
            }

            // Mark as processed
            await snapshot.ref.update({
                processed: true,
                processedAt: admin.firestore.FieldValue.serverTimestamp(),
            });

            console.log(`✅ Notification queue item processed: ${queueId}`);
            return null;
        } catch (error) {
            console.error("❌ Error processing notification queue:", error);

            // Mark as failed
            await snapshot.ref.update({
                processed: true,
                failed: true,
                error: error.message,
                processedAt: admin.firestore.FieldValue.serverTimestamp(),
            });

            return null;
        }
    });

/**
 * Cloud Function triggered when order status is updated
 * Sends notification to customer if status is 'Shipped'
 */
exports.notifyCustomerOnStatusUpdate = functions.firestore
    .document("orders/{orderId}")
    .onUpdate(async (change, context) => {
        try {
            const beforeData = change.before.data();
            const afterData = change.after.data();
            const orderId = context.params.orderId;

            // Check if order status changed
            if (beforeData.orderStatus === afterData.orderStatus) {
                return null; // No status change
            }

            const newStatus = afterData.orderStatus;
            const userId = afterData.userId;

            console.log(`📦 Order ${orderId} status changed from ` +
                       `${beforeData.orderStatus} to ${newStatus}`);

            // Only send notification for specific status changes
            if (!["Shipped", "Delivered", "Cancelled"].includes(newStatus)) {
                console.log(`⚠️ No notification needed for status: ${newStatus}`);
                return null;
            }

            // Get user's FCM token
            const userDoc = await db.collection("users").doc(userId).get();

            if (!userDoc.exists) {
                console.log(`⚠️ User document not found: ${userId}`);
                return null;
            }

            const userData = userDoc.data();
            const userToken = userData.fcmToken;

            if (!userToken) {
                console.log(`⚠️ No FCM token found for user: ${userId}`);
                return null;
            }

            // Prepare notification based on status
            let notification = {};
            const orderIdShort = orderId.substring(0, 8).toUpperCase();

            switch (newStatus.toLowerCase()) {
            case "shipped":
                notification = {
                    title: "🚚 Order Shipped",
                    body: `Your order #${orderIdShort} has been shipped and is on its way!`,
                };
                break;
            case "delivered":
                notification = {
                    title: "✅ Order Delivered",
                    body: `Your order #${orderIdShort} has been delivered successfully!`,
                };
                break;
            case "cancelled":
                notification = {
                    title: "❌ Order Cancelled",
                    body: `Your order #${orderIdShort} has been cancelled.`,
                };
                break;
            default:
                return null;
            }

            const data = {
                type: "order",
                action: "view_order",
                orderId: orderId,
                newStatus: newStatus,
            };

            // Send notification to customer
            const message = {
                notification: notification,
                data: data,
                token: userToken,
                android: {
                    notification: {
                        channelId: "order_notifications",
                        priority: "high",
                        sound: "default",
                        icon: "ic_launcher",
                    },
                },
                apns: {
                    payload: {
                        aps: {
                            alert: {
                                title: notification.title,
                                body: notification.body,
                            },
                            badge: 1,
                            sound: "default",
                        },
                    },
                },
            };

            const response = await messaging.send(message);
            console.log(`✅ Customer notification sent successfully: ${response}`);

            return null;
        } catch (error) {
            console.error("❌ Error sending customer notification:", error);
            return null;
        }
    });

/**
 * Cloud Function for updating admin FCM tokens
 */
exports.updateAdminToken = functions.https.onCall(async (data, context) => {
    try {
        // Check if user is authenticated
        if (!context.auth) {
            throw new functions.https.HttpsError(
                "unauthenticated",
                "The function must be called while authenticated.",
            );
        }

        const userId = context.auth.uid;
        const {token} = data;

        if (!token) {
            throw new functions.https.HttpsError(
                "invalid-argument",
                "Token is required.",
            );
        }

        // Verify user is admin
        const userDoc = await db.collection("users").doc(userId).get();
        if (!userDoc.exists || !userDoc.data().isAdmin) {
            throw new functions.https.HttpsError(
                "permission-denied",
                "Only admins can update admin tokens.",
            );
        }

        // Update or create admin token document
        await db.collection("admin_tokens").doc(userId).set({
            token: token,
            userId: userId,
            isActive: true,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        console.log(`✅ Admin token updated for user: ${userId}`);
        return {success: true, message: "Admin token updated successfully"};
    } catch (error) {
        console.error("❌ Error updating admin token:", error);
        throw error;
    }
});

/**
 * Cloud Function for removing admin FCM tokens
 */
exports.removeAdminToken = functions.https.onCall(async (data, context) => {
    try {
        // Check if user is authenticated
        if (!context.auth) {
            throw new functions.https.HttpsError(
                "unauthenticated",
                "The function must be called while authenticated.",
            );
        }

        const userId = context.auth.uid;

        // Mark token as inactive instead of deleting
        await db.collection("admin_tokens").doc(userId).update({
            isActive: false,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        console.log(`✅ Admin token deactivated for user: ${userId}`);
        return {success: true, message: "Admin token removed successfully"};
    } catch (error) {
        console.error("❌ Error removing admin token:", error);
        throw error;
    }
});

/**
 * Cloud Function for manually sending notifications from admin panel
 */
exports.sendManualNotification = functions.https.onCall(async (data, context) => {
    try {
        // Check if user is authenticated
        if (!context.auth) {
            throw new functions.https.HttpsError(
                "unauthenticated",
                "The function must be called while authenticated.",
            );
        }

        const userId = context.auth.uid;

        // Verify user is admin
        const userDoc = await db.collection("users").doc(userId).get();
        if (!userDoc.exists || !userDoc.data().isAdmin) {
            throw new functions.https.HttpsError(
                "permission-denied",
                "Only admins can send manual notifications.",
            );
        }

        const {title, body, targetType, targetUserId} = data;

        if (!title || !body) {
            throw new functions.https.HttpsError(
                "invalid-argument",
                "Title and body are required.",
            );
        }

        const notificationData = {
            type: "manual",
            action: "general",
            timestamp: new Date().toISOString(),
            sentBy: userId,
        };

        if (targetType === "all_admins") {
            // Send to all admins
            await broadcastToAllAdmins({
                title: title,
                body: body,
                data: notificationData,
            });
            return {success: true, message: "Notification sent to all admins"};
        } else if (targetType === "specific_user" && targetUserId) {
            // Send to specific user
            const targetUserDoc = await db.collection("users").doc(targetUserId).get();
            if (!targetUserDoc.exists) {
                throw new functions.https.HttpsError(
                    "not-found",
                    "Target user not found.",
                );
            }

            const targetUserData = targetUserDoc.data();
            const userToken = targetUserData.fcmToken;

            if (!userToken) {
                throw new functions.https.HttpsError(
                    "not-found",
                    "User does not have an FCM token.",
                );
            }

            await sendIndividualNotification({
                token: userToken,
                title: title,
                body: body,
                data: notificationData,
            });

            return {success: true, message: "Notification sent to specific user"};
        }

        throw new functions.https.HttpsError(
            "invalid-argument",
            "Invalid target type or missing target user ID.",
        );
    } catch (error) {
        console.error("❌ Error sending manual notification:", error);
        throw error;
    }
});

/**
 * Helper function to send individual notification
 * @param {Object} payload - The notification payload
 * @return {Promise} Response from FCM
 */
async function sendIndividualNotification(payload) {
    const {token, title, body, data} = payload;

    const message = {
        notification: {
            title: title,
            body: body,
        },
        data: data,
        token: token,
        android: {
            notification: {
                channelId: data.type === "admin" ? "admin_notifications" : "order_notifications",
                priority: "high",
                sound: "default",
                icon: "ic_launcher",
            },
        },
        apns: {
            payload: {
                aps: {
                    alert: {
                        title: title,
                        body: body,
                    },
                    badge: 1,
                    sound: "default",
                },
            },
        },
    };

    const response = await messaging.send(message);
    console.log(`✅ Individual notification sent: ${response}`);
    return response;
}

/**
 * Helper function to broadcast to all admins
 * @param {Object} payload - The notification payload
 * @return {Promise} Response from FCM
 */
async function broadcastToAllAdmins(payload) {
    const {title, body, data} = payload;

    // Get all active admin tokens
    const adminTokensSnapshot = await db.collection("admin_tokens")
        .where("isActive", "==", true)
        .get();

    if (adminTokensSnapshot.empty) {
        console.log("⚠️ No active admin tokens found for broadcast");
        return;
    }

    const adminTokens = [];
    adminTokensSnapshot.forEach((doc) => {
        const tokenData = doc.data();
        if (tokenData.token) {
            adminTokens.push(tokenData.token);
        }
    });

    if (adminTokens.length === 0) {
        console.log("⚠️ No valid admin tokens for broadcast");
        return;
    }

    const message = {
        notification: {
            title: title,
            body: body,
        },
        data: data,
        tokens: adminTokens,
        android: {
            notification: {
                channelId: "admin_notifications",
                priority: "high",
                sound: "default",
                icon: "ic_launcher",
            },
        },
        apns: {
            payload: {
                aps: {
                    alert: {
                        title: title,
                        body: body,
                    },
                    badge: 1,
                    sound: "default",
                },
            },
        },
    };

    const response = await messaging.sendMulticast(message);
    console.log(`✅ Broadcast sent: ${response.successCount} successful, ` +
               `${response.failureCount} failed`);

    // Clean up invalid tokens
    const invalidTokens = [];
    response.responses.forEach((resp, idx) => {
        if (!resp.success && resp.error &&
            resp.error.code === "messaging/registration-token-not-registered") {
            invalidTokens.push(adminTokens[idx]);
        }
    });

    if (invalidTokens.length > 0) {
        await cleanupInvalidTokens(invalidTokens);
    }

    return response;
}

/**
 * Helper function to clean up invalid tokens
 * @param {Array} invalidTokens - Array of invalid FCM tokens
 * @return {Promise} Batch commit result
 */
async function cleanupInvalidTokens(invalidTokens) {
    console.log(`🗑️ Cleaning up ${invalidTokens.length} invalid tokens`);

    const batch = db.batch();

    for (const token of invalidTokens) {
        // Find and delete documents with invalid tokens
        const adminTokenQuery = await db.collection("admin_tokens")
            .where("token", "==", token)
            .get();

        adminTokenQuery.forEach((doc) => {
            batch.delete(doc.ref);
        });

        // Also clean up from users collection
        const userQuery = await db.collection("users")
            .where("fcmToken", "==", token)
            .get();

        userQuery.forEach((doc) => {
            batch.update(doc.ref, {
                fcmToken: admin.firestore.FieldValue.delete(),
                tokenUpdatedAt: admin.firestore.FieldValue.delete(),
            });
        });
    }

    await batch.commit();
    console.log(`✅ Cleaned up ${invalidTokens.length} invalid tokens`);
}

/**
 * Scheduled function to clean up old notification queue items
 * Runs daily at midnight
 */
exports.cleanupNotificationQueue = functions.pubsub
    .schedule("0 0 * * *") // Daily at midnight
    .timeZone("Africa/Cairo") // Egypt timezone
    .onRun(async (context) => {
        try {
            console.log("🧹 Starting notification queue cleanup...");

            // Delete processed notifications older than 7 days
            const sevenDaysAgo = admin.firestore.Timestamp.fromDate(
                new Date(Date.now() - 7 * 24 * 60 * 60 * 1000),
            );

            const oldNotifications = await db.collection("notification_queue")
                .where("processed", "==", true)
                .where("createdAt", "<", sevenDaysAgo)
                .get();

            if (!oldNotifications.empty) {
                const batch = db.batch();
                oldNotifications.forEach((doc) => {
                    batch.delete(doc.ref);
                });
                await batch.commit();
                console.log(`🗑️ Deleted ${oldNotifications.size} old notification queue items`);
            }

            // Clean up old admin tokens (inactive for more than 30 days)
            const thirtyDaysAgo = admin.firestore.Timestamp.fromDate(
                new Date(Date.now() - 30 * 24 * 60 * 60 * 1000),
            );

            const oldTokens = await db.collection("admin_tokens")
                .where("updatedAt", "<", thirtyDaysAgo)
                .get();

            if (!oldTokens.empty) {
                const tokenBatch = db.batch();
                oldTokens.forEach((doc) => {
                    tokenBatch.delete(doc.ref);
                });
                await tokenBatch.commit();
                console.log(`🗑️ Deleted ${oldTokens.size} old admin tokens`);
            }

            console.log("✅ Notification queue cleanup completed");
            return null;
        } catch (error) {
            console.error("❌ Error during cleanup:", error);
            return null;
        }
    });

/**
 * HTTP Cloud Function for testing notifications
 * Can be called from admin panel for testing
 */
exports.testNotification = functions.https.onCall(async (data, context) => {
    try {
        // Verify the caller is authenticated and is an admin
        if (!context.auth) {
            throw new functions.https.HttpsError("unauthenticated",
                "The function must be called while authenticated.");
        }

        const userId = context.auth.uid;

        // Check if user is admin
        const userDoc = await db.collection("users").doc(userId).get();

        if (!userDoc.exists || !userDoc.data().isAdmin) {
            throw new functions.https.HttpsError("permission-denied",
                "Only admins can send test notifications.");
        }

        const {title, body, targetType} = data;

        if (targetType === "self") {
            // Send test notification to calling admin
            const adminTokenDoc = await db.collection("admin_tokens").doc(userId).get();

            if (!adminTokenDoc.exists) {
                throw new functions.https.HttpsError("not-found", "Admin token not found.");
            }

            const token = adminTokenDoc.data().token;

            await sendIndividualNotification({
                token: token,
                title: title || "🧪 Test Notification",
                body: body || "This is a test notification sent from the admin panel.",
                data: {
                    type: "test",
                    timestamp: new Date().toISOString(),
                },
            });

            return {success: true, message: "Test notification sent successfully"};
        } else if (targetType === "all_admins") {
            // Broadcast to all admins
            await broadcastToAllAdmins({
                title: title || "📢 Admin Broadcast Test",
                body: body || "This is a test broadcast to all administrators.",
                data: {
                    type: "test",
                    timestamp: new Date().toISOString(),
                },
            });

            return {success: true, message: "Test broadcast sent to all admins"};
        }

        throw new functions.https.HttpsError("invalid-argument",
            "Invalid target type. Use \"self\" or \"all_admins\".");
    } catch (error) {
        console.error("❌ Error sending test notification:", error);
        throw new functions.https.HttpsError("internal",
            "Error sending test notification: " + error.message);
    }
});

/**
 * HTTP Cloud Function to get notification statistics
 */
exports.getNotificationStats = functions.https.onCall(async (data, context) => {
    try {
        // Verify the caller is authenticated and is an admin
        if (!context.auth) {
            throw new functions.https.HttpsError("unauthenticated",
                "The function must be called while authenticated.");
        }

        const userId = context.auth.uid;

        // Check if user is admin
        const userDoc = await db.collection("users").doc(userId).get();

        if (!userDoc.exists || !userDoc.data().isAdmin) {
            throw new functions.https.HttpsError("permission-denied",
                "Only admins can view notification statistics.");
        }

        // Get statistics
        const [adminTokens, pendingQueue, last24hQueue] = await Promise.all([
            db.collection("admin_tokens").where("isActive", "==", true).get(),
            db.collection("notification_queue").where("processed", "==", false).get(),
            db.collection("notification_queue")
                .where("processed", "==", true)
                .where("createdAt", ">",
                    admin.firestore.Timestamp.fromDate(new Date(Date.now() - 24 * 60 * 60 * 1000)))
                .get(),
        ]);

        return {
            activeAdminTokens: adminTokens.size,
            pendingNotifications: pendingQueue.size,
            notificationsLast24h: last24hQueue.size,
            lastUpdated: new Date().toISOString(),
        };
    } catch (error) {
        console.error("❌ Error getting notification stats:", error);
        throw new functions.https.HttpsError("internal",
            "Error getting notification statistics: " + error.message);
    }
});