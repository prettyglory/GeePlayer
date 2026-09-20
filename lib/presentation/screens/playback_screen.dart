import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gee_player/app/gee_colors.dart';
import 'package:gee_player/app/playback_controller.dart';
import 'package:gee_player/app/playback_providers.dart';
import 'package:gee_player/domain/media/local_media.dart';
import 'package:gee_player/presentation/widgets/media_artwork.dart';
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
                        Text(
                          media.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.headlineSmall,
                          textAlign: TextAlign.center,
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
            child: IconButton.filledTonal(
              tooltip: 'Exit fullscreen',
              onPressed: _toggleFullscreen,
              icon: const Icon(Icons.fullscreen_exit_rounded),
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
