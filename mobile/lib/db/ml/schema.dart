// Faces Table Fields & Schema Queries
import 'package:photos/services/machine_learning/face_ml/face_filtering/face_filtering_constants.dart';

const facesTable = 'faces';
const fileIDColumn = 'file_id';
const objectIdColumn = 'obj_id';
const faceIDColumn = 'face_id';
const faceDetectionColumn = 'detection';
const embeddingColumn = 'embedding';
const faceScore = 'score';
const faceBlur = 'blur';
const isSideways = 'is_sideways';
const imageWidth = 'width';
const imageHeight = 'height';
const mlVersionColumn = 'ml_version';
const personIdColumn = 'person_id';
const clusterIDColumn = 'cluster_id';
const personOrClusterIdColumn = 'person_or_cluster_id';

const createFacesTable = '''CREATE TABLE IF NOT EXISTS $facesTable (
  $fileIDColumn	INTEGER NOT NULL,
  $faceIDColumn  TEXT NOT NULL UNIQUE,
	$faceDetectionColumn	TEXT NOT NULL,
  $embeddingColumn BLOB NOT NULL,
  $faceScore  REAL NOT NULL,
  $faceBlur REAL NOT NULL DEFAULT $kLapacianDefault,
  $isSideways	INTEGER NOT NULL DEFAULT 0,
  $imageHeight	INTEGER NOT NULL DEFAULT 0,
  $imageWidth	INTEGER NOT NULL DEFAULT 0,
  $mlVersionColumn	INTEGER NOT NULL DEFAULT -1,
  PRIMARY KEY($fileIDColumn, $faceIDColumn)
  );
  ''';

const deleteFacesTable = 'DELETE FROM $facesTable';
// End of Faces Table Fields & Schema Queries

//##region Face Clusters Table Fields & Schema Queries
const faceClustersTable = 'face_clusters';

// fcClusterId & fcFaceId are the primary keys and fcClusterId is a foreign key to faces table
const createFaceClustersTable = '''
CREATE TABLE IF NOT EXISTS $faceClustersTable (
  $faceIDColumn	TEXT NOT NULL,
  $clusterIDColumn TEXT NOT NULL,
  PRIMARY KEY($faceIDColumn)
);
''';
// -- Creating a non-unique index on clusterID for query optimization
const fcClusterIDIndex =
    '''CREATE INDEX IF NOT EXISTS idx_fcClusterID ON $faceClustersTable($clusterIDColumn);''';
const deleteFaceClustersTable = 'DELETE FROM $faceClustersTable';
//##endregion

// Clusters Table Fields & Schema Queries
const clusterPersonTable = 'cluster_person';

const createClusterPersonTable = '''
CREATE TABLE IF NOT EXISTS $clusterPersonTable (
  $personIdColumn	TEXT NOT NULL,
  $clusterIDColumn	TEXT NOT NULL,
  PRIMARY KEY($personIdColumn, $clusterIDColumn)
);
''';
const deleteClusterPersonTable = 'DELETE FROM $clusterPersonTable';
// End Clusters Table Fields & Schema Queries

/// Cluster Summary Table Fields & Schema Queries
const clusterSummaryTable = 'cluster_summary';
const avgColumn = 'avg';
const countColumn = 'count';
const createClusterSummaryTable = '''
CREATE TABLE IF NOT EXISTS $clusterSummaryTable (
  $clusterIDColumn	TEXT NOT NULL,
  $avgColumn BLOB NOT NULL,
  $countColumn INTEGER NOT NULL,
  PRIMARY KEY($clusterIDColumn)
);
''';

const deleteClusterSummaryTable = 'DELETE FROM $clusterSummaryTable';

/// End Cluster Summary Table Fields & Schema Queries

/// notPersonFeedback Table Fields & Schema Queries
const notPersonFeedback = 'not_person_feedback';

const createNotPersonFeedbackTable = '''
CREATE TABLE IF NOT EXISTS $notPersonFeedback (
  $personIdColumn	TEXT NOT NULL,
  $clusterIDColumn TEXT NOT NULL,
  PRIMARY KEY($personIdColumn, $clusterIDColumn)
);
''';
const deleteNotPersonFeedbackTable = 'DELETE FROM $notPersonFeedback';
// End Clusters Table Fields & Schema Queries

// ## CLIP EMBEDDINGS TABLE
const clipTable = 'clip';

const createClipEmbeddingsTable = '''
CREATE TABLE IF NOT EXISTS $clipTable ( 
  $fileIDColumn INTEGER NOT NULL,
  $embeddingColumn BLOB NOT NULL,
  $mlVersionColumn INTEGER NOT NULL,
  PRIMARY KEY ($fileIDColumn)
  );
''';

const deleteClipEmbeddingsTable = 'DELETE FROM $clipTable';

const fileDataTable = 'filedata';
const createFileDataTable = '''
CREATE TABLE IF NOT EXISTS $fileDataTable ( 
  $fileIDColumn INTEGER NOT NULL,
  user_id INTEGER NOT NULL,
  type TEXT NOT NULL,
  size INTEGER NOT NULL,
  $objectIdColumn TEXT,
  obj_nonce TEXT,
  updated_at INTEGER NOT NULL,
  PRIMARY KEY ($fileIDColumn, type)
  );
''';

const deleteFileDataTable = 'DELETE FROM $fileDataTable';

// ## FACE CACHE TABLE
const faceCacheTable = 'face_cache';

const createFaceCacheTable = '''
CREATE TABLE IF NOT EXISTS $faceCacheTable (
  $personOrClusterIdColumn TEXT NOT NULL UNIQUE,
  $faceIDColumn TEXT NOT NULL UNIQUE,
  PRIMARY KEY ($personOrClusterIdColumn)
);
''';

const deleteFaceCacheTable = 'DELETE FROM $faceCacheTable';
