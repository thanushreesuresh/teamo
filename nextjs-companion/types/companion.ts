// ─── Companion Mode Types ────────────────────────────────────────────────────

/** Partner communication style, stored in DB as JSONB */
export interface StyleSummary {
  avg_length: 'short' | 'medium' | 'long';
  emoji_usage: 'low' | 'medium' | 'high';
  tone: 'playful' | 'calm' | 'serious';
  response_speed: 'fast' | 'slow';
}

/** A single message in the companion chat thread */
export interface CompanionMessage {
  id: string;
  role: 'user' | 'assistant';
  content: string;
  timestamp: Date;
}

/** Request body sent from client to /api/ai-companion */
export interface CompanionRequest {
  message: string;
  /** Optional mood string, e.g. "anxious", "happy", "sad" */
  mood?: string;
}

/** Successful response from /api/ai-companion */
export interface CompanionResponse {
  reply: string;
  /** Always shown in UI — reminds user this is AI, not their partner */
  disclaimer: string;
}

/** Error response shape */
export interface CompanionError {
  error: string;
  code: 'UNAUTHORIZED' | 'RATE_LIMITED' | 'PARTNER_ACTIVE' | 'GENERATION_FAILED' | 'INVALID_INPUT';
}
