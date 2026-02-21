/**
 * In-memory rate limiter for the AI Companion API route.
 *
 * Limits: MAX_REQUESTS per WINDOW_MS per userId.
 *
 * For production with multiple instances, swap the Map
 * for a Redis store (e.g. @upstash/ratelimit).
 */

const MAX_REQUESTS = 20;          // max messages per window
const WINDOW_MS    = 60 * 60 * 1000; // 1 hour rolling window

interface RateLimitEntry {
  timestamps: number[];
}

// Module-scoped store — survives across requests within the same process
const store = new Map<string, RateLimitEntry>();

/** Purge stale entries to prevent unbounded memory growth */
function purgeStale(): void {
  const cutoff = Date.now() - WINDOW_MS;
  for (const [key, entry] of store.entries()) {
    entry.timestamps = entry.timestamps.filter((t) => t > cutoff);
    if (entry.timestamps.length === 0) store.delete(key);
  }
}

/**
 * Returns `{ allowed: true }` when the user is under the rate limit,
 * or `{ allowed: false, retryAfterMs }` when they are over it.
 */
export function checkRateLimit(userId: string): {
  allowed: boolean;
  retryAfterMs?: number;
  remaining?: number;
} {
  purgeStale();

  const now    = Date.now();
  const cutoff = now - WINDOW_MS;
  const entry  = store.get(userId) ?? { timestamps: [] };

  // Only keep timestamps within the current window
  entry.timestamps = entry.timestamps.filter((t) => t > cutoff);

  if (entry.timestamps.length >= MAX_REQUESTS) {
    const oldest       = entry.timestamps[0];
    const retryAfterMs = oldest + WINDOW_MS - now;
    return { allowed: false, retryAfterMs };
  }

  entry.timestamps.push(now);
  store.set(userId, entry);

  return {
    allowed:   true,
    remaining: MAX_REQUESTS - entry.timestamps.length,
  };
}

/** Expose limits for response headers */
export const RATE_LIMIT_MAX    = MAX_REQUESTS;
export const RATE_LIMIT_WINDOW = WINDOW_MS;
