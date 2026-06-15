import 'package:flutter/material.dart';

import 'receiver_page.dart';

/// Root widget for Ente Photos TV.
class PhotosTvApp extends StatelessWidget {
  const PhotosTvApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ente Photos TV',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: const ReceiverPage(),
    );
  }
}
