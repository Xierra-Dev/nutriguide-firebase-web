import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../constants/meal_times.dart';
import '../services/timezone_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'firestore_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // Initialize timezone
    TimezoneService.initializeTimeZones();

    // Firebase Messaging Setup
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Get FCM token
    String? token = await _firebaseMessaging.getToken();
    print('FCM Token: $token');

    // Local Notifications Setup
    await _requestPermissions();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) async {
        print('Notification tapped: ${details.payload}');
      },
    );

    // Create FCM notification channel
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Handle FCM foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              icon: android.smallIcon,
            ),
          ),
        );
      }
    });

    // Check if app was launched from notification
    final notificationAppLaunchDetails = await _localNotifications.getNotificationAppLaunchDetails();
    if (notificationAppLaunchDetails?.didNotificationLaunchApp ?? false) {
      print('App launched from notification');
    }
  }

  Future<void> _requestPermissions() async {
    await _localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();

    if (await Permission.scheduleExactAlarm.isDenied) {
      await Permission.scheduleExactAlarm.request();
    }
  }

  // Local Notifications Methods
  Future<void> scheduleMealReminder({
    required String recipeId,
    required String recipeName,
    required String mealType,
    required DateTime mealDate,
  }) async {
    try {
      if (!(await Permission.scheduleExactAlarm.isGranted)) {
        print('Exact alarms permission not granted');
        return await _scheduleInexactReminder(
          recipeId: recipeId,
          recipeName: recipeName,
          mealType: mealType,
          mealDate: mealDate,
        );
      }

      if (!MealTimes.ranges.containsKey(mealType)) {
        print('Invalid meal type: $mealType');
        return;
      }

      final mealTime = MealTimes.ranges[mealType]!;
      
      final scheduledDate = tz.TZDateTime.from(
        DateTime(
          mealDate.year,
          mealDate.month,
          mealDate.day,
          mealTime.start.hour,
          mealTime.start.minute,
        ).subtract(const Duration(minutes: 15)),
        tz.local,
      );

      if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
        print('Skipping notification for past time: $scheduledDate');
        return;
      }

      final androidDetails = AndroidNotificationDetails(
        'meal_reminders',
        'Meal Reminders',
        channelDescription: 'Notifications for meal reminders',
        importance: Importance.high,
        priority: Priority.high,
        styleInformation: BigTextStyleInformation(
          'It\'s time to prepare ${recipeName} for your ${mealType.toLowerCase()}! 🍳\n\n'
          'Get ready to cook this delicious meal. Remember to check your ingredients and follow the recipe steps carefully.',
          htmlFormatBigText: true,
          contentTitle: '🔔 Meal Reminder',
          htmlFormatContentTitle: true,
          summaryText: 'Time to cook!',
          htmlFormatSummaryText: true,
        ),
        color: const Color(0xFF4CAF50),
        icon: '@mipmap/ic_launcher',
        enableLights: true,
        ledColor: const Color(0xFF4CAF50),
        ledOnMs: 1000,
        ledOffMs: 500,
        vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
        category: AndroidNotificationCategory.reminder,
        fullScreenIntent: true,
        channelShowBadge: true,
        visibility: NotificationVisibility.public,
        playSound: true,
        enableVibration: true,
      );

      // Schedule the notification
      await _localNotifications.zonedSchedule(
        recipeId.hashCode,
        '🔔 Time to Cook!',
        'Prepare ${recipeName} for ${mealType}',
        scheduledDate,
        NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      // Save to Firestore
      final firestoreService = FirestoreService();
      await firestoreService.addNotification(
        title: '🔔 Meal Reminder',
        message: 'Time to prepare ${recipeName} for ${mealType}',
        type: 'meal_reminder',
        relatedId: recipeId,
      );
      
      print('Notification scheduled and saved to Firestore successfully');
    } catch (e) {
      print('Error scheduling notification: $e');
      print('Stack trace: ${StackTrace.current}');
      return;
    }
  }

  Future<void> _scheduleInexactReminder({
    required String recipeId,
    required String recipeName,
    required String mealType,
    required DateTime mealDate,
  }) async {
    final mealTime = MealTimes.ranges[mealType]!;
    final scheduledDate = tz.TZDateTime.from(
      DateTime(
        mealDate.year,
        mealDate.month,
        mealDate.day,
        mealTime.start.hour,
        mealTime.start.minute,
      ).subtract(const Duration(minutes: 15)),
      tz.local,
    );

    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
      print('Skipping notification for past time');
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      'meal_reminders',
      'Meal Reminders',
      channelDescription: 'Notifications for meal reminders',
      importance: Importance.high,
      priority: Priority.high,
    );

    await _localNotifications.zonedSchedule(
      recipeId.hashCode,
      'Meal Reminder',
      'Time to prepare $recipeName for $mealType!',
      scheduledDate,
      const NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.alarmClock,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );

    // Save to Firestore
    final firestoreService = FirestoreService();
    await firestoreService.addNotification(
      title: '🔔 Meal Reminder',
      message: 'Time to prepare $recipeName for $mealType',
      type: 'meal_reminder',
      relatedId: recipeId,
    );
  }

  Future<void> cancelMealReminder(String recipeId) async {
    try {
      await _localNotifications.cancel(recipeId.hashCode);
      print('Notification cancelled for recipe: $recipeId');
    } catch (e) {
      print('Error cancelling notification: $e');
    }
  }

  // FCM Methods
  Future<String?> getFCMToken() async {
    return await _firebaseMessaging.getToken();
  }

  void onFCMTokenRefresh(Function(String) callback) {
    _firebaseMessaging.onTokenRefresh.listen(callback);
  }

  Future<void> showFCMNotification({
    required String title,
    required String body,
  }) async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
    );

    await _localNotifications.show(
      DateTime.now().millisecond,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }
}

// Handle FCM background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling a background message: ${message.messageId}');
}