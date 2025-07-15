import "dart:io" show Platform;

const faceMlVersion = 1;
const clipMlVersion = 1;
const clusterMlVersion = 1;
const minimumClusterSize = 2;

const embeddingFetchLimit = 200;
final fileDownloadMlLimit = Platform.isIOS ? 5 : 10;
const maxFileDownloadSize = 100000000;
