import * as log from 'electron-log';
import util from 'util';
import path from 'path';
const shellescape = require('any-shell-escape');
const execAsync = util.promisify(require('child_process').exec);

const CLIP_MODEL_PATH_PLACEHOLDER = 'CLIP_MODEL';
const GGMLCLIP_PATH_PLACEHOLDER = 'GGML_PATH';
const INPUT_PATH_PLACEHOLDER = 'INPUT';

const IMAGE_EMBEDDING_EXTRACT_CMD: string[] = [
    GGMLCLIP_PATH_PLACEHOLDER,
    '-m',
    CLIP_MODEL_PATH_PLACEHOLDER,
    '-image',
    INPUT_PATH_PLACEHOLDER,
];

function getClipModelPath() {
    return path.join(
        __dirname,
        '../models/openai_clip-vit-base-patch32.ggmlv0.f16'
    );
}

function getGGMLClipPath() {
    return path.join(__dirname, '../bin/ggmlclip');
}

export async function computeImageEmbeddings(
    inputFilePath: string
): Promise<Float32Array> {
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
    const { stdout, stderr } = await execAsync(escapedCmd);
    log.info('clip command execution time ', Date.now() - startTime);
    log.info('clip command stdout ', stdout);
    log.info('clip command stderr ', stderr);
    const embeddings = JSON.parse(stdout);
    return embeddings;
}
