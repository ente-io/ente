import "package:ente_auth/theme/ente_theme.dart";
import "package:flutter/material.dart";

class CustomPinKeypad extends StatelessWidget {
  final TextEditingController controller;
  const CustomPinKeypad({required this.controller, super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              color: getEnteColorScheme(context).strokeFainter,
              child: Column(
                children: [
                  Row(
                    children: [
                      _Button(
                        text: '',
                        number: '1',
                        onTap: () {
                          _onKeyTap('1');
                        },
                      ),
                      _Button(
                        text: "ABC",
                        number: '2',
                        onTap: () {
                          _onKeyTap('2');
                        },
                      ),
                      _Button(
                        text: "DEF",
                        number: '3',
                        onTap: () {
                          _onKeyTap('3');
                        },
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _Button(
                        number: '4',
                        text: "GHI",
                        onTap: () {
                          _onKeyTap('4');
                        },
                      ),
                      _Button(
                        number: '5',
                        text: 'JKL',
                        onTap: () {
                          _onKeyTap('5');
                        },
                      ),
                      _Button(
                        number: '6',
                        text: 'MNO',
                        onTap: () {
                          _onKeyTap('6');
                        },
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _Button(
                        number: '7',
                        text: 'PQRS',
                        onTap: () {
                          _onKeyTap('7');
                        },
                      ),
                      _Button(
                        number: '8',
                        text: 'TUV',
                        onTap: () {
                          _onKeyTap('8');
                        },
                      ),
                      _Button(
                        number: '9',
                        text: 'WXYZ',
                        onTap: () {
                          _onKeyTap('9');
                        },
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const _Button(
                        number: '',
                        text: '',
                        muteButton: true,
                        onTap: null,
                      ),
                      _Button(
                        number: '0',
                        text: '',
                        onTap: () {
                          _onKeyTap('0');
                        },
                      ),
                      _Button(
                        number: '',
                        text: '',
                        icon: const Icon(Icons.backspace_outlined),
                        onTap: () {
                          _onBackspace();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onKeyTap(String number) {
    controller.text += number;
    return;
  }

  void _onBackspace() {
    if (controller.text.isNotEmpty) {
      controller.text =
          controller.text.substring(0, controller.text.length - 1);
    }
    return;
  }
}

class _Button extends StatelessWidget {
  final String number;
  final String text;
  final VoidCallback? onTap;
  final bool muteButton;
  final Widget? icon;
  const _Button({
    required this.number,
    required this.text,
    this.muteButton = false,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(6),
            color: muteButton
                ? colorScheme.fillFaintPressed
                : icon == null
                    ? colorScheme.backgroundElevated2
                    : null,
          ),
          child: Center(
            child: muteButton
                ? const SizedBox.shrink()
                : icon != null
                    ? Container(
                        child: icon,
                      )
                    : Container(
                        padding: const EdgeInsets.all(4),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              number,
                              style: textTheme.h3,
                            ),
                            Text(
                              text,
                              style: textTheme.tinyBold,
                            ),
                          ],
                        ),
                      ),
          ),
        ),
      ),
    );
  }
}
