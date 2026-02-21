import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../services/auth_service.dart';
import '../models/pair_model.dart';
import 'dashboard_screen.dart';

class PairingScreen extends StatefulWidget {
  const PairingScreen({super.key});

  @override
  State<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends State<PairingScreen> {
  final _codeController = TextEditingController();
  final _service = SupabaseService();
  final _auth = AuthService();
  bool _loading = false;
  String? _inviteCode;
  String? _error;
  bool _waitingForPartner = false;
  RealtimeChannel? _partnerChannel;

  Future<void> _createPair() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final pair = await _service.createPair();
      setState(() {
        _inviteCode = pair.inviteCode;
        _waitingForPartner = true;
      });
      _watchForPartner(pair.id);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Subscribes to the pair row; when user2 joins, auto-navigate to Dashboard.
  void _watchForPartner(String pairId) {
    _partnerChannel?.unsubscribe();
    _partnerChannel = _service.subscribeToPair(pairId, (data) {
      final joined = data['user2_id'];
      if (joined != null && mounted) {
        _navigateToDashboard(PairModel.fromMap(data));
      }
    });
  }

  Future<void> _joinPair() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() => _error = 'Enter an invite code');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final pair = await _service.joinPair(code);
      if (pair == null) {
        setState(() => _error = 'Invalid code or already paired');
      } else if (mounted) {
        _navigateToDashboard(pair);
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _navigateToDashboard(PairModel pair) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => DashboardScreen(pairId: pair.id)),
    );
  }

  @override
  void dispose() {
    if (_partnerChannel != null) _service.unsubscribeChannel(_partnerChannel!);
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFF0F5),
              Color(0xFFFFE8F0),
              Color(0xFFEDE8FF),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Top bar ──
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  children: [
                    if (Navigator.canPop(context))
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.pop(context),
                      )
                    else
                      const SizedBox(width: 8),
                    const Spacer(),
                    // Logout button
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.8),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.pink.withValues(alpha: 0.1),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: ShaderMask(
                          shaderCallback: (bounds) =>
                              const LinearGradient(
                            colors: [
                              Color(0xFFFF6B9D),
                              Color(0xFF6C63FF),
                            ],
                          ).createShader(bounds),
                          child: const Icon(Icons.logout,
                              color: Colors.white),
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
                          if (confirmed == true) await _auth.signOut();
                        },
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: Column(
                    children: [
                      // ── Hero ──
                      Container(
                        width: 78,
                        height: 78,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF6B9D), Color(0xFF6C63FF)],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF6B9D)
                                  .withValues(alpha: 0.35),
                              blurRadius: 24,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text('🔗', style: TextStyle(fontSize: 34)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ShaderMask(
                        shaderCallback: (b) => const LinearGradient(
                          colors: [Color(0xFFFF6B9D), Color(0xFF6C63FF)],
                        ).createShader(b),
                        child: const Text(
                          'Connect with your person',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── How it works ──
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.purple.withValues(alpha: 0.07),
                              blurRadius: 18,
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
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(colors: [
                                      Color(0xFFFF6B9D),
                                      Color(0xFF6C63FF),
                                    ]),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.info_outline,
                                      color: Colors.white, size: 16),
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  'How to connect',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1A1A2E),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _Step(
                              number: '1',
                              emoji: '📱',
                              color: const Color(0xFFFF6B9D),
                              title: 'Person A generates a code',
                              detail:
                                  'Tap "Generate Code" below to create a unique 6-character invite code.',
                            ),
                            _Step(
                              number: '2',
                              emoji: '📤',
                              color: const Color(0xFFD63AF9),
                              title: 'Share the code',
                              detail:
                                  'Copy and send the code to your partner via WhatsApp, SMS, or any app.',
                            ),
                            _Step(
                              number: '3',
                              emoji: '🔓',
                              color: const Color(0xFF6C63FF),
                              title: 'Person B enters the code',
                              detail:
                                  'Your partner types the code in the "Join with a code" section and taps Join.',
                              isLast: true,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Create invite code ──
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: const Color(0xFFFF6B9D)
                                .withValues(alpha: 0.2),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.pink.withValues(alpha: 0.07),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(9),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(colors: [
                                      Color(0xFFFF6B9D),
                                      Color(0xFFD63AF9),
                                    ]),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.add_link,
                                      color: Colors.white, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const Text('Create an invite code',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15)),
                                    Text('You are Person A',
                                        style: TextStyle(
                                            color: Colors.grey[500],
                                            fontSize: 12)),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (_inviteCode != null) ...[
                              // Invite code display
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 18),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFFFF6B9D)
                                          .withValues(alpha: 0.08),
                                      const Color(0xFF6C63FF)
                                          .withValues(alpha: 0.08),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFFFF6B9D)
                                        .withValues(alpha: 0.2),
                                  ),
                                ),
                                child: SelectableText(
                                  _inviteCode!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 34,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 8,
                                    color: Color(0xFF6C63FF),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    Clipboard.setData(
                                        ClipboardData(text: _inviteCode!));
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                      SnackBar(
                                        content: const Row(
                                          children: [
                                            Icon(Icons.check_circle,
                                                color: Colors.white,
                                                size: 18),
                                            SizedBox(width: 8),
                                            Text('Code copied to clipboard!'),
                                          ],
                                        ),
                                        backgroundColor:
                                            const Color(0xFF6C63FF),
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12)),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.copy_rounded,
                                      size: 18),
                                  label: const Text('Copy Code',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600)),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor:
                                        const Color(0xFF6C63FF),
                                    side: const BorderSide(
                                        color: Color(0xFF6C63FF), width: 1.5),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(14)),
                                  ),
                                ),
                              ),
                              if (_waitingForPartner) ...[
                                const SizedBox(height: 14),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade50,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                        color: Colors.amber.shade200),
                                  ),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.amber.shade700,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Waiting for your partner…',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color:
                                                    Colors.amber.shade800,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            Text(
                                              'You\'ll be connected automatically when they join',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color:
                                                    Colors.amber.shade700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ] else
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFFFF6B9D),
                                        Color(0xFFD63AF9),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFFF6B9D)
                                            .withValues(alpha: 0.35),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: FilledButton.icon(
                                    onPressed:
                                        _loading ? null : _createPair,
                                    style: FilledButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(14),
                                      ),
                                    ),
                                    icon: _loading
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white))
                                        : const Icon(Icons.auto_awesome,
                                            size: 18),
                                    label: Text(
                                      _loading
                                          ? 'Generating…'
                                          : 'Generate Code',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                              child: Divider(color: Colors.grey.shade300)),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 14),
                            child: Text('OR',
                                style: TextStyle(
                                    color: Colors.grey[400],
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12)),
                          ),
                          Expanded(
                              child: Divider(color: Colors.grey.shade300)),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ── Join with code ──
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: const Color(0xFF6C63FF)
                                .withValues(alpha: 0.2),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.purple.withValues(alpha: 0.07),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(9),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(colors: [
                                      Color(0xFF6C63FF),
                                      Color(0xFFD63AF9),
                                    ]),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.link_rounded,
                                      color: Colors.white, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const Text('Join with a code',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15)),
                                    Text('You are Person B',
                                        style: TextStyle(
                                            color: Colors.grey[500],
                                            fontSize: 12)),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _codeController,
                              textCapitalization:
                                  TextCapitalization.characters,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 28,
                                letterSpacing: 8,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF6C63FF),
                              ),
                              decoration: InputDecoration(
                                hintText: 'XXXXXX',
                                hintStyle: TextStyle(
                                    color: Colors.grey.shade300,
                                    letterSpacing: 8,
                                    fontSize: 28),
                                counterText: '',
                                filled: true,
                                fillColor: const Color(0xFFEDE8FF)
                                    .withValues(alpha: 0.5),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                      color: const Color(0xFF6C63FF)
                                          .withValues(alpha: 0.2)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                      color: Color(0xFF6C63FF), width: 2),
                                ),
                              ),
                              maxLength: 6,
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF6C63FF),
                                      Color(0xFFD63AF9),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF6C63FF)
                                          .withValues(alpha: 0.35),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: FilledButton.icon(
                                  onPressed: _loading ? null : _joinPair,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(14),
                                    ),
                                  ),
                                  icon: _loading
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white))
                                      : const Icon(Icons.favorite_rounded,
                                          size: 18),
                                  label: Text(
                                    _loading ? 'Joining…' : 'Join Partner',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (_error != null) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(14),
                            border:
                                Border.all(color: Colors.red.shade100),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline,
                                  color: Colors.red.shade400, size: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(_error!,
                                    style: TextStyle(
                                        color: Colors.red.shade700,
                                        fontSize: 13)),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 32),
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

// ── Step widget ────────────────────────────────────────────────────────────

class _Step extends StatelessWidget {
  final String number;
  final String emoji;
  final Color color;
  final String title;
  final String detail;
  final bool isLast;

  const _Step({
    required this.number,
    required this.emoji,
    required this.color,
    required this.title,
    required this.detail,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Numbered circle + connector line
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    number,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          // Text + emoji
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: Color(0xFF1A1A2E))),
                        const SizedBox(height: 2),
                        Text(detail,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[500])),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(emoji, style: const TextStyle(fontSize: 22)),
                ],
              ),
            ),
          ),
        ],      ),
    );
  }
}