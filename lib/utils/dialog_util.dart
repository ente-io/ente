import "package:dio/dio.dart";
import "package:flutter/foundation.dart";
import 'package:flutter/material.dart';
import "package:flutter/services.dart";
import "package:photos/core/constants.dart";
import "package:photos/generated/l10n.dart";
import 'package:photos/models/button_result.dart';
import 'package:photos/models/typedefs.dart';
import 'package:photos/theme/colors.dart';
import 'package:photos/ui/common/loading_widget.dart';
import 'package:photos/ui/common/progress_dialog.dart';
import 'package:photos/ui/components/action_sheet_widget.dart';
import 'package:photos/ui/components/buttons/button_widget.dart';
import 'package:photos/ui/components/dialog_widget.dart';
import 'package:photos/ui/components/models/button_type.dart';
import "package:photos/utils/email_util.dart";

typedef DialogBuilder = DialogWidget Function(BuildContext context);

///Will return null if dismissed by tapping outside
Future<ButtonResult?> showErrorDialog(
  BuildContext context,
  String title,
  String? body, {
  bool isDismissable = true,
}) async {
  return showDialogWidget(
    context: context,
    title: title,
    body: body,
    isDismissible: isDismissable,
    buttons: [
      ButtonWidget(
        buttonType: ButtonType.secondary,
        labelText: S.of(context).ok,
        isInAlert: true,
        buttonAction: ButtonAction.first,
      ),
    ],
  );
}

Future<ButtonResult?> showErrorDialogForException({
  required BuildContext context,
  required Exception exception,
  bool isDismissible = true,
  String apiErrorPrefix = "It looks like something went wrong.",
  String? message,
}) async {
  String errorMessage =
      message ?? S.of(context).tempErrorContactSupportIfPersists;
  if (exception is DioError &&
      exception.response != null &&
      exception.response!.data["code"] != null) {
    errorMessage =
        "$apiErrorPrefix\n\nReason: " + exception.response!.data["code"];
  }
  return showDialogWidget(
    context: context,
    title: S.of(context).error,
    icon: Icons.error_outline_outlined,
    body: errorMessage,
    isDismissible: isDismissible,
    buttons: const [
      ButtonWidget(
        buttonType: ButtonType.secondary,
        labelText: "OK",
        isInAlert: true,
      ),
    ],
  );
}

String parseErrorForUI(
  BuildContext context,
  String genericError, {
  Object? error,
  bool surfaceError = kDebugMode,
}) {
  if (error == null) {
    return genericError;
  }
  if (error is DioError) {
    final DioError dioError = error;
    if (dioError.type == DioErrorType.other) {
      if (dioError.error.toString().contains('Failed host lookup')) {
        return S.of(context).networkHostLookUpErr;
      } else if (dioError.error.toString().contains('SocketException')) {
        return S.of(context).networkConnectionRefusedErr;
      }
    }
  }
  // return generic error if the user is not internal and the error is not in debug mode
  if (!(isInternalUser && kDebugMode)) {
    return genericError;
  }
  String errorInfo = "";
  if (error is DioError) {
    final DioError dioError = error;
    if (dioError.type == DioErrorType.response) {
      if (dioError.response?.data["code"] != null) {
        errorInfo = "Reason: " + dioError.response!.data["code"];
      } else {
        errorInfo = "Reason: " + dioError.response!.data.toString();
      }
    } else if (dioError.type == DioErrorType.other) {
      errorInfo = "Reason: " + dioError.error.toString();
    } else {
      errorInfo = "Reason: " + dioError.type.toString();
    }
  } else {
    errorInfo = error.toString().split('Source stack')[0];
  }
  if (errorInfo.isNotEmpty) {
    return "$genericError\n\n$errorInfo";
  }
  return genericError;
}

///Will return null if dismissed by tapping outside
Future<ButtonResult?> showGenericErrorDialog({
  required BuildContext context,
  bool isDismissible = true,
  required Object? error,
}) async {
  final errorBody = parseErrorForUI(
    context,
    S.of(context).itLooksLikeSomethingWentWrongPleaseRetryAfterSome,
    error: error,
  );

  final ButtonResult? result = await showDialogWidget(
    context: context,
    title: S.of(context).error,
    icon: Icons.error_outline_outlined,
    body: errorBody,
    isDismissible: isDismissible,
    buttons: [
      ButtonWidget(
        buttonType: ButtonType.primary,
        labelText: S.of(context).ok,
        buttonAction: ButtonAction.first,
        isInAlert: true,
      ),
      ButtonWidget(
        buttonType: ButtonType.secondary,
        labelText: S.of(context).contactSupport,
        buttonAction: ButtonAction.second,
        onTap: () async {
          await sendLogs(
            context,
            S.of(context).contactSupport,
            "support@ente.io",
            postShare: () {},
          );
        },
      ),
    ],
  );
  return result;
}

DialogWidget choiceDialog({
  required String title,
  String? body,
  required String firstButtonLabel,
  String secondButtonLabel = "Cancel",
  ButtonType firstButtonType = ButtonType.neutral,
  ButtonType secondButtonType = ButtonType.secondary,
  ButtonAction firstButtonAction = ButtonAction.first,
  ButtonAction secondButtonAction = ButtonAction.cancel,
  FutureVoidCallback? firstButtonOnTap,
  FutureVoidCallback? secondButtonOnTap,
  bool isCritical = false,
  IconData? icon,
}) {
  final buttons = [
    ButtonWidget(
      buttonType: isCritical ? ButtonType.critical : firstButtonType,
      labelText: firstButtonLabel,
      isInAlert: true,
      onTap: firstButtonOnTap,
      buttonAction: firstButtonAction,
    ),
    ButtonWidget(
      buttonType: secondButtonType,
      labelText: secondButtonLabel,
      isInAlert: true,
      onTap: secondButtonOnTap,
      buttonAction: secondButtonAction,
    ),
  ];

  return DialogWidget(title: title, body: body, buttons: buttons, icon: icon);
}

///Will return null if dismissed by tapping outside
Future<ButtonResult?> showChoiceDialog(
  BuildContext context, {
  required String title,
  String? body,
  required String firstButtonLabel,
  String secondButtonLabel = "Cancel",
  ButtonType firstButtonType = ButtonType.neutral,
  ButtonType secondButtonType = ButtonType.secondary,
  ButtonAction firstButtonAction = ButtonAction.first,
  ButtonAction secondButtonAction = ButtonAction.cancel,
  FutureVoidCallback? firstButtonOnTap,
  FutureVoidCallback? secondButtonOnTap,
  bool isCritical = false,
  IconData? icon,
  bool isDismissible = true,
}) async {
  final buttons = [
    ButtonWidget(
      buttonType: isCritical ? ButtonType.critical : firstButtonType,
      labelText: firstButtonLabel,
      isInAlert: true,
      onTap: firstButtonOnTap,
      buttonAction: firstButtonAction,
    ),
    ButtonWidget(
      buttonType: secondButtonType,
      labelText: secondButtonLabel,
      isInAlert: true,
      onTap: secondButtonOnTap,
      buttonAction: secondButtonAction,
    ),
  ];
  return showDialogWidget(
    context: context,
    title: title,
    body: body,
    buttons: buttons,
    icon: icon,
    isDismissible: isDismissible,
  );
}

///Will return null if dismissed by tapping outside
Future<ButtonResult?> showChoiceActionSheet(
  BuildContext context, {
  required String title,
  String? body,
  required String firstButtonLabel,
  String secondButtonLabel = "Cancel",
  ButtonType firstButtonType = ButtonType.neutral,
  ButtonType secondButtonType = ButtonType.secondary,
  ButtonAction firstButtonAction = ButtonAction.first,
  ButtonAction secondButtonAction = ButtonAction.cancel,
  FutureVoidCallback? firstButtonOnTap,
  FutureVoidCallback? secondButtonOnTap,
  bool isCritical = false,
  IconData? icon,
  bool isDismissible = true,
}) async {
  final buttons = [
    ButtonWidget(
      buttonType: isCritical ? ButtonType.critical : firstButtonType,
      labelText: firstButtonLabel,
      isInAlert: true,
      onTap: firstButtonOnTap,
      buttonAction: firstButtonAction,
      shouldStickToDarkTheme: true,
    ),
    ButtonWidget(
      buttonType: secondButtonType,
      labelText: secondButtonLabel,
      isInAlert: true,
      onTap: secondButtonOnTap,
      buttonAction: secondButtonAction,
      shouldStickToDarkTheme: true,
    ),
  ];
  return showActionSheet(
    context: context,
    title: title,
    body: body,
    buttons: buttons,
    isDismissible: isDismissible,
  );
}

ProgressDialog createProgressDialog(
  BuildContext context,
  String message, {
  isDismissible = false,
}) {
  final dialog = ProgressDialog(
    context,
    type: ProgressDialogType.normal,
    isDismissible: isDismissible,
    barrierColor: Colors.black12,
  );
  dialog.style(
    message: message,
    messageTextStyle: Theme.of(context).textTheme.bodySmall,
    backgroundColor: Theme.of(context).dialogTheme.backgroundColor,
    progressWidget: const EnteLoadingWidget(),
    borderRadius: 10,
    elevation: 10.0,
    insetAnimCurve: Curves.easeInOut,
  );
  return dialog;
}

///Can return ButtonResult? from ButtonWidget or Exception? from TextInputDialog
Future<dynamic> showTextInputDialog(
  BuildContext context, {
  required String title,
  String? body,
  required String submitButtonLabel,
  IconData? icon,
  String? label,
  String? message,
  String? hintText,
  required FutureVoidCallbackParamStr onSubmit,
  IconData? prefixIcon,
  String? initialValue,
  Alignment? alignMessage,
  int? maxLength,
  bool showOnlyLoadingState = false,
  TextCapitalization textCapitalization = TextCapitalization.none,
  bool alwaysShowSuccessState = false,
  bool isPasswordInput = false,
  TextEditingController? textEditingController,
  List<TextInputFormatter>? textInputFormatter,
  TextInputType? textInputType,
}) {
  return showDialog(
    barrierColor: backdropFaintDark,
    context: context,
    builder: (context) {
      final bottomInset = MediaQuery.of(context).viewInsets.bottom;
      final isKeyboardUp = bottomInset > 100;
      return Center(
        child: Padding(
          padding: EdgeInsets.only(bottom: isKeyboardUp ? bottomInset : 0),
          child: TextInputDialog(
            title: title,
            message: message,
            label: label,
            body: body,
            icon: icon,
            submitButtonLabel: submitButtonLabel,
            onSubmit: onSubmit,
            hintText: hintText,
            prefixIcon: prefixIcon,
            initialValue: initialValue,
            alignMessage: alignMessage,
            maxLength: maxLength,
            showOnlyLoadingState: showOnlyLoadingState,
            textCapitalization: textCapitalization,
            alwaysShowSuccessState: alwaysShowSuccessState,
            isPasswordInput: isPasswordInput,
            textEditingController: textEditingController,
            textInputFormatter: textInputFormatter,
            textInputType: textInputType,
          ),
        ),
      );
    },
  );
}
