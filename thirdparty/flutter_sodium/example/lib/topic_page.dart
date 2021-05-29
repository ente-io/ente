import 'package:flutter/material.dart';
import 'package:flutter_sodium_example/sample_widget.dart';
import 'package:url_launcher/url_launcher.dart';
import 'toc.dart';

class TopicPage extends StatelessWidget {
  final Topic topic;

  TopicPage(this.topic);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(topic.title),
        ),
        body: SafeArea(
            child: SingleChildScrollView(
                child: Container(
                    padding: EdgeInsets.all(15.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        // description
                        if (topic.description != null)
                          Padding(
                              padding: EdgeInsets.only(bottom: 16.0),
                              child: Text(topic.description!)),
                        // more info button
                        if (topic.url != null)
                          Padding(
                            padding: EdgeInsets.only(bottom: 16.0),
                            child: InkWell(
                                child: Text(
                                  'More information',
                                  style: TextStyle(
                                      color: Theme.of(context).accentColor),
                                ),
                                onTap: () => launch(topic.url!)),
                          ),
                        // 0..n samples
                        if (topic.samples != null)
                          for (var sample in topic.samples!)
                            Padding(
                                padding: EdgeInsets.only(bottom: 16.0),
                                child: SampleWidget(sample))
                      ],
                    )))));
  }
}
