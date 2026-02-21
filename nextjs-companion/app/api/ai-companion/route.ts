import { NextRequest, NextResponse } from 'next/server';
import { createServerClient } from '@supabase/ssr';
import { cookies } from 'next/headers';

import { getCompanionModel }           from '../../../lib/ai/gemini';
import {
  SYSTEM_INSTRUCTION,
  buildContextBlock,
  buildPromptParts,
  COMPANION_DISCLAIMER,
}                                       from '../../../lib/ai/prompt-builder';
import {
  checkRateLimit,
  RATE_LIMIT_MAX,
  RATE_LIMIT_WINDOW,
}                                       from '../../../lib/ai/rate-limiter';
import type {
  CompanionRequest,
  CompanionResponse,
  CompanionError,
  StyleSummary,
}                                       from '../../../types/companion';

// ─── Config ──────────────────────────────────────────────────────────────────

/** Partner must have been inactive for at least this many minutes */
const INACTIVITY_THRESHOLD_MINUTES = 10;

// ─── Helper ───────────────────────────────────────────────────────────────────

function errorResponse(
  message: string,
  code: CompanionError['code'],
  status: number,
  headers?: Record<string, string>,
): NextResponse {
  return NextResponse.json<CompanionError>(
    { error: message, code },
    { status, headers },
  );
}

// ─── POST /api/ai-companion ───────────────────────────────────────────────────

export async function POST(req: NextRequest) {
  // ── 1. Parse & validate request body ──────────────────────────────────────
  let body: CompanionRequest;
  try {
    body = await req.json();
  } catch {
    return errorResponse('Invalid JSON body.', 'INVALID_INPUT', 400);
  }

  const userMessage = body.message?.trim();
  if (!userMessage || userMessage.length < 1) {
    return errorResponse('Message is required.', 'INVALID_INPUT', 400);
  }
  if (userMessage.length > 1000) {
    return errorResponse('Message exceeds 1000 characters.', 'INVALID_INPUT', 400);
  }

  const userMood = body.mood?.trim() ?? null;

  // ── 2. Validate Supabase session ───────────────────────────────────────────
  const cookieStore = await cookies();
  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll:    () => cookieStore.getAll(),
        setAll:    (cookiesToSet) => {
          cookiesToSet.forEach(({ name, value, options }) =>
            cookieStore.set(name, value, options),
          );
        },
      },
    },
  );

  const {
    data: { user },
    error: authError,
  } = await supabase.auth.getUser();

  if (authError || !user) {
    return errorResponse('Unauthorized. Please sign in.', 'UNAUTHORIZED', 401);
  }

  // ── 3. Rate limiting ───────────────────────────────────────────────────────
  const rateLimit = checkRateLimit(user.id);
  const rateLimitHeaders: Record<string, string> = {
    'X-RateLimit-Limit':     String(RATE_LIMIT_MAX),
    'X-RateLimit-Window-Ms': String(RATE_LIMIT_WINDOW),
  };

  if (!rateLimit.allowed) {
    return errorResponse(
      `Too many requests. Please wait ${Math.ceil((rateLimit.retryAfterMs ?? 0) / 60_000)} minutes.`,
      'RATE_LIMITED',
      429,
      {
        ...rateLimitHeaders,
        'Retry-After': String(Math.ceil((rateLimit.retryAfterMs ?? 0) / 1000)),
      },
    );
  }

  if (rateLimit.remaining !== undefined) {
    rateLimitHeaders['X-RateLimit-Remaining'] = String(rateLimit.remaining);
  }

  // ── 4. Fetch pair + partner activity ──────────────────────────────────────
  const { data: pair, error: pairError } = await supabase
    .from('pairs')
    .select('id, user1_id, user2_id')
    .or(`user1_id.eq.${user.id},user2_id.eq.${user.id}`)
    .maybeSingle();

  if (pairError || !pair) {
    return errorResponse('No active pair found.', 'UNAUTHORIZED', 403);
  }

  const partnerId =
    pair.user1_id === user.id ? pair.user2_id : pair.user1_id;

  if (!partnerId) {
    return errorResponse('Partner has not joined yet.', 'UNAUTHORIZED', 403);
  }

  // Check partner last_active — must be > INACTIVITY_THRESHOLD_MINUTES ago
  const { data: partnerProfile } = await supabase
    .from('profiles')
    .select('last_active, style_summary')
    .eq('id', partnerId)
    .single();

  if (partnerProfile?.last_active) {
    const lastActive    = new Date(partnerProfile.last_active);
    const diffMinutes   = (Date.now() - lastActive.getTime()) / 60_000;

    if (diffMinutes < INACTIVITY_THRESHOLD_MINUTES) {
      return errorResponse(
        'Your partner is active. Companion Mode is only available when your partner is away.',
        'PARTNER_ACTIVE',
        403,
      );
    }
  }

  // ── 5. Extract style summary (graceful fallback) ───────────────────────────
  let styleSummary: StyleSummary | null = null;
  try {
    const raw = partnerProfile?.style_summary;
    if (raw && typeof raw === 'object') {
      styleSummary = raw as StyleSummary;
    }
  } catch {
    // Non-fatal: proceed without style guidance
  }

  // ── 6. Build prompt ────────────────────────────────────────────────────────
  const contextBlock  = buildContextBlock(styleSummary, userMood);
  const promptParts   = buildPromptParts(contextBlock, userMessage);

  // ── 7. Call Gemini ─────────────────────────────────────────────────────────
  try {
    const model  = getCompanionModel(SYSTEM_INSTRUCTION);
    const result = await model.generateContent(promptParts);

    // Check if response was blocked by safety filters
    const candidate = result.response.candidates?.[0];
    if (!candidate || candidate.finishReason === 'SAFETY') {
      return errorResponse(
        'Response could not be generated safely. Please try rephrasing.',
        'GENERATION_FAILED',
        422,
        rateLimitHeaders,
      );
    }

    const reply = result.response.text()?.trim();
    if (!reply) {
      throw new Error('Empty response from model.');
    }

    const responseBody: CompanionResponse = {
      reply,
      disclaimer: COMPANION_DISCLAIMER,
    };

    return NextResponse.json(responseBody, {
      status:  200,
      headers: rateLimitHeaders,
    });

  } catch (err: unknown) {
    console.error('[ai-companion] Gemini error:', err);
    return errorResponse(
      'AI generation failed. Please try again.',
      'GENERATION_FAILED',
      500,
      rateLimitHeaders,
    );
  }
}

// Only POST is supported
export async function GET() {
  return NextResponse.json({ error: 'Method not allowed' }, { status: 405 });
}
