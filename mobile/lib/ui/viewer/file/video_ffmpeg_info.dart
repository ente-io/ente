import 'package:flutter/material.dart';

class VideoProbeInfo extends StatelessWidget {
  final Map<String, dynamic> probeData;

  const VideoProbeInfo({Key? key, required this.probeData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection('General Information', _buildGeneralInfo()),
            const SizedBox(height: 8),
            _buildSection('Streams', _buildStreamsList()),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, Widget content) {
    return ExpansionTile(
      initiallyExpanded: true,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      children: [content],
    );
  }

  Widget _buildGeneralInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow('Duration', probeData, 'duration'),
        _buildInfoRow('Probe Score', probeData, 'probe_score'),
        _buildInfoRow('Number of Programs', probeData, 'nb_programs'),
        _buildInfoRow('Number of Streams', probeData, 'nb_streams'),
        _buildInfoRow('Bitrate', probeData, 'bitrate'),
        _buildInfoRow('Format', probeData, 'format'),
        _buildInfoRow('Creation Time', probeData, 'creation_time'),
      ],
    );
  }

  Widget _buildStreamsList() {
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
      children: data.map((stream) => _buildStreamInfo(stream)).toList(),
    );
  }

  Widget _buildStreamInfo(Map<String, dynamic> stream) {
    return ExpansionTile(
      title: Text(
        'Stream ${stream['index']}: ${stream['codec_name']} (${stream['type']})',
      ),
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: stream.entries
              .map((entry) => _buildInfoRow(entry.key, stream, entry.key))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildInfoRow(
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
                style: const TextStyle(fontWeight: FontWeight.bold),
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
