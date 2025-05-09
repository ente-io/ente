import shellescape from "any-shell-escape";
import { exec } from "node:child_process";
import { promisify } from "node:util";
import log from "../log-worker";

/**
 * Run a shell command asynchronously (utility process edition).
 *
 * This is an almost verbatim copy of {@link execAsync} from `electron.ts`,
 * except it is meant to be usable from a utility process where only a subset of
 * imports are available. See [Note: Using Electron APIs in UtilityProcess].
 */
export const execAsyncWorker = async (command: string | string[]) => {
    const escapedCommand = Array.isArray(command)
        ? shellescape(command)
        : command;
    const startTime = Date.now();
    const result = await execAsync_(escapedCommand);
    log.debugString(`${escapedCommand} (${Date.now() - startTime} ms)`);
    return result;
};

const execAsync_ = promisify(exec);
