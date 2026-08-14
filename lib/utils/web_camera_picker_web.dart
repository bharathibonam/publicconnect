import 'dart:html' as html;
import 'dart:async';
import 'dart:typed_data';

class WebPickedFile {
  final Uint8List bytes;
  final bool isVideo;
  final String name;

  WebPickedFile({
    required this.bytes,
    required this.isVideo,
    required this.name,
  });
}

class CameraHelper {
  static Future<Uint8List?> pickImageFromCamera() async {
    final list = await pickFiles(accept: 'image/*', capture: 'environment', multiple: false);
    return list.isNotEmpty ? list.first.bytes : null;
  }

  static Future<Uint8List?> pickVideoFromCamera() async {
    final list = await pickFiles(accept: 'video/*', capture: 'environment', multiple: false);
    return list.isNotEmpty ? list.first.bytes : null;
  }

  static Future<List<WebPickedFile>> pickMultiImagesFromGallery() async {
    return await pickFiles(accept: 'image/*', multiple: true);
  }

  static Future<List<WebPickedFile>> pickMultiVideosFromGallery() async {
    return await pickFiles(accept: 'video/*', multiple: true);
  }

  static Future<List<WebPickedFile>> pickFiles({
    required String accept,
    String? capture,
    bool multiple = false,
  }) async {
    final completer = Completer<List<WebPickedFile>>();
    final input = html.FileUploadInputElement();
    input.accept = accept;
    if (capture != null) {
      input.setAttribute('capture', capture);
    }
    input.multiple = multiple;

    input.onChange.listen((event) async {
      if (input.files != null && input.files!.isNotEmpty) {
        final List<WebPickedFile> results = [];
        for (var i = 0; i < input.files!.length; i++) {
          final file = input.files![i];
          final reader = html.FileReader();
          final readCompleter = Completer<Uint8List?>();
          reader.readAsArrayBuffer(file);
          reader.onLoadEnd.listen((e) {
            readCompleter.complete(reader.result as Uint8List?);
          });
          reader.onError.listen((e) {
            readCompleter.complete(null);
          });

          final bytes = await readCompleter.future;
          if (bytes != null) {
            final isVideo = file.type.startsWith('video/') ||
                file.name.toLowerCase().endsWith('.mp4') ||
                file.name.toLowerCase().endsWith('.mov') ||
                file.name.toLowerCase().endsWith('.avi') ||
                file.name.toLowerCase().endsWith('.mkv') ||
                file.name.toLowerCase().endsWith('.webm');
            results.add(WebPickedFile(bytes: bytes, isVideo: isVideo, name: file.name));
          }
        }
        completer.complete(results);
      } else {
        completer.complete([]);
      }
    });

    input.onError.listen((e) {
      completer.complete([]);
    });

    input.click();
    return completer.future;
  }
}

