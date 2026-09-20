import 'package:flutter/material.dart';

enum AppDestination {
  home('Home', Icons.home_outlined, Icons.home_rounded),
  videos('Videos', Icons.movie_outlined, Icons.movie_rounded),
  music('Music', Icons.music_note_outlined, Icons.music_note_rounded),
  folders('Folders', Icons.folder_outlined, Icons.folder_rounded),
  favorites('Favorites', Icons.favorite_border_rounded, Icons.favorite_rounded),
  settings('Settings', Icons.settings_outlined, Icons.settings_rounded);

  const AppDestination(this.label, this.icon, this.selectedIcon);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}
