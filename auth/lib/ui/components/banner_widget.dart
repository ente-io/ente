import 'package:dotted_border/dotted_border.dart';
import 'package:ente_auth/theme/ente_theme.dart';
import 'package:flutter/material.dart';
import 'package:styled_text/tags/styled_text_tag.dart';
import 'package:styled_text/widgets/styled_text.dart';

enum BannerType {
  rateUs,
  starUs,
  freeStorage,
  discount,
}

class BannerWidget extends StatelessWidget {
  final String text;
  final String? subText;
  final BannerType type;
  final TextStyle? mainTextStyle;

  const BannerWidget({
    super.key,
    required this.text,
    required this.type,
    this.subText,
    this.mainTextStyle,
  });

  @override
  Widget build(BuildContext context) {
    bool isLightMode =
        MediaQuery.of(context).platformBrightness == Brightness.light;

    final colorScheme = getEnteColorScheme(context);
    Color dashColor;
    List<BoxShadow>? boxShadow;
    String imagePath;

    switch (type) {
      case BannerType.rateUs:
        imagePath = "assets/rate_us.png";
        dashColor = const Color.fromRGBO(255, 191, 12, 1);
        boxShadow = [
          BoxShadow(
            color: const Color(0xFFFDB816).withOpacity(0.1),
            blurRadius: 50,
            spreadRadius: 80,
          ),
          BoxShadow(
            color: const Color(0xFFFDB816).withOpacity(0.2),
            blurRadius: 25,
          ),
        ];
        break;
      case BannerType.starUs:
        imagePath = "assets/star_us.png";
        dashColor = const Color.fromRGBO(233, 233, 233, 1);
        boxShadow = [
          BoxShadow(
            color: const Color.fromRGBO(78, 78, 78, 1).withOpacity(0.2),
            blurRadius: 50,
            spreadRadius: 100,
          ),
          BoxShadow(
            color: const Color.fromRGBO(23, 22, 22, 0.30).withOpacity(0.1),
            blurRadius: 25,
          ),
        ];

      case BannerType.freeStorage:
        imagePath = "assets/ente_5gb.png";
        dashColor = const Color.fromRGBO(29, 185, 84, 1);
        boxShadow = [
          BoxShadow(
            color: const Color.fromRGBO(38, 203, 95, 1).withOpacity(0.08),
            blurRadius: 50,
            spreadRadius: 100,
          ),
          BoxShadow(
            color: const Color.fromRGBO(0, 0, 0, 0.50).withOpacity(0.08),
            blurRadius: 25,
          ),
        ];
      case BannerType.discount:
        dashColor = const Color.fromRGBO(29, 185, 84, 1);
        imagePath = "assets/discount.png";
        boxShadow = [
          BoxShadow(
            color: const Color.fromRGBO(38, 203, 95, 1).withOpacity(0.08),
            blurRadius: 50,
            spreadRadius: 100,
          ),
          BoxShadow(
            color: const Color.fromRGBO(0, 0, 0, 0.50).withOpacity(0.08),
            blurRadius: 25,
          ),
        ];
    }
    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(50)),
      child: DottedBorder(
        borderType: BorderType.RRect,
        radius: const Radius.circular(50),
        dashPattern: const <double>[3, 3],
        color: dashColor,
        child: Stack(
          children: [
            if (BannerType.starUs == type)
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(50)),
                  child: isLightMode
                      ? Image.asset("assets/calender_banner_light.png")
                      : Image.asset("assets/calender_banner_dark.png"),
                ),
              ),
            Row(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    if (!isLightMode)
                      Container(
                        height: 80,
                        width: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: boxShadow,
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: SizedBox(
                        height: 60,
                        width: 60,
                        child: Image.asset(imagePath),
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      StyledText(
                        text: text,
                        style: getEnteTextTheme(context).large,
                        textAlign: TextAlign.left,
                        tags: {
                          'bold-green': StyledTextTag(
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primaryGreen,
                            ),
                          ),
                        },
                      ),
                      const SizedBox(height: 5),
                      Text(
                        subText ?? "",
                        textAlign: TextAlign.left,
                        style: const TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
