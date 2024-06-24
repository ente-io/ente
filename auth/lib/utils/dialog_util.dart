import 'dart:math';

import 'package:confetti/confetti.dart';
import "package:dio/dio.dart";
import 'package:ente_auth/l10n/l10n.dart';
import 'package:ente_auth/models/typedefs.dart';
import 'package:ente_auth/theme/colors.dart';
import 'package:ente_auth/ui/common/loading_widget.dart';
import 'package:ente_auth/ui/common/progress_dialog.dart';
import 'package:ente_auth/ui/components/action_sheet_widget.dart';
import 'package:ente_auth/ui/components/buttons/button_widget.dart';
import 'package:ente_auth/ui/components/components_constants.dart';
import 'package:ente_auth/ui/components/dialog_widget.dart';
import 'package:ente_auth/ui/components/models/button_result.dart';
import 'package:ente_auth/ui/components/models/button_type.dart';
import 'package:ente_auth/utils/email_util.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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
    buttons: const [
      ButtonWidget(
        buttonType: ButtonType.secondary,
        labelText: "OK",
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
}) async {
  String errorMessage = context.l10n.tempErrorContactSupportIfPersists;
  if (exception is DioException &&
      exception.response != null &&
      exception.response!.data["code"] != null) {
    errorMessage =
        "$apiErrorPrefix\n\nReason: ${exception.response!.data["code"]}";
  }
  return showDialogWidget(
    context: context,
    title: context.l10n.error,
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
  try {
    if (error == null) {
      return genericError;
    }
    if (error is DioException) {
      final DioException dioError = error;
      if (dioError.type == DioExceptionType.unknown) {
        if (dioError.error.toString().contains('Failed host lookup')) {
          return context.l10n.networkHostLookUpErr;
        } else if (dioError.error.toString().contains('SocketException')) {
          return context.l10n.networkConnectionRefusedErr;
        }
      }
    }
    // return generic error if the user is not internal and the error is not in debug mode
    if (!kDebugMode) {
      return genericError;
    }
    String errorInfo = "";
    if (error is DioException) {
      final DioException dioError = error;
      if (dioError.type == DioExceptionType.badResponse) {
        if (dioError.response?.data["code"] != null) {
          errorInfo = "Reason: " + dioError.response!.data["code"];
        } else {
          errorInfo = "Reason: " + dioError.response!.data.toString();
        }
      } else if (dioError.type == DioExceptionType.unknown) {
        errorInfo = "Reason: " + dioError.error.toString();
      } else {
        errorInfo = "Reason: " + dioError.type.toString();
      }
    } else {
      if (kDebugMode) {
        errorInfo = error.toString();
      } else {
        errorInfo = error.toString().split('Source stack')[0];
      }
    }
    if (errorInfo.isNotEmpty) {
      return "$genericError\n\n$errorInfo";
    }
    return genericError;
  } catch (e) {
    return genericError;
  }
}

///Will return null if dismissed by tapping outside
Future<ButtonResult?> showGenericErrorDialog({
  required BuildContext context,
  bool isDismissible = true,
  required Object? error,
}) async {
  final errorBody = parseErrorForUI(
    context,
    context.l10n.itLooksLikeSomethingWentWrongPleaseRetryAfterSome,
    error: error,
  );

  return showDialogWidget(
    context: context,
    title: context.l10n.error,
    icon: Icons.error_outline_outlined,
    body: errorBody,
    isDismissible: isDismissible,
    buttons: [
      ButtonWidget(
        buttonType: ButtonType.primary,
        labelText: context.l10n.ok,
        buttonAction: ButtonAction.first,
        isInAlert: true,
      ),
      ButtonWidget(
        buttonType: ButtonType.secondary,
        labelText: context.l10n.contactSupport,
        buttonAction: ButtonAction.second,
        onTap: () async {
          await sendLogs(
            context,
            context.l10n.contactSupport,
            "support@ente.io",
            postShare: () {},
          );
        },
      ),
    ],
  );
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
    messageTextStyle: Theme.of(context).textTheme.labelMedium,
    backgroundColor: Theme.of(context).dialogTheme.backgroundColor,
    progressWidget: const EnteLoadingWidget(),
    borderRadius: 10,
    elevation: 10.0,
    insetAnimCurve: Curves.easeInOut,
  );
  return dialog;
}

Future<ButtonResult?> showConfettiDialog<T>({
  required BuildContext context,
  required DialogBuilder dialogBuilder,
  bool barrierDismissible = true,
  Color? barrierColor,
  bool useSafeArea = true,
  bool useRootNavigator = true,
  RouteSettings? routeSettings,
  Alignment confettiAlignment = Alignment.center,
}) {
  final widthOfScreen = MediaQuery.of(context).size.width;
  final isMobileSmall = widthOfScreen <= mobileSmallThreshold;
  final pageBuilder = Builder(
    builder: dialogBuilder,
  );
  final ConfettiController confettiController =
      ConfettiController(duration: const Duration(seconds: 1));
  confettiController.play();
  return showDialog(
    context: context,
    builder: (BuildContext buildContext) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: isMobileSmall ? 8 : 0),
        child: Stack(
          children: [
            Align(alignment: Alignment.center, child: pageBuilder),
            Align(
              alignment: confettiAlignment,
              child: ConfettiWidget(
                confettiController: confettiController,
                blastDirection: pi / 2,
                emissionFrequency: 0,
                numberOfParticles: 100,
                // a lot of particles at once
                gravity: 1,
                blastDirectionality: BlastDirectionality.explosive,
              ),
            ),
          ],
        ),
      );
    },
    barrierDismissible: barrierDismissible,
    barrierColor: barrierColor,
    useSafeArea: useSafeArea,
    useRootNavigator: useRootNavigator,
    routeSettings: routeSettings,
  );
}

//Can return ButtonResult? from ButtonWidget or Exception? from TextInputDialog
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
}) {
  return showDialog(
    barrierColor: backdropFaintDark,
    context: context,
    builder: (context) {
      final bottomInset = MediaQuery.of(context).viewInsets.bottom;
      final isKeyboardUp = bottomInset > 100;
      return Material(
        color: Colors.transparent,
        child: Center(
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
            ),
          ),
        ),
      );
    },
  );
}
