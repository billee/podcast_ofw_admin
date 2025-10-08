// web_file_picker.dart
import 'dart:html' as html;
import 'dart:async';
import 'dart:typed_data';

class WebFilePicker {
  static Future<WebFile?> pickFile({List<String>? acceptedTypes}) async {
    final completer = Completer<WebFile?>();

    final input = html.FileUploadInputElement()
      ..accept = acceptedTypes?.join(',') ?? 'audio/*'
      ..multiple = false;

    input.onChange.listen((e) {
      final files = input.files;
      if (files != null && files.isNotEmpty) {
        final file = files[0];
        final reader = html.FileReader();

        reader.onLoadEnd.listen((e) {
          final bytes = reader.result as Uint8List?;
          if (bytes != null) {
            completer.complete(WebFile(
              name: file.name,
              size: file.size,
              bytes: bytes,
              type: file.type,
            ));
          } else {
            completer.complete(null);
          }
        });

        reader.onError.listen((e) {
          completer.completeError(reader.error!);
        });

        reader.readAsArrayBuffer(file);
      } else {
        completer.complete(null);
      }
    });

    input.click();
    return completer.future;
  }
}

class WebFile {
  final String name;
  final int size;
  final Uint8List bytes;
  final String type;

  WebFile({
    required this.name,
    required this.size,
    required this.bytes,
    required this.type,
  });
}
