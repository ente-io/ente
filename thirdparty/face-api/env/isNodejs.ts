export function isNodejs(): boolean {
  return typeof global === 'object'
    && typeof require === 'function'
    && typeof module !== 'undefined'
    // issues with gatsby.js: module.exports is undefined
    // && !!module.exports
    && typeof process !== 'undefined' && !!process.version
}