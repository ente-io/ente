import 'dart:convert';
import "dart:developer" as dev show log;
import "dart:io" show File;

import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:ml_linalg/vector.dart';
import "package:path_provider/path_provider.dart"
    show getExternalStorageDirectory;
import 'package:photos/models/memories/clip_memory.dart';
import 'package:photos/models/memories/people_memory.dart';
import 'package:photos/models/ml/discover/prompt.dart';
import "package:photos/services/machine_learning/ml_computer.dart"
    show MLComputer;

final _logger = Logger('TextEmbeddingsUtil');

/// Loads pre-computed memories text embeddings from assets
Future<MemoriesEmbeddings?> loadMemoriesEmbeddings() async {
  try {
    _logger.info('Loading text embeddings from assets');
    final jsonString =
        await rootBundle.loadString('assets/ml/text_embeddings.json');
    final data = json.decode(jsonString) as Map<String, dynamic>;

    final embeddings = data['embeddings'] as Map<String, dynamic>;

    // Parse clip positive embedding
    Vector? clipPositiveVector;
    final clipPositive = embeddings['clip_positive'] as Map<String, dynamic>;
    final clipPositiveVectorData =
        (clipPositive['vector'] as List).cast<double>();
    if (clipPositiveVectorData.isNotEmpty) {
      clipPositiveVector = Vector.fromList(clipPositiveVectorData);
    }

    // Parse people activities embeddings
    final Map<PeopleActivity, Vector> peopleActivityVectors = {};
    final peopleActivities =
        embeddings['people_activities'] as Map<String, dynamic>;
    for (final activity in PeopleActivity.values) {
      final activityName = activity.toString().split('.').last;
      if (peopleActivities.containsKey(activityName)) {
        final activityData =
            peopleActivities[activityName] as Map<String, dynamic>;
        final vector = (activityData['vector'] as List).cast<double>();
        if (vector.isNotEmpty) {
          peopleActivityVectors[activity] = Vector.fromList(vector);
        }
      }
    }

    // Parse clip memory types embeddings
    final Map<ClipMemoryType, Vector> clipMemoryTypeVectors = {};
    final clipMemoryTypes =
        embeddings['clip_memory_types'] as Map<String, dynamic>;
    for (final memoryType in ClipMemoryType.values) {
      final typeName = memoryType.toString().split('.').last;
      if (clipMemoryTypes.containsKey(typeName)) {
        final typeData = clipMemoryTypes[typeName] as Map<String, dynamic>;
        final vector = (typeData['vector'] as List).cast<double>();
        if (vector.isNotEmpty) {
          clipMemoryTypeVectors[memoryType] = Vector.fromList(vector);
        }
      }
    }

    // Check if we have all required embeddings
    if (clipPositiveVector == null) {
      _logger.severe('Clip positive vector is missing');
      throw Exception('Clip positive vector is missing');
    }

    if (peopleActivityVectors.length != PeopleActivity.values.length) {
      _logger.severe('Some people activity vectors are missing');
      throw Exception('Some people activity vectors are missing');
    }

    if (clipMemoryTypeVectors.length != ClipMemoryType.values.length) {
      _logger.severe('Some clip memory type vectors are missing');
      throw Exception('Some clip memory type vectors are missing');
    }

    _logger.info('Text embeddings loaded successfully from JSON assets');
    return MemoriesEmbeddings(
      clipPositiveVector: clipPositiveVector,
      peopleActivityVectors: peopleActivityVectors,
      clipMemoryTypeVectors: clipMemoryTypeVectors,
    );
  } catch (e, stackTrace) {
    _logger.severe('Failed to load text embeddings from JSON', e, stackTrace);
    return null;
  }
}

/// Container for all memories text embeddings
class MemoriesEmbeddings {
  final Vector clipPositiveVector;
  final Map<PeopleActivity, Vector> peopleActivityVectors;
  final Map<ClipMemoryType, Vector> clipMemoryTypeVectors;

  const MemoriesEmbeddings({
    required this.clipPositiveVector,
    required this.peopleActivityVectors,
    required this.clipMemoryTypeVectors,
  });
}

/// Loads pre-computed discover text embeddings from assets
Future<DiscoverEmbeddings?> loadDiscoverEmbeddings() async {
  try {
    _logger.info('Loading discover embeddings from assets');
    final jsonString =
        await rootBundle.loadString('assets/ml/discover_embeddings.json');
    final data = json.decode(jsonString) as Map<String, dynamic>;

    final promptsList = data['prompts'] as List;
    final Map<String, Vector> queryToVector = {};
    final Map<String, PromptData> queryToPromptData = {};

    // Parse all discover embeddings
    for (final promptJson in promptsList) {
      final query = promptJson['query'] as String;
      final vector = (promptJson['vector'] as List).cast<double>();
      if (vector.isNotEmpty) {
        queryToVector[query] = Vector.fromList(vector);
        queryToPromptData[query] = PromptData(
          title: promptJson['title'] as String,
          minScore: (promptJson['minScore'] as num).toDouble(),
          minSize: (promptJson['minSize'] as num).toDouble(),
          showVideo: promptJson['showVideo'] as bool?,
          recentFirst: promptJson['recentFirst'] as bool?,
        );
      }
    }

    // Check if we have all embeddings
    if (queryToVector.isEmpty) {
      _logger.warning('No discover embeddings found');
      return null;
    }

    _logger.info(
      'Discover embeddings loaded successfully with ${queryToVector.length} queries',
    );
    return DiscoverEmbeddings(
      queryToVector: queryToVector,
      queryToPromptData: queryToPromptData,
    );
  } catch (e, stackTrace) {
    _logger.severe('Failed to load discover embeddings', e, stackTrace);
    return null;
  }
}

/// Container for discover/magic embeddings
class DiscoverEmbeddings {
  final Map<String, Vector> queryToVector;
  final Map<String, PromptData> queryToPromptData;

  const DiscoverEmbeddings({
    required this.queryToVector,
    required this.queryToPromptData,
  });
}

/// Container for prompt metadata
class PromptData {
  final String title;
  final double minScore;
  final double minSize;
  final bool? showVideo;
  final bool? recentFirst;

  const PromptData({
    required this.title,
    required this.minScore,
    required this.minSize,
    this.showVideo,
    this.recentFirst,
  });
}

/// Helper function to generate text embeddings and save them to a JSON file
/// Run this once to generate the embeddings, then copy the output
/// to assets/ml/text_embeddings.json
Future<void> generateAndSaveTextEmbeddings() async {
  final Map<String, dynamic> embeddingsData = {
    'version': '1.0.0',
    'embeddings': {
      'clip_positive': {},
      'people_activities': {},
      'clip_memory_types': {},
    },
  };

  // Generate clip positive embedding
  const String clipPositiveQuery =
      'Photo of a precious and nostalgic memory radiating warmth, vibrant energy, or quiet beauty — alive with color, light, or emotion';
  final clipPositiveVector =
      await MLComputer.instance.runClipText(clipPositiveQuery);
  embeddingsData['embeddings']['clip_positive'] = {
    'prompt': clipPositiveQuery,
    'vector': clipPositiveVector,
  };

  // Generate people activity embeddings
  final peopleActivities = <String, dynamic>{};
  for (final activity in PeopleActivity.values) {
    final activityName = activity.toString().split('.').last;
    final prompt = activityQuery(activity);
    final vector = await MLComputer.instance.runClipText(prompt);
    peopleActivities[activityName] = {
      'prompt': prompt,
      'vector': vector,
    };
  }
  embeddingsData['embeddings']['people_activities'] = peopleActivities;

  // Generate clip memory type embeddings
  final clipMemoryTypes = <String, dynamic>{};
  for (final memoryType in ClipMemoryType.values) {
    final typeName = memoryType.toString().split('.').last;
    final prompt = clipQuery(memoryType);
    final vector = await MLComputer.instance.runClipText(prompt);
    clipMemoryTypes[typeName] = {
      'prompt': prompt,
      'vector': vector,
    };
  }
  embeddingsData['embeddings']['clip_memory_types'] = clipMemoryTypes;

  // Convert to JSON and log it
  final jsonString = const JsonEncoder.withIndent('  ').convert(embeddingsData);
  dev.log(
    '_generateAndSaveTextEmbeddings: Generated text embeddings JSON',
  );

  final tempDir = await getExternalStorageDirectory();
  final file = File('${tempDir!.path}/text_embeddings.json');
  await file.writeAsString(jsonString);
  dev.log(
    '_generateAndSaveTextEmbeddings: Saved text embeddings to ${file.path}',
  );

  dev.log(
    '_generateAndSaveTextEmbeddings: Text embeddings generation complete! Copy the JSON output above to assets/ml/text_embeddings.json',
  );
}

/// Helper function to generate discover text embeddings and save them to a JSON file
/// Run this once to generate the embeddings, then copy the output
/// to assets/ml/discover_embeddings.json
Future<void> generateAndSaveDiscoverEmbeddings() async {
  // Hardcoded prompts from v2.json
  final magicPromptsData = [
    Prompt(
      query: "identity documents and cards",
      title: "Identity",
      minScore: 0.20,
      minSize: 0.0,
      showVideo: false,
    ),
    Prompt(
      query: "screenshots",
      title: "Screenshots",
      minScore: 0.18,
      minSize: 0.0,
      recentFirst: true,
      showVideo: false,
    ),
    Prompt(
      query: "receipts, bills and invoices",
      title: "Receipts",
      minScore: 0.20,
      minSize: 0.0,
      recentFirst: true,
    ),
    Prompt(
      query: "screenshots of digital notes, photos of notebook and whiteboards",
      title: "Notes",
      minScore: 0.20,
      minSize: 0.0,
      recentFirst: true,
    ),
    Prompt(
      query: "memes",
      title: "Memes",
      minScore: 0.18,
      minSize: 0.0,
      recentFirst: true,
    ),
    Prompt(
      query: "business card",
      title: "Visiting Cards",
      minScore: 0.20,
      minSize: 0.0,
      recentFirst: true,
      showVideo: false,
    ),
    Prompt(
      query: "photo of toddler",
      title: "Babies",
      minScore: 0.20,
      minSize: 0.0,
      recentFirst: true,
    ),
    Prompt(
      query: "photos of pets",
      title: "Pets",
      minScore: 0.20,
      minSize: 0.0,
      recentFirst: true,
    ),
    Prompt(
      query: "selfie",
      title: "Selfies",
      minScore: 0.18,
      minSize: 0.0,
      recentFirst: true,
    ),
    Prompt(
      query: "high resolution hd wallpaper",
      title: "Wallpapers",
      minScore: 0.18,
      minSize: 0.0,
      showVideo: false,
    ),
    Prompt(
      query: "photo of food",
      title: "Food",
      minScore: 0.20,
      minSize: 0.0,
      recentFirst: true,
    ),
    Prompt(
      query: "celebration with friends",
      title: "Celebrations",
      minScore: 0.20,
      minSize: 0.0,
      recentFirst: true,
    ),
    Prompt(
      query: "photo of setting sun",
      title: "Sunset",
      minScore: 0.20,
      minSize: 0.0,
    ),
    Prompt(
      query: "photo of mountains or hills",
      title: "Hills",
      minScore: 0.20,
      minSize: 0.0,
    ),
    Prompt(
      query: "outdoor photo of trees, leaves, flowers",
      title: "Greenery",
      minScore: 0.20,
      minSize: 0.0,
    ),
  ];

  final Map<String, dynamic> embeddingsData = {
    'version': '1.0.0',
    'prompts': [],
  };

  final prompts = <Map<String, dynamic>>[];

  for (final prompt in magicPromptsData) {
    _logger.info('Generating embedding for discover prompt: ${prompt.title}');
    final vector = await MLComputer.instance.runClipText(prompt.query);

    final promptData = {
      'query': prompt.query,
      'title': prompt.title,
      'minScore': prompt.minScore,
      'minSize': prompt.minSize,
      'vector': vector,
    };

    // Add optional fields
    promptData['showVideo'] = prompt.showVideo;
    promptData['recentFirst'] = prompt.recentFirst;

    prompts.add(promptData);
  }

  embeddingsData['prompts'] = prompts;

  // Convert to JSON and log it
  final jsonString = const JsonEncoder.withIndent('  ').convert(embeddingsData);
  dev.log(
    '_generateAndSaveDiscoverEmbeddings: Generated discover embeddings JSON',
  );

  final tempDir = await getExternalStorageDirectory();
  final file = File('${tempDir!.path}/discover_embeddings.json');
  await file.writeAsString(jsonString);
  dev.log(
    '_generateAndSaveDiscoverEmbeddings: Saved discover embeddings to ${file.path}',
  );

  dev.log(
    '_generateAndSaveDiscoverEmbeddings: Discover embeddings generation complete! Copy the JSON output above to assets/ml/discover_embeddings.json',
  );
}
