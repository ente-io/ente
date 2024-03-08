// Faces Table Fields & Schema Queries
import "package:photos/services/face_ml/blur_detection/blur_constants.dart";

const facesTable = 'faces';
const fileIDColumn = 'file_id';
const faceIDColumn = 'face_id';
const faceDetectionColumn = 'detection';
const faceEmbeddingBlob = 'eBlob';
const faceScore = 'score';
const faceBlur = 'blur';
const faceClusterId = 'cluster_id';
const faceConfirmedColumn = 'confirmed';
const faceClosestDistColumn = 'close_dist';
const faceClosestFaceID = 'close_face_id';
const mlVersionColumn = 'ml_version';

const createFacesTable = '''CREATE TABLE IF NOT EXISTS $facesTable (
  $fileIDColumn	INTEGER NOT NULL,
  $faceIDColumn  TEXT NOT NULL,
	$faceDetectionColumn	TEXT NOT NULL,
  $faceEmbeddingBlob BLOB NOT NULL,
  $faceScore  REAL NOT NULL,
  $faceBlur REAL NOT NULL DEFAULT $kLapacianDefault,
	$faceClusterId	INTEGER,
	$faceClosestDistColumn	REAL,
  $faceClosestFaceID  TEXT,
	$faceConfirmedColumn  INTEGER NOT NULL DEFAULT 0,
  $mlVersionColumn	INTEGER NOT NULL DEFAULT -1,
  PRIMARY KEY($fileIDColumn, $faceIDColumn)
  );
  ''';

const deleteFacesTable = 'DROP TABLE IF EXISTS $facesTable';
// End of Faces Table Fields & Schema Queries

// People Table Fields & Schema Queries
const peopleTable = 'people';
const idColumn = 'id';
const nameColumn = 'name';
const personHiddenColumn = 'hidden';
const clusterToFaceIdJson = 'clusterToFaceIds';
const coverFaceIDColumn = 'cover_face_id';

const createPeopleTable = '''CREATE TABLE IF NOT EXISTS $peopleTable (
  $idColumn	TEXT NOT NULL UNIQUE,
	$nameColumn	TEXT NOT NULL DEFAULT '',
  $personHiddenColumn	INTEGER NOT NULL DEFAULT 0,
  $clusterToFaceIdJson	TEXT NOT NULL DEFAULT '{}',
  $coverFaceIDColumn	TEXT,
	PRIMARY KEY($idColumn)
  );
  ''';

const deletePeopleTable = 'DROP TABLE IF EXISTS $peopleTable';
//End People Table Fields & Schema Queries

// Clusters Table Fields & Schema Queries
const clustersTable = 'clusters';
const personIdColumn = 'person_id';
const cluserIDColumn = 'cluster_id';

const createClusterTable = '''
CREATE TABLE IF NOT EXISTS $clustersTable (
  $personIdColumn	TEXT NOT NULL,
  $cluserIDColumn	INTEGER NOT NULL,
  PRIMARY KEY($personIdColumn, $cluserIDColumn)
);
''';
const dropClustersTable = 'DROP TABLE IF EXISTS $clustersTable';
// End Clusters Table Fields & Schema Queries

/// Cluster Summary Table Fields & Schema Queries
const clusterSummaryTable = 'cluster_summary';
const avgColumn = 'avg';
const countColumn = 'count';
const createClusterSummaryTable = '''
CREATE TABLE IF NOT EXISTS $clusterSummaryTable (
  $cluserIDColumn	INTEGER NOT NULL,
  $avgColumn BLOB NOT NULL,
  $countColumn INTEGER NOT NULL,
  PRIMARY KEY($cluserIDColumn)
);
''';

const dropClusterSummaryTable = 'DROP TABLE IF EXISTS $clusterSummaryTable';

/// End Cluster Summary Table Fields & Schema Queries

/// notPersonFeedback Table Fields & Schema Queries
const notPersonFeedback = 'not_person_feedback';

const createNotPersonFeedbackTable = '''
CREATE TABLE IF NOT EXISTS $notPersonFeedback (
  $personIdColumn	TEXT NOT NULL,
  $cluserIDColumn	INTEGER NOT NULL
);
''';
const dropNotPersonFeedbackTable = 'DROP TABLE IF EXISTS $notPersonFeedback';
// End Clusters Table Fields & Schema Queries
