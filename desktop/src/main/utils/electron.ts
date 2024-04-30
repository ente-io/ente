import shellescape from "any-shell-escape";
import { app } from "electron/main";
import { exec } from "node:child_process";
import path from "node:path";
import { promisify } from "node:util";
import log from "../log";

/** `true` if the app is running in development mode. */
export const isDev = !app.isPackaged;

/**
 * Convert a file system {@link filePath} that uses the local system specific
 * path separators into a path that uses POSIX file separators.
 */
export const posixPath = (filePath: string) =>
    filePath.split(path.sep).join(path.posix.sep);

/**
 * Run a shell command asynchronously.
 *
 * This is a convenience promisified version of child_process.exec. It runs the
 * command asynchronously and returns its stdout and stderr if there were no
 * errors.
 *
 * If the command is passed as a string, then it will be executed verbatim.
 *
 * If the command is passed as an array, then the first argument will be treated
 * as the executable and the remaining (optional) items as the command line
 * parameters. This function will shellescape and join the array to form the
 * command that finally gets executed.
 *
 * > Note: This is not a 1-1 replacement of child_process.exec - if you're
 * > trying to run a trivial shell command, say something that produces a lot of
 * > output, this might not be the best option and it might be better to use the
 * > underlying functions.
 */
export const execAsync = (command: string | string[]) => {
    const escapedCommand = Array.isArray(command)
        ? shellescape(command)
        : command;
    const startTime = Date.now();
    const result = execAsync_(escapedCommand);
    log.debug(
        () => `${escapedCommand} (${Math.round(Date.now() - startTime)} ms)`,
    );
    return result;
};

const execAsync_ = promisify(exec);
