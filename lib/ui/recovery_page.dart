import 'package:flutter/material.dart';

class RecoveryPage extends StatelessWidget {
  const RecoveryPage({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "recover account",
          style: TextStyle(
            fontSize: 18,
          ),
        ),
      ),
      body: Column(
        children: [
          Text("please enter your recovery key to recover your data"),
        ],
      ),
    );
  }
}
