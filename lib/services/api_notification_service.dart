// lib/services/api_notification_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

/// Service for making HTTP API calls to the Vercel notification endpoints
/// This is separate from the Firebase notification service
class ApiNotificationService {
  // FIXED: Use the correct Vercel URL format
  static const String _baseUrl = 'https://the-hall-zdaf.vercel.app/api';

  /// Notify admins via HTTP API
  static Future<Map<String, dynamic>> notifyAdmins({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      debugPrint('🔔 Sending admin notification via API: $title');

      final response = await http.post(
        Uri.parse('$_baseUrl/notify-admins'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'title': title,
          'body': body,
          'data': {
            ...?data,
            'timestamp': DateTime.now().toIso8601String(),
            'source': 'bubbles-flutter-app',
          },
        }),
      );

      debugPrint('📡 API Response Status: ${response.statusCode}');
      debugPrint('📡 API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        debugPrint('✅ Admin notification sent successfully via API');
        return {'success': true, 'data': result, 'message': result['message'] ?? 'Success'};
      } else {
        final errorBody = response.body.isNotEmpty ? response.body : 'No error details';
        throw Exception('HTTP ${response.statusCode}: $errorBody');
      }
    } catch (error) {
      debugPrint('❌ Error sending admin notification via API: $error');
      return {'success': false, 'error': error.toString()};
    }
  }

  /// Notify customer via HTTP API
  static Future<Map<String, dynamic>> notifyCustomer({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      debugPrint('🔔 Sending customer notification via API: $title');

      final response = await http.post(
        Uri.parse('$_baseUrl/notify-customer'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'title': title,
          'body': body,
          'data': {
            ...?data,
            'timestamp': DateTime.now().toIso8601String(),
            'source': 'bubbles-flutter-app',
          },
        }),
      );

      debugPrint('📡 API Response Status: ${response.statusCode}');
      debugPrint('📡 API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        debugPrint('✅ Customer notification sent successfully via API');
        return {'success': true, 'data': result, 'message': result['message'] ?? 'Success'};
      } else {
        final errorBody = response.body.isNotEmpty ? response.body : 'No error details';
        throw Exception('HTTP ${response.statusCode}: $errorBody');
      }
    } catch (error) {
      debugPrint('❌ Error sending customer notification via API: $error');
      return {'success': false, 'error': error.toString()};
    }
  }

  /// Test API connection
  static Future<Map<String, dynamic>> testConnection() async {
    try {
      final result = await notifyAdmins(
        title: '🧪 Test Notification',
        body: 'Testing API connection from Flutter app!',
        data: {
          'type': 'test',
          'platform': 'flutter',
          'testTime': DateTime.now().toIso8601String(),
        },
      );
      return result;
    } catch (error) {
      return {'success': false, 'error': error.toString()};
    }
  }

  /// E-commerce specific methods
  static Future<void> notifyNewOrder({
    required String orderId,
    required String customerName,
    required String customerEmail,
    required double total,
    required int itemCount,
  }) async {
    // FIXED: Send order data in the correct format that the API expects
    debugPrint('🛒 Notifying new order: $orderId, Total: $total, Items: $itemCount');

    // Notify admins about new order using the ORDER FORMAT
    await notifyAdmins(
      title: '🛒 New Order Received!',
      body: 'Order #${orderId.substring(0, 8).toUpperCase()} from $customerName - Total: EGP ${total.toStringAsFixed(2)}',
      data: {
        'type': 'admin',
        'action': 'new_order',
        'orderId': orderId,
        'customerEmail': customerEmail,
        'customerName': customerName,
        'totalPrice': total.toString(),
        'itemCount': itemCount.toString(),
        'orderStatus': 'Pending',
      },
    );

    // Notify customer about order confirmation
    await notifyCustomer(
      title: '✅ Order Confirmed!',
      body: 'Thank you $customerName! Your order #${orderId.substring(0, 8).toUpperCase()} has been confirmed.',
      data: {
        'type': 'order_confirmation',
        'orderId': orderId,
        'total': total,
        'estimatedDelivery': '3-5 business days',
      },
    );
  }

  /// Alternative method that sends order data in the format expected by the API
  static Future<void> notifyNewOrderDirect({
    required String orderId,
    required Map<String, dynamic> orderData,
  }) async {
    try {
      debugPrint('🛒 Sending direct order notification: $orderId');
      debugPrint('📦 Order data being sent: ${jsonEncode(orderData)}');

      // Send to admin API using the direct order format
      final response = await http.post(
        Uri.parse('$_baseUrl/notify-admins'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'orderId': orderId,
          'orderData': orderData,
        }),
      );

      debugPrint('📡 Direct Admin API Response Status: ${response.statusCode}');
      debugPrint('📡 Direct Admin API Response Body: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }

      // Send customer notification
      final customerName = orderData['userEmail']?.split('@')[0] ?? 'Customer';
      final total = (orderData['totalPrice'] as num?)?.toDouble() ?? 0.0;

      await notifyCustomer(
        title: '✅ Order Confirmed!',
        body: 'Thank you! Your order #${orderId.substring(0, 8).toUpperCase()} has been confirmed.',
        data: {
          'type': 'order_confirmation',
          'orderId': orderId,
          'total': total,
        },
      );

    } catch (error) {
      debugPrint('❌ Error in notifyNewOrderDirect: $error');
      throw error;
    }
  }

  static Future<void> notifyOrderStatusUpdate({
    required String orderId,
    required String status,
    required String customerName,
    String? trackingNumber,
  }) async {
    String statusMessage;
    String emoji;

    switch (status.toLowerCase()) {
      case 'processing':
        statusMessage = 'Your order is being processed';
        emoji = '⚙️';
        break;
      case 'shipped':
        statusMessage = trackingNumber != null
            ? 'Your order has been shipped - Tracking: $trackingNumber'
            : 'Your order has been shipped';
        emoji = '📦';
        break;
      case 'delivered':
        statusMessage = 'Your order has been delivered!';
        emoji = '✅';
        break;
      case 'cancelled':
        statusMessage = 'Your order has been cancelled';
        emoji = '❌';
        break;
      default:
        statusMessage = 'Your order status has been updated';
        emoji = '📋';
    }

    await notifyCustomer(
      title: '$emoji Order Update',
      body: '$customerName, $statusMessage',
      data: {
        'type': 'order_status_update',
        'orderId': orderId,
        'status': status,
        'trackingNumber': trackingNumber,
      },
    );
  }

  static Future<void> notifyLowStock({
    required String productName,
    required int currentStock,
    required int minThreshold,
  }) async {
    await notifyAdmins(
      title: '⚠️ Low Stock Alert',
      body: '$productName is running low! Current stock: $currentStock (Minimum: $minThreshold)',
      data: {
        'type': 'low_stock',
        'productName': productName,
        'currentStock': currentStock,
        'minThreshold': minThreshold,
        'urgent': currentStock <= minThreshold,
      },
    );
  }

  static Future<void> notifyPaymentFailed({
    required String orderId,
    required String customerName,
    required double amount,
    required String reason,
  }) async {
    // Notify admins
    await notifyAdmins(
      title: '💳 Payment Failed',
      body: 'Payment failed for order #$orderId - $customerName - EGP ${amount.toStringAsFixed(2)}',
      data: {
        'type': 'payment_failed',
        'orderId': orderId,
        'customerName': customerName,
        'amount': amount,
        'reason': reason,
      },
    );

    // Notify customer
    await notifyCustomer(
      title: '❌ Payment Issue',
      body: '$customerName, there was an issue processing your payment for order #$orderId. Please try again.',
      data: {
        'type': 'payment_failed',
        'orderId': orderId,
        'amount': amount,
      },
    );
  }

  static Future<void> notifyRefundProcessed({
    required String orderId,
    required String customerName,
    required double amount,
  }) async {
    await notifyCustomer(
      title: '💰 Refund Processed',
      body: '$customerName, your refund of EGP ${amount.toStringAsFixed(2)} for order #$orderId has been processed.',
      data: {
        'type': 'refund_processed',
        'orderId': orderId,
        'amount': amount,
        'processingTime': '3-5 business days',
      },
    );
  }

  static Future<void> notifyNewCustomerRegistration({
    required String customerName,
    required String customerEmail,
  }) async {
    await notifyAdmins(
      title: '👤 New Customer Registration',
      body: '$customerName ($customerEmail) just registered!',
      data: {
        'type': 'new_customer',
        'customerName': customerName,
        'customerEmail': customerEmail,
        'registrationDate': DateTime.now().toIso8601String(),
      },
    );
  }

  static Future<void> notifyContactForm({
    required String name,
    required String email,
    required String subject,
    required String message,
  }) async {
    await notifyAdmins(
      title: '📧 New Contact Form: $subject',
      body: '$name ($email) sent a message: ${message.length > 100 ? message.substring(0, 100) + '...' : message}',
      data: {
        'type': 'contact_form',
        'customerName': name,
        'customerEmail': email,
        'subject': subject,
        'submittedAt': DateTime.now().toIso8601String(),
      },
    );
  }
}