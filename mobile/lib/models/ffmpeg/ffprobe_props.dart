// Adapted from: https://github.com/deckerst/aves

import "package:collection/collection.dart";
import "package:intl/intl.dart";
import "package:photos/models/ffmpeg/channel_layouts.dart";
import "package:photos/models/ffmpeg/codecs.dart";
import "package:photos/models/ffmpeg/ffprobe_keys.dart";
import "package:photos/models/ffmpeg/language.dart";
import "package:photos/models/ffmpeg/mp4.dart";
import "package:photos/models/location/location.dart";

class FFProbeProps {
  final Map<String, dynamic>? prodData;

  FFProbeProps({
    required this.prodData,
  });

  // toString() method
  @override
  String toString() {
    final buffer = StringBuffer();
    for (final key in prodData!.keys) {
      final value = prodData![key];
      if (value != null) {
        buffer.writeln('$key: $value');
      }
    }
    return buffer.toString();
  }

  factory FFProbeProps.fromJson(Map<dynamic, dynamic>? json) {
    final Map<String, dynamic> parsedData = {};

    for (final key in json!.keys) {
      final stringKey = key.toString();
      switch (stringKey) {
        case FFProbeKeys.bitrate:
        case FFProbeKeys.bps:
          parsedData[stringKey] = _formatMetric(json[key], 'b/s');
          break;
        case FFProbeKeys.byteCount:
          parsedData[stringKey] = _formatFilesize(json[key]);
          break;
        case FFProbeKeys.channelLayout:
          parsedData[stringKey] = _formatChannelLayout(json[key]);
          break;
        case FFProbeKeys.codecName:
          parsedData[stringKey] = _formatCodecName(json[key]);
          break;
        case FFProbeKeys.codecPixelFormat:
        case FFProbeKeys.colorPrimaries:
        case FFProbeKeys.colorRange:
        case FFProbeKeys.colorSpace:
        case FFProbeKeys.colorTransfer:
          parsedData[stringKey] = (json[key] as String?)?.toUpperCase();
          break;
        case FFProbeKeys.creationTime:
          parsedData[stringKey] = _formatDate(json[key] ?? "");
          break;
        case FFProbeKeys.durationMicros:
          parsedData[stringKey] = formatPreciseDuration(
            Duration(microseconds: int.tryParse(json[key] ?? "") ?? 0),
          );
          break;
        case FFProbeKeys.duration:
          parsedData[stringKey] = _formatDuration(json[key]);
        case FFProbeKeys.location:
          parsedData[stringKey] = _formatLocation(json[key]);
          break;
        case FFProbeKeys.majorBrand:
          parsedData[stringKey] = _formatBrand(json[key]);
          break;
        case FFProbeKeys.startTime:
          parsedData[stringKey] = _formatDuration(json[key]);
          break;
        default:
          parsedData[stringKey] = json[key];
      }
    }

    return FFProbeProps(prodData: parsedData);
  }

  static String _formatBrand(String value) => Mp4.brands[value] ?? value;

  static String _formatChannelLayout(dynamic value) {
    if (value is int) {
      return ChannelLayouts.names[value] ?? 'unknown ($value)';
    }
    return '$value';
  }

  static final Map<String, String> _codecNames = {
    Codecs.ac3: 'AC-3',
    Codecs.eac3: 'E-AC-3',
    Codecs.h264: 'AVC (H.264)',
    Codecs.hevc: 'HEVC (H.265)',
    Codecs.matroska: 'Matroska',
    Codecs.mpeg4: 'MPEG-4 Visual',
    Codecs.mpts: 'MPEG-TS',
    Codecs.opus: 'Opus',
    Codecs.pgs: 'PGS',
    Codecs.subrip: 'SubRip',
    Codecs.theora: 'Theora',
    Codecs.vorbis: 'Vorbis',
    Codecs.webm: 'WebM',
  };

  static String? _formatCodecName(String? value) =>
      value == null || value == "none"
          ? null
          : _codecNames[value] ?? value.toUpperCase().replaceAll('_', ' ');

  // input example: '2021-04-12T09:14:37.000000Z'
  static String? _formatDate(String value) {
    final dateInUtc = DateTime.tryParse(value);
    if (dateInUtc == null) return value;
    final epoch = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    if (dateInUtc == epoch) return null;
    final newDate =
        DateTime.fromMicrosecondsSinceEpoch(dateInUtc.microsecondsSinceEpoch);
    return formatDateTime(newDate, 'en_US', false);
  }

  // input example: '00:00:05.408000000' or '5.408000'
  static Duration? _parseDuration(String? value) {
    if (value == null) return null;

    var match = _durationHmsmPattern.firstMatch(value);
    if (match != null) {
      final h = int.tryParse(match.group(1)!);
      final m = int.tryParse(match.group(2)!);
      final s = int.tryParse(match.group(3)!);
      final millis = double.tryParse(match.group(4)!);
      if (h != null && m != null && s != null && millis != null) {
        return Duration(
          hours: h,
          minutes: m,
          seconds: s,
          milliseconds: (millis * 1000).toInt(),
        );
      }
    }

    match = _durationSmPattern.firstMatch(value);
    if (match != null) {
      final s = int.tryParse(match.group(1)!);
      final millis = double.tryParse(match.group(2)!);
      if (s != null && millis != null) {
        return Duration(
          seconds: s,
          milliseconds: (millis * 1000).toInt(),
        );
      }
    }

    return null;
  }

  // input example: '00:00:05.408000000' or '5.408000'
  static String? _formatDuration(String? value) {
    if (value == null) return null;
    final duration = _parseDuration(value);
    return duration != null ? formatFriendlyDuration(duration) : value;
  }

  static String? _formatFilesize(dynamic value) {
    if (value == null) return null;
    final size = value is int ? value : int.tryParse(value);
    const String asciiLocale = 'en_US';
    return size != null ? formatFileSize(asciiLocale, size) : value;
  }

  static String _formatLanguage(String value) {
    final language = Language.living639_2
        .firstWhereOrNull((language) => language.iso639_2 == value);
    return language?.native ?? value;
  }

  static final _durationHmsmPattern = RegExp(r'(\d+):(\d+):(\d+)(.\d+)');
  static final _durationSmPattern = RegExp(r'(\d+)(.\d+)');
  static final _locationPattern = RegExp(r'([+-][.0-9]+)');

  // format ISO 6709 input, e.g. '+37.5090+127.0243/' (Samsung), '+51.3328-000.7053+113.474/' (Apple)
  static Location? _formatLocation(String? value) {
    if (value == null) return null;
    final matches = _locationPattern.allMatches(value);
    if (matches.isNotEmpty) {
      final coordinates =
          matches.map((m) => double.tryParse(m.group(0)!)).toList();
      if (coordinates.every((c) => c == 0)) return null;
      try {
        return Location(
          latitude: coordinates[0],
          longitude: coordinates[1],
        );
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  static String? _formatMetric(dynamic size, String unit, {int round = 2}) {
    if (size == null) return null;
    if (size is String) {
      final parsed = int.tryParse(size);
      if (parsed == null) return size;
      size = parsed;
    }

    const divider = 1000;
    if (size < divider) return '$size $unit';
    if (size < divider * divider) {
      return '${(size / divider).toStringAsFixed(round)} K$unit';
    }
    return '${(size / divider / divider).toStringAsFixed(round)} M$unit';
  }
}

String formatDay(DateTime date, String locale) =>
    DateFormat.yMMMd(locale).format(date);

String formatTime(DateTime date, String locale, bool use24hour) =>
    (use24hour ? DateFormat.Hm(locale) : DateFormat.jm(locale)).format(date);

String formatDateTime(DateTime date, String locale, bool use24hour) => [
      formatDay(date, locale),
      formatTime(date, locale, use24hour),
    ].join(" ");

String formatFriendlyDuration(Duration d) {
  final seconds = (d.inSeconds.remainder(Duration.secondsPerMinute))
      .toString()
      .padLeft(2, '0');
  if (d.inHours == 0) return '${d.inMinutes}:$seconds';

  final minutes = (d.inMinutes.remainder(Duration.minutesPerHour))
      .toString()
      .padLeft(2, '0');
  return '${d.inHours}:$minutes:$seconds';
}

String? formatPreciseDuration(Duration d) {
  if (d.inSeconds == 0) return null;
  final millis =
      ((d.inMicroseconds / 1000.0).round() % 1000).toString().padLeft(3, '0');
  final seconds = (d.inSeconds.remainder(Duration.secondsPerMinute))
      .toString()
      .padLeft(2, '0');
  final minutes = (d.inMinutes.remainder(Duration.minutesPerHour))
      .toString()
      .padLeft(2, '0');
  final hours = (d.inHours).toString().padLeft(2, '0');
  return '$hours:$minutes:$seconds.$millis';
}

const kilo = 1024;
const mega = kilo * kilo;
const giga = mega * kilo;
const tera = giga * kilo;

String formatFileSize(String locale, int size, {int round = 2}) {
  if (size < kilo) return '$size B';

  final compactFormatter =
      NumberFormat('0${round > 0 ? '.${'0' * round}' : ''}', locale);
  if (size < mega) return '${compactFormatter.format(size / kilo)} KB';
  if (size < giga) return '${compactFormatter.format(size / mega)} MB';
  if (size < tera) return '${compactFormatter.format(size / giga)} GB';
  return '${compactFormatter.format(size / tera)} TB';
}
