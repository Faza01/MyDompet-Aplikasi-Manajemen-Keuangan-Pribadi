import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<void> shareBackupFile(String jsonContent, String fileName) async {
  final tempDir = await getTemporaryDirectory();
  final file = File('${tempDir.path}/$fileName');
  await file.writeAsString(jsonContent);
  await Share.shareXFiles([XFile(file.path)], subject: 'Backup Keuangan Offline');
}
