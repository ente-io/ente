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
if (!config.tauri && config.bundle && typeof config.bundle === "object") {
    config.bundle.createUpdaterArtifacts = true;
}

if (pubkey) {
    if (config.tauri && typeof config.tauri === "object") {
        config.tauri.updater = {
            ...(config.tauri.updater || {}),
            active: true,
            dialog: false,
            pubkey,
            endpoints: [endpoint],
        };
    } else {
        config.plugins = config.plugins || {};
        config.plugins.updater = {
            ...(config.plugins.updater || {}),
            pubkey,
            endpoints: [endpoint],
        };
    }
    console.log(`Enabled updater config in ${configPath}`);
} else {
    console.log(
        `No updater key configured for ${configPath}; leaving updater config unchanged`,
    );
}

fs.writeFileSync(configPath, JSON.stringify(config, null, 2));
