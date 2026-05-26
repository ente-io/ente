import fs from "node:fs";

const pubkey = process.env.ENSU_TAURI_UPDATER_PUBKEY?.trim();
if (!pubkey) throw new Error("ENSU_TAURI_UPDATER_PUBKEY is required");

const configPath = new URL("../src-tauri/tauri.conf.json", import.meta.url);
const config = JSON.parse(fs.readFileSync(configPath, "utf8"));
config.tauri.updater.active = true;
config.tauri.updater.pubkey = pubkey;

fs.writeFileSync(configPath, JSON.stringify(config, null, 2));
