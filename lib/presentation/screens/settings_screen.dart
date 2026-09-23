import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gee_player/app/application_settings_providers.dart';
import 'package:gee_player/data/settings/application_preferences.dart';
import 'package:gee_player/presentation/screens/subtitle_settings_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Text(
                'Settings',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            const TabBar(
              tabs: [
                Tab(text: 'General'),
                Tab(text: 'Subtitles'),
              ],
            ),
            const Expanded(
              child: TabBarView(
                children: [
                  _GeneralSettingsPanel(),
                  SubtitleSettingsScreen(embedded: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GeneralSettingsPanel extends ConsumerStatefulWidget {
  const _GeneralSettingsPanel();

  @override
  ConsumerState<_GeneralSettingsPanel> createState() =>
      _GeneralSettingsPanelState();
}

class _GeneralSettingsPanelState extends ConsumerState<_GeneralSettingsPanel> {
  bool _saving = false;

  Future<void> _save(ApplicationSettings settings) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(applicationSettingsProvider.notifier)
          .saveSettings(settings);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save settings.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _reset() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await ref.read(applicationSettingsProvider.notifier).reset();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('General settings reset.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not reset settings.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(applicationSettingsProvider);
    return settings.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Could not load settings on this device.'),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => ref.invalidate(applicationSettingsProvider),
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      ),
      data: (value) => ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Appearance', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          DropdownButtonFormField<AccentPreference>(
            key: ValueKey(value.accent),
            initialValue: value.accent,
            decoration: const InputDecoration(
              labelText: 'Accent color',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(
                value: AccentPreference.electricBlue,
                child: Text('Electric blue'),
              ),
              DropdownMenuItem(
                value: AccentPreference.cyan,
                child: Text('Cyan'),
              ),
              DropdownMenuItem(
                value: AccentPreference.violet,
                child: Text('Violet'),
              ),
            ],
            onChanged: _saving
                ? null
                : (accent) {
                    if (accent != null) {
                      _save(value.copyWith(accent: accent));
                    }
                  },
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Pure black theme'),
            subtitle: const Text('Use black backgrounds on OLED displays.'),
            value: value.pureBlackTheme,
            onChanged: _saving
                ? null
                : (enabled) => _save(value.copyWith(pureBlackTheme: enabled)),
          ),
          const SizedBox(height: 20),
          Text('Playback', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          DropdownButtonFormField<double>(
            key: ValueKey(value.defaultPlaybackSpeed),
            initialValue: value.defaultPlaybackSpeed,
            decoration: const InputDecoration(
              labelText: 'Default playback speed',
              border: OutlineInputBorder(),
            ),
            items: [
              for (final speed in applicationPlaybackSpeeds)
                DropdownMenuItem(value: speed, child: Text('${speed}x')),
            ],
            onChanged: _saving
                ? null
                : (speed) {
                    if (speed != null) {
                      _save(value.copyWith(defaultPlaybackSpeed: speed));
                    }
                  },
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Resume playback'),
            subtitle: const Text('Continue media from its saved position.'),
            value: value.resumePlayback,
            onChanged: _saving
                ? null
                : (enabled) => _save(value.copyWith(resumePlayback: enabled)),
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Background audio'),
            subtitle: const Text('Keep music playing when the app is hidden.'),
            value: value.backgroundAudio,
            onChanged: _saving
                ? null
                : (enabled) => _save(value.copyWith(backgroundAudio: enabled)),
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Video gesture controls'),
            subtitle: const Text(
              'Enable double-tap seeking and brightness or volume swipes.',
            ),
            value: value.gestureControls,
            onChanged: _saving
                ? null
                : (enabled) => _save(value.copyWith(gestureControls: enabled)),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: _saving ? null : _reset,
              icon: const Icon(Icons.restart_alt_rounded),
              label: const Text('Reset general settings'),
            ),
          ),
        ],
      ),
    );
  }
}
