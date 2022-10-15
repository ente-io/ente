import 'package:flutter/material.dart';

enum SizeVarient {
  small(21),
  medium(24),
  large(28);

  final double size;
  const SizeVarient(this.size);
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
        fontSize: SizeVarient.medium.size,
      ),
    );
  }
}
