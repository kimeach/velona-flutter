import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

/// 백그라운드 메시지 핸들러 (top-level 함수 필수)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  NotificationService._showLocalNotification(message);
}

class NotificationService {
  NotificationService._();
  static final _messaging = FirebaseMessaging.instance;
  static final _localNotif = FlutterLocalNotificationsPlugin();

  static const _channel = AndroidNotificationChannel(
    'velona_default',
    'Velona AI 알림',
    description: '영상 생성 완료 및 서비스 알림',
    importance: Importance.high,
  );

  static Future<void> init() async {
    // 권한 요청
    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    // 로컬 알림 초기화
    await _localNotif.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );

    // Android 채널 생성
    await _localNotif
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // 포어그라운드 메시지 수신
    FirebaseMessaging.onMessage.listen((message) {
      _showLocalNotification(message);
    });

    // 앱 종료 상태에서 알림 탭으로 열린 경우
    final initial = await _messaging.getInitialMessage();
    if (initial != null) _handleMessageOpen(initial);

    // 백그라운드에서 알림 탭으로 열린 경우
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpen);

    // 백그라운드 핸들러 등록
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  static Future<String?> getToken() => _messaging.getToken();

  static void _showLocalNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _localNotif.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }

  static void _handleMessageOpen(RemoteMessage message) {
    // 알림 탭 시 라우팅 처리 — projectId가 있으면 해당 프로젝트로 이동
    final projectId = message.data['projectId'] as String?;
    if (projectId != null) {
      // GoRouter는 context 없이 접근 불가 → navigatorKey로 처리
      navigatorKey.currentState?.pushNamed('/projects/$projectId');
    }
  }

  /// GlobalKey<NavigatorState> — main.dart에서 MaterialApp.router에 연결
  static final navigatorKey = GlobalKey<NavigatorState>();
}
