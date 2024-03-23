/**
 * @file file system related functions exposed over the context bridge.
 */
import { existsSync } from "node:fs";

export const fsExists = (path: string) => existsSync(path);
