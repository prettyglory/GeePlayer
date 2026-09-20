import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gee_player/app/gee_player_app.dart';

void main() {
  runApp(const ProviderScope(child: GeePlayerApp()));
}
