import "package:flutter/material.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/components/buttons/button_widget.dart";
import "package:photos/ui/components/buttons/icon_button_widget.dart";
import "package:photos/ui/components/models/button_type.dart";

class LockScreenOptionPin extends StatelessWidget {
  const LockScreenOptionPin({super.key});
  @override
  Widget build(BuildContext context) {
    final ValueNotifier<bool> isPinEnabled = ValueNotifier<bool>(false);
    final colorTheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                height: 80,
                width: 80,
                child: IconButtonWidget(
                  icon: Icons.lock_outline,
                  iconButtonType: IconButtonType.primary,
                  iconColor: colorTheme.tabIcon,
                  onTap: () {},
                ),
              ),
              Text(
                S.of(context).enterThePinToLockTheApp,
                style: textTheme.bodyBold,
              ),
              if (isPinEnabled.value == false)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    textAlign: TextAlign.center,
                    S.of(context).whenPinIsSetYouNeedToEnterPassword,
                    style: textTheme.smallFaint,
                  ),
                ),
              // ValueListenableBuilder(
              //   valueListenable: isPinEnabled,
              //   builder: (context, value, _) {
              //     return Padding(
              //       padding: const EdgeInsets.all(16.0),
              //       child: isPinEnabled.value
              //           ? ButtonWidget(
              //               labelText: S.of(context).enablePin,
              //               buttonType: ButtonType.neutral,
              //               buttonSize: ButtonSize.large,
              //               shouldStickToDarkTheme: true,
              //               isInAlert: true,
              //             )
              //           : ButtonWidget(
              //               labelText: S.of(context).yes,
              //               buttonType: ButtonType.neutral,
              //               buttonSize: ButtonSize.large,
              //               shouldStickToDarkTheme: true,
              //               isInAlert: true,
              //             ),
              //     );
              //   },
              // ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: isPinEnabled.value
                    ? ButtonWidget(
                        labelText: S.of(context).enablePin,
                        buttonType: ButtonType.neutral,
                        buttonSize: ButtonSize.large,
                        shouldStickToDarkTheme: true,
                        isInAlert: true,
                      )
                    : ButtonWidget(
                        labelText: S.of(context).yes,
                        buttonType: ButtonType.neutral,
                        buttonSize: ButtonSize.large,
                        shouldStickToDarkTheme: true,
                        isInAlert: true,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
// import 'package:flutter/material.dart';
// import 'package:photos/generated/l10n.dart';
// import 'package:photos/theme/ente_theme.dart';
// import 'package:photos/ui/components/buttons/button_widget.dart';
// import 'package:photos/ui/components/buttons/icon_button_widget.dart';
// import 'package:photos/ui/components/models/button_type.dart';

// class LockScreenOptionPin extends StatelessWidget {
//   final ValueNotifier<bool> isPinEnabled = ValueNotifier<bool>(false);

//   @override
//   Widget build(BuildContext context) {
//     final colorTheme = getEnteColorScheme(context);
//     final textTheme = getEnteTextTheme(context);

//     return Scaffold(
//       body: SafeArea(
//         child: Center(
//           child: ValueListenableBuilder<bool>(
//             valueListenable: isPinEnabled,
//             builder: (context, isPinEnabled, _) {
//               return Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 crossAxisAlignment: CrossAxisAlignment.center,
//                 children: [
//                   SizedBox(
//                     height: 80,
//                     width: 80,
//                     child: IconButtonWidget(
//                       icon: Icons.lock_outline,
//                       iconButtonType: IconButtonType.primary,
//                       iconColor: colorTheme.tabIcon,
//                       onTap: () {},
//                     ),
//                   ),
//                   Text(
//                     isPinEnabled
//                         ? S.of(context).enterThePinToLockTheApp
//                         : S.of(context).enterThePinToLockTheApp,
//                     style: textTheme.bodyBold,
//                   ),
//                   if(isPinEnabled == false)
                  
//                   Padding(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 16,
//                       vertical: 8,
//                     ),
//                     child: Text(
//  S.of(context).whenPinIsSetYouNeedToEnterPassword,
//                       textAlign: TextAlign.center,
//                       style: textTheme.smallFaint,
//                     ),
//                   ),
//                   if (!isPinEnabled)
//                     Padding(
//                       padding: const EdgeInsets.all(16.0),
//                       child: ButtonWidget(
//                         labelText: S.of(context).enablePin,
//                         buttonType: ButtonType.neutral,
//                         buttonSize: ButtonSize.large,
//                         shouldStickToDarkTheme: true,
//                         isInAlert: true,
//                         onTap: () {
//                           isPinEnabled.value = true;
//                           return Future<void>.value();
//                         },
//                       ),
//                     ),
//                   if (isPinEnabled)
//                     Padding(
//                       padding: const EdgeInsets.all(16.0),
//                       child: Column(
//                         children: [
//                           Row(
//                             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                             children: List.generate(4, (index) {
//                               return Container(
//                                 width: 50,
//                                 height: 50,
//                                 decoration: BoxDecoration(
//                                   border: Border.all(color: colorTheme.tabIcon),
//                                   borderRadius: BorderRadius.circular(8),
//                                 ),
//                               );
//                             }),
//                           ),
//                           const SizedBox(height: 20),
//                           ButtonWidget(
//                             labelText: S.of(context).yes,
//                             buttonType: ButtonType.neutral,
//                             buttonSize: ButtonSize.large,
//                             shouldStickToDarkTheme: true,
//                             isInAlert: true,
//                           ),
//                         ],
//                       ),
//                     ),
//                 ],
//               );
//             },
//           ),
//         ),
//       ),
//     );
//   }
// }
