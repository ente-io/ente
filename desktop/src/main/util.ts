import shellescape from "any-shell-escape";
import { shell } from "electron"; /* TODO(MR): Why is this not in /main? */
import { app } from "electron/main";
import { exec } from "node:child_process";
import path from "node:path";
import { promisify } from "node:util";
import log from "./log";

/** `true` if the app is running in development mode. */
export const isDev = !app.isPackaged;

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
    log.debug(() => `Running shell command: ${escapedCommand}`);
    const result = execAsync_(escapedCommand);
    log.debug(
        () =>
            `Completed in ${Math.round(Date.now() - startTime)} ms (${escapedCommand})`,
    );
    return result;
};

const execAsync_ = promisify(exec);

/**
 * Open the given {@link dirPath} in the system's folder viewer.
 *
 * For example, on macOS this'll open {@link dirPath} in Finder.
 */
export const openDirectory = async (dirPath: string) => {
    const res = await shell.openPath(path.normalize(dirPath));
    // shell.openPath resolves with a string containing the error message
    // corresponding to the failure if a failure occurred, otherwise "".
    if (res) throw new Error(`Failed to open directory ${dirPath}: res`);
};

/**
 * Return the path where the logs for the app are saved.
 *
 * [Note: Electron app paths]
 *
 * By default, these paths are at the following locations:
 *
 * - macOS: `~/Library/Application Support/ente`
 * - Linux: `~/.config/ente`
 * - Windows: `%APPDATA%`, e.g. `C:\Users\<username>\AppData\Local\ente`
 * - Windows: C:\Users\<you>\AppData\Local\<Your App Name>
 *
 * https://www.electronjs.org/docs/latest/api/app
 *
 */
const logDirectoryPath = () => app.getPath("logs");

/**
 * Open the app's log directory in the system's folder viewer.
 *
 * @see {@link openDirectory}
 */
export const openLogDirectory = () => openDirectory(logDirectoryPath());
