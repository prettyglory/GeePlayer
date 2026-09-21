import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gee_player/app/gee_colors.dart';
import 'package:gee_player/app/subtitle_providers.dart';
import 'package:gee_player/data/subtitles/subtitle_preferences.dart';

class SubtitleSettingsScreen extends ConsumerStatefulWidget {
  const SubtitleSettingsScreen({super.key});

  @override
  ConsumerState<SubtitleSettingsScreen> createState() =>
      _SubtitleSettingsScreenState();
}

class _SubtitleSettingsScreenState
    extends ConsumerState<SubtitleSettingsScreen> {
  final _keyController = TextEditingController();
  bool _loading = true;
  bool _autoSearch = false;
  String _language = 'SW';
  SubtitleAppearance _appearance = const SubtitleAppearance();
  String? _status;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = ref.read(subtitlePreferencesProvider);
      final key = await prefs.apiKey();
      final auto = await prefs.autoSearch();
      final language = await prefs.preferredLanguage();
      final appearance = await prefs.appearance();
      if (!mounted) return;
      _keyController.text = key ?? '';
      setState(() {
        _autoSearch = auto;
        _language = language;
        _appearance = appearance;
      });
    } catch (_) {
      if (mounted) {
        setState(
          () => _status = 'Could not read subtitle settings on this device.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveKey() async {
    setState(() => _status = 'Checking SubDL…');
    try {
      await ref
          .read(subtitlePreferencesProvider)
          .setApiKey(_keyController.text);
      final status = await ref
          .read(subtitleProvider)
          .accountStatus(_keyController.text);
      if (mounted) setState(() => _status = status);
    } catch (_) {
      if (mounted) setState(() => _status = 'Could not save the API key.');
    }
  }

  Future<void> _updateAppearance(SubtitleAppearance appearance) async {
    setState(() => _appearance = appearance);
    await ref
        .read(subtitleAppearanceProvider.notifier)
        .saveAppearance(appearance);
  }

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Subtitles', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          const Text(
            'Embedded and imported subtitles work offline. Add your own SubDL key to search online.',
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _keyController,
            obscureText: true,
            autocorrect: false,
            enableSuggestions: false,
            decoration: const InputDecoration(
              labelText: 'SubDL API key',
              border: OutlineInputBorder(),
              helperText: 'Stored in Android secure storage',
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: _loading ? null : _saveKey,
              child: const Text('Save key'),
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Search automatically'),
            subtitle: const Text(
              'Search when a video has no embedded or cached subtitle.',
            ),
            value: _autoSearch,
            onChanged: _loading
                ? null
                : (value) async {
                    await ref
                        .read(subtitlePreferencesProvider)
                        .setAutoSearch(value);
                    if (mounted) setState(() => _autoSearch = value);
                  },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _language,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Preferred subtitle language',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(
                value: 'SW',
                child: Text(
                  'Kiswahili → English',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              DropdownMenuItem(value: 'EN', child: Text('English')),
            ],
            onChanged: _loading
                ? null
                : (value) async {
                    if (value == null) return;
                    await ref
                        .read(subtitlePreferencesProvider)
                        .setPreferredLanguage(value);
                    if (mounted) setState(() => _language = value);
                  },
          ),
          const SizedBox(height: 28),
          Text(
            'Subtitle appearance',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text('Text size: ${_appearance.fontSize.round()}'),
          Slider(
            value: _appearance.fontSize.clamp(20, 48),
            min: 20,
            max: 48,
            divisions: 14,
            label: _appearance.fontSize.round().toString(),
            onChanged: _loading
                ? null
                : (value) =>
                      _updateAppearance(_appearance.copyWith(fontSize: value)),
          ),
          DropdownButtonFormField<int>(
            initialValue: _appearance.textColor,
            decoration: const InputDecoration(
              labelText: 'Text color',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 0xFFFFFFFF, child: Text('White')),
              DropdownMenuItem(value: 0xFFFFEB3B, child: Text('Yellow')),
              DropdownMenuItem(value: 0xFF80DEEA, child: Text('Cyan')),
            ],
            onChanged: _loading
                ? null
                : (value) {
                    if (value != null) {
                      _updateAppearance(_appearance.copyWith(textColor: value));
                    }
                  },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            initialValue: _appearance.backgroundColor,
            decoration: const InputDecoration(
              labelText: 'Background',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 0x00000000, child: Text('Transparent')),
              DropdownMenuItem(value: 0x88000000, child: Text('Soft black')),
              DropdownMenuItem(value: 0xAA000000, child: Text('Black')),
            ],
            onChanged: _loading
                ? null
                : (value) {
                    if (value != null) {
                      _updateAppearance(
                        _appearance.copyWith(backgroundColor: value),
                      );
                    }
                  },
          ),
          const SizedBox(height: 12),
          Text('Bottom position: ${_appearance.bottomPadding.round()} px'),
          Slider(
            value: _appearance.bottomPadding.clamp(8, 160),
            min: 8,
            max: 160,
            divisions: 19,
            onChanged: _loading
                ? null
                : (value) => _updateAppearance(
                    _appearance.copyWith(bottomPadding: value),
                  ),
          ),
          Text(
            'Subtitle delay: '
            '${(_appearance.delayMilliseconds / 1000).toStringAsFixed(1)} s',
          ),
          Slider(
            value: _appearance.delayMilliseconds.toDouble().clamp(-5000, 5000),
            min: -5000,
            max: 5000,
            divisions: 20,
            label:
                '${(_appearance.delayMilliseconds / 1000).toStringAsFixed(1)} s',
            onChanged: _loading
                ? null
                : (value) => _updateAppearance(
                    _appearance.copyWith(delayMilliseconds: value.round()),
                  ),
          ),
          if (_status != null) ...[
            const SizedBox(height: 16),
            Text(_status!, style: const TextStyle(color: GeeColors.textMuted)),
          ],
        ],
      ),
    );
  }
}
