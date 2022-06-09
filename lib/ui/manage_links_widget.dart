import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';
import 'package:flutter_sodium/flutter_sodium.dart';
import 'package:photos/ente_theme_data.dart';
import 'package:photos/models/collection.dart';
import 'package:photos/services/collections_service.dart';
import 'package:photos/ui/common/dialogs.dart';
import 'package:photos/utils/crypto_util.dart';
import 'package:photos/utils/date_time_util.dart';
import 'package:photos/utils/dialog_util.dart';
import 'package:photos/utils/toast_util.dart';
import 'package:tuple/tuple.dart';

class ManageSharedLinkWidget extends StatefulWidget {
  final Collection collection;

  ManageSharedLinkWidget({Key key, this.collection}) : super(key: key);

  @override
  _ManageSharedLinkWidgetState createState() => _ManageSharedLinkWidgetState();
}

class _ManageSharedLinkWidgetState extends State<ManageSharedLinkWidget> {
  // index, title, milliseconds in future post which link should expire (when >0)
  final List<Tuple3<int, String, int>> _expiryOptions = [
    Tuple3(0, "Never", 0),
    Tuple3(1, "After 1 hour", Duration(hours: 1).inMicroseconds),
    Tuple3(2, "After 1 day", Duration(days: 1).inMicroseconds),
    Tuple3(3, "After 1 week", Duration(days: 7).inMicroseconds),
    // todo: make this time calculation perfect
    Tuple3(4, "After 1 month", Duration(days: 30).inMicroseconds),
    Tuple3(5, "After 1 year", Duration(days: 365).inMicroseconds),
    Tuple3(6, "Custom", -1),
  ];

  Tuple3<int, String, int> _selectedExpiry;
  int _selectedDeviceLimitIndex = 0;

  @override
  void initState() {
    _selectedExpiry = _expiryOptions.first;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).backgroundColor,
      appBar: AppBar(
        elevation: 0,
        title: Text(
          "Manage link",
        ),
      ),
      body: SingleChildScrollView(
        child: ListBody(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                children: [
                  Padding(padding: EdgeInsets.all(4)),
                  GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () async {
                      await showPicker();
                    },
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Link expiry"),
                            Padding(padding: EdgeInsets.all(4)),
                            _getLinkExpiryTimeWidget(),
                          ],
                        ),
                        Icon(Icons.navigate_next),
                      ],
                    ),
                  ),
                  Padding(padding: EdgeInsets.all(4)),
                  Divider(height: 4),
                  Padding(padding: EdgeInsets.all(4)),
                  GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () {
                      _showDeviceLimitPicker();
                    },
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Device limit"),
                            Padding(padding: EdgeInsets.all(4)),
                            Text(
                              widget.collection.publicURLs.first.deviceLimit
                                  .toString(),
                              style: TextStyle(
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        Icon(Icons.navigate_next),
                      ],
                    ),
                  ),
                  Padding(padding: EdgeInsets.all(4)),
                  Divider(height: 4),
                  Padding(padding: EdgeInsets.all(4)),
                  SizedBox(
                    height: 36,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Password lock"),
                        Switch.adaptive(
                          value: widget.collection.publicURLs?.first
                                  ?.passwordEnabled ??
                              false,
                          onChanged: (enablePassword) async {
                            if (enablePassword) {
                              var inputResult =
                                  await _displayLinkPasswordInput(context);
                              if (inputResult != null &&
                                  inputResult == 'ok' &&
                                  _textFieldController.text.trim().isNotEmpty) {
                                var propToUpdate = await _getEncryptedPassword(
                                    _textFieldController.text);
                                await _updateUrlSettings(context, propToUpdate);
                              }
                            } else {
                              await _updateUrlSettings(
                                  context, {'disablePassword': true});
                            }
                            setState(() {});
                          },
                        ),
                      ],
                    ),
                  ),
                  Padding(padding: EdgeInsets.all(4)),
                  Divider(height: 4),
                  Padding(padding: EdgeInsets.all(4)),
                  SizedBox(
                    height: 36,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("File download"),
                        Switch.adaptive(
                          value: widget.collection.publicURLs?.first
                                  ?.enableDownload ??
                              true,
                          onChanged: (value) async {
                            if (!value) {
                              final choice = await showChoiceDialog(
                                  context,
                                  'Disable downloads',
                                  'Are you sure that you want to disable the download button for files?',
                                  firstAction: 'No',
                                  secondAction: 'Yes',
                                  firstActionColor:
                                      Theme.of(context).colorScheme.greenText,
                                  secondActionColor: Theme.of(context)
                                      .colorScheme
                                      .inverseBackgroundColor);
                              if (choice != DialogUserChoice.secondChoice) {
                                return;
                              }
                            }
                            await _updateUrlSettings(
                                context, {'enableDownload': value});
                            if (!value) {
                              showErrorDialog(context, "Please note",
                                  "Viewers can still take screenshots or save a copy of your photos using external tools");
                            }
                            setState(() {});
                          },
                        ),
                      ],
                    ),
                  ),
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
      return Text(text, style: Theme.of(context).textTheme.subtitle1);
    }

    return showCupertinoModalPopup(
      context: context,
      builder: (context) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.cupertinoPickerTopColor,
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
                    child: Text(
                      'Cancel',
                      style: Theme.of(context).textTheme.subtitle1,
                    ),
                    onPressed: () {
                      Navigator.of(context).pop('cancel');
                    },
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 5.0,
                    ),
                  ),
                  CupertinoButton(
                    child: Text(
                      'Confirm',
                      style: Theme.of(context).textTheme.subtitle1,
                    ),
                    onPressed: () async {
                      int newValidTill = -1;
                      int expireAfterInMicroseconds = _selectedExpiry.item3;
                      // need to manually select time
                      if (expireAfterInMicroseconds < 0) {
                        var timeInMicrosecondsFromEpoch =
                            await _showDateTimePicker();
                        if (timeInMicrosecondsFromEpoch != null) {
                          newValidTill = timeInMicrosecondsFromEpoch;
                        }
                      } else if (expireAfterInMicroseconds == 0) {
                        // no expiry
                        newValidTill = 0;
                      } else {
                        newValidTill = DateTime.now().microsecondsSinceEpoch +
                            expireAfterInMicroseconds;
                      }
                      if (newValidTill >= 0) {
                        await _updateUrlSettings(
                            context, {'validTill': newValidTill});
                        setState(() {});
                      }
                      Navigator.of(context).pop('');
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
                backgroundColor:
                    Theme.of(context).backgroundColor.withOpacity(0.95),
                children:
                    _expiryOptions.map((e) => getOptionText(e.item2)).toList(),
                onSelectedItemChanged: (value) {
                  var firstWhere = _expiryOptions
                      .firstWhere((element) => element.item1 == value);
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
  Future<int> _showDateTimePicker() async {
    final dateResult = await DatePicker.showDatePicker(
      context,
      minTime: DateTime.now(),
      currentTime: DateTime.now(),
      locale: LocaleType.en,
      theme: Theme.of(context).colorScheme.dateTimePickertheme,
    );
    if (dateResult == null) {
      return null;
    }
    final dateWithTimeResult = await DatePicker.showTime12hPicker(
      context,
      showTitleActions: true,
      currentTime: dateResult,
      locale: LocaleType.en,
      theme: Theme.of(context).colorScheme.dateTimePickertheme,
    );
    if (dateWithTimeResult == null) {
      return null;
    } else {
      return dateWithTimeResult.microsecondsSinceEpoch;
    }
  }

  final TextEditingController _textFieldController = TextEditingController();

  Future<String> _displayLinkPasswordInput(BuildContext context) async {
    _textFieldController.clear();
    return showDialog<String>(
        context: context,
        builder: (context) {
          bool _passwordVisible = false;
          return StatefulBuilder(builder: (context, setState) {
            return AlertDialog(
              title: Text('Enter password'),
              content: TextFormField(
                autofillHints: const [AutofillHints.newPassword],
                decoration: InputDecoration(
                  hintText: "Password",
                  contentPadding: EdgeInsets.all(12),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _passwordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: Colors.white.withOpacity(0.5),
                      size: 20,
                    ),
                    onPressed: () {
                      _passwordVisible = !_passwordVisible;
                      setState(() {});
                    },
                  ),
                ),
                obscureText: !_passwordVisible,
                controller: _textFieldController,
                autofocus: true,
                autocorrect: false,
                keyboardType: TextInputType.visiblePassword,
                onChanged: (_) {
                  setState(() {});
                },
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('Cancel',
                      style: Theme.of(context).textTheme.subtitle2),
                  onPressed: () {
                    Navigator.pop(context, 'cancel');
                  },
                ),
                TextButton(
                  child:
                      Text('Ok', style: Theme.of(context).textTheme.subtitle2),
                  onPressed: () {
                    if (_textFieldController.text.trim().isEmpty) {
                      return;
                    }
                    Navigator.pop(context, 'ok');
                  },
                ),
              ],
            );
          });
        });
  }

  Future<Map<String, dynamic>> _getEncryptedPassword(String pass) async {
    assert(Sodium.cryptoPwhashAlgArgon2id13 == Sodium.cryptoPwhashAlgDefault,
        "mismatch in expected default pw hashing algo");
    int memLimit = Sodium.cryptoPwhashMemlimitInteractive;
    int opsLimit = Sodium.cryptoPwhashOpslimitInteractive;
    final kekSalt = CryptoUtil.getSaltToDeriveKey();
    final result = await CryptoUtil.deriveKey(
        utf8.encode(pass), kekSalt, memLimit, opsLimit);
    return {
      'passHash': Sodium.bin2base64(result),
      'nonce': Sodium.bin2base64(kekSalt),
      'memLimit': memLimit,
      'opsLimit': opsLimit,
    };
  }

  Future<void> _updateUrlSettings(
      BuildContext context, Map<String, dynamic> prop) async {
    final dialog = createProgressDialog(context, "Please wait...");
    await dialog.show();
    try {
      await CollectionsService.instance.updateShareUrl(widget.collection, prop);
      await dialog.hide();
      showToast("Album updated");
    } catch (e) {
      await dialog.hide();
      await showGenericErrorDialog(context);
    }
  }

  Text _getLinkExpiryTimeWidget() {
    int validTill = widget.collection.publicURLs?.first?.validTill ?? 0;
    if (validTill == 0) {
      return Text(
        'Never',
        style: TextStyle(
          color: Colors.grey,
        ),
      );
    }
    if (validTill < DateTime.now().microsecondsSinceEpoch) {
      return Text(
        'Expired',
        style: TextStyle(
          color: Colors.orange[300],
        ),
      );
    }
    return Text(
      getFormattedTime(DateTime.fromMicrosecondsSinceEpoch(validTill)),
      style: TextStyle(
        color: Colors.grey,
      ),
    );
  }

  Future<void> _showDeviceLimitPicker() async {
    List<Text> options = [];
    for (int i = 50; i > 0; i--) {
      options.add(
          Text(i.toString(), style: Theme.of(context).textTheme.subtitle1));
    }
    return showCupertinoModalPopup(
      context: context,
      builder: (context) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.cupertinoPickerTopColor,
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
                    child: Text(
                      'Cancel',
                      style: Theme.of(context).textTheme.subtitle1,
                    ),
                    onPressed: () {
                      Navigator.of(context).pop('cancel');
                    },
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 5.0,
                    ),
                  ),
                  CupertinoButton(
                    child: Text(
                      'Confirm',
                      style: Theme.of(context).textTheme.subtitle1,
                    ),
                    onPressed: () async {
                      await _updateUrlSettings(context, {
                        'deviceLimit': int.tryParse(
                            options[_selectedDeviceLimitIndex].data),
                      });
                      setState(() {});
                      Navigator.of(context).pop('');
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
                backgroundColor:
                    Theme.of(context).backgroundColor.withOpacity(0.95),
                children: options,
                onSelectedItemChanged: (value) {
                  _selectedDeviceLimitIndex = value;
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
}
