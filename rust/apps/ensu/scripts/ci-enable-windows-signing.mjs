import fs from "node:fs";

const { AZURE_ENDPOINT, AZURE_CODE_SIGNING_NAME, AZURE_CERT_PROFILE_NAME } =
    process.env;

if (!AZURE_ENDPOINT || !AZURE_CODE_SIGNING_NAME || !AZURE_CERT_PROFILE_NAME) {
    throw new Error(
        "AZURE_ENDPOINT, AZURE_CODE_SIGNING_NAME, and AZURE_CERT_PROFILE_NAME are required",
    );
}

const configPath = new URL("../src-tauri/tauri.conf.json", import.meta.url);
const config = JSON.parse(fs.readFileSync(configPath, "utf8"));
config.tauri.bundle.windows = {
    signCommand: `artifact-signing-cli -e ${AZURE_ENDPOINT} -a ${AZURE_CODE_SIGNING_NAME} -c ${AZURE_CERT_PROFILE_NAME} -d Ensu %1`,
};

fs.writeFileSync(configPath, JSON.stringify(config, null, 2));
