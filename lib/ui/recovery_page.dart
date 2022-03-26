import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/ui/common_elements.dart';
import 'package:photos/ui/password_entry_page.dart';
import 'package:photos/utils/dialog_util.dart';
import 'package:photos/utils/toast_util.dart';
import 'package:dotted_border/dotted_border.dart';

class RecoveryPage extends StatefulWidget {
  final bool showAppBar;
  const RecoveryPage({Key key, @required this.showAppBar}) : super(key: key);

  @override
  _RecoveryPageState createState() => _RecoveryPageState();
}

class _RecoveryPageState extends State<RecoveryPage> {
  final _recoveryKey = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(
              title: Text(""),
            )
          : null,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          // mainAxisAlignment: MainAxisAlignment.center,

          mainAxisSize: MainAxisSize.max,
          children: [
            Text("Recovery Key", style: Theme.of(context).textTheme.headline4),
            Padding(padding: EdgeInsets.all(12)),
            Text(
              "If you forget your password, the only way you can recover your data is with this key.",
              style: Theme.of(context).textTheme.subtitle1,
            ),
            Padding(padding: EdgeInsets.only(top: 24)),
            DottedBorder(
              color: Color.fromRGBO(17, 127, 56, 1), //color of dotted/dash line
              strokeWidth: 1, //thickness of dash/dots
              dashPattern: const [6, 6],
              radius: Radius.circular(8),
              //dash patterns, 10 is dash width, 6 is space width
              child: SizedBox(
                //inner container
                height: 200, //height of inner container
                width:
                    double.infinity, //width to 100% match to parent container.
                // ignore: prefer_const_literals_to_create_immutables
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Color.fromRGBO(49, 155, 86, .2),
                        ),
                        borderRadius: BorderRadius.all(
                          Radius.circular(12),
                        ),
                        color: Color.fromRGBO(49, 155, 86, .2),
                      ),
                      // color: Color.fromRGBO(49, 155, 86, .2),
                      height: 120,
                      width: double.infinity,
                      child: const Text('1'),
                    ),
                    SizedBox(
                      height: 80,
                      width: double.infinity,
                      child: Padding(
                          child: Text(
                            "we don’t store this key, please save this in a safe place",
                            style: Theme.of(context).textTheme.bodyText1,
                          ),
                          padding: EdgeInsets.all(20)),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
