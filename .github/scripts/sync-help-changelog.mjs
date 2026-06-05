#!/usr/bin/env node

// Prepend a release's notes to the help-site changelog. Run by app-release.yml's
// promote, with the published release body in RELEASE_BODY.

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../..");

const apps = {
    photos: { changelog: "docs/docs/photos/changelog.md", label: "mobile" },
    "photos-desktop": { changelog: "docs/docs/photos/changelog.md", label: "desktop" },
    auth: { changelog: "docs/docs/auth/changelog.md", label: undefined },
    locker: { changelog: "docs/docs/locker/changelog.md", label: "mobile" },
    ensu: { changelog: "docs/docs/ensu/changelog.md", label: undefined },
};

const [app, version] = process.argv.slice(2);
const config = apps[app];
if (!config || !version) {
    throw new Error(`Usage: RELEASE_BODY=... node .github/scripts/sync-help-changelog.mjs ${Object.keys(apps).join("|")} <version>`);
}

const file = path.join(root, config.changelog);
const content = fs.readFileSync(file, "utf8");

const heading = `## v${version}${config.label ? ` (${config.label})` : ""}`;
if (content.includes(`${heading} - `)) {
    console.log(`${config.changelog} already has ${heading}`);
    process.exit(0);
}

const date = new Date().toLocaleString("en-US", { month: "short", year: "numeric", timeZone: "UTC" });
const body = (process.env.RELEASE_BODY ?? "").trim();
const section = `${heading} - ${date}\n\n${body}\n`;

const at = content.search(/^## v/m);
if (at < 0) throw new Error(`No "## v" entry to insert before in ${config.changelog}`);

fs.writeFileSync(file, `${content.slice(0, at)}${section}\n${content.slice(at)}`);
