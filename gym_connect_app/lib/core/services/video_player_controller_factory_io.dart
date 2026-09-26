import 'dart:io';
import 'package:video_player/video_player.dart';

VideoPlayerController createPlatformVideoController(String pathOrUrl) {
  final clean = pathOrUrl.trim();
  if (clean.startsWith('http://') || clean.startsWith('https://')) {
    return VideoPlayerController.networkUrl(Uri.parse(clean));
  }
  return VideoPlayerController.file(File(clean));
}
