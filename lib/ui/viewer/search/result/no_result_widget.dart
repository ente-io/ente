import 'package:flutter/material.dart';
import 'package:photos/ente_theme_data.dart';
import "package:photos/generated/l10n.dart";

class NoResultWidget extends StatelessWidget {
  const NoResultWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 6),
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
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              child: Text(
                S.of(context).noResultsFound,
                textAlign: TextAlign.left,
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 16),
              child: Text(
                S.of(context).youCanTrySearchingForADifferentQuery,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context)
                      .colorScheme
                      .defaultTextColor
                      .withOpacity(0.5),
                  height: 1.5,
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(bottom: 20, top: 12),
              child: Text(
                S.of(context).searchByExamples,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context)
                      .colorScheme
                      .defaultTextColor
                      .withOpacity(0.5),
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
