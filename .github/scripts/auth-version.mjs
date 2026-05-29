#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../..");
const pubspec = path.join(root, "mobile/apps/auth/pubspec.yaml");

function read() {
    return fs.readFileSync(pubspec, "utf8");
}

function write(text) {
    fs.writeFileSync(pubspec, text);
}

function pubspecVersion() {
    const match = read().match(/^version:\s*(\d+\.\d+\.\d+)\+(\d+)$/m);
    if (!match) throw new Error("Invalid Auth pubspec version");
    return { source: match[1], buildBase: match[2] };
}

function setPubspecVersion(version) {
    const text = read();
    let count = 0;
    const next = text.replace(/^version:\s*\S+/m, () => {
        count += 1;
        return `version: ${version}`;
    });
    if (!count) throw new Error("No version field found in mobile/apps/auth/pubspec.yaml");
    write(next);
}

function usage() {
    console.error(`Usage:
  node .github/scripts/auth-version.mjs get
  node .github/scripts/auth-version.mjs get-build-base
  node .github/scripts/auth-version.mjs set 4.4.23
  node .github/scripts/auth-version.mjs set-build 4.4.23 1007`);
}

const [command = "get", ...args] = process.argv.slice(2);

try {
    if (command === "get") {
        console.log(pubspecVersion().source);
    } else if (command === "get-build-base") {
        console.log(pubspecVersion().buildBase);
    } else if (command === "set") {
        if (!/^\d+\.\d+\.\d+$/.test(args[0])) throw new Error(`Invalid Auth version: ${args[0]}`);
        setPubspecVersion(`${args[0]}+${pubspecVersion().buildBase}`);
    } else if (command === "set-build") {
        if (!/^\d+\.\d+\.\d+$/.test(args[0])) throw new Error(`Invalid Auth release version: ${args[0]}`);
        if (!/^\d+$/.test(args[1])) throw new Error(`Invalid Auth build number: ${args[1]}`);
        setPubspecVersion(`${args[0]}+${args[1]}`);
    } else {
        usage();
        process.exit(2);
    }
} catch (error) {
    console.error(error.message);
    process.exit(1);
}
