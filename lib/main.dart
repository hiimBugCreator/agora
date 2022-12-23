import 'dart:convert';

import 'package:agora/src/pages/call.dart';
import 'package:agora/src/pages/index.dart';
import 'package:agora/src/utils/notification_widget.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/entities/call_event.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:go_router/go_router.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

import 'firebase_options.dart';

void main() {
  runApp(const MyApp());
}

final _router = GoRouter(
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) {
        return const IndexPage();
      },
    ),
    GoRoute(
      path: '/callscreen',
      builder: (BuildContext context, GoRouterState state) {
        var cData = jsonDecode(jsonEncode(state.extra)) ;
        print("XXXXXXXXXXXXX ${cData}");
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => CallPage(
                  channelName: cData['roomId'],
                  token: cData['token'],
                  role: ClientRoleType.clientRoleBroadcaster,
                )));
        return CallPage(
          channelName: cData['roomId'],
          token: cData['token'],
          role: ClientRoleType.clientRoleAudience,
        );
      },
    ),
  ],
);

Map<String, dynamic> callData = {};

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");
  showCallkitIncoming(const Uuid().v4(), message.data);
}

Future<void> showCallkitIncoming(String uuid, Map<String, dynamic> data) async {
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
  Future<void> _handleCameraAndMic(Permission permission) async {
    final status = await permission.request();
  }

  await FlutterCallkitIncoming.onEvent.listen((event) async {
    switch (event?.event){
      case Event.ACTION_CALL_ACCEPT:
        await _handleCameraAndMic(Permission.camera);
        await _handleCameraAndMic(Permission.microphone);
        _router.go('/callscreen',extra: data);
        break;
      case Event.ACTION_DID_UPDATE_DEVICE_PUSH_TOKEN_VOIP:
        // TODO: Handle this case.
        break;
      case Event.ACTION_CALL_INCOMING:
        // TODO: Handle this case.
        break;
      case Event.ACTION_CALL_START:
        // TODO: Handle this case.
        break;
      case Event.ACTION_CALL_DECLINE:
        FlutterCallkitIncoming.endAllCalls();
        _router.go('/');
        break;
      case Event.ACTION_CALL_ENDED:
        FlutterCallkitIncoming.endAllCalls();
        _router.go('/');
        break;
      case Event.ACTION_CALL_TIMEOUT:
        // TODO: Handle this case.
        break;
      case Event.ACTION_CALL_CALLBACK:
        // TODO: Handle this case.
        break;
      case Event.ACTION_CALL_TOGGLE_HOLD:
        // TODO: Handle this case.
        break;
      case Event.ACTION_CALL_TOGGLE_MUTE:
        // TODO: Handle this case.
        break;
      case Event.ACTION_CALL_TOGGLE_DMTF:
        // TODO: Handle this case.
        break;
      case Event.ACTION_CALL_TOGGLE_GROUP:
        // TODO: Handle this case.
        break;
      case Event.ACTION_CALL_TOGGLE_AUDIO_SESSION:
        // TODO: Handle this case.
        break;
      default:
        break;
    }
  });
  await FlutterCallkitIncoming.showCallkitIncoming(
      CallKitParams.fromJson(params));
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
    //   _router.go('/callscreen', extra: callData);
    // } else {
    //   _router.go('/');
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
      showCallkitIncoming(_currentUuid, message.data);
    });
    _firebaseMessaging.getToken().then((token) {
      print('Device Token FCM: $token');
    });
  }

  @override
  Widget build(BuildContext context) {
    return OverlaySupport(
      child: MaterialApp.router(
        routerConfig: _router,
      ),
    );
  }
}
