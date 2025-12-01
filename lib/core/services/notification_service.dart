import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal() {
    if (!Platform.isWindows && !Platform.isLinux) {
      _firebaseMessaging = FirebaseMessaging.instance;
    }
  }

  FirebaseMessaging? _firebaseMessaging;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // Bildirim servisini başlat
  Future<void> initialize() async {
    if (_initialized) return;

    // Local notifications ayarları
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Firebase Cloud Messaging izinleri
    if (_firebaseMessaging != null) {
      await _requestPermissions();
    
      // FCM token al
      final token = await _firebaseMessaging!.getToken();
      debugPrint('FCM Token: $token');

      // Token yenileme dinleyicisi
      _firebaseMessaging!.onTokenRefresh.listen((newToken) {
        debugPrint('FCM Token yenilendi: $newToken');
        // Token'ı backend'e gönderme işlemi burada yapılabilir
      });

      // Foreground mesajları dinle
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Background mesajları dinle
      FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);

      // Uygulama kapalıyken açılan mesajları kontrol et
      final initialMessage = await _firebaseMessaging!.getInitialMessage();
      if (initialMessage != null) {
        _handleBackgroundMessage(initialMessage);
      }
    }

    _initialized = true;
  }

  // İzinleri iste
  Future<void> _requestPermissions() async {
    if (_firebaseMessaging == null) return;
    final settings = await _firebaseMessaging!.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('Kullanıcı bildirim izni verdi');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      debugPrint('Kullanıcı geçici bildirim izni verdi');
    } else {
      debugPrint('Kullanıcı bildirim izni vermedi');
    }
  }

  // Foreground mesajlarını işle
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Foreground mesaj alındı: ${message.messageId}');
    _showLocalNotification(message);
  }

  // Background mesajlarını işle
  void _handleBackgroundMessage(RemoteMessage message) {
    debugPrint('Background mesaj alındı: ${message.messageId}');
    // Mesaj türüne göre yönlendirme yapılabilir
    _navigateFromNotification(message);
  }

  // Local bildirim göster
  Future<void> _showLocalNotification(RemoteMessage message) async {
    const androidDetails = AndroidNotificationDetails(
      'pos_pro_tr_channel',
      'POS Pro TR Bildirimleri',
      channelDescription: 'POS Pro TR uygulaması bildirimleri',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'Yeni Bildirim',
      message.notification?.body ?? '',
      notificationDetails,
      payload: message.data.toString(),
    );
  }

  // Bildirim tıklandığında
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Bildirim tıklandı: ${response.payload}');
    // Payload'a göre yönlendirme yapılabilir
  }

  // Bildirimden yönlendirme
  void _navigateFromNotification(RemoteMessage message) {
    final data = message.data;
    final type = data['type'];

    switch (type) {
      case 'order':
        // Sipariş detay sayfasına git
        break;
      case 'payment':
        // Ödeme detay sayfasına git
        break;
      case 'stock_alert':
        // Ürün listesi sayfasına git
        break;
      default:
        // Ana sayfaya git
        break;
    }
  }

  // Sipariş bildirimi gönder
  Future<void> sendOrderNotification({
    required String orderId,
    required String customerName,
    required double totalAmount,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'pos_pro_tr_channel',
      'POS Pro TR Bildirimleri',
      channelDescription: 'POS Pro TR uygulaması bildirimleri',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      orderId.hashCode,
      'Yeni Sipariş',
      '$customerName için ${totalAmount.toStringAsFixed(2)} ₺ tutarında sipariş oluşturuldu',
      notificationDetails,
      payload: 'order:$orderId',
    );
  }

  // Ödeme bildirimi gönder
  Future<void> sendPaymentNotification({
    required String paymentId,
    required String orderId,
    required double amount,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'pos_pro_tr_channel',
      'POS Pro TR Bildirimleri',
      channelDescription: 'POS Pro TR uygulaması bildirimleri',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      paymentId.hashCode,
      'Ödeme Alındı',
      'Sipariş #$orderId için ${amount.toStringAsFixed(2)} ₺ ödeme alındı',
      notificationDetails,
      payload: 'payment:$paymentId',
    );
  }

  // Stok uyarısı gönder
  Future<void> sendStockAlertNotification({
    required String productName,
    required int stock,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'pos_pro_tr_channel',
      'POS Pro TR Bildirimleri',
      channelDescription: 'POS Pro TR uygulaması bildirimleri',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      productName.hashCode,
      'Düşük Stok Uyarısı',
      '$productName ürününün stoğu $stock adede düştü',
      notificationDetails,
      payload: 'stock:$productName',
    );
  }

  // FCM token'ı al
  Future<String?> getToken() async {
    if (_firebaseMessaging == null) return null;
    return await _firebaseMessaging!.getToken();
  }

  // Belirli bir konuya abone ol
  Future<void> subscribeToTopic(String topic) async {
    if (_firebaseMessaging == null) return;
    await _firebaseMessaging!.subscribeToTopic(topic);
    debugPrint('Konuya abone olundu: $topic');
  }

  // Konudan abonelikten çık
  Future<void> unsubscribeFromTopic(String topic) async {
    if (_firebaseMessaging == null) return;
    await _firebaseMessaging!.unsubscribeFromTopic(topic);
    debugPrint('Konudan abonelikten çıkıldı: $topic');
  }
}

// Background message handler (top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background mesaj alındı: ${message.messageId}');
}

