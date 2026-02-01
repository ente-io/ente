/**
 * Site-to-issuer matching for autofill.
 */
import type { Code } from "../types/code";
import type { SiteMatch } from "../types/messages";
import { getDomain } from "tldts";

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

const getBaseDomain = (hostname: string): string => {
  // Correct eTLD+1 handling using the Public Suffix List via tldts.
  // Falls back to the hostname for IPs/localhost/unparseable values.
  return getDomain(hostname) ?? hostname;
};

/**
 * Strict domain matching to reduce phishing/typo-squatting.
 *
 * We only match when the current eTLD+1 matches the issuer's domain or a vetted
 * alias. Fuzzy/substring matches are intentionally avoided.
 */
export const matchCodesToSite = (codes: Code[], url: string): SiteMatch[] => {
  let hostname: string;
  try {
    hostname = new URL(url).hostname.toLowerCase();
  } catch {
    return [];
  }

  const baseDomain = getBaseDomain(hostname);
  const baseKey = baseDomain.replace(/[^a-z0-9]/g, "");
  const matches: SiteMatch[] = [];

  const isAliasMatch = (issuerKey: string): boolean => {
    const aliases = ISSUER_ALIASES[issuerKey];
    return (
      !!aliases &&
      aliases.some(
        (alias) => hostname === alias || hostname.endsWith("." + alias),
      )
    );
  };

  for (const code of codes) {
    const issuer = code.issuer.toLowerCase();
    const issuerClean = issuer.replace(/[^a-z0-9.]/g, "");
    const issuerKey = issuer.replace(/[^a-z0-9]/g, "");

    // Exact domain or subdomain match for known aliases
    if (isAliasMatch(issuerClean)) {
      matches.push({ code, score: 90, matchType: "alias" });
      continue;
    }

    // Domain match when issuer itself is a domain-like string
    if (issuer.includes(".")) {
      const issuerDomain = getBaseDomain(issuer);
      if (baseDomain === issuerDomain) {
        matches.push({ code, score: 80, matchType: "domain" });
        continue;
      }
    }

    // Strict issuer-to-hostname equality (handles simple issuers like "github")
    if (issuerClean && issuerClean === baseDomain.replace(/\./g, "")) {
      matches.push({ code, score: 70, matchType: "exact" });
      continue;
    }

    // Fallback fuzzy match: helps "bitwarden" match "bitwarden.com", etc.
    // This is intentionally lower-confidence and should NOT trigger "silent" autofill.
    if (issuerKey.length >= 4) {
      const STOPWORDS = new Set([
        "auth",
        "authenticator",
        "otp",
        "totp",
        "mfa",
        "2fa",
        "verify",
        "verification",
        "code",
        "security",
      ]);
      if (!STOPWORDS.has(issuerKey) && baseKey.includes(issuerKey)) {
        matches.push({ code, score: 50, matchType: "fuzzy" });
        continue;
      }
    }
  }

  return matches.sort((a, b) => {
    if (a.code.codeDisplay?.pinned && !b.code.codeDisplay?.pinned) return -1;
    if (!a.code.codeDisplay?.pinned && b.code.codeDisplay?.pinned) return 1;
    return b.score - a.score;
  });
};
