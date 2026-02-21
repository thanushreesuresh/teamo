'use client';

import {
  useState,
  useRef,
  useEffect,
  useCallback,
  type FormEvent,
  type KeyboardEvent,
} from 'react';
import type {
  CompanionMessage,
  CompanionResponse,
  CompanionError,
} from '../../types/companion';

// ─── Types ────────────────────────────────────────────────────────────────────

interface CompanionChatProps {
  /** Display name of the user's partner, shown in the header */
  partnerName: string;
  /** Current user mood string, passed along with each request */
  mood?: string;
  /** Called when the user closes/disables Companion Mode */
  onClose?: () => void;
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

function generateId(): string {
  return `${Date.now()}-${Math.random().toString(36).slice(2, 7)}`;
}

function formatTime(date: Date): string {
  return date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
}

// ─── Sub-components ───────────────────────────────────────────────────────────

function AIBadge() {
  return (
    <span className="inline-flex items-center gap-1 rounded-full bg-violet-100 px-2 py-0.5 text-[10px] font-semibold uppercase tracking-wide text-violet-600">
      <span className="h-1.5 w-1.5 rounded-full bg-violet-500 animate-pulse" />
      AI Companion
    </span>
  );
}

function TypingIndicator() {
  return (
    <div className="flex items-end gap-2">
      <div className="flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-violet-100 text-sm">
        🤖
      </div>
      <div className="rounded-2xl rounded-bl-sm bg-white px-4 py-3 shadow-sm">
        <span className="flex gap-1">
          {[0, 1, 2].map((i) => (
            <span
              key={i}
              className="h-1.5 w-1.5 rounded-full bg-gray-400 animate-bounce"
              style={{ animationDelay: `${i * 150}ms` }}
            />
          ))}
        </span>
      </div>
    </div>
  );
}

interface MessageBubbleProps {
  message: CompanionMessage;
  disclaimer?: string;
}

function MessageBubble({ message, disclaimer }: MessageBubbleProps) {
  const isUser = message.role === 'user';

  return (
    <div className={`flex items-end gap-2 ${isUser ? 'flex-row-reverse' : 'flex-row'}`}>
      {/* Avatar */}
      <div
        className={`flex h-8 w-8 shrink-0 items-center justify-center rounded-full text-sm ${
          isUser ? 'bg-pink-100' : 'bg-violet-100'
        }`}
      >
        {isUser ? '🙂' : '🤖'}
      </div>

      {/* Bubble */}
      <div className={`max-w-[75%] ${isUser ? 'items-end' : 'items-start'} flex flex-col gap-1`}>
        <div
          className={`rounded-2xl px-4 py-2.5 text-sm leading-relaxed shadow-sm ${
            isUser
              ? 'rounded-br-sm bg-gradient-to-br from-pink-500 to-violet-500 text-white'
              : 'rounded-bl-sm bg-white text-gray-800'
          }`}
        >
          {message.content}
        </div>

        {/* Disclaimer for AI messages */}
        {!isUser && disclaimer && (
          <p className="px-1 text-[10px] leading-tight text-gray-400">{disclaimer}</p>
        )}

        <span className="px-1 text-[10px] text-gray-400">{formatTime(message.timestamp)}</span>
      </div>
    </div>
  );
}

// ─── Main Component ───────────────────────────────────────────────────────────

export default function CompanionChat({
  partnerName,
  mood,
  onClose,
}: CompanionChatProps) {
  const [messages,  setMessages]  = useState<CompanionMessage[]>([]);
  const [input,     setInput]     = useState('');
  const [loading,   setLoading]   = useState(false);
  const [error,     setError]     = useState<string | null>(null);
  const [rateLimited, setRateLimited] = useState<number | null>(null); // retry-after ms
  const [disclaimer, setDisclaimer] = useState<string>('');

  const bottomRef  = useRef<HTMLDivElement>(null);
  const inputRef   = useRef<HTMLTextAreaElement>(null);

  // Scroll to latest message
  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages, loading]);

  // Auto-focus input on mount
  useEffect(() => {
    inputRef.current?.focus();

    // Inject an opening message from Companion
    setMessages([
      {
        id:        generateId(),
        role:      'assistant',
        content:   `Hi 👋 I'm Companion, an AI here to keep you company while ${partnerName} is away. I'm not them — but I'm here to listen. How are you doing?`,
        timestamp: new Date(),
      },
    ]);
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const sendMessage = useCallback(async () => {
    const text = input.trim();
    if (!text || loading) return;

    setInput('');
    setError(null);

    // Optimistically add user message
    const userMsg: CompanionMessage = {
      id:        generateId(),
      role:      'user',
      content:   text,
      timestamp: new Date(),
    };
    setMessages((prev) => [...prev, userMsg]);
    setLoading(true);

    try {
      const res = await fetch('/api/ai-companion', {
        method:  'POST',
        headers: { 'Content-Type': 'application/json' },
        body:    JSON.stringify({ message: text, mood }),
      });

      const data = (await res.json()) as CompanionResponse | CompanionError;

      if (!res.ok) {
        const err = data as CompanionError;

        if (err.code === 'RATE_LIMITED') {
          const retryAfter = parseInt(res.headers.get('Retry-After') ?? '60', 10);
          setRateLimited(Date.now() + retryAfter * 1000);
          setError(`You've sent too many messages. Please wait and try again.`);
        } else if (err.code === 'PARTNER_ACTIVE') {
          setError('Your partner is currently active — Companion Mode is only available when they\'re away.');
        } else {
          setError(err.error ?? 'Something went wrong. Please try again.');
        }
        return;
      }

      const success = data as CompanionResponse;
      if (success.disclaimer) setDisclaimer(success.disclaimer);

      const aiMsg: CompanionMessage = {
        id:        generateId(),
        role:      'assistant',
        content:   success.reply,
        timestamp: new Date(),
      };
      setMessages((prev) => [...prev, aiMsg]);

    } catch {
      setError('Network error. Please check your connection and try again.');
    } finally {
      setLoading(false);
      inputRef.current?.focus();
    }
  }, [input, loading, mood]);

  const handleSubmit = (e: FormEvent) => {
    e.preventDefault();
    sendMessage();
  };

  const handleKeyDown = (e: KeyboardEvent<HTMLTextAreaElement>) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      sendMessage();
    }
  };

  // Rate limit countdown
  const isRateLimited = rateLimited !== null && Date.now() < rateLimited;

  return (
    <div className="flex h-full max-h-[600px] w-full max-w-md flex-col overflow-hidden rounded-2xl border border-violet-100 bg-gray-50 shadow-xl">

      {/* ── Header ── */}
      <div className="flex items-center justify-between border-b border-violet-100 bg-white px-4 py-3">
        <div className="flex flex-col gap-0.5">
          <div className="flex items-center gap-2">
            <span className="text-sm font-semibold text-gray-800">Companion Mode</span>
            <AIBadge />
          </div>
          <p className="text-[11px] text-gray-400">
            While {partnerName} is away — I&apos;m here to listen 💜
          </p>
        </div>
        {onClose && (
          <button
            onClick={onClose}
            className="rounded-lg p-1.5 text-gray-400 transition hover:bg-gray-100 hover:text-gray-600"
            aria-label="Close Companion Mode"
          >
            <svg className="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        )}
      </div>

      {/* ── AI identity notice (always visible) ── */}
      <div className="border-b border-amber-100 bg-amber-50 px-4 py-2 text-[11px] text-amber-700">
        <strong>Heads up:</strong> You&apos;re chatting with an AI, not {partnerName}.
        Companion adapts its tone but is not your partner and cannot replace them.
      </div>

      {/* ── Messages ── */}
      <div className="flex-1 overflow-y-auto px-4 py-4 space-y-4">
        {messages.map((msg) => (
          <MessageBubble
            key={msg.id}
            message={msg}
            disclaimer={msg.role === 'assistant' ? disclaimer : undefined}
          />
        ))}
        {loading && <TypingIndicator />}
        <div ref={bottomRef} />
      </div>

      {/* ── Error banner ── */}
      {error && (
        <div className="mx-4 mb-2 rounded-xl bg-red-50 px-3 py-2 text-xs text-red-600 border border-red-100">
          {error}
        </div>
      )}

      {/* ── Input ── */}
      <form
        onSubmit={handleSubmit}
        className="border-t border-gray-200 bg-white px-3 py-3 flex items-end gap-2"
      >
        <textarea
          ref={inputRef}
          value={input}
          onChange={(e) => setInput(e.target.value)}
          onKeyDown={handleKeyDown}
          placeholder={
            isRateLimited
              ? 'Rate limit reached — please wait…'
              : 'Share what\'s on your mind…'
          }
          disabled={loading || isRateLimited}
          rows={1}
          maxLength={1000}
          className="flex-1 resize-none rounded-xl border border-gray-200 bg-gray-50 px-3 py-2 text-sm text-gray-800 placeholder-gray-400 outline-none transition focus:border-violet-300 focus:ring-2 focus:ring-violet-100 disabled:opacity-50"
          style={{ maxHeight: '120px' }}
          onInput={(e) => {
            // Auto-grow textarea
            const el = e.currentTarget;
            el.style.height = 'auto';
            el.style.height = `${el.scrollHeight}px`;
          }}
        />
        <button
          type="submit"
          disabled={!input.trim() || loading || isRateLimited}
          className="flex h-9 w-9 shrink-0 items-center justify-center rounded-xl bg-gradient-to-br from-violet-500 to-pink-500 text-white shadow transition hover:opacity-90 disabled:opacity-40"
          aria-label="Send message"
        >
          <svg className="h-4 w-4 rotate-90" fill="currentColor" viewBox="0 0 24 24">
            <path d="M2 21l21-9L2 3v7l15 2-15 2z" />
          </svg>
        </button>
      </form>
    </div>
  );
}
