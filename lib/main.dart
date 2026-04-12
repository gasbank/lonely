import 'dart:io';

import 'package:data_table_2/data_table_2.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lonely/model/package_model.dart';
import 'package:lonely/model/price_model.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'excel_converter_meritz.dart';
import 'model/lonely_model.dart';
import 'my_home_page.dart';
import 'package:firebase_core/firebase_core.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    // 웹에서는 sqflite 못쓴다.
    throw Exception('Web is not supported');
  }

  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
  }

  await initFirebase();

  dataTableShowLogs = false;

  final file = File("C:\\Users\\gb\\Downloads\\Telegram Desktop\\pbrtp00030_hts.xlsx");
  if (kDebugMode) {
    print(file.path);
  }

  final converter = ConverterMeritz();
  await converter.loadSheet(file);

  runApp(const MyApp());
}

Future<void> initFirebase() async {
  if (!_supportsFirebaseCore()) {
    return;
  }

  await Firebase.initializeApp();

  if (!_supportsFirebaseMessaging()) {
    return;
  }

  FirebaseMessaging.instance.onTokenRefresh.listen((fcmToken) {
    if (kDebugMode) {
      debugPrint('FCM token refreshed 1: $fcmToken');
    }
  }).onError((err) {
    if (kDebugMode) {
      debugPrint('FCM token refresh error!: $err');
    }
  });

  final notificationSettings =
      await FirebaseMessaging.instance.requestPermission(
    provisional: true,
  );
  if (kDebugMode) {
    debugPrint(
      'Notification permission status: '
      '${notificationSettings.authorizationStatus}',
    );
  }

  if (Platform.isIOS || Platform.isMacOS) {
    final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
    if (apnsToken != null) {
      if (kDebugMode) {
        debugPrint('FCM APNS token acquired: $apnsToken');
      }
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (kDebugMode) {
        debugPrint('FCM token acquired 2: $fcmToken');
      }
    }
  } else if (Platform.isAndroid) {
    final fcmToken = await FirebaseMessaging.instance.getToken();
    if (kDebugMode) {
      debugPrint('FCM token acquired 3: $fcmToken');
    }
  }
}

bool _supportsFirebaseCore() {
  return Platform.isAndroid || Platform.isIOS || Platform.isMacOS;
}

bool _supportsFirebaseMessaging() {
  return Platform.isAndroid || Platform.isIOS || Platform.isMacOS;
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
