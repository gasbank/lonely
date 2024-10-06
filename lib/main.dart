import 'dart:io';

import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lonely/model/package_model.dart';
import 'package:lonely/model/price_model.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'model/lonely_model.dart';
import 'my_home_page.dart';

void main() {
  if (kIsWeb) {
    // 웹에서는 sqflite 못쓴다.
    throw Exception('Web is not supported');
  }

  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
  }

  dataTableShowLogs = false;

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
