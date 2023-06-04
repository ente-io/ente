import "package:flutter/material.dart";

class MapGalleryTileBadge extends StatelessWidget {
  final int size;
  const MapGalleryTileBadge({super.key, required this.size});

  String formatNumber(int number) {
    if (number <= 99) {
      return number.toString();
    } else if (number <= 999) {
      return '${(number / 100).toStringAsFixed(0)}00+';
    } else if (number >= 1000 && number < 2000) {
      return '1K+';
    } else {
      final int thousands = ((number - 1) ~/ 1000);
      return '${thousands}K+';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.all(
            Radius.circular(5),
          ),
          shape: BoxShape.rectangle,
          color: Colors.green,
        ),
        child: Text(
          formatNumber(size),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 8,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
