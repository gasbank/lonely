import 'package:flutter/material.dart';
import 'package:lonely_flutter/database.dart';
import 'package:share_plus/share_plus.dart';

class SettingsWidget extends StatelessWidget {
  const SettingsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ListView(children: [
        OutlinedButton(
          onPressed: () async {
            Share.shareXFiles([XFile(await getDbPath())]);
          },
          child: const Text('매매 기록 내보내기'),
        )
      ]),
    );
  }
}
