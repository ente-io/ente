import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/ui/common/widget_theme.dart';
import 'package:photos/ui/settings/settings_text_item.dart';
import 'package:photos/utils/toast_util.dart';
import 'package:tuple/tuple.dart';

class ManageSharedLinkWidget extends StatefulWidget {
  ManageSharedLinkWidget({Key key}) : super(key: key);

  @override
  _ManageSharedLinkWidgetState createState() => _ManageSharedLinkWidgetState();
}

class _ManageSharedLinkWidgetState extends State<ManageSharedLinkWidget> {
  // index, title, milliseconds in future post which link should expire (when >0)
  List<Tuple3<int, String, int>> expiryOptions = [
    Tuple3(0, "never", 0),
    Tuple3(1, "after 1 hour", Duration(days: 1).inMicroseconds),
    Tuple3(2, "after 1 day", Duration(days: 1).inMicroseconds),
    Tuple3(3, "after 1 week", Duration(days: 1).inMicroseconds),
    // todo: make this time calculation perfect
    Tuple3(4, "after 1 month", Duration(days: 30).inMicroseconds),
    Tuple3(5, "after 1 year", Duration(days: 365).inMicroseconds),
    Tuple3(6, "other", -1),
  ];

  Tuple3<int, String, int> _selectedExpiry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "manage link",
          style: TextStyle(
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: ListBody(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: Column(
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () async {
                      showPicker();
                    },
                    child: SettingsTextItem(
                        text: "never expires", icon: Icons.navigate_next),
                  ),
                  Platform.isIOS
                      ? Padding(padding: EdgeInsets.all(2))
                      : Padding(padding: EdgeInsets.all(0)),
                  Divider(height: 4),
                  Platform.isIOS
                      ? Padding(padding: EdgeInsets.all(2))
                      : Padding(padding: EdgeInsets.all(4)),
                  SizedBox(
                    height: 36,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("enable password"),
                        Switch.adaptive(
                          value: Configuration.instance
                              .shouldBackupOverMobileData(),
                          onChanged: (value) async {
                            Configuration.instance
                                .setBackupOverMobileData(value);
                            setState(() {});
                          },
                        ),
                      ],
                    ),
                  ),
                  Platform.isIOS
                      ? Padding(padding: EdgeInsets.all(2))
                      : Padding(padding: EdgeInsets.all(4)),
                  Divider(height: 4),
                  Platform.isIOS
                      ? Padding(padding: EdgeInsets.all(2))
                      : Padding(padding: EdgeInsets.all(4)),
                  SizedBox(
                    height: 36,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("hide download option"),
                        Switch(
                          value: Configuration.instance.shouldBackupVideos(),
                          onChanged: (value) async {
                            Configuration.instance.setShouldBackupVideos(value);
                            setState(() {});
                          },
                        ),
                      ],
                    ),
                  ),
                  Platform.isIOS
                      ? Padding(padding: EdgeInsets.all(4))
                      : Padding(padding: EdgeInsets.all(2)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> showPicker() async {
    Widget getOptionText(String text) {
      return Text(text, style: TextStyle(color: Colors.white));
    }

    showCupertinoModalPopup(
      context: context,
      builder: (context) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            Container(
              decoration: BoxDecoration(
                color: Colors.black,
                border: Border(
                  bottom: BorderSide(
                    color: Color(0xff999999),
                    width: 0.0,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  CupertinoButton(
                    child: Text('Cancel',
                        style: TextStyle(
                          color: Colors.white,
                        )),
                    onPressed: () {
                      print("wtf");
                      // Navigator.of(context).pop('');
                    },
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 5.0,
                    ),
                  ),
                  CupertinoButton(
                    child: Text('Confirm',
                        style: TextStyle(
                          color: Colors.white,
                        )),
                    onPressed: () async {
                      int expiry = -1;
                      if (_selectedExpiry.item3 < 0) {
                        var showDateTimePicker = _showDateTimePicker(null);
                      } else {
                        showToast('hello');
                      }
                      // Navigator.of(context).pop('');
                    },
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 2.0,
                    ),
                  )
                ],
              ),
            ),
            Container(
              height: 220.0,
              color: Color(0xfff7f7f7),
              child: CupertinoPicker(
                backgroundColor: Colors.black,
                children:
                    expiryOptions.map((e) => getOptionText(e.item2)).toList(),
                onSelectedItemChanged: (value) {
                  var firstWhere = expiryOptions
                      .firstWhere((element) => element.item1 == value);
                  Logger('t').info('whats happening $firstWhere');
                  setState(() {
                    _selectedExpiry = firstWhere;
                  });
                },
                magnification: 1.3,
                useMagnifier: true,
                itemExtent: 25,
                diameterRatio: 1,
              ),
            )
          ],
        );
      },
    );
  }

  // _showDateTimePicker return null if user doesn't select date-time
  Future<int> _showDateTimePicker(File file) async {
    final dateResult = await DatePicker.showDatePicker(
      context,
      minTime: DateTime.now(),
      currentTime: DateTime.now(),
      locale: LocaleType.en,
      theme: kDatePickerTheme,
    );
    if (dateResult == null) {
      return null;
    }
    final dateWithTimeResult = await DatePicker.showTime12hPicker(
      context,
      showTitleActions: true,
      currentTime: dateResult,
      locale: LocaleType.en,
      theme: kDatePickerTheme,
    );
    if (dateWithTimeResult == null) {
      return null;
    } else {
      return dateWithTimeResult.microsecondsSinceEpoch;
    }
  }
}
