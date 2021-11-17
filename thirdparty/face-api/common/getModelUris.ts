export function getModelUris(uri: string | undefined, defaultModelName: string) {
  const defaultManifestFilename = `${defaultModelName}-weights_manifest.json`

  if (!uri) {
    return {
      modelBaseUri: '',
      manifestUri: defaultManifestFilename
    }
  }

  if (uri === '/') {
    return {
      modelBaseUri: '/',
      manifestUri: `/${defaultManifestFilename}`
    }
  }
  const protocol = uri.startsWith('http://') ? 'http://' : uri.startsWith('https://') ? 'https://' : '';
  uri = uri.replace(protocol, '');

  const parts = uri.split('/').filter(s => s)

  const manifestFile = uri.endsWith('.json')
    ? parts[parts.length - 1]
    : defaultManifestFilename

  let modelBaseUri = protocol + (uri.endsWith('.json') ? parts.slice(0, parts.length - 1) : parts).join('/')
  modelBaseUri = uri.startsWith('/') ? `/${modelBaseUri}` : modelBaseUri

  return {
    modelBaseUri,
    manifestUri: modelBaseUri === '/' ? `/${manifestFile}` : `${modelBaseUri}/${manifestFile}`
  }
}