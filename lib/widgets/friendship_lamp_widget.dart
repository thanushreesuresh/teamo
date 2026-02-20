import 'package:flutter/material.dart';

class FriendshipLampWidget extends StatelessWidget {
  final String? myColor;
  final String? partnerColor;
  final ValueChanged<String> onColorSelected;

  const FriendshipLampWidget({
    super.key,
    this.myColor,
    this.partnerColor,
    required this.onColorSelected,
  });

  static const List<Map<String, dynamic>> lampColors = [
    {'hex': '#FF6B6B', 'color': Color(0xFFFF6B6B), 'name': 'Red'},
    {'hex': '#FFD93D', 'color': Color(0xFFFFD93D), 'name': 'Yellow'},
    {'hex': '#6BCB77', 'color': Color(0xFF6BCB77), 'name': 'Green'},
    {'hex': '#4D96FF', 'color': Color(0xFF4D96FF), 'name': 'Blue'},
    {'hex': '#9B59B6', 'color': Color(0xFF9B59B6), 'name': 'Purple'},
    {'hex': '#FF8FA3', 'color': Color(0xFFFF8FA3), 'name': 'Pink'},
    {'hex': '#FF9F43', 'color': Color(0xFFFF9F43), 'name': 'Orange'},
    {'hex': '#00D2D3', 'color': Color(0xFF00D2D3), 'name': 'Teal'},
  ];

  Color _parseHex(String hex) {
    return Color(int.parse(hex.replaceFirst('#', '0xFF')));
  }

  @override
  Widget build(BuildContext context) {
    final partnerParsed =
        partnerColor != null ? _parseHex(partnerColor!) : null;
    final myParsed = myColor != null ? _parseHex(myColor!) : null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withValues(alpha: 0.08),
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
                    colors: [Color(0xFF6C63FF), Color(0xFF00D2D3)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.lightbulb, size: 20, color: Colors.white),
              ),
              const SizedBox(width: 10),
              const Text('Friendship Lamp',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            ],
          ),
          const SizedBox(height: 20),

          // Lamp display
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LampBulb(label: 'You', color: myParsed),
                const SizedBox(width: 40),
                Container(
                  width: 40,
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        myParsed ?? Colors.grey.shade300,
                        partnerParsed ?? Colors.grey.shade300,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
                const SizedBox(width: 40),
                _LampBulb(label: 'Partner', color: partnerParsed),
              ],
            ),
          ),
          const SizedBox(height: 18),

          Text('Choose your color:',
              style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 10),

          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: lampColors.map((lc) {
              final selected = myColor == lc['hex'];
              return GestureDetector(
                onTap: () => onColorSelected(lc['hex'] as String),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: lc['color'] as Color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? Colors.white : Colors.transparent,
                      width: selected ? 3 : 0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (lc['color'] as Color)
                            .withValues(alpha: selected ? 0.6 : 0.2),
                        blurRadius: selected ? 16 : 6,
                        spreadRadius: selected ? 3 : 0,
                      ),
                    ],
                  ),
                  child: selected
                      ? const Center(
                          child: Icon(Icons.check, color: Colors.white, size: 20))
                      : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _LampBulb extends StatelessWidget {
  final String label;
  final Color? color;

  const _LampBulb({required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color ?? Colors.grey[200],
            boxShadow: color != null
                ? [
                    BoxShadow(
                      color: color!.withValues(alpha: 0.6),
                      blurRadius: 28,
                      spreadRadius: 6,
                    ),
                    BoxShadow(
                      color: color!.withValues(alpha: 0.3),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ]
                : [],
          ),
          child: color == null
              ? Center(
                  child: Icon(Icons.lightbulb_outline,
                      color: Colors.grey[400], size: 28))
              : null,
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.grey[600],
        )),
      ],
    );
  }
}
