'use client';

/**
 * Example: How to integrate CompanionChat into a dashboard page.
 *
 * Drop this pattern into your existing dashboard/page.tsx.
 * Replace the partner-active check with your own real-time logic.
 */

import { useState, useEffect } from 'react';
import dynamic from 'next/dynamic';

// Lazy-load companion chat — it's a secondary feature
const CompanionChat = dynamic(
  () => import('../../components/companion/CompanionChat'),
  { ssr: false },
);

interface Partner {
  name: string;
  lastActive: Date | null;
}

const INACTIVITY_THRESHOLD_MINUTES = 10;

function isPartnerInactive(lastActive: Date | null): boolean {
  if (!lastActive) return true; // never seen = inactive
  return (Date.now() - lastActive.getTime()) / 60_000 > INACTIVITY_THRESHOLD_MINUTES;
}

export default function DashboardWithCompanion() {
  const [partner,       setPartner]       = useState<Partner | null>(null);
  const [companionOpen, setCompanionOpen] = useState(false);
  const [userMood,      setUserMood]      = useState<string | undefined>();

  // TODO: Replace with your actual data fetch
  useEffect(() => {
    // Simulated partner data — swap with Supabase query
    setPartner({ name: 'Alex', lastActive: new Date(Date.now() - 15 * 60_000) });
    setUserMood('a little lonely');
  }, []);

  const partnerInactive = partner ? isPartnerInactive(partner.lastActive) : false;

  return (
    <div className="flex min-h-screen flex-col items-center bg-gradient-to-b from-pink-50 to-violet-50 p-6">
      <h1 className="mb-8 text-2xl font-bold text-gray-800">
        Hey! How are you feeling?
      </h1>

      {/* ── Companion Mode trigger ── */}
      {partnerInactive && !companionOpen && (
        <div className="mb-6 w-full max-w-md rounded-2xl border border-violet-100 bg-white px-5 py-4 shadow-md">
          <p className="text-sm text-gray-500">
            <strong className="text-gray-700">{partner?.name}</strong> has been away
            for a while.
          </p>
          <button
            onClick={() => setCompanionOpen(true)}
            className="mt-3 w-full rounded-xl bg-gradient-to-r from-violet-500 to-pink-500 py-2.5 text-sm font-semibold text-white shadow transition hover:opacity-90"
          >
            💜 Enable Companion Mode
          </button>
          <p className="mt-2 text-center text-[11px] text-gray-400">
            An AI (not {partner?.name}) will keep you company
          </p>
        </div>
      )}

      {/* ── Companion Chat ── */}
      {companionOpen && partner && (
        <CompanionChat
          partnerName={partner.name}
          mood={userMood}
          onClose={() => setCompanionOpen(false)}
        />
      )}
    </div>
  );
}
