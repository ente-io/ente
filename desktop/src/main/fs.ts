/**
 * @file file system related functions exposed over the context bridge.
 */
import { existsSync } from "node:fs";
import * as fs from "node:fs/promises";

export const fsExists = (path: string) => existsSync(path);

/* TODO: Audit below this  */

export const checkExistsAndCreateDir = (dirPath: string) =>
    fs.mkdir(dirPath, { recursive: true });
