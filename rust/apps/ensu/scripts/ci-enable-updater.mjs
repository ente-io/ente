import fs from "node:fs";

const configPath =
    process.env.ENSU_TAURI_CONFIG_PATH ??
    "rust/apps/ensu/src-tauri/tauri.conf.json";

const pubkey = process.env.ENSU_TAURI_UPDATER_PUBKEY?.trim();
const endpoint = (
    process.env.ENSU_TAURI_UPDATER_ENDPOINT ||
    "https://ente.io/release-info/ensu-desktop.json"
).trim();

const config = JSON.parse(fs.readFileSync(configPath, "utf8"));
config.bundle = config.bundle || {};
config.bundle.createUpdaterArtifacts = true;

if (pubkey) {
    config.plugins = config.plugins || {};
    config.plugins.updater = {
        pubkey,
        endpoints: [endpoint],
    };
    console.log(`Enabled updater artifacts + updater plugin config in ${configPath}`);
} else {
    console.log(
        `Enabled updater artifacts in ${configPath} (ENSU_TAURI_UPDATER_PUBKEY not set, leaving updater plugin config unchanged)`,
    );
}

fs.writeFileSync(configPath, JSON.stringify(config, null, 2));
