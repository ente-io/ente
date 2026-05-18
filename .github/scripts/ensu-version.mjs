#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../..");
const files = {
    packageJson: path.join(root, "rust/apps/ensu/package.json"),
    tauri: path.join(root, "rust/apps/ensu/src-tauri/tauri.conf.json"),
    cargoToml: path.join(root, "rust/apps/ensu/src-tauri/Cargo.toml"),
    cargoLock: path.join(root, "rust/apps/ensu/src-tauri/Cargo.lock"),
    android: path.join(root, "mobile/native/android/apps/ensu/app-ui/build.gradle.kts"),
    xcode: path.join(root, "mobile/native/darwin/Apps/Ensu/Ensu.xcodeproj/project.pbxproj"),
    plist: path.join(root, "mobile/native/darwin/Apps/Ensu/Ensu/Info.plist"),
};

function read(file) {
    return fs.readFileSync(file, "utf8");
}

function write(file, text) {
    fs.writeFileSync(file, text);
}

function trimVersion(version) {
    const match = /^(\d+\.\d+\.\d+)(-beta)?$/.exec(version);
    if (!match) throw new Error(`Invalid Ensu version: ${version}`);
    return match[1];
}

function sourceVersion() {
    return JSON.parse(read(files.packageJson)).version;
}

function value(file, regex) {
    return read(file).match(regex)?.[1];
}

function replace(file, regex, replacement) {
    const text = read(file);
    let count = 0;
    const next = text.replace(regex, (...args) => {
        count += 1;
        return typeof replacement === "function" ? replacement(...args) : replacement;
    });
    if (!count) throw new Error(`No match in ${path.relative(root, file)}`);
    write(file, next);
}

function expect(label, actual, wanted) {
    if (actual !== wanted) throw new Error(`${label}: expected ${wanted}, found ${actual}`);
}

function check() {
    const version = sourceVersion();
    const releaseVersion = trimVersion(version);

    expect("tauri.conf.json", JSON.parse(read(files.tauri)).package?.version, version);
    expect("Cargo.toml", value(files.cargoToml, /\[package\][\s\S]*?^version = "([^"]+)"/m), version);
    expect("Cargo.lock", value(files.cargoLock, /\[\[package\]\]\nname = "ensu-tauri"\nversion = "([^"]+)"/), version);
    expect("Android versionName", value(files.android, /versionName = "([^"]+)"/), releaseVersion);
    expect("Info.plist", value(files.plist, /<key>CFBundleShortVersionString<\/key>\s*<string>([^<]+)<\/string>/), releaseVersion);

    const xcodeMarketingVersions = [...read(files.xcode).matchAll(/MARKETING_VERSION = ([^;]+);/g)];
    if (!xcodeMarketingVersions.length) throw new Error("Xcode MARKETING_VERSION: no entries found");
    for (const match of xcodeMarketingVersions) {
        expect("Xcode MARKETING_VERSION", match[1], releaseVersion);
    }
}

function setVersion(version) {
    const releaseVersion = trimVersion(version);

    const packageJson = JSON.parse(read(files.packageJson));
    packageJson.version = version;
    write(files.packageJson, `${JSON.stringify(packageJson, null, 2)}\n`);

    replace(files.tauri, /("package"\s*:\s*\{[\s\S]*?"version"\s*:\s*")[^"]+(")/, (_m, a, b) => `${a}${version}${b}`);
    replace(files.cargoToml, /(\[package\][\s\S]*?^version = ")[^"]+(")/m, (_m, a, b) => `${a}${version}${b}`);
    replace(files.cargoLock, /(\[\[package\]\]\nname = "ensu-tauri"\nversion = ")[^"]+(")/, (_m, a, b) => `${a}${version}${b}`);
    replace(files.android, /versionName = "[^"]+"/, `versionName = "${releaseVersion}"`);
    replace(files.xcode, /MARKETING_VERSION = [^;]+;/g, `MARKETING_VERSION = ${releaseVersion};`);
    replace(files.plist, /(<key>CFBundleShortVersionString<\/key>\s*<string>)[^<]+(<\/string>)/, (_m, a, b) => `${a}${releaseVersion}${b}`);
}

function usage() {
    console.error(`Usage:
  node .github/scripts/ensu-version.mjs get
  node .github/scripts/ensu-version.mjs set 0.1.16-beta
  node .github/scripts/ensu-version.mjs set 0.1.16`);
}

const [command = "get", ...args] = process.argv.slice(2);

try {
    if (command === "get") {
        check();
        console.log(sourceVersion());
    } else if (command === "set") {
        setVersion(args[0]);
        check();
    } else {
        usage();
        process.exit(2);
    }
} catch (error) {
    console.error(error.message);
    process.exit(1);
}
