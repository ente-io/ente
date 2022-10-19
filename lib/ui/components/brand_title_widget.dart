import 'package:flutter/material.dart';

enum SizeVarient { small, medium, large }

extension ExtraSizeVarient on SizeVarient {
  double size() {
    if (this == SizeVarient.small) {
      return 21;
    } else if (this == SizeVarient.medium) {
      return 24;
    } else if (this == SizeVarient.large) {
      return 28;
    }
    return -1;
  }
}

class BrandTitleWidget extends StatelessWidget {
  final SizeVarient size;

  const BrandTitleWidget({required this.size, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      "ente",
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontFamily: 'Montserrat',
        fontSize: size.size(),
      ),
    );
  }
}
