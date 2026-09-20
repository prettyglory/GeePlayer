import 'package:flutter/material.dart';

class GeePlayerApp extends StatelessWidget {
  const GeePlayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Gee Player',
      home: Scaffold(
        body: Center(child: Text('Gee Player')),
      ),
    );
  }
}
