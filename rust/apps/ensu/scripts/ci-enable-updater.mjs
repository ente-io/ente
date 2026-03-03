import fs from "node:fs";

const configPath =
    process.env.ENSU_TAURI_CONFIG_PATH ??
    "rust/apps/ensu/src-tauri/tauri.conf.json";

const pubkey = process.env.ENSU_TAURI_UPDATER_PUBKEY;
const endpoint = (
    process.env.ENSU_TAURI_UPDATER_ENDPOINT ||
    "https://ente.io/release-info/ensu-desktop.json"
).trim();

if (!pubkey) {
    throw new Error("ENSU_TAURI_UPDATER_PUBKEY is required");
}

const config = JSON.parse(fs.readFileSync(configPath, "utf8"));
config.bundle = config.bundle || {};
config.bundle.createUpdaterArtifacts = true;
config.plugins = config.plugins || {};
config.plugins.updater = {
    pubkey,
    endpoints: [endpoint],
};

fs.writeFileSync(configPath, JSON.stringify(config, null, 2));
console.log(`Enabled updater in ${configPath}`);
