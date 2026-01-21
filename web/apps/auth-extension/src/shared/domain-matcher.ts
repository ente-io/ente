/**
 * Domain matching utilities for matching websites to stored auth codes.
 */
import type { Code, DomainMatch } from "./types";

/**
 * Known domain mappings for common services.
 * Maps issuer names to their associated domains.
 */
const KNOWN_DOMAIN_MAPPINGS: Record<string, string[]> = {
    google: [
        "google.com",
        "gmail.com",
        "youtube.com",
        "accounts.google.com",
        "myaccount.google.com",
    ],
    github: ["github.com", "github.io", "githubusercontent.com"],
    microsoft: [
        "microsoft.com",
        "live.com",
        "outlook.com",
        "office.com",
        "azure.com",
        "xbox.com",
    ],
    amazon: ["amazon.com", "amazon.co.uk", "amazon.de", "aws.amazon.com"],
    aws: ["aws.amazon.com", "console.aws.amazon.com", "signin.aws.amazon.com"],
    facebook: ["facebook.com", "fb.com", "messenger.com", "instagram.com"],
    instagram: ["instagram.com"],
    twitter: ["twitter.com", "x.com"],
    x: ["x.com", "twitter.com"],
    apple: ["apple.com", "icloud.com", "appleid.apple.com"],
    dropbox: ["dropbox.com"],
    discord: ["discord.com", "discord.gg"],
    slack: ["slack.com"],
    linkedin: ["linkedin.com"],
    reddit: ["reddit.com"],
    twitch: ["twitch.tv"],
    steam: ["steampowered.com", "steamcommunity.com", "store.steampowered.com"],
    paypal: ["paypal.com"],
    stripe: ["stripe.com", "dashboard.stripe.com"],
    digitalocean: ["digitalocean.com", "cloud.digitalocean.com"],
    cloudflare: ["cloudflare.com", "dash.cloudflare.com"],
    netlify: ["netlify.com", "netlify.app"],
    vercel: ["vercel.com"],
    heroku: ["heroku.com", "herokucdn.com"],
    bitbucket: ["bitbucket.org"],
    gitlab: ["gitlab.com"],
    atlassian: ["atlassian.com", "atlassian.net", "jira.com", "confluence.com"],
    jira: ["jira.com", "atlassian.com", "atlassian.net"],
    confluence: ["confluence.com", "atlassian.com", "atlassian.net"],
    notion: ["notion.so", "notion.com"],
    figma: ["figma.com"],
    adobe: ["adobe.com", "creativecloud.adobe.com"],
    spotify: ["spotify.com"],
    coinbase: ["coinbase.com"],
    binance: ["binance.com", "binance.us"],
    kraken: ["kraken.com"],
    bitwarden: ["bitwarden.com", "vault.bitwarden.com"],
    lastpass: ["lastpass.com"],
    "1password": ["1password.com"],
    proton: ["proton.me", "protonmail.com", "protonvpn.com"],
    protonmail: ["proton.me", "protonmail.com"],
    tutanota: ["tutanota.com", "tuta.com"],
    namecheap: ["namecheap.com"],
    godaddy: ["godaddy.com"],
    hover: ["hover.com"],
    gandi: ["gandi.net"],
    npm: ["npmjs.com", "npm.io"],
    pypi: ["pypi.org"],
    docker: ["docker.com", "hub.docker.com"],
    nvidia: ["nvidia.com"],
    epic: ["epicgames.com", "unrealengine.com"],
    ubisoft: ["ubisoft.com", "ubi.com"],
    ea: ["ea.com", "origin.com"],
    blizzard: ["blizzard.com", "battle.net"],
    ente: ["ente.io", "auth.ente.io", "web.ente.io"],
};

/**
 * Calculate Levenshtein distance between two strings.
 */
const levenshteinDistance = (a: string, b: string): number => {
    const matrix: number[][] = [];

    for (let i = 0; i <= b.length; i++) {
        matrix[i] = [i];
    }

    for (let j = 0; j <= a.length; j++) {
        matrix[0]![j] = j;
    }

    for (let i = 1; i <= b.length; i++) {
        for (let j = 1; j <= a.length; j++) {
            if (b.charAt(i - 1) === a.charAt(j - 1)) {
                matrix[i]![j] = matrix[i - 1]![j - 1]!;
            } else {
                matrix[i]![j] = Math.min(
                    matrix[i - 1]![j - 1]! + 1,
                    matrix[i]![j - 1]! + 1,
                    matrix[i - 1]![j]! + 1
                );
            }
        }
    }

    return matrix[b.length]![a.length]!;
};

/**
 * Calculate similarity between two strings (0-1).
 */
const similarity = (a: string, b: string): number => {
    const maxLen = Math.max(a.length, b.length);
    if (maxLen === 0) return 1;
    const distance = levenshteinDistance(a.toLowerCase(), b.toLowerCase());
    return 1 - distance / maxLen;
};

/**
 * Extract the base domain from a hostname.
 * e.g., "accounts.google.com" -> "google.com"
 */
const getBaseDomain = (hostname: string): string => {
    const parts = hostname.split(".");
    if (parts.length <= 2) return hostname;
    return parts.slice(-2).join(".");
};

/**
 * Normalize issuer name for comparison.
 */
const normalizeIssuer = (issuer: string): string => {
    return issuer
        .toLowerCase()
        .replace(/[^a-z0-9]/g, "")
        .trim();
};

/**
 * Match codes to a domain.
 *
 * @param codes The list of codes to search.
 * @param domain The domain to match against.
 * @returns Sorted list of matches with confidence scores.
 */
export const matchCodesToDomain = (
    codes: Code[],
    domain: string
): DomainMatch[] => {
    const hostname = domain.toLowerCase();
    const baseDomain = getBaseDomain(hostname);
    const matches: DomainMatch[] = [];

    for (const code of codes) {
        const issuer = code.issuer.toLowerCase();
        const normalizedIssuer = normalizeIssuer(code.issuer);
        let confidence = 0;

        // 1. Exact match (confidence: 1.0)
        if (issuer === hostname || issuer === baseDomain) {
            confidence = 1.0;
        }
        // 2. Check known mappings
        else {
            // First try exact match on normalized issuer
            let knownDomains = KNOWN_DOMAIN_MAPPINGS[normalizedIssuer];

            // If no exact match, check if issuer contains any known key as a whole word
            // This handles cases like "AWS - Adam" or "Adam's AWS Account"
            // but avoids false matches like "paws" matching "aws"
            if (!knownDomains) {
                const lowerIssuer = code.issuer.toLowerCase();
                for (const [key, domains] of Object.entries(KNOWN_DOMAIN_MAPPINGS)) {
                    // Use word boundary regex to match the key as a whole word
                    const wordBoundaryRegex = new RegExp(`\\b${key}\\b`, "i");
                    if (wordBoundaryRegex.test(lowerIssuer)) {
                        knownDomains = domains;
                        break;
                    }
                }
            }

            if (knownDomains) {
                for (const knownDomain of knownDomains) {
                    const matchesExact = hostname === knownDomain;
                    const matchesSubdomain = hostname.endsWith(`.${knownDomain}`);
                    const matchesBase = baseDomain === knownDomain;
                    if (matchesExact || matchesSubdomain || matchesBase) {
                        confidence = 0.95;
                        break;
                    }
                }
            }
        }

        // 3. Subdomain/partial match (confidence: 0.8)
        if (confidence === 0) {
            if (
                hostname.includes(normalizedIssuer) ||
                normalizedIssuer.includes(baseDomain.split(".")[0]!)
            ) {
                confidence = 0.8;
            }
        }

        // 4. Fuzzy match with Levenshtein (confidence based on similarity)
        if (confidence === 0) {
            const baseDomainName = baseDomain.split(".")[0]!;
            const sim = similarity(normalizedIssuer, baseDomainName);
            if (sim > 0.7) {
                confidence = sim * 0.7; // Scale to max 0.49
            }
        }

        if (confidence > 0) {
            // Boost pinned codes slightly within their tier
            const pinnedBoost = code.codeDisplay?.pinned ? 0.001 : 0;
            matches.push({ code, confidence: confidence + pinnedBoost });
        }
    }

    // Sort by confidence descending
    matches.sort((a, b) => b.confidence - a.confidence);

    return matches;
};

/**
 * Get the best matching code for a domain.
 */
export const getBestMatch = (
    codes: Code[],
    domain: string
): DomainMatch | undefined => {
    const matches = matchCodesToDomain(codes, domain);
    return matches[0];
};

/**
 * Filter codes matching a search query.
 */
export const searchCodes = (codes: Code[], query: string): Code[] => {
    if (!query.trim()) return codes;

    const lowerQuery = query.toLowerCase().trim();

    return codes.filter((code) => {
        const issuerMatch = code.issuer.toLowerCase().includes(lowerQuery);
        const accountMatch = code.account?.toLowerCase().includes(lowerQuery);
        const noteMatch = code.codeDisplay?.note
            ?.toLowerCase()
            .includes(lowerQuery);

        return issuerMatch || accountMatch || noteMatch;
    });
};
