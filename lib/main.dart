import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'database.dart';
import 'my_home_page.dart';

void main() async {
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lonely',
      theme: ThemeData(
        primarySwatch: Colors.grey,
      ),
      home: MyHomePage(
        database: LonelyDatabase(),
      ),
    );
  }

}
