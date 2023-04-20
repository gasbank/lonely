import 'package:flutter/material.dart';

import 'database.dart';
import 'my_home_page.dart';

void main() async {
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
        title: '고독한 투자자',
        database: LonelyDatabase(),
      ),
    );
  }
}
