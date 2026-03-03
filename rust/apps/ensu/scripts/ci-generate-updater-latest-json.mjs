import fs from "node:fs";

const token = process.env.GH_TOKEN || process.env.GITHUB_TOKEN;
const repo = process.env.GH_REPO;
const tag = process.env.RELEASE_TAG;
const version = process.env.ENSU_UPDATER_VERSION;
const outputPath = process.env.ENSU_UPDATER_LATEST_JSON_PATH || "/tmp/ensu-latest.json";

if (!token) throw new Error("Missing GH_TOKEN/GITHUB_TOKEN");
if (!repo) throw new Error("Missing GH_REPO");
if (!tag) throw new Error("Missing RELEASE_TAG");
if (!version) throw new Error("Missing ENSU_UPDATER_VERSION");

const apiHeaders = {
    Authorization: `token ${token}`,
    Accept: "application/vnd.github+json",
};

const releaseRes = await fetch(
    `https://api.github.com/repos/${repo}/releases/tags/${tag}`,
    {
        headers: apiHeaders,
    },
);

if (!releaseRes.ok) {
    throw new Error(
        `Failed to fetch release: ${releaseRes.status} ${releaseRes.statusText}`,
    );
}

const release = await releaseRes.json();
const assets = release.assets || [];
const assetByName = new Map(assets.map((asset) => [asset.name, asset]));
const bundleAssets = assets.filter((asset) => !asset.name.endsWith(".sig"));

const findAsset = (patterns) => {
    for (const pattern of patterns) {
        const match = bundleAssets.find((asset) => pattern.test(asset.name));
        if (match) return match;
    }
    return undefined;
};

const fetchSignature = async (signatureAsset) => {
    const signatureRes = await fetch(signatureAsset.url, {
        headers: {
            Authorization: `token ${token}`,
            Accept: "application/octet-stream",
        },
    });

    if (!signatureRes.ok) {
        throw new Error(
            `Failed to fetch ${signatureAsset.name}: ${signatureRes.status} ${signatureRes.statusText}`,
        );
    }

    return (await signatureRes.text()).trim();
};

const urlPrefix = (
    process.env.ENSU_UPDATER_URL_PREFIX ||
    `https://github.com/${repo}/releases/download/${tag}`
).replace(/\/$/, "");

const platforms = {};

const addPlatform = async (key, asset) => {
    if (!asset || platforms[key]) return;
    const signatureAsset = assetByName.get(`${asset.name}.sig`);
    if (!signatureAsset) return;

    platforms[key] = {
        url: `${urlPrefix}/${asset.name}`,
        signature: await fetchSignature(signatureAsset),
    };
};

const linuxX64 = findAsset([
    /(?:amd64|x86_64)\.AppImage$/i,
    /(?:amd64|x86_64)\.deb$/i,
    /x86_64\.rpm$/i,
]);
const linuxAarch64 = findAsset([
    /(?:aarch64|arm64)\.AppImage$/i,
    /(?:aarch64|arm64)\.deb$/i,
    /aarch64\.rpm$/i,
]);
const windowsX64 = findAsset([
    /x64-setup(?:-machine)?\.exe$/i,
    /x64.*\.exe$/i,
    /x64.*\.msi$/i,
]);
const darwinX64 = findAsset([
    /(?:x64|x86_64)\.app\.tar\.gz$/i,
    /universal\.app\.tar\.gz$/i,
]);
const darwinAarch64 = findAsset([
    /(?:aarch64|arm64)\.app\.tar\.gz$/i,
    /universal\.app\.tar\.gz$/i,
]);

await addPlatform("linux-x86_64", linuxX64);
await addPlatform("linux-aarch64", linuxAarch64);
await addPlatform("windows-x86_64", windowsX64);
await addPlatform("darwin-x86_64", darwinX64);
await addPlatform("darwin-aarch64", darwinAarch64);

if (Object.keys(platforms).length === 0) {
    throw new Error("No updater platforms found from release assets");
}

const latest = {
    version,
    notes: "",
    pub_date: new Date().toISOString(),
    platforms,
};

fs.writeFileSync(outputPath, JSON.stringify(latest, null, 2));
console.log(
    `Generated ${outputPath} with platforms: ${Object.keys(platforms).join(", ")}`,
);
