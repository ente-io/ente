import 'dart:convert';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sodium/flutter_sodium.dart';
import 'package:photos/models/collection.dart';
import 'package:photos/services/collections_service.dart';
import 'package:photos/theme/colors.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/actions/collection/collection_sharing_actions.dart';
import 'package:photos/ui/components/captioned_text_widget.dart';
import 'package:photos/ui/components/divider_widget.dart';
import 'package:photos/ui/components/menu_item_widget/menu_item_widget.dart';
import 'package:photos/ui/components/menu_section_description_widget.dart';
import 'package:photos/ui/sharing/pickers/device_limit_picker_page.dart';
import 'package:photos/ui/sharing/pickers/link_expiry_picker_page.dart';
import 'package:photos/utils/crypto_util.dart';
import 'package:photos/utils/date_time_util.dart';
import 'package:photos/utils/dialog_util.dart';
import 'package:photos/utils/navigation_util.dart';
import 'package:photos/utils/toast_util.dart';

class ManageSharedLinkWidget extends StatefulWidget {
  final Collection? collection;

  const ManageSharedLinkWidget({Key? key, this.collection}) : super(key: key);

  @override
  State<ManageSharedLinkWidget> createState() => _ManageSharedLinkWidgetState();
}

class _ManageSharedLinkWidgetState extends State<ManageSharedLinkWidget> {
  final CollectionActions sharingActions =
      CollectionActions(CollectionsService.instance);

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final isCollectEnabled =
        widget.collection!.publicURLs?.firstOrNull?.enableCollect ?? false;
    final isDownloadEnabled =
        widget.collection!.publicURLs?.firstOrNull?.enableDownload ?? true;
    final isPasswordEnabled =
        widget.collection!.publicURLs?.firstOrNull?.passwordEnabled ?? false;
    final enteColorScheme = getEnteColorScheme(context);
    final PublicURL url = widget.collection!.publicURLs!.firstOrNull!;
    return Scaffold(
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
                    key: ValueKey("Allow collect $isCollectEnabled"),
                    captionedTextWidget: const CaptionedTextWidget(
                      title: "Allow adding photos",
                    ),
                    alignCaptionedTextToLeft: true,
                    menuItemColor: getEnteColorScheme(context).fillFaint,
                    trailingWidget: Switch.adaptive(
                      value: widget.collection!.publicURLs?.firstOrNull
                              ?.enableCollect ??
                          false,
                      onChanged: (value) async {
                        await _updateUrlSettings(
                          context,
                          {'enableCollect': value},
                        );
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
                    surfaceExecutionStates: false,
                    onTap: () async {
                      routeToPage(
                        context,
                        LinkExpiryPickerPage(widget.collection!),
                      ).then((value) {
                        setState(() {});
                      });
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
                      subTitle: widget
                          .collection!.publicURLs!.first!.deviceLimit
                          .toString(),
                    ),
                    trailingIcon: Icons.chevron_right,
                    menuItemColor: enteColorScheme.fillFaint,
                    alignCaptionedTextToLeft: true,
                    isBottomBorderRadiusRemoved: true,
                    onTap: () async {
                      routeToPage(
                        context,
                        DeviceLimitPickerPage(widget.collection!),
                      ).then((value) {
                        setState(() {});
                      });
                    },
                    surfaceExecutionStates: false,
                  ),
                  DividerWidget(
                    dividerType: DividerType.menuNoIcon,
                    bgColor: getEnteColorScheme(context).fillFaint,
                  ),
                  MenuItemWidget(
                    key: ValueKey("Allow downloads $isDownloadEnabled"),
                    captionedTextWidget: const CaptionedTextWidget(
                      title: "Allow downloads",
                    ),
                    alignCaptionedTextToLeft: true,
                    isBottomBorderRadiusRemoved: true,
                    isTopBorderRadiusRemoved: true,
                    menuItemColor: getEnteColorScheme(context).fillFaint,
                    trailingWidget: Switch.adaptive(
                      value: isDownloadEnabled,
                      onChanged: (value) async {
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
                      },
                    ),
                  ),
                  DividerWidget(
                    dividerType: DividerType.menuNoIcon,
                    bgColor: getEnteColorScheme(context).fillFaint,
                  ),
                  MenuItemWidget(
                    key: ValueKey("Password lock $isPasswordEnabled"),
                    captionedTextWidget: const CaptionedTextWidget(
                      title: "Password lock",
                    ),
                    alignCaptionedTextToLeft: true,
                    isTopBorderRadiusRemoved: true,
                    menuItemColor: getEnteColorScheme(context).fillFaint,
                    trailingWidget: Switch.adaptive(
                      value: isPasswordEnabled,
                      onChanged: (enablePassword) async {
                        if (enablePassword) {
                          showTextInputDialog(
                            context,
                            title: "Set a password",
                            submitButtonLabel: "Lock",
                            hintText: "Enter password",
                            isPasswordInput: true,
                            alwaysShowSuccessState: true,
                            onSubmit: (String password) async {
                              if (password.trim().isNotEmpty) {
                                final propToUpdate =
                                    await _getEncryptedPassword(
                                  password,
                                );
                                await _updateUrlSettings(
                                  context,
                                  propToUpdate,
                                  showProgressDialog: false,
                                );
                              }
                            },
                          );
                        } else {
                          await _updateUrlSettings(
                            context,
                            {'disablePassword': true},
                          );
                        }
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
                    surfaceExecutionStates: false,
                    onTap: () async {
                      final bool result = await sharingActions.disableUrl(
                        context,
                        widget.collection!,
                      );
                      if (result && mounted) {
                        Navigator.of(context).pop();
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

  Future<Map<String, dynamic>> _getEncryptedPassword(String pass) async {
    assert(
      Sodium.cryptoPwhashAlgArgon2id13 == Sodium.cryptoPwhashAlgDefault,
      "mismatch in expected default pw hashing algo",
    );
    final int memLimit = Sodium.cryptoPwhashMemlimitInteractive;
    final int opsLimit = Sodium.cryptoPwhashOpslimitInteractive;
    final kekSalt = CryptoUtil.getSaltToDeriveKey();
    final result = await CryptoUtil.deriveKey(
      utf8.encode(pass) as Uint8List,
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
    Map<String, dynamic> prop, {
    bool showProgressDialog = true,
  }) async {
    final dialog = showProgressDialog
        ? createProgressDialog(context, "Please wait...")
        : null;
    await dialog?.show();
    try {
      await CollectionsService.instance
          .updateShareUrl(widget.collection!, prop);
      await dialog?.hide();
      showShortToast(context, "Album updated");
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      await dialog?.hide();
      await showGenericErrorDialog(context: context);
      rethrow;
    }
  }
}
