import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class UsageDetailsWidget extends StatelessWidget {
  const UsageDetailsWidget({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 343,
            height: 196,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 12,
                  offset: Offset(0, 6),
                ),
              ],
              color: Color(0xff42b96c),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Container(
                      width: 343,
                      height: 120,
                      child: Stack(
                        children: [
                          Container(
                            width: 343,
                            height: 120,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: Color(0xff42b96c),
                            ),
                          ),
                          Positioned.fill(
                            child: Align(
                              alignment: Alignment.bottomLeft,
                              child: Opacity(
                                opacity: 0.20,
                                child: Container(
                                  width: 306,
                                  height: 266,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 1,
                                    ),
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Positioned.fill(
                            child: Align(
                              alignment: Alignment.topRight,
                              child: Opacity(
                                opacity: 0.20,
                                child: Container(
                                  width: 376,
                                  height: 256,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 1,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Positioned.fill(
                            child: Align(
                              alignment: Alignment.bottomRight,
                              child: Container(
                                width: 229,
                                height: 226,
                                child: FlutterLogo(size: 226),
                              ),
                            ),
                          ),
                          Positioned.fill(
                            child: Align(
                              alignment: Alignment.topRight,
                              child: Opacity(
                                opacity: 0.20,
                                child: Container(
                                  width: 306,
                                  height: 336,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 1,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: Container(
                      width: 343,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Color(0x33000000),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  top: 20,
                  child: Text(
                    "Current plan",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontFamily: "SF Pro Text",
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Positioned(
                  left: 224,
                  top: 20,
                  child: Opacity(
                    opacity: 0.50,
                    child: Text(
                      "Ends 22 Jan’23",
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontFamily: "SF Pro Text",
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  top: 40,
                  child: Text(
                    "10 GB",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontFamily: "SF Pro Display",
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  top: 136,
                  child: SizedBox(
                    width: 311,
                    height: 36,
                    child: Column(
                      children: [
                        LinearProgressIndicator(
                          value: 0.4,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).buttonColor),
                        ),
                        Padding(padding: EdgeInsets.fromLTRB(0, 12, 0, 0)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text(
                              "2.3 GB of 10 GB used",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontFamily: "SF Pro Text",
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              "3,846 Memories",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontFamily: "SF Pro Text",
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
