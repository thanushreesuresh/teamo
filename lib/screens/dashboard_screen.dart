import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../services/auth_service.dart';
import '../models/pair_model.dart';
import '../widgets/mood_ping_widget.dart';
import '../widgets/miss_you_widget.dart';
import '../widgets/friendship_lamp_widget.dart';
import 'shared_diary_screen.dart';
import 'time_capsule_screen.dart';
import 'companion_chat_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String pairId;

  const DashboardScreen({super.key, required this.pairId});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _service = SupabaseService();
  final _auth = AuthService();
  PairModel? _pair;
  String? _partnerName;          // display name of the other user
  bool _loading = true;
  RealtimeChannel? _channel;

  // Optimistic local overrides – applied immediately on user interaction
  // and cleared once the realtime update confirms the new value.
  String? _myMoodOverride;
  String? _myLampOverride;
  int _missYouDelta = 0; // taps not yet reflected from server

  @override
  void initState() {
    super.initState();
    _loadPair();
    _subscribeRealtime();
  }

  Future<void> _loadPair() async {
    try {
      final pair = await _service.getPair(widget.pairId);

      // Load partner's profile to get their display name.
      String? partnerName;
      if (pair != null) {
        final currentId = _service.currentUserId;
        final partnerId =
            pair.user1Id == currentId ? pair.user2Id : pair.user1Id;
        if (partnerId != null) {
          final partnerProfile = await _service.getProfile(partnerId);
          partnerName =
              partnerProfile?.displayName ?? partnerProfile?.email;
        }
      }

      if (mounted) {
        setState(() {
          _pair = pair;
          _partnerName = partnerName;
          _loading = false;
          _missYouDelta = 0;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _subscribeRealtime() {
    _channel = _service.subscribeToPair(widget.pairId, (data) {
      if (mounted) {
        setState(() {
          _pair = PairModel.fromMap(data);
          // Server echoed back our updates — clear local overrides.
          _myMoodOverride = null;
          _myLampOverride = null;
          _missYouDelta = 0;
        });
        // If partner just joined (user2 first appearance), reload to get name.
        if (_partnerName == null) _loadPair();
      }
    });
  }

  bool get _isUser1 => _pair?.user1Id == _service.currentUserId;

  String? get _myMood =>
      _myMoodOverride ?? (_isUser1 ? _pair?.mood1 : _pair?.mood2);
  String? get _partnerMood => _isUser1 ? _pair?.mood2 : _pair?.mood1;
  String? get _myLampColor =>
      _myLampOverride ?? (_isUser1 ? _pair?.lampColor1 : _pair?.lampColor2);
  String? get _partnerLampColor =>
      _isUser1 ? _pair?.lampColor2 : _pair?.lampColor1;
  int get _missYouCount => (_pair?.missYouCount ?? 0) + _missYouDelta;

  Future<void> _onMoodSelected(String mood) async {
    // Optimistic update.
    setState(() => _myMoodOverride = mood);
    try {
      await _service.updateMood(widget.pairId, mood);
    } catch (e) {
      // Revert on error.
      if (mounted) setState(() => _myMoodOverride = null);
    }
  }

  Future<void> _onMissYou() async {
    // Optimistic update.
    setState(() => _missYouDelta++);
    try {
      await _service.incrementMissYou(widget.pairId);
    } catch (e) {
      if (mounted) setState(() => _missYouDelta = (_missYouDelta - 1).clamp(0, 999));
    }
  }

  Future<void> _onLampColorSelected(String colorHex) async {
    // Optimistic update.
    setState(() => _myLampOverride = colorHex);
    try {
      await _service.updateLampColor(widget.pairId, colorHex);
    } catch (e) {
      if (mounted) setState(() => _myLampOverride = null);
    }
  }

  @override
  void dispose() {
    if (_channel != null) _service.unsubscribeChannel(_channel!);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_pair == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Could not load pair data.'),
              const SizedBox(height: 12),
              FilledButton(
                  onPressed: _loadPair, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFF5F7),
              Color(0xFFFFE8F0),
              Color(0xFFE8E0FF),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom gradient appbar
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Color(0xFFFF6B9D), Color(0xFF6C63FF)],
                          ).createShader(bounds),
                          child: const Text(
                            'Tiamo',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        if (_partnerName != null)
                          Text(
                            '💕 ${ _partnerName!}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.pink.shade400,
                              fontWeight: FontWeight.w500,
                            ),
                          )
                        else if (_pair!.isPaired)
                          Text(
                            '💕 Partner connected',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.pink.shade400,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.8),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Color(0xFFFF6B9D), Color(0xFF6C63FF)],
                          ).createShader(bounds),
                          child: const Icon(Icons.logout, color: Colors.white),
                        ),
                        tooltip: 'Sign Out',
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20)),
                              title: const Text('Sign Out'),
                              content: const Text(
                                  'Are you sure you want to sign out?'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(ctx, false),
                                  child: const Text('Cancel'),
                                ),
                                FilledButton(
                                  onPressed: () =>
                                      Navigator.pop(ctx, true),
                                  style: FilledButton.styleFrom(
                                    backgroundColor:
                                        const Color(0xFFFF6B9D),
                                  ),
                                  child: const Text('Sign Out'),
                                ),
                              ],
                            ),
                          );
                          if (confirmed == true) {
                            await _auth.signOut();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadPair,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (!_pair!.isPaired)
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.amber.shade100,
                                Colors.orange.shade100,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade200,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.hourglass_top,
                                    color: Colors.orange, size: 20),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Waiting for your partner to join...',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (!_pair!.isPaired) const SizedBox(height: 12),

                      // Mood Ping
                      MoodPingWidget(
                        myMood: _myMood,
                        partnerMood: _partnerMood,
                        onMoodSelected: _onMoodSelected,
                      ),
                      const SizedBox(height: 12),

                      // Miss You
                      MissYouWidget(
                        count: _missYouCount,
                        onTap: _onMissYou,
                      ),
                      const SizedBox(height: 12),

                      // Friendship Lamp
                      FriendshipLampWidget(
                        myColor: _myLampColor,
                        partnerColor: _partnerLampColor,
                        onColorSelected: _onLampColorSelected,
                      ),
                      const SizedBox(height: 12),

                      // Companion Mode card
                      _CompanionCard(
                        partnerName: _partnerName ?? 'your partner',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CompanionChatScreen(
                              partnerName: _partnerName ?? 'your partner',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Navigation Row
                      Row(
                        children: [
                          Expanded(
                            child: _NavCard(
                              icon: Icons.menu_book_outlined,
                              label: 'Shared Diary',
                              gradientColors: const [
                                Color(0xFFFF6B9D),
                                Color(0xFFFFA07A),
                              ],
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      SharedDiaryScreen(pairId: widget.pairId),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _NavCard(
                              icon: Icons.hourglass_bottom_outlined,
                              label: 'Time Capsule',
                              gradientColors: const [
                                Color(0xFF6C63FF),
                                Color(0xFFC44DFF),
                              ],
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      TimeCapsuleScreen(pairId: widget.pairId),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final List<Color> gradientColors;

  const _NavCard({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 28),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradientColors.first.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: Colors.white),
            const SizedBox(height: 8),
            Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

// ── Companion Mode Card ────────────────────────────────────────────────────────

class _CompanionCard extends StatelessWidget {
  final String partnerName;
  final VoidCallback onTap;

  const _CompanionCard({required this.partnerName, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6C63FF), Color(0xFFD63AF9)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6C63FF).withValues(alpha: 0.3),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('🤖', style: TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Companion Mode',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'AI',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Chat with an AI while $partnerName is away',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ],
        ),
      ),
    );
  }
}
