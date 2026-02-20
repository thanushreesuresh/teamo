import 'package:flutter/material.dart';

class MoodPingWidget extends StatelessWidget {
  final String? myMood;
  final String? partnerMood;
  final ValueChanged<String> onMoodSelected;

  const MoodPingWidget({
    super.key,
    this.myMood,
    this.partnerMood,
    required this.onMoodSelected,
  });

  static const List<Map<String, String>> moods = [
    {'emoji': '😊', 'label': 'Happy'},
    {'emoji': '😢', 'label': 'Sad'},
    {'emoji': '😴', 'label': 'Sleepy'},
    {'emoji': '🥰', 'label': 'Loving'},
    {'emoji': '😤', 'label': 'Frustrated'},
    {'emoji': '🤗', 'label': 'Grateful'},
    {'emoji': '😌', 'label': 'Calm'},
    {'emoji': '🤒', 'label': 'Sick'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.pink.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD93D), Color(0xFFFF6B6B)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.emoji_emotions, size: 20, color: Colors.white),
              ),
              const SizedBox(width: 10),
              const Text('Mood Ping',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            ],
          ),
          const SizedBox(height: 14),

          // Partner mood
          if (partnerMood != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFC44DFF).withValues(alpha: 0.1),
                    const Color(0xFFFF6B9D).withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Text(
                    moods.firstWhere(
                      (m) => m['label'] == partnerMood,
                      orElse: () => {'emoji': '❓', 'label': 'Unknown'},
                    )['emoji']!,
                    style: const TextStyle(fontSize: 28),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('Partner feels $partnerMood',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
            )
          else
            Text('Partner hasn\'t shared their mood yet',
                style: TextStyle(color: Colors.grey[400], fontStyle: FontStyle.italic)),

          const SizedBox(height: 14),
          Text('How are you feeling?',
              style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 10),

          // Mood grid
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: moods.map((m) {
              final isSelected = myMood == m['label'];
              return GestureDetector(
                onTap: () => onMoodSelected(m['label']!),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? const LinearGradient(
                            colors: [Color(0xFFFF6B9D), Color(0xFFC44DFF)],
                          )
                        : null,
                    color: isSelected ? null : const Color(0xFFF5F0FF),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0xFFFF6B9D)
                                  .withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : [],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(m['emoji']!, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 5),
                      Text(
                        m['label']!,
                        style: TextStyle(
                          color: isSelected ? Colors.white : const Color(0xFF6C63FF),
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
