import 'package:agora/src/pages/index.dart';
import 'package:agora/src/utils/notification_widget.dart';
import 'package:agora/test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:uuid/uuid.dart';

import 'firebase_options.dart';

void main() {
  runApp(const MyApp());
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");
  showCallkitIncoming(Uuid().v4());
}

Future<void> showCallkitIncoming(String uuid) async {
  var params = <String, dynamic>{
    'id': uuid,
    'nameCaller': 'Hien Nguyen',
    'appName': 'Callkit',
    'avatar': 'https://i.pravatar.cc/100',
    'handle': '0123456789',
    'type': 0,
    'duration': 30000,
    'textAccept': 'Accept',
    'textDecline': 'Decline',
    'textMissedCall': 'Missed call',
    'textCallback': 'Call back',
    'extra': <String, dynamic>{'userId': '1a2b3c4d'},
    'headers': <String, dynamic>{'apiKey': 'Abc@123!', 'platform': 'flutter'},
    'android': <String, dynamic>{
      'isCustomNotification': true,
      'isShowLogo': false,
      'isShowCallback': false,
      'ringtonePath': 'system_ringtone_default',
      'backgroundColor': '#0955fa',
      'backgroundUrl': 'https://i.pravatar.cc/500',
      'actionColor': '#4CAF50'
    },
    'ios': <String, dynamic>{
      'iconName': 'CallKitLogo',
      'handleType': '',
      'supportsVideo': true,
      'maximumCallGroups': 2,
      'maximumCallsPerCallGroup': 1,
      'audioSessionMode': 'default',
      'audioSessionActive': true,
      'audioSessionPreferredSampleRate': 44100.0,
      'audioSessionPreferredIOBufferDuration': 0.005,
      'supportsDTMF': true,
      'supportsHolding': true,
      'supportsGrouping': false,
      'supportsUngrouping': false,
      'ringtonePath': 'system_ringtone_default'
    }
  };
  await FlutterCallkitIncoming.showCallkitIncoming(params);
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  var _uuid;
  var _currentUuid;

  late final FirebaseMessaging _firebaseMessaging;

  @override
  void initState() {
    super.initState();
    _uuid = Uuid();
    initFirebase();
    WidgetsBinding.instance.addObserver(this);
    //Check call when open app from terminated
    checkAndNavigationCallingPage();
  }

  getCurrentCall() async {
    //check current call from pushkit if possible
    var calls = await FlutterCallkitIncoming.activeCalls();
    if (calls is List) {
      if (calls.isNotEmpty) {
        print('DATA: $calls');
        this._currentUuid = calls[0]['id'];
        return calls[0];
      } else {
        this._currentUuid = "";
        return null;
      }
    }
  }

  void registerNotification() async {
    // 1. Initialize the Firebase app
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // 2. Instantiate Firebase Messaging
    var messaging = FirebaseMessaging.instance;

    // 3. On iOS, this helps to take the user permissions
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      provisional: false,
      sound: true,
    );

    messaging.getInitialMessage().then((value) async {
      print(value?.data);
      // onJoin(channelName, token);
      // if (value != null) {
      //   if (value.data["roomId"].toString().isNotEmpty && value.data["token"].toString().isNotEmpty) {
      //     print("VKL");
      //     if (open)  {
      //       await Permission.camera.request();
      //       await Permission.microphone.request();
      //       await Navigator.push(
      //           context,
      //           MaterialPageRoute(
      //               builder: (context) => CallPage(
      //                 channelName: value.data["roomId"] ?? channelName,
      //                 token: value.data["token"] ?? token,
      //                 role: _role ?? ClientRole.Broadcaster,
      //               )));
      //       setState(() {
      //         token = value.data["token"] ?? token;
      //         channelName = value.data["roomId"] ?? channelName;
      //         // open = false;
      //       });
      //     }
      //   }
      // }
    });

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
      // For handling the received notifications
      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        // Parse the message received
        PushNotification notification = PushNotification(
          title: "title",
          // body: message.notification?.body,
          body: "body",
        );
        message.data.forEach((key, value) {
          notification = PushNotification(
            title: key,
            body: value,
          );
        });

        showSimpleNotification(
          Text(notification.title!),
          leading: const NotificationBadge(totalNotifications: 1),
          subtitle: Text(notification.body!),
          background: Colors.cyan.shade700,
          duration: const Duration(seconds: 2),
        );
      });
    } else {
      print('User declined or has not accepted permission');
    }
  }

  Future<void> getDevicePushTokenVoIP() async {
    var devicePushTokenVoIP =
    await FlutterCallkitIncoming.getDevicePushTokenVoIP();
    print(devicePushTokenVoIP);
  }

  checkAndNavigationCallingPage() async {
    // var currentCall = await getCurrentCall();
    // if (currentCall != null) {
    //   NavigationService.instance
    //       .pushNamedIfNotCurrent(AppRoute.callingPage, args: currentCall);
    // }
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    print(state);
    if (state == AppLifecycleState.resumed) {
      //Check call when open app from background
      checkAndNavigationCallingPage();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  initFirebase() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    _firebaseMessaging = FirebaseMessaging.instance;
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      provisional: false,
      sound: true,
    );
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print(
          'Message title: ${message.notification?.title}, body: ${message.notification?.body}, data: ${message.data}');
      _currentUuid = _uuid.v4();
      showCallkitIncoming(_currentUuid);
    });
    _firebaseMessaging.getToken().then((token) {
      print('Device Token FCM: $token');
    });
  }

  @override
  Widget build(BuildContext context) {
    return OverlaySupport(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Flutter Demo',
        theme: ThemeData(
          primarySwatch: Colors.green,
        ),
        home: const IndexPage(),
      ),
    );
  }

}
