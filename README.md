# 💕 Tiamo

> *"Ti amo" — Italian for "I love you"*

A Flutter mobile app for long-distance couples and close friends to stay emotionally connected — not a chat app, but a **presence app**.

---

## Features

- 🔐 **Auth** — Email sign-up & sign-in via Supabase
- 💞 **Pairing System** — Connect two users with an invite code
- 😊 **Mood Ping** — Share your current mood with your partner in real time
- 💗 **Miss You Counter** — Tap to let them know you're thinking of them
- 💡 **Friendship Lamp** — Set a color to signal your emotional presence
- 📖 **Shared Diary** — Write entries only your partner can read
- ⏳ **Time Capsule** — Leave a message that unlocks on a future date

---

## Tech Stack

- **Flutter** (Android & iOS)
- **Supabase** (Auth + PostgreSQL + Realtime)
- **Google Fonts** (Poppins)
- **Material 3** with pink-purple gradient theme

---

## Getting Started

### 1. Clone the repo
```bash
git clone https://github.com/YOUR_USERNAME/tiamo.git
cd tiamo
```

### 2. Set up Supabase credentials
```bash
cp lib/config.example.dart lib/config.dart
```
Edit `lib/config.dart` with your Supabase URL and anon key from [Supabase Dashboard](https://supabase.com/dashboard) → Settings → API.

### 3. Run the SQL schema
In Supabase Dashboard → SQL Editor, run `supabase_schema.sql`.

### 4. Disable email confirmation
Supabase Dashboard → Authentication → Providers → Email → turn OFF "Confirm email".

### 5. Run the app
```bash
flutter pub get
flutter run
```

---

## Database Schema

| Table | Description |
|-------|-------------|
| `profiles` | User profile linked to auth.users |
| `pairs` | Two users connected by an invite code |
| `diary_entries` | Shared diary entries per pair |
| `time_capsules` | Time-locked messages per pair |

---

## Pairing Flow

1. **Person 1** signs up → taps "Create a Pair" → gets an invite code
2. **Person 2** signs up → taps "Join with Code" → enters the invite code
3. Both land on the Dashboard and are connected in real time 💕

---

## License

MIT

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
