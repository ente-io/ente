/// API origin for Ente Photos TV.
const apiOrigin = String.fromEnvironment(
  'endpoint',
  defaultValue: 'https://api.ente.io',
);

/// Cast worker origin for Ente Photos TV.
const castWorkerOrigin = String.fromEnvironment(
  'castWorkerEndpoint',
  defaultValue: 'https://cast-albums.ente.com',
);

/// Time between slideshow images.
const slideDuration = Duration(seconds: 12);
