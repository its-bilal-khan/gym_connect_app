import 'package:video_player/video_player.dart';

VideoPlayerController createPlatformVideoController(String pathOrUrl) =>
    throw UnsupportedError('Cannot create VideoPlayerController without platform implementation');
