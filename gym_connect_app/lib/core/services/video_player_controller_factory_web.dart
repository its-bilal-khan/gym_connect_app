import 'package:video_player/video_player.dart';

VideoPlayerController createPlatformVideoController(String pathOrUrl) {
  return VideoPlayerController.networkUrl(Uri.parse(pathOrUrl.trim()));
}
