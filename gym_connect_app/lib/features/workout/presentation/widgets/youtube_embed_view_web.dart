// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
// ignore: undefined_prefixed_name
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

Widget buildPlatformYoutubeEmbed({
  required String embedUrl,
  required String videoId,
}) {
  final viewType = 'yt-embed-v3-$videoId-${embedUrl.hashCode.abs()}';

  // ignore: undefined_prefixed_name
  ui_web.platformViewRegistry.registerViewFactory(
    viewType,
    (int viewId) {
      final iframe = html.IFrameElement()
        ..src = embedUrl
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.pointerEvents = 'none' // Permanently blocks mouse hover/clicks from reaching YouTube DOM
        ..style.userSelect = 'none'
        ..style.touchAction = 'none'
        ..tabIndex = -1
        ..allow =
            'accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share'
        ..allowFullscreen = false;

      final container = html.DivElement()
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.pointerEvents = 'none'
        ..style.overflow = 'hidden'
        ..style.position = 'relative'
        ..append(iframe);

      return container;
    },
  );

  return HtmlElementView(viewType: viewType);
}

bool get isPlatformWeb => true;
