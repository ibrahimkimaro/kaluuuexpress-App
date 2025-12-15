// import 'dart:io';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'dart:convert';
// import 'package:kaluu_Epreess_Cargo/auths/api_service.dart';

// class NotificationService {
//   final FirebaseMessaging _fcm = FirebaseMessaging.instance;
//   final FlutterLocalNotificationsPlugin _localNotifications =
//       FlutterLocalNotificationsPlugin();

//   String? _fcmToken;

//   Future<void> initialize() async {
//     try {
//       // Request permission
//       NotificationSettings settings = await _fcm.requestPermission(
//         alert: true,
//         badge: true,
//         sound: true,
//       );

//       if (settings.authorizationStatus == AuthorizationStatus.authorized) {
//         if (kDebugMode) {
//           print('✅ Notification permission granted');
//         }

//         // Get FCM token
//         _fcmToken = await _fcm.getToken();
//         if (kDebugMode) {
//           print('FCM Token: $_fcmToken');
//         }

//         // Initialize local notifications
//         await _initializeLocalNotifications();

//         // Handle foreground messages
//         FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

//         // Handle notification tap when app is in background
//         FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

//         // Register token with backend
//         if (_fcmToken != null) {
//           await registerDeviceToken(_fcmToken!);
//         }
//       } else {
//         if (kDebugMode) {
//           print('❌ Notification permission denied');
//         }
//       }
//     } catch (e) {
//       if (kDebugMode) {
//         print('Error initializing notifications: $e');
//       }
//     }
//   }

//   Future<void> _initializeLocalNotifications() async {
//     const android = AndroidInitializationSettings('@mipmap/ic_launcher');
//     const ios = DarwinInitializationSettings();
//     const settings = InitializationSettings(android: android, iOS: ios);

//     await _localNotifications.initialize(
//       settings,
//       onDidReceiveNotificationResponse: (details) {
//         // Handle notification tap
//         if (kDebugMode) {
//           print('Notification tapped: ${details.payload}');
//         }
//         // TODO: Navigate to tracking page
//       },
//     );

//     // Create Android notification channel
//     const androidChannel = AndroidNotificationChannel(
//       'shipment_updates',
//       'Shipment Updates',
//       description: 'Notifications for shipment status and route updates',
//       importance: Importance.high,
//     );

//     await _localNotifications
//         .resolvePlatformSpecificImplementation<
//           AndroidFlutterLocalNotificationsPlugin
//         >()
//         ?.createNotificationChannel(androidChannel);
//   }

//   void _handleForegroundMessage(RemoteMessage message) {
//     if (kDebugMode) {
//       print('Foreground message: ${message.notification?.title}');
//     }

//     // Show local notification when app is in foreground
//     _showLocalNotification(message);
//   }

//   void _handleNotificationTap(RemoteMessage message) {
//     if (kDebugMode) {
//       print('Notification tapped: ${message.data}');
//     }

//     // Navigate to shipment details if tracking_code exists
//     if (message.data.containsKey('tracking_code')) {
//       // TODO: Navigate to tracking page
//       // You can use a global navigator key or event bus here
//     }
//   }

//   Future<void> _showLocalNotification(RemoteMessage message) async {
//     final androidDetails = AndroidNotificationDetails(
//       'shipment_updates',
//       'Shipment Updates',
//       channelDescription: 'Notifications for shipment status and route updates',
//       importance: Importance.high,
//       priority: Priority.high,
//       icon: '@mipmap/ic_launcher',
//       color: const Color(0xFF0EA5E9), // Sky blue brand color
//     );

//     const iosDetails = DarwinNotificationDetails(
//       presentAlert: true,
//       presentBadge: true,
//       presentSound: true,
//     );

//     final details = NotificationDetails(
//       android: androidDetails,
//       iOS: iosDetails,
//     );

//     await _localNotifications.show(
//       message.hashCode,
//       message.notification?.title ?? 'Kaluu Express',
//       message.notification?.body,
//       details,
//       payload: jsonEncode(message.data),
//     );
//   }

//   Future<void> registerDeviceToken(String token) async {
//     try {
//       final apiService = ApiService();
//       final response = await apiService.registerDevice(
//         deviceToken: token,
//         deviceType: Platform.isAndroid ? 'android' : 'ios',
//       );

//       if (response.isSuccess) {
//         if (kDebugMode) {
//           print('✅ Device registered successfully');
//         }
//       } else {
//         if (kDebugMode) {
//           print('❌ Error registering device: ${response.error}');
//         }
//       }
//     } catch (e) {
//       if (kDebugMode) {
//         print('❌ Error registering device: $e');
//       }
//     }
//   }

//   String? get fcmToken => _fcmToken;
// }
