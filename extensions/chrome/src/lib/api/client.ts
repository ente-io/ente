/**
 * API client for Ente endpoints.
 */
import { localStorage } from "../storage";

const DEFAULT_API_ENDPOINT = "https://api.ente.io";
const ALLOWED_API_HOSTS = new Set(["api.ente.io", "localhost"]);

const isAllowedCustomEndpoint = (url: string | undefined): boolean => {
  if (!url) return false;
  try {
    const parsed = new URL(url);
    const isHttps = parsed.protocol === "https:";
    const isLocalhost = parsed.hostname === "localhost";
    const isHttpLocal = parsed.protocol === "http:" && isLocalhost;
    const portOk =
      !parsed.port ||
      parsed.port === "8080" ||
      parsed.port === "80" ||
      parsed.port === "443";
    if (!ALLOWED_API_HOSTS.has(parsed.hostname)) return false;
    if (isHttps && portOk) return true;
    if (isHttpLocal && portOk) return true;
    return false;
  } catch {
    return false;
  }
};

/**
 * Get the API endpoint to use.
 */
export const getApiEndpoint = async (): Promise<string> => {
  const custom = await localStorage.getCustomApiEndpoint();
  if (isAllowedCustomEndpoint(custom)) {
    return custom!;
  }
  if (custom) {
    console.warn("Ignoring disallowed custom API endpoint", custom);
  }
  return DEFAULT_API_ENDPOINT;
};

/**
 * HTTP error with status code.
 */
export class HTTPError extends Error {
  constructor(
    public status: number,
    message: string,
  ) {
    super(message);
    this.name = "HTTPError";
  }
}

/**
 * Unauthorized error (401).
 */
export class UnauthorizedError extends HTTPError {
  constructor(message = "Unauthorized") {
    super(401, message);
    this.name = "UnauthorizedError";
  }
}

/**
 * Make an API request.
 */
export const apiRequest = async <T>(
  path: string,
  options: RequestInit = {},
  token?: string,
): Promise<T> => {
  const endpoint = await getApiEndpoint();
  const url = `${endpoint}${path}`;

  const headers: HeadersInit = {
    "Content-Type": "application/json",
    "X-Client-Package": "io.ente.auth.extension",
    ...(options.headers || {}),
  };

  if (token) {
    (headers as Record<string, string>)["X-Auth-Token"] = token;
  }

  const response = await fetch(url, {
    ...options,
    headers,
  });

  if (!response.ok) {
    if (response.status === 401) {
      throw new UnauthorizedError();
    }
    const text = await response.text().catch(() => "Unknown error");
    throw new HTTPError(response.status, text);
  }

  // Handle empty responses
  const text = await response.text();
  if (!text) {
    return {} as T;
  }

  return JSON.parse(text) as T;
};

/**
 * Make an authenticated API request.
 */
export const authenticatedRequest = async <T>(
  path: string,
  options: RequestInit = {},
): Promise<T> => {
  const user = await localStorage.getUser();
  if (!user?.token) {
    throw new UnauthorizedError("Not logged in");
  }
  return apiRequest<T>(path, options, user.token);
};

/**
 * Make an API request without authentication.
 * Similar to apiRequest but explicitly without token.
 */
export const apiRequestNoAuth = async <T>(
  path: string,
  options: RequestInit = {},
): Promise<T> => {
  const endpoint = await getApiEndpoint();
  const url = `${endpoint}${path}`;

  const headers: HeadersInit = {
    "Content-Type": "application/json",
    "X-Client-Package": "io.ente.auth.extension",
    ...(options.headers || {}),
  };

  const response = await fetch(url, {
    ...options,
    headers,
  });

  if (!response.ok) {
    const text = await response.text().catch(() => "Unknown error");
    throw new HTTPError(response.status, `${response.status}: ${text}`);
  }

  // Handle empty responses
  const text = await response.text();
  if (!text) {
    return {} as T;
  }

  return JSON.parse(text) as T;
};

/**
 * Build URL with query parameters.
 */
export const buildUrl = (
  path: string,
  params: Record<string, string | number | undefined>,
): string => {
  const searchParams = new URLSearchParams();
  for (const [key, value] of Object.entries(params)) {
    if (value !== undefined) {
      searchParams.set(key, String(value));
    }
  }
  const queryString = searchParams.toString();
  return queryString ? `${path}?${queryString}` : path;
};
