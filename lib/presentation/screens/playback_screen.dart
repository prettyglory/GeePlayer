import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gee_player/app/gee_colors.dart';
import 'package:gee_player/app/playback_controller.dart';
import 'package:gee_player/app/playback_providers.dart';
import 'package:gee_player/app/subtitle_providers.dart';
import 'package:gee_player/domain/media/local_media.dart';
import 'package:gee_player/presentation/widgets/media_artwork.dart';
import 'package:gee_player/presentation/widgets/media_actions_button.dart';
import 'package:media_kit_video/media_kit_video.dart';

class PlaybackScreen extends ConsumerStatefulWidget {
  const PlaybackScreen({this.queue, this.index = 0, super.key});

  final List<LocalMedia>? queue;
  final int index;

  @override
  ConsumerState<PlaybackScreen> createState() => _PlaybackScreenState();
}

class _PlaybackScreenState extends ConsumerState<PlaybackScreen> {
  late final PlaybackController _controller;
  double? _dragPosition;
  double _aspectRatio = 16 / 9;
  bool _fullscreen = false;

  void _showSubtitles() {
    final subtitles = ref.read(subtitleControllerProvider);
    final searchController = TextEditingController(
      text: _controller.current?.title ?? '',
    );
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => AnimatedBuilder(
        animation: subtitles,
        builder: (context, _) => SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.75,
            ),
            child: ListView(
              shrinkWrap: true,
              padding: EdgeInsets.fromLTRB(
                20,
                0,
                20,
                MediaQuery.viewInsetsOf(context).bottom + 24,
              ),
              children: [
                Text(
                  'Subtitles',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                if (subtitles.message != null) Text(subtitles.message!),
                if (subtitles.busy) ...[
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: subtitles.progress),
                ],
                ListTile(
                  leading: const Icon(Icons.closed_caption_off_rounded),
                  title: const Text('Off'),
                  onTap: subtitles.disable,
                ),
                if (subtitles.embedded.isNotEmpty) ...[
                  const Divider(),
                  const Text('In this video'),
                  for (final track in subtitles.embedded)
                    ListTile(
                      leading: const Icon(Icons.closed_caption_rounded),
                      title: Text(
                        track.title ?? track.language ?? 'Embedded subtitle',
                      ),
                      subtitle: track.language == null
                          ? null
                          : Text(track.language!),
                      onTap: () => subtitles.selectEmbedded(track),
                    ),
                ],
                if (subtitles.cached.isNotEmpty) ...[
                  const Divider(),
                  const Text('Saved on this device'),
                  for (final file in subtitles.cached)
                    ListTile(
                      leading: const Icon(Icons.download_done_rounded),
                      title: Text('${file.source} • ${file.language}'),
                      onTap: () => subtitles.selectCached(file),
                    ),
                ],
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.file_open_rounded),
                  title: const Text('Import local subtitle'),
                  subtitle: const Text('SRT, VTT, ASS, SSA or SUB'),
                  onTap: subtitles.importLocal,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: searchController,
                  textInputAction: TextInputAction.search,
                  onSubmitted: subtitles.search,
                  decoration: InputDecoration(
                    labelText: 'Search SubDL by title',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      tooltip: 'Search subtitles',
                      onPressed: subtitles.busy
                          ? null
                          : () => subtitles.search(searchController.text),
                      icon: const Icon(Icons.search_rounded),
                    ),
                  ),
                ),
                if (subtitles.online.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'SubDL results',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  for (final option in subtitles.online)
                    ListTile(
                      leading: const Icon(Icons.download_rounded),
                      title: Text(
                        option.releaseName.isEmpty
                            ? option.name
                            : option.releaseName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text('${option.language} • ${option.name}'),
                      onTap: subtitles.busy
                          ? null
                          : () => subtitles.download(option),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    ).whenComplete(searchController.dispose);
  }

  @override
  void initState() {
    super.initState();
    _controller = ref.read(playbackControllerProvider);
    if (widget.queue != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _controller.open(widget.queue!, widget.index);
        }
      });
    }
  }

  Future<void> _toggleFullscreen() async {
    final next = !_fullscreen;
    await SystemChrome.setEnabledSystemUIMode(
      next ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge,
    );
    await SystemChrome.setPreferredOrientations(
      next
          ? [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]
          : DeviceOrientation.values,
    );
    if (mounted) setState(() => _fullscreen = next);
  }

  @override
  void dispose() {
    if (_fullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    }
    if (_controller.current?.kind == MediaKind.video && _controller.playing) {
      _controller.player.pause();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(playbackControllerProvider);
    final subtitles = ref.watch(subtitleControllerProvider);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final media = controller.current;
        return Scaffold(
          appBar: _fullscreen
              ? null
              : AppBar(title: Text(media?.title ?? 'Now playing')),
          body: media == null
              ? const Center(child: Text('Choose a video or song to play.'))
              : _fullscreen && media.kind == MediaKind.video
              ? _fullscreenVideo(controller)
              : SafeArea(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                    children: [
                      if (media.kind == MediaKind.video)
                        _videoSurface(controller)
                      else
                        Center(child: MediaArtwork(media: media, size: 220)),
                      if (!_fullscreen) ...[
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                media.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall,
                                textAlign: TextAlign.center,
                              ),
                            ),
                            MediaActionsButton(media: media),
                          ],
                        ),
                        if (media.artist != null)
                          Text(
                            media.artist!,
                            style: const TextStyle(color: GeeColors.textMuted),
                            textAlign: TextAlign.center,
                          ),
                        if (controller.error != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            controller.error!,
                            style: const TextStyle(color: Colors.redAccent),
                          ),
                          TextButton.icon(
                            onPressed: controller.loading
                                ? null
                                : () => controller.open(
                                    controller.queue,
                                    controller.index,
                                  ),
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Try again'),
                          ),
                        ],
                        const SizedBox(height: 20),
                        _timeline(controller),
                        _controls(controller),
                        if (media.kind == MediaKind.video)
                          _videoOptions(controller),
                        if (media.kind == MediaKind.video)
                          AnimatedBuilder(
                            animation: subtitles,
                            builder: (context, _) => Text(
                              subtitles.message ?? '',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        if (controller.loading)
                          const Center(child: CircularProgressIndicator()),
                      ],
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _videoSurface(PlaybackController controller) {
    return Center(
      child: AspectRatio(
        aspectRatio: _aspectRatio,
        child: Video(
          controller: controller.videoController,
          controls: NoVideoControls,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _fullscreenVideo(PlaybackController controller) {
    return Stack(
      children: [
        Positioned.fill(
          child: Video(
            controller: controller.videoController,
            controls: NoVideoControls,
            fit: BoxFit.contain,
          ),
        ),
        SafeArea(
          child: Align(
            alignment: Alignment.topRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton.filledTonal(
                  tooltip: 'Subtitles',
                  onPressed: _showSubtitles,
                  icon: const Icon(Icons.closed_caption_rounded),
                ),
                IconButton.filledTonal(
                  tooltip: 'Exit fullscreen',
                  onPressed: _toggleFullscreen,
                  icon: const Icon(Icons.fullscreen_exit_rounded),
                ),
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: ColoredBox(
            color: const Color(0xCC111827),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [_timeline(controller), _controls(controller)],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _timeline(PlaybackController controller) {
    final total = controller.duration.inMilliseconds.toDouble();
    final elapsed = controller.position.inMilliseconds.toDouble();
    final sliderValue = (_dragPosition ?? elapsed).clamp(0.0, total);
    return Column(
      children: [
        Slider(
          value: sliderValue,
          min: 0,
          max: total > 0 ? total : 1,
          onChanged: total > 0 && !controller.loading
              ? (value) => setState(() => _dragPosition = value)
              : null,
          onChangeEnd: (value) {
            setState(() => _dragPosition = null);
            controller.seek(Duration(milliseconds: value.round()));
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_time(controller.position)),
              Text('-${_time(controller.duration - controller.position)}'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _controls(PlaybackController controller) {
    final audio = controller.current?.kind == MediaKind.audio;
    return Wrap(
      alignment: WrapAlignment.center,
      children: [
        if (audio)
          IconButton(
            tooltip: 'Previous track',
            onPressed: controller.loading ? null : controller.previous,
            icon: const Icon(Icons.skip_previous_rounded),
          ),
        IconButton(
          tooltip: 'Rewind 10 seconds',
          onPressed: controller.loading
              ? null
              : () => controller.skipBy(const Duration(seconds: -10)),
          icon: const Icon(Icons.replay_10_rounded),
        ),
        IconButton.filled(
          tooltip: controller.playing ? 'Pause' : 'Play',
          onPressed: controller.loading ? null : controller.togglePlayPause,
          iconSize: 38,
          icon: Icon(
            controller.playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
          ),
        ),
        IconButton(
          tooltip: 'Forward 10 seconds',
          onPressed: controller.loading
              ? null
              : () => controller.skipBy(const Duration(seconds: 10)),
          icon: const Icon(Icons.forward_10_rounded),
        ),
        if (audio)
          IconButton(
            tooltip: 'Next track',
            onPressed: controller.loading || !controller.hasNext
                ? null
                : controller.next,
            icon: const Icon(Icons.skip_next_rounded),
          ),
        IconButton(
          tooltip: 'Stop',
          onPressed: controller.loading ? null : controller.stop,
          icon: const Icon(Icons.stop_rounded),
        ),
      ],
    );
  }

  Widget _videoOptions(PlaybackController controller) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 18,
      children: [
        TextButton.icon(
          onPressed: _showSubtitles,
          icon: const Icon(Icons.closed_caption_rounded),
          label: const Text('Subtitles'),
        ),
        DropdownButton<double>(
          value: controller.player.state.rate,
          onChanged: (value) {
            if (value != null) controller.setRate(value);
          },
          items: const [0.5, 1.0, 1.25, 1.5, 2.0]
              .map(
                (rate) =>
                    DropdownMenuItem(value: rate, child: Text('${rate}x')),
              )
              .toList(),
        ),
        DropdownButton<double>(
          value: _aspectRatio,
          onChanged: (value) {
            if (value != null) setState(() => _aspectRatio = value);
          },
          items: const [
            DropdownMenuItem(value: 16 / 9, child: Text('16:9')),
            DropdownMenuItem(value: 4 / 3, child: Text('4:3')),
            DropdownMenuItem(value: 1.0, child: Text('1:1')),
          ],
        ),
        IconButton(
          tooltip: 'Fullscreen landscape',
          onPressed: _toggleFullscreen,
          icon: const Icon(Icons.fullscreen_rounded),
        ),
      ],
    );
  }

  String _time(Duration duration) {
    final safe = duration < Duration.zero ? Duration.zero : duration;
    final minutes = safe.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = safe.inSeconds.remainder(60).toString().padLeft(2, '0');
    return safe.inHours > 0
        ? '${safe.inHours}:$minutes:$seconds'
        : '$minutes:$seconds';
  }
}
