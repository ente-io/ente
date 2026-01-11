/**
 * Site-to-issuer matching for autofill.
 */
import type { Code } from "../types/code";
import type { SiteMatch } from "../types/messages";

/**
 * Known domain aliases for common services.
 */
const ISSUER_ALIASES: Record<string, string[]> = {
  google: ["google.com", "gmail.com", "accounts.google.com", "youtube.com"],
  github: ["github.com", "gist.github.com"],
  microsoft: [
    "microsoft.com",
    "live.com",
    "outlook.com",
    "office.com",
    "azure.com",
  ],
  amazon: ["amazon.com", "aws.amazon.com", "amazon.co.uk", "amazon.de"],
  facebook: ["facebook.com", "fb.com", "instagram.com", "meta.com"],
  apple: ["apple.com", "icloud.com", "appleid.apple.com"],
  twitter: ["twitter.com", "x.com"],
  discord: ["discord.com", "discordapp.com"],
  slack: ["slack.com"],
  dropbox: ["dropbox.com"],
  paypal: ["paypal.com"],
  coinbase: ["coinbase.com"],
  binance: ["binance.com"],
  kraken: ["kraken.com"],
  reddit: ["reddit.com"],
  linkedin: ["linkedin.com"],
  twitch: ["twitch.tv"],
  steam: ["steampowered.com", "steamcommunity.com"],
  epic: ["epicgames.com"],
  cloudflare: ["cloudflare.com", "dash.cloudflare.com"],
  digitalocean: ["digitalocean.com", "cloud.digitalocean.com"],
  heroku: ["heroku.com"],
  netlify: ["netlify.com", "app.netlify.com"],
  vercel: ["vercel.com"],
  stripe: ["stripe.com", "dashboard.stripe.com"],
  gitlab: ["gitlab.com"],
  bitbucket: ["bitbucket.org"],
  atlassian: ["atlassian.com", "atlassian.net"],
  jira: ["atlassian.net"],
  npm: ["npmjs.com"],
  docker: ["docker.com", "hub.docker.com"],
  godaddy: ["godaddy.com"],
  namecheap: ["namecheap.com"],
  zoho: ["zoho.com", "zoho.eu"],
  protonmail: ["protonmail.com", "proton.me"],
  tutanota: ["tutanota.com", "tuta.io"],
  fastmail: ["fastmail.com"],
  hover: ["hover.com"],
  nvidia: ["nvidia.com"],
};

/**
 * Extract base domain from hostname.
 * e.g., "accounts.google.com" -> "google.com"
 */
const extractBaseDomain = (hostname: string): string => {
  const parts = hostname.split(".");
  if (parts.length <= 2) return hostname;

  // Handle known TLDs like .co.uk
  const knownTLDs = [".co.uk", ".com.au", ".co.nz", ".co.jp"];
  for (const tld of knownTLDs) {
    if (hostname.endsWith(tld)) {
      return parts.slice(-3).join(".");
    }
  }

  return parts.slice(-2).join(".");
};

/**
 * Calculate Levenshtein distance between two strings.
 */
const levenshtein = (a: string, b: string): number => {
  const m = a.length;
  const n = b.length;

  if (m === 0) return n;
  if (n === 0) return m;

  const dp: number[][] = Array(m + 1)
    .fill(null)
    .map(() => Array(n + 1).fill(0));

  for (let i = 0; i <= m; i++) dp[i][0] = i;
  for (let j = 0; j <= n; j++) dp[0][j] = j;

  for (let i = 1; i <= m; i++) {
    for (let j = 1; j <= n; j++) {
      const cost = a[i - 1] === b[j - 1] ? 0 : 1;
      dp[i][j] = Math.min(
        dp[i - 1][j] + 1,
        dp[i][j - 1] + 1,
        dp[i - 1][j - 1] + cost,
      );
    }
  }

  return dp[m][n];
};

/**
 * Match codes to the current site URL.
 *
 * @param codes - All available codes
 * @param url - Current page URL
 * @returns Matched codes sorted by relevance
 */
export const matchCodesToSite = (codes: Code[], url: string): SiteMatch[] => {
  let hostname: string;
  try {
    hostname = new URL(url).hostname.toLowerCase();
  } catch {
    return [];
  }

  const baseDomain = extractBaseDomain(hostname);

  const matches: SiteMatch[] = [];

  for (const code of codes) {
    const issuer = code.issuer.toLowerCase();
    const issuerClean = issuer.replace(/[^a-z0-9]/g, "");

    // Exact match: hostname contains issuer or issuer contains base domain
    if (
      hostname.includes(issuerClean) ||
      issuerClean.includes(baseDomain.replace(/\./g, ""))
    ) {
      matches.push({ code, score: 100, matchType: "exact" });
      continue;
    }

    // Alias match: check known aliases
    const aliases = ISSUER_ALIASES[issuerClean];
    if (aliases?.some((alias) => hostname.includes(alias.split(".")[0]))) {
      matches.push({ code, score: 90, matchType: "alias" });
      continue;
    }

    // Check if any alias domain matches the current hostname
    for (const [key, domainAliases] of Object.entries(ISSUER_ALIASES)) {
      if (domainAliases.some((d) => hostname.endsWith(d))) {
        if (issuerClean.includes(key) || key.includes(issuerClean)) {
          matches.push({ code, score: 85, matchType: "alias" });
          break;
        }
      }
    }

    // Skip if already added
    if (matches.some((m) => m.code.id === code.id)) {
      continue;
    }

    // Domain match: check if issuer looks like a domain
    if (issuer.includes(".")) {
      const issuerDomain = extractBaseDomain(issuer);
      if (baseDomain === issuerDomain) {
        matches.push({ code, score: 80, matchType: "domain" });
        continue;
      }
    }

    // Fuzzy match: Levenshtein distance
    const distance = levenshtein(issuerClean, baseDomain.replace(/\./g, ""));
    if (distance <= 3 && distance < issuerClean.length / 2) {
      matches.push({
        code,
        score: 70 - distance * 10,
        matchType: "fuzzy",
      });
    }
  }

  // Sort by pinned first, then by score
  return matches.sort((a, b) => {
    // Pinned codes first
    if (a.code.codeDisplay?.pinned && !b.code.codeDisplay?.pinned) return -1;
    if (!a.code.codeDisplay?.pinned && b.code.codeDisplay?.pinned) return 1;
    // Then by score
    return b.score - a.score;
  });
};

/**
 * Get known domains for an issuer (for phishing detection).
 */
export const getKnownDomainsForIssuer = (issuer: string): string[] => {
  const issuerClean = issuer.toLowerCase().replace(/[^a-z0-9]/g, "");
  return ISSUER_ALIASES[issuerClean] || [];
};

/**
 * Check if a URL might be a phishing attempt.
 */
export interface PhishingCheck {
  isPhishing: boolean;
  warning?: string;
  expectedDomains?: string[];
}

export const checkPhishing = (url: string, issuer: string): PhishingCheck => {
  let hostname: string;
  try {
    hostname = new URL(url).hostname.toLowerCase();
  } catch {
    return { isPhishing: false };
  }

  const expectedDomains = getKnownDomainsForIssuer(issuer);
  if (expectedDomains.length === 0) {
    // No known domains for this issuer
    return { isPhishing: false };
  }

  const matches = expectedDomains.some(
    (domain) => hostname === domain || hostname.endsWith("." + domain),
  );

  if (!matches) {
    return {
      isPhishing: true,
      warning: `This site doesn't match known domains for ${issuer}`,
      expectedDomains,
    };
  }

  return { isPhishing: false };
};
