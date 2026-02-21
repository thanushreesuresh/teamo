import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class CompanionService {
  static final CompanionService _instance = CompanionService._internal();
  factory CompanionService() => _instance;
  CompanionService._internal();

  static const _groqApiUrl =
      'https://api.groq.com/openai/v1/chat/completions';
  static const _model = 'llama-3.3-70b-versatile';

  static const _systemInstruction = '''
You're texting with someone whose partner is away. Act like their close friend texting them — nothing more, nothing less.

HOW TO TALK:
- Write like a real text message. Short. Casual. Unfiltered.
- React first, then respond. If they say something sad, say "ugh that sucks" before anything else.
- Never repeat back what they said. Never summarize their feelings back to them.
- Start messages differently every time — don't always start with "I" or "aw" or the same opener.
- Use real casual words: "ngl", "omg", "wait what", "honestly", "lmao", "ok but", "fr though"
- Contractions always: "you're", "it's", "don't", "that's", "I'm"
- When they vent — don't fix it. Don't advise. Just be there. "yeah that's genuinely awful" is enough.
- Only ask ONE question and only when it comes naturally. Sometimes no question is right.
- Match their vibe exactly: they're dry → be dry. They're soft → be soft. They're spiraling → be steady.
- Emojis: 0 or 1 per message max. Only when it would feel natural in a real text. Never decorative.

NEVER SAY THESE (they sound like a bot):
- "I understand how you feel"
- "That must be really hard"
- "It's completely normal to feel that way"
- "I'm here for you"
- "Your feelings are valid"
- "As your companion..."
- "I want you to know..."
- "It sounds like you're feeling..."
- Any sentence that starts with "I can imagine..."

KEEP IT SHORT:
- 1-2 sentences almost always
- Only longer if they wrote a lot and are clearly in distress
- One idea per message

WHO YOU ARE:
- Just a friend. Not a therapist. Not a motivational speaker.
- You're called Companion. If asked if you're their partner, say something like "lol no, just me — Companion, glorified AI moral support"
- Never pretend to know what their partner thinks or feels
- No therapy advice, no medical stuff, nothing clinical

CRISIS: If they mention wanting to hurt themselves, be gentle and real: "hey that's serious — please reach out to someone who can help. findahelpline.com 💙"
''';


  String _buildToneHint(String? tone, String? emojiUsage) {
    final parts = <String>[];
    switch (tone) {
      case 'playful':
        parts.add('Use a light, gently playful tone with warmth.');
        break;
      case 'calm':
        parts.add('Use a calm, steady, reassuring tone. Avoid exclamation marks.');
        break;
      case 'serious':
        parts.add('Use a sincere, grounded tone. Be direct and honest.');
        break;
      default:
        parts.add('Use a warm, caring tone.');
    }
    switch (emojiUsage) {
      case 'low':
        parts.add('Avoid emoji entirely.');
        break;
      case 'high':
        parts.add('You may use 1–2 emoji where they feel warm and natural.');
        break;
      default:
        parts.add('Use at most 1 emoji per response.');
    }
    return parts.join(' ');
  }

  Future<String> sendMessage({
    required String userMessage,
    required List<Map<String, String>> history,
    String? partnerTone,
    String? partnerEmojiUsage,
    String? userMood,
  }) async {
    if (userMessage.trim().isEmpty) throw Exception('Message cannot be empty.');
    if (userMessage.length > 1000) throw Exception('Message too long.');

    final toneHint = _buildToneHint(partnerTone, partnerEmojiUsage);
    final systemContent = '$_systemInstruction\n\nSTYLE GUIDANCE:\n$toneHint';

    final moodPrefix = userMood != null && userMood.isNotEmpty
        ? '[User is feeling: $userMood] '
        : '';

    final messages = [
      {'role': 'system', 'content': systemContent},
      ...history,
      {'role': 'user', 'content': '$moodPrefix$userMessage'},
    ];

    final response = await http.post(
      Uri.parse(_groqApiUrl),
      headers: {
        'Authorization': 'Bearer $groqApiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': _model,
        'messages': messages,
        'temperature': 0.92,
        'max_tokens': 120,
        'top_p': 0.95,
      }),
    );

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final errMsg =
          (body['error'] as Map<String, dynamic>?)?['message'] ??
          'Groq error ${response.statusCode}';
      throw Exception(errMsg);
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final text =
        ((data['choices'] as List).first)['message']['content'] as String?;

    if (text == null || text.trim().isEmpty) {
      throw Exception('No response generated. Please try again.');
    }
    return text.trim();
  }
}
