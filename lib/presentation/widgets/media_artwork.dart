import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gee_player/app/gee_colors.dart';
import 'package:gee_player/app/media_library_providers.dart';
import 'package:gee_player/domain/media/local_media.dart';

class MediaArtwork extends ConsumerStatefulWidget {
  const MediaArtwork({required this.media, this.size = 58, super.key});

  final LocalMedia media;
  final double size;

  @override
  ConsumerState<MediaArtwork> createState() => _MediaArtworkState();
}

class _MediaArtworkState extends ConsumerState<MediaArtwork> {
  late Future<Uint8List?> _artwork;

  @override
  void initState() {
    super.initState();
    _artwork = ref.read(localMediaRepositoryProvider).loadArtwork(widget.media);
  }

  @override
  void didUpdateWidget(covariant MediaArtwork oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.media.id != widget.media.id) {
      _artwork = ref
          .read(localMediaRepositoryProvider)
          .loadArtwork(widget.media);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(13),
      child: SizedBox.square(
        dimension: widget.size,
        child: FutureBuilder<Uint8List?>(
          future: _artwork,
          builder: (context, snapshot) {
            final bytes = snapshot.data;
            if (bytes == null || bytes.isEmpty) return _fallback();
            return Image.memory(
              bytes,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.low,
              errorBuilder: (context, error, stackTrace) => _fallback(),
            );
          },
        ),
      ),
    );
  }

  Widget _fallback() => ColoredBox(
    color: GeeColors.surfaceRaised,
    child: Icon(
      widget.media.kind == MediaKind.video
          ? Icons.movie_outlined
          : Icons.music_note_rounded,
      color: GeeColors.accentLight,
      size: widget.size * 0.5,
    ),
  );
}
