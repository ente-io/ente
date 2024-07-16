import 'package:flutter/material.dart';
import "package:photos/theme/ente_theme.dart";

class VideoExifDialog extends StatelessWidget {
  final Map<String, dynamic> probeData;

  const VideoExifDialog({Key? key, required this.probeData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGeneralInfo(context),
            const SizedBox(height: 8),
            _buildSection(context, 'Streams', _buildStreamsList(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, Widget content) {
    return ExpansionTile(
      initiallyExpanded: true,
      title: Text(title, style: getEnteTextTheme(context).largeFaint),
      childrenPadding: const EdgeInsets.symmetric(vertical: 2),
      tilePadding: const EdgeInsets.symmetric(vertical: 4),
      children: [content],
    );
  }

  Widget _buildGeneralInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow(context, 'Creation Time', probeData, 'creation_time'),
        _buildInfoRow(context, 'Duration', probeData, 'duration'),
        _buildInfoRow(context, 'Location', probeData, 'location'),
        _buildInfoRow(context, 'Bitrate', probeData, 'bitrate'),
        _buildInfoRow(context, 'Model', probeData, 'com.apple.quicktime.model'),
        _buildInfoRow(context, 'OS', probeData, 'com.apple.quicktime.software'),
        _buildInfoRow(context, 'Major Brand', probeData, 'major_brand'),
        _buildInfoRow(context, 'Format', probeData, 'format'),
      ],
    );
  }

  Widget _buildStreamsList(BuildContext context) {
    final List<dynamic> streams = probeData['streams'];
    final List<Map<String, dynamic>> data = [];
    for (final stream in streams) {
      final Map<String, dynamic> streamData = {};

      for (final key in stream.keys) {
        final dynamic value = stream[key];
        // print type of value
        if (value is int ||
            value is double ||
            value is String ||
            value is bool) {
          streamData[key] = stream[key];
        } else {
          streamData[key] = stream[key].toString();
        }
      }
      data.add(streamData);
    }

    return Column(
      children:
          data.map((stream) => _buildStreamInfo(context, stream)).toList(),
    );
  }

  Widget _buildStreamInfo(BuildContext context, Map<String, dynamic> stream) {
    String titleString = stream['type']?.toString().toUpperCase() ?? '';
    final codeName = stream['codec_name']?.toString().toUpperCase() ?? '';
    if (codeName != 'NULL') {
      titleString += ' - $codeName';
    }
    return ExpansionTile(
      title: Text(
        titleString,
        style: getEnteTextTheme(context).smallBold,
      ),
      childrenPadding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
      tilePadding: const EdgeInsets.symmetric(vertical: 4),
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: stream.entries
              .map(
                (entry) => _buildInfoRow(context, entry.key, stream, entry.key),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String rowName,
    Map<String, dynamic> data,
    String dataKey,
  ) {
    rowName = rowName.replaceAll('_', ' ');
    rowName = rowName[0].toUpperCase() + rowName.substring(1);
    try {
      final value = data[dataKey];
      if (value == null) {
        return Container(); // Return an empty container if there's no data for the key.
      }
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 150,
              child: Text(
                rowName,
                style: getEnteTextTheme(context).smallMuted,
              ),
            ),
            Expanded(child: Text(value.toString())),
          ],
        ),
      );
    } catch (e, s) {
      return Container();
    }
  }
}
