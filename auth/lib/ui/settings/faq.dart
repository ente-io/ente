import 'dart:convert';

import 'package:ente_auth/ente_theme_data.dart';
import 'package:ente_auth/l10n/l10n.dart';
import 'package:ente_auth/ui/common/loading_widget.dart';
import 'package:expansion_tile_card/expansion_tile_card.dart';
import 'package:flutter/material.dart';

class FAQQuestionsWidget extends StatelessWidget {
  const FAQQuestionsWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<FaqItem>>(
      future: Future.value(_getFAQs(context)),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.hasData) {
          final faqs = <Widget>[];
          faqs.add(
             Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                context.l10n.faq,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
          for (final faq in snapshot.data) {
            faqs.add(FaqWidget(faq: faq));
          }
          faqs.add(
            const Padding(
              padding: EdgeInsets.all(16),
            ),
          );
          return SingleChildScrollView(
            child: Column(
              children: faqs,
            ),
          );
        } else {
          return const EnteLoadingWidget();
        }
      },
    );
  }

  List<FaqItem> _getFAQs(BuildContext context) {
    final l01n = context.l10n;
    List<FaqItem> faqs = [];
    faqs.add(FaqItem(q: l01n.faq_q_1, a: l01n.faq_a_1));
    faqs.add(FaqItem(q: l01n.faq_q_2, a: l01n.faq_a_2));
    faqs.add(FaqItem(q: l01n.faq_q_3, a: l01n.faq_a_3));
    faqs.add(FaqItem(q: l01n.faq_q_4, a: l01n.faq_a_4));
    faqs.add(FaqItem(q: l01n.faq_q_5, a: l01n.faq_a_5));
    return faqs;
  }
}

class FaqWidget extends StatelessWidget {
  const FaqWidget({
    super.key,
    required this.faq,
  });

  final FaqItem? faq;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(2),
      child: ExpansionTileCard(
        elevation: 0,
        title: Text(faq!.q),
        expandedTextColor: Theme.of(context).colorScheme.alternativeColor,
        baseColor: Theme.of(context).cardColor,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: 12,
              ),
              child: Text(
                faq!.a,
                style: const TextStyle(
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FaqItem {
  final String q;
  final String a;

  FaqItem({
    required this.q,
    required this.a,
  });

  factory FaqItem.fromMap(Map<String, dynamic> map) {
    return FaqItem(
      q: map['q'] ?? 'q',
      a: map['a'] ?? 'a',
    );
  }

  factory FaqItem.fromJson(String source) =>
      FaqItem.fromMap(json.decode(source));

}
