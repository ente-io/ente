const PROD_HOST_URL: string = 'ente://app';
const RENDERER_OUTPUT_DIR: string = './ui/out';
const LOG_FILENAME = 'ente.log';
const MAX_LOG_SIZE = 50 * 1024 * 1024; // 50MB

const FILE_STREAM_CHUNK_SIZE: number = 4 * 1024 * 1024;

const SENTRY_DSN = 'https://e9268b784d1042a7a116f53c58ad2165@sentry.ente.io/5';

const RELEASE_VERSION = require('../../package.json').version;

export {
    PROD_HOST_URL,
    RENDERER_OUTPUT_DIR,
    FILE_STREAM_CHUNK_SIZE,
    LOG_FILENAME,
    MAX_LOG_SIZE,
    SENTRY_DSN,
    RELEASE_VERSION,
};
