import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'database.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import 'lonely_model.dart';

class SettingsWidget extends StatelessWidget {
  const SettingsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Consumer<LonelyModel>(
        builder: (context, model, child) {
          return ListView(children: [
            OutlinedButton(
              onPressed: () async {
                Share.shareXFiles([XFile(await getDbPath())]);
              },
              child: const Text('매매 기록 내보내기'),
            ),
            OutlinedButton(
              onPressed: () async {
                final result = await FilePicker.platform.pickFiles();

                if (result != null) {
                  final file = File(result.files.single.path!);
                  if (kDebugMode) {
                    print(file.path);
                  }
                  await model.closeAndReplaceDatabase(file);
                } else {
                  // User canceled the picker
                }
              },
              child: const Text('매매 기록 불러오기'),
            ),
          ]);
        },
      ),
    );
  }
}
