import fs from "node:fs";

const configPath =
    process.env.ENSU_TAURI_CONFIG_PATH ??
    "rust/apps/ensu/src-tauri/tauri.conf.json";

const endpoint = process.env.AZURE_ENDPOINT;
const accountName = process.env.AZURE_CODE_SIGNING_NAME;
const profileName = process.env.AZURE_CERT_PROFILE_NAME;

if (!endpoint || !accountName || !profileName) {
    throw new Error(
        "AZURE_ENDPOINT, AZURE_CODE_SIGNING_NAME, and AZURE_CERT_PROFILE_NAME are required",
    );
}

const config = JSON.parse(fs.readFileSync(configPath, "utf8"));
config.bundle = config.bundle || {};
config.bundle.windows = config.bundle.windows || {};
config.bundle.windows.signCommand = `trusted-signing-cli -e ${endpoint} -a ${accountName} -c ${profileName} -d Ensu "%1"`;

fs.writeFileSync(configPath, JSON.stringify(config, null, 2));
console.log(`Updated windows signCommand in ${configPath}`);
