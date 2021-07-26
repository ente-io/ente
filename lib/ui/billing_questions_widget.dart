import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:photos/core/network.dart';
import 'package:photos/ui/expansion_card.dart';
import 'package:photos/ui/loading_widget.dart';

class BillingQuestionsWidget extends StatelessWidget {
  const BillingQuestionsWidget({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Network.instance
          .getDio()
          .get("https://static.ente.io/faq.json")
          .then((response) {
        final faqItems = <FaqItem>[];
        for (final item in response.data as List) {
          faqItems.add(FaqItem.fromMap(item));
        }
        return faqItems;
      }),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.hasData) {
          final faqs = <Widget>[];
          faqs.add(Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              "faqs",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ));
          for (final faq in snapshot.data) {
            faqs.add(FaqWidget(faq: faq));
          }
          faqs.add(Padding(
            padding: EdgeInsets.all(16),
          ));
          return SingleChildScrollView(
            child: Column(
              children: faqs,
            ),
          );
        } else {
          return loadWidget;
        }
      },
    );
  }
}

class FaqWidget extends StatelessWidget {
  const FaqWidget({
    Key key,
    @required this.faq,
  }) : super(key: key);

  final FaqItem faq;

  @override
  Widget build(BuildContext context) {
    return ExpansionCard(
      title: Text(faq.q),
      color: Theme.of(context).buttonColor,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16),
          child: Text(
            faq.a,
            style: TextStyle(
              height: 1.5,
            ),
          ),
        )
      ],
    );
  }
}

class FaqItem {
  final String q;
  final String a;
  FaqItem({
    this.q,
    this.a,
  });

  FaqItem copyWith({
    String q,
    String a,
  }) {
    return FaqItem(
      q: q ?? this.q,
      a: a ?? this.a,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'q': q,
      'a': a,
    };
  }

  factory FaqItem.fromMap(Map<String, dynamic> map) {
    if (map == null) return null;

    return FaqItem(
      q: map['q'],
      a: map['a'],
    );
  }

  String toJson() => json.encode(toMap());

  factory FaqItem.fromJson(String source) =>
      FaqItem.fromMap(json.decode(source));

  @override
  String toString() => 'FaqItem(q: $q, a: $a)';

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is FaqItem && o.q == q && o.a == a;
  }

  @override
  int get hashCode => q.hashCode ^ a.hashCode;
}
