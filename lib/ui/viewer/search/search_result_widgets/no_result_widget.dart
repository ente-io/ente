import 'package:flutter/material.dart';
import 'package:photos/ente_theme_data.dart';

class NoResultWidget extends StatelessWidget {
  const NoResultWidget({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.searchResultsColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: -3,
            blurRadius: 6,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text("Sorry, no results found"),
          const SizedBox(
            height: 12,
          ),
          Text(
            "Try expanding your query",
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.subTextColor,
            ),
          ),
        ],
      ),
    );
  }
}
