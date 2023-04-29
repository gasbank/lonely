import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'lonely_model.dart';
import 'my_home_page.dart';

void main() {
  if (kIsWeb) {
    // 웹에서는 sqflite 못쓴다.
    throw Exception('Web is not supported');
  }

  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ReorderableListView 사용하려니까,
    // Provider()가 MaterialApp()을 감싸야 된다고 카더라...
    // https://github.com/flutter/flutter/issues/88570
    // 그래서 최상위까지 기어올라왔다...
    return ChangeNotifierProvider(
      create: (context) => LonelyModel(),
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
