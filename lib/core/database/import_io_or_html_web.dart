import 'dart:convert';
import 'dart:html' as html;

Future<void> shareBackupFile(String jsonContent, String fileName) async {
  final bytes = utf8.encode(jsonContent);
  final blob = html.Blob([bytes], 'application/json');
  final url = html.Url.createObjectUrlFromBlob(blob);
  
  html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..click();
    
  html.Url.revokeObjectUrl(url);
}
