import 'dart:io';

import 'package:data_table_2/data_table_2.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lonely/model/package_model.dart';
import 'package:lonely/model/price_model.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'model/lonely_model.dart';
import 'my_home_page.dart';
import 'package:firebase_core/firebase_core.dart';
// 아래 파일이 없다는 오류가 난다면 Firebase CLI, FlutterFire CLI 이용해서 초기 설정해야한다.
// 상세 절차는 아래 링크를 참조한다.
// https://firebase.google.com/docs/flutter/setup
import 'firebase_options.dart';

void main() {
  if (kIsWeb) {
    // 웹에서는 sqflite 못쓴다.
    throw Exception('Web is not supported');
  }

  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
  }

  initFirebase();

  dataTableShowLogs = false;

  runApp(const MyApp());
}

void initFirebase() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.instance.onTokenRefresh
      .listen((fcmToken) {
        if (kDebugMode) {
          print('FCM token refreshed 1: $fcmToken');
        }
  })
      .onError((err) {
    if (kDebugMode) {
      print('FCM token refresh error!: $err');
    }
  });

  final notificationSettings = await FirebaseMessaging.instance.requestPermission(provisional: true);

  if (Platform.isIOS) {
    final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
    if (apnsToken != null) {
      print('FCM APNS token acquired: $apnsToken');
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (kDebugMode) {
        print('FCM token acquired 2: $fcmToken');
      }
    }
  } else {
    final fcmToken = await FirebaseMessaging.instance.getToken();
    if (kDebugMode) {
      print('FCM token acquired 3: $fcmToken');
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ReorderableListView 사용하려니까,
    // Provider()가 MaterialApp()을 감싸야 된다고 카더라...
    // https://github.com/flutter/flutter/issues/88570
    // 그래서 최상위까지 기어올라왔다...

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LonelyModel()),
        ChangeNotifierProvider(create: (_) => PriceModel()),
        ChangeNotifierProvider(create: (_) => PackageModel()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Lonely',
        theme: ThemeData(
          primarySwatch: Colors.blueGrey,
        ),
        home: const MyHomePage(),
      ),
    );
  }
}
