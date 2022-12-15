// @dart=2.9

import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';
import 'package:flutter_sodium/flutter_sodium.dart';
import 'package:photos/ente_theme_data.dart';
import 'package:photos/models/collection.dart';
import 'package:photos/services/collections_service.dart';
import 'package:photos/theme/colors.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/actions/collection/collection_sharing_actions.dart';
import 'package:photos/ui/common/dialogs.dart';
import 'package:photos/ui/components/captioned_text_widget.dart';
import 'package:photos/ui/components/divider_widget.dart';
import 'package:photos/ui/components/menu_item_widget.dart';
import 'package:photos/ui/components/menu_section_description_widget.dart';
import 'package:photos/utils/crypto_util.dart';
import 'package:photos/utils/date_time_util.dart';
import 'package:photos/utils/dialog_util.dart';
import 'package:photos/utils/toast_util.dart';
import 'package:tuple/tuple.dart';

class ManageSharedLinkWidget extends StatefulWidget {
  final Collection collection;

  const ManageSharedLinkWidget({Key key, this.collection}) : super(key: key);

  @override
  State<ManageSharedLinkWidget> createState() => _ManageSharedLinkWidgetState();
}

class _ManageSharedLinkWidgetState extends State<ManageSharedLinkWidget> {
  // index, title, milliseconds in future post which link should expire (when >0)
  final List<Tuple3<int, String, int>> _expiryOptions = [
    const Tuple3(0, "Never", 0),
    Tuple3(1, "After 1 hour", const Duration(hours: 1).inMicroseconds),
    Tuple3(2, "After 1 day", const Duration(days: 1).inMicroseconds),
    Tuple3(3, "After 1 week", const Duration(days: 7).inMicroseconds),
    // todo: make this time calculation perfect
    Tuple3(4, "After 1 month", const Duration(days: 30).inMicroseconds),
    Tuple3(5, "After 1 year", const Duration(days: 365).inMicroseconds),
    const Tuple3(6, "Custom", -1),
  ];

  Tuple3<int, String, int> _selectedExpiry;
  int _selectedDeviceLimitIndex = 0;
  final CollectionActions sharingActions =
      CollectionActions(CollectionsService.instance);

  @override
  void initState() {
    _selectedExpiry = _expiryOptions.first;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final enteColorScheme = getEnteColorScheme(context);
    final PublicURL url = widget.collection?.publicURLs?.firstOrNull;
    return Scaffold(
      backgroundColor: Theme.of(context).backgroundColor,
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          "Manage link",
        ),
      ),
      body: SingleChildScrollView(
        child: ListBody(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MenuItemWidget(
                    captionedTextWidget: const CaptionedTextWidget(
                      title: "Allow adding photos",
                    ),
                    alignCaptionedTextToLeft: true,
                    menuItemColor: getEnteColorScheme(context).fillFaint,
                    pressedColor: getEnteColorScheme(context).fillFaint,
                    trailingWidget: Switch.adaptive(
                      value: widget.collection.publicURLs?.firstOrNull
                              ?.enableCollect ??
                          false,
                      onChanged: (value) async {
                        await _updateUrlSettings(
                          context,
                          {'enableCollect': value},
                        );

                        setState(() {});
                      },
                    ),
                  ),
                  const MenuSectionDescriptionWidget(
                    content:
                        "Allow people with the link to also add photos to the shared "
                        "album.",
                  ),
                  const SizedBox(height: 24),
                  MenuItemWidget(
                    alignCaptionedTextToLeft: true,
                    captionedTextWidget: CaptionedTextWidget(
                      title: "Link expiry",
                      subTitle: (url.hasExpiry
                          ? (url.isExpired ? "Expired" : "Enabled")
                          : "Never"),
                      subTitleColor: url.isExpired ? warning500 : null,
                    ),
                    trailingIcon: Icons.chevron_right,
                    menuItemColor: enteColorScheme.fillFaint,
                    onTap: () async {
                      await showPicker();
                    },
                  ),
                  url.hasExpiry
                      ? MenuSectionDescriptionWidget(
                          content: url.isExpired
                              ? "This link has expired. Please select a new expiry time or disable link expiry."
                              : 'Link will expire on '
                                  '${getFormattedTime(DateTime.fromMicrosecondsSinceEpoch(url.validTill))}',
                        )
                      : const SizedBox.shrink(),
                  const Padding(padding: EdgeInsets.only(top: 24)),
                  MenuItemWidget(
                    captionedTextWidget: CaptionedTextWidget(
                      title: "Device limit",
                      subTitle: widget.collection.publicURLs.first.deviceLimit
                          .toString(),
                    ),
                    trailingIcon: Icons.chevron_right,
                    menuItemColor: enteColorScheme.fillFaint,
                    alignCaptionedTextToLeft: true,
                    isBottomBorderRadiusRemoved: true,
                    onTap: () async {
                      await _showDeviceLimitPicker();
                    },
                  ),
                  DividerWidget(
                    dividerType: DividerType.menu,
                    bgColor: getEnteColorScheme(context).blurStrokeFaint,
                  ),
                  MenuItemWidget(
                    captionedTextWidget: const CaptionedTextWidget(
                      title: "Allow downloads",
                    ),
                    alignCaptionedTextToLeft: true,
                    isBottomBorderRadiusRemoved: true,
                    isTopBorderRadiusRemoved: true,
                    menuItemColor: getEnteColorScheme(context).fillFaint,
                    pressedColor: getEnteColorScheme(context).fillFaint,
                    trailingWidget: Switch.adaptive(
                      value: widget.collection.publicURLs?.firstOrNull
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
                                .inverseBackgroundColor,
                          );
                          if (choice != DialogUserChoice.secondChoice) {
                            return;
                          }
                        }
                        await _updateUrlSettings(
                          context,
                          {'enableDownload': value},
                        );
                        if (!value) {
                          showErrorDialog(
                            context,
                            "Please note",
                            "Viewers can still take screenshots or save a copy of your photos using external tools",
                          );
                        }
                        setState(() {});
                      },
                    ),
                  ),
                  DividerWidget(
                    dividerType: DividerType.menu,
                    bgColor: getEnteColorScheme(context).blurStrokeFaint,
                  ),
                  MenuItemWidget(
                    captionedTextWidget: const CaptionedTextWidget(
                      title: "Password lock",
                    ),
                    alignCaptionedTextToLeft: true,
                    isTopBorderRadiusRemoved: true,
                    menuItemColor: getEnteColorScheme(context).fillFaint,
                    pressedColor: getEnteColorScheme(context).fillFaint,
                    trailingWidget: Switch.adaptive(
                      value: widget.collection.publicURLs?.firstOrNull
                              ?.passwordEnabled ??
                          false,
                      onChanged: (enablePassword) async {
                        if (enablePassword) {
                          final inputResult =
                              await _displayLinkPasswordInput(context);
                          if (inputResult != null &&
                              inputResult == 'ok' &&
                              _textFieldController.text.trim().isNotEmpty) {
                            final propToUpdate = await _getEncryptedPassword(
                              _textFieldController.text,
                            );
                            await _updateUrlSettings(context, propToUpdate);
                          }
                        } else {
                          await _updateUrlSettings(
                            context,
                            {'disablePassword': true},
                          );
                        }
                        setState(() {});
                      },
                    ),
                  ),
                  const SizedBox(
                    height: 24,
                  ),
                  MenuItemWidget(
                    captionedTextWidget: const CaptionedTextWidget(
                      title: "Remove link",
                      textColor: warning500,
                      makeTextBold: true,
                    ),
                    leadingIcon: Icons.remove_circle_outline,
                    leadingIconColor: warning500,
                    menuItemColor: getEnteColorScheme(context).fillFaint,
                    pressedColor: getEnteColorScheme(context).fillFaint,
                    onTap: () async {
                      final bool result = await sharingActions.publicLinkToggle(
                        context,
                        widget.collection,
                        false,
                      );
                      if (result && mounted) {
                        Navigator.of(context).pop();
                        // setState(() => {});
                      }
                    },
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
                border: const Border(
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
                    onPressed: () {
                      Navigator.of(context).pop('cancel');
                    },
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 5.0,
                    ),
                    child: Text(
                      'Cancel',
                      style: Theme.of(context).textTheme.subtitle1,
                    ),
                  ),
                  CupertinoButton(
                    onPressed: () async {
                      int newValidTill = -1;
                      final int expireAfterInMicroseconds =
                          _selectedExpiry.item3;
                      // need to manually select time
                      if (expireAfterInMicroseconds < 0) {
                        final timeInMicrosecondsFromEpoch =
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
                          context,
                          {'validTill': newValidTill},
                        );
                        setState(() {});
                      }
                      Navigator.of(context).pop('');
                    },
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 2.0,
                    ),
                    child: Text(
                      'Confirm',
                      style: Theme.of(context).textTheme.subtitle1,
                    ),
                  )
                ],
              ),
            ),
            Container(
              height: 220.0,
              color: const Color(0xfff7f7f7),
              child: CupertinoPicker(
                backgroundColor:
                    Theme.of(context).backgroundColor.withOpacity(0.95),
                onSelectedItemChanged: (value) {
                  final firstWhere = _expiryOptions
                      .firstWhere((element) => element.item1 == value);
                  setState(() {
                    _selectedExpiry = firstWhere;
                  });
                },
                magnification: 1.3,
                useMagnifier: true,
                itemExtent: 25,
                diameterRatio: 1,
                children:
                    _expiryOptions.map((e) => getOptionText(e.item2)).toList(),
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
        bool passwordVisible = false;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Enter password'),
              content: TextFormField(
                autofillHints: const [AutofillHints.newPassword],
                decoration: InputDecoration(
                  hintText: "Password",
                  contentPadding: const EdgeInsets.all(12),
                  suffixIcon: IconButton(
                    icon: Icon(
                      passwordVisible ? Icons.visibility : Icons.visibility_off,
                      color: Colors.white.withOpacity(0.5),
                      size: 20,
                    ),
                    onPressed: () {
                      passwordVisible = !passwordVisible;
                      setState(() {});
                    },
                  ),
                ),
                obscureText: !passwordVisible,
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
                  child: Text(
                    'Cancel',
                    style: Theme.of(context).textTheme.subtitle2,
                  ),
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
          },
        );
      },
    );
  }

  Future<Map<String, dynamic>> _getEncryptedPassword(String pass) async {
    assert(
      Sodium.cryptoPwhashAlgArgon2id13 == Sodium.cryptoPwhashAlgDefault,
      "mismatch in expected default pw hashing algo",
    );
    final int memLimit = Sodium.cryptoPwhashMemlimitInteractive;
    final int opsLimit = Sodium.cryptoPwhashOpslimitInteractive;
    final kekSalt = CryptoUtil.getSaltToDeriveKey();
    final result = await CryptoUtil.deriveKey(
      utf8.encode(pass),
      kekSalt,
      memLimit,
      opsLimit,
    );
    return {
      'passHash': Sodium.bin2base64(result),
      'nonce': Sodium.bin2base64(kekSalt),
      'memLimit': memLimit,
      'opsLimit': opsLimit,
    };
  }

  Future<void> _updateUrlSettings(
    BuildContext context,
    Map<String, dynamic> prop,
  ) async {
    final dialog = createProgressDialog(context, "Please wait...");
    await dialog.show();
    try {
      await CollectionsService.instance.updateShareUrl(widget.collection, prop);
      await dialog.hide();
      showToast(context, "Album updated");
    } catch (e) {
      await dialog.hide();
      await showGenericErrorDialog(context);
    }
  }

  Text _getLinkExpiryTimeWidget() {
    final int validTill =
        widget.collection.publicURLs?.firstOrNull?.validTill ?? 0;
    if (validTill == 0) {
      return const Text(
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
      style: const TextStyle(
        color: Colors.grey,
      ),
    );
  }

  Future<void> _showDeviceLimitPicker() async {
    final List<Text> options = [];
    for (int i = 50; i > 0; i--) {
      options.add(
        Text(i.toString(), style: Theme.of(context).textTheme.subtitle1),
      );
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
                border: const Border(
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
                    onPressed: () {
                      Navigator.of(context).pop('cancel');
                    },
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 5.0,
                    ),
                    child: Text(
                      'Cancel',
                      style: Theme.of(context).textTheme.subtitle1,
                    ),
                  ),
                  CupertinoButton(
                    onPressed: () async {
                      await _updateUrlSettings(context, {
                        'deviceLimit': int.tryParse(
                          options[_selectedDeviceLimitIndex].data,
                        ),
                      });
                      setState(() {});
                      Navigator.of(context).pop('');
                    },
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 2.0,
                    ),
                    child: Text(
                      'Confirm',
                      style: Theme.of(context).textTheme.subtitle1,
                    ),
                  )
                ],
              ),
            ),
            Container(
              height: 220.0,
              color: const Color(0xfff7f7f7),
              child: CupertinoPicker(
                backgroundColor:
                    Theme.of(context).backgroundColor.withOpacity(0.95),
                onSelectedItemChanged: (value) {
                  _selectedDeviceLimitIndex = value;
                },
                magnification: 1.3,
                useMagnifier: true,
                itemExtent: 25,
                diameterRatio: 1,
                children: options,
              ),
            )
          ],
        );
      },
    );
  }
}
