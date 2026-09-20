import 'package:flutter/services.dart';
import 'package:gee_player/domain/media/local_media.dart';

class PlaybackSourceLease {
  const PlaybackSourceLease(this.uri, this.close);

  final String uri;
  final Future<void> Function() close;
}

class PlaybackSourceResolver {
  const PlaybackSourceResolver({
    this.channel = const MethodChannel('com.gee.player/media_library'),
  });

  final MethodChannel channel;

  Future<PlaybackSourceLease> resolve(LocalMedia media) async {
    final playbackUri = await channel.invokeMethod<String>('openPlayback', {
      'uri': media.uri,
    });
    if (playbackUri == null || !playbackUri.startsWith('fd://')) {
      throw const FormatException('Android did not return a playable file.');
    }
    return PlaybackSourceLease(
      playbackUri,
      () => channel.invokeMethod<void>('closePlayback'),
    );
  }
}
