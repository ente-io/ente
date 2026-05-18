const { execSync } = require("child_process");

const log = (message) => console.log(`\n${message}`);

const fail = (message) => {
    console.error(message);
    process.exit(1);
};

const run = (command) => execSync(command, { stdio: "inherit" });

const platform = () => {
    switch (process.platform) {
        case "darwin":
            return "mac";
        case "win32":
            return "windows";
        default:
            return "linux";
    }
};

const setEnv = (name, value) => {
    if (value) process.env[name] = value;
};

if (!process.env.GH_TOKEN) fail("GH_TOKEN is not set");

const target = platform();

if (target == "mac") {
    setEnv("CSC_LINK", process.env.MAC_CERTS);
    setEnv("CSC_KEY_PASSWORD", process.env.MAC_CERTS_PASSWORD);
}

process.env.ADBLOCK = "true";

log("Installing dependencies...");
run("yarn");

log("Running the build script...");
run("yarn run build:ci");

log("Building and releasing the Electron app...");
run(`yarn run electron-builder --${target} --publish always`);
