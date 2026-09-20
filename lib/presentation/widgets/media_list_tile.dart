import 'package:flutter/material.dart';
import 'package:gee_player/app/gee_colors.dart';
import 'package:gee_player/domain/media/local_media.dart';
import 'package:gee_player/presentation/widgets/media_artwork.dart';

class MediaListTile extends StatelessWidget {
  const MediaListTile({required this.media, this.onTap, super.key});

  final LocalMedia media;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final details = [
      if (media.artist != null && media.artist!.isNotEmpty) media.artist!,
      if (media.format.isNotEmpty) media.format,
      if (media.duration != null) _duration(media.duration!),
      if (media.sizeBytes != null) _size(media.sizeBytes!),
    ];

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: GeeColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: GeeColors.outline),
        ),
        child: Row(
          children: [
            MediaArtwork(media: media),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    media.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    details.join('  •  '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: GeeColors.textMuted),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    media.folderPath,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: GeeColors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _duration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return hours > 0
        ? '$hours:$minutes:$seconds'
        : '${duration.inMinutes}:$seconds';
  }

  static String _size(int bytes) {
    if (bytes >= 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }
}
