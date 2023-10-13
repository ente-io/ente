import * as log from 'electron-log';
import util from 'util';
import { logErrorSentry } from './sentry';
const shellescape = require('any-shell-escape');
const execAsync = util.promisify(require('child_process').exec);

const CLIP_MODEL_PATH_PLACEHOLDER = 'CLIP_MODEL';
const GGMLCLIP_PATH_PLACEHOLDER = 'GGML_PATH';
const INPUT_PATH_PLACEHOLDER = 'INPUT';

const IMAGE_EMBEDDING_EXTRACT_CMD: string[] = [
    GGMLCLIP_PATH_PLACEHOLDER,
    '-m',
    CLIP_MODEL_PATH_PLACEHOLDER,
    '--image',
    INPUT_PATH_PLACEHOLDER,
];

const TEXT_EMBEDDING_EXTRACT_CMD: string[] = [
    GGMLCLIP_PATH_PLACEHOLDER,
    '-m',
    CLIP_MODEL_PATH_PLACEHOLDER,
    '--text',
    INPUT_PATH_PLACEHOLDER,
];

function getClipModelPath() {
    return './models/openai_clip-vit-base-patch32.ggmlv0.f16.bin';
}

function getGGMLClipPath() {
    return './bin/ggmlclip';
}

export async function computeImageEmbedding(
    inputFilePath: string
): Promise<Float32Array> {
    try {
        const clipModelPath = getClipModelPath();
        const ggmlclipPath = getGGMLClipPath();
        const cmd = IMAGE_EMBEDDING_EXTRACT_CMD.map((cmdPart) => {
            if (cmdPart === GGMLCLIP_PATH_PLACEHOLDER) {
                return ggmlclipPath;
            } else if (cmdPart === CLIP_MODEL_PATH_PLACEHOLDER) {
                return clipModelPath;
            } else if (cmdPart === INPUT_PATH_PLACEHOLDER) {
                return inputFilePath;
            } else {
                return cmdPart;
            }
        });

        const escapedCmd = shellescape(cmd);
        log.info('running clip command', escapedCmd);
        const startTime = Date.now();
        const { stdout } = await execAsync(escapedCmd);
        log.info('clip command execution time ', Date.now() - startTime);
        // parse stdout and return embedding
        // get the last line of stdout
        const lines = stdout.split('\n');
        const lastLine = lines[lines.length - 1];
        const embedding = JSON.parse(lastLine);
        const embeddingArray = new Float32Array(embedding);
        return embeddingArray;
    } catch (err) {
        logErrorSentry(err, 'Error in computeImageEmbedding');
    }
}

export async function computeTextEmbedding(
    text: string
): Promise<Float32Array> {
    try {
        const clipModelPath = getClipModelPath();
        const ggmlclipPath = getGGMLClipPath();
        const cmd = TEXT_EMBEDDING_EXTRACT_CMD.map((cmdPart) => {
            if (cmdPart === GGMLCLIP_PATH_PLACEHOLDER) {
                return ggmlclipPath;
            } else if (cmdPart === CLIP_MODEL_PATH_PLACEHOLDER) {
                return clipModelPath;
            } else if (cmdPart === INPUT_PATH_PLACEHOLDER) {
                return text;
            } else {
                return cmdPart;
            }
        });

        const escapedCmd = shellescape(cmd);
        log.info('running clip command', escapedCmd);
        const startTime = Date.now();
        const { stdout } = await execAsync(escapedCmd);
        log.info('clip command execution time ', Date.now() - startTime);
        // parse stdout and return embedding
        // get the last line of stdout
        const lines = stdout.split('\n');
        const lastLine = lines[lines.length - 1];
        const embedding = JSON.parse(lastLine);
        const embeddingArray = new Float32Array(embedding);
        return embeddingArray;
    } catch (err) {
        logErrorSentry(err, 'Error in computeImageEmbedding');
    }
}
