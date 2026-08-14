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
  static Future<Uint8List?> pickImageFromCamera() async => null;
  static Future<Uint8List?> pickVideoFromCamera() async => null;
  static Future<List<WebPickedFile>> pickMultiImagesFromGallery() async => [];
  static Future<List<WebPickedFile>> pickMultiVideosFromGallery() async => [];
}

