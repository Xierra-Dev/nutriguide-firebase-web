import 'package:firebase_messaging/firebase_messaging.dart';


class NotificationsServices{
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  void requestNotificationPermission()async{
    NotificationSettings notificationSettings = await messaging.requestPermission(
      alert: true,
      announcement: true,
      badge: true,
      carPlay: true,
      criticalAlert: true,
      provisional: true,
      sound: true,
    );

    if(notificationSettings.authorizationStatus == AuthorizationStatus.authorized){
      print('Notification Permission Granted');
    } else if(notificationSettings.authorizationStatus == AuthorizationStatus.authorized){
      print('Notification Provosional Permission Granted');
    } else {
      print('Notification Permission Declined');
    }
  }
}

