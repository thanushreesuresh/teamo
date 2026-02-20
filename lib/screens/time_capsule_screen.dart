import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/time_capsule.dart';
import '../services/supabase_service.dart';

class TimeCapsuleScreen extends StatefulWidget {
  final String pairId;

  const TimeCapsuleScreen({super.key, required this.pairId});

  @override
  State<TimeCapsuleScreen> createState() => _TimeCapsuleScreenState();
}

class _TimeCapsuleScreenState extends State<TimeCapsuleScreen> {
  final _service = SupabaseService();
  List<TimeCapsule> _capsules = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCapsules();
  }

  Future<void> _loadCapsules() async {
    try {
      final capsules = await _service.getTimeCapsules(widget.pairId);
      if (mounted) setState(() {
        _capsules = capsules;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _showAddDialog() {
    final messageController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 7));

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('New Time Capsule'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: messageController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Write a message for the future...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today),
                title: const Text('Unlock Date'),
                subtitle: Text(DateFormat('MMM d, yyyy').format(selectedDate)),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: selectedDate,
                    firstDate: DateTime.now().add(const Duration(days: 1)),
                    lastDate:
                        DateTime.now().add(const Duration(days: 365 * 5)),
                  );
                  if (picked != null) {
                    setDialogState(() => selectedDate = picked);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final msg = messageController.text.trim();
                if (msg.isEmpty) return;
                Navigator.pop(ctx);
                await _service.addTimeCapsule(
                    widget.pairId, msg, selectedDate);
                _loadCapsules();
              },
              child: const Text('Seal Capsule'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF6C63FF), Color(0xFFC44DFF)],
          ).createShader(bounds),
          child: const Text('Time Capsules',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.white)),
        ),
        centerTitle: true,
      ),
      backgroundColor: const Color(0xFFFFF5F7),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6C63FF), Color(0xFFC44DFF)],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6C63FF).withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: _showAddDialog,
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Error loading capsules',
                          style: TextStyle(color: Colors.red[400])),
                      TextButton(
                          onPressed: _loadCapsules,
                          child: const Text('Retry')),
                    ],
                  ),
                )
              : _capsules.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.hourglass_empty,
                              size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 8),
                          Text('No capsules yet',
                              style: TextStyle(color: Colors.grey[500])),
                          const Text('Create your first time capsule!'),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadCapsules,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _capsules.length,
                        itemBuilder: (context, index) {
                          return _CapsuleCard(capsule: _capsules[index]);
                        },
                      ),
                    ),
    );
  }
}

class _CapsuleCard extends StatelessWidget {
  final TimeCapsule capsule;

  const _CapsuleCard({required this.capsule});

  @override
  Widget build(BuildContext context) {
    final unlocked = capsule.isUnlocked;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: unlocked
              ? const Color(0xFF6BCB77).withValues(alpha: 0.3)
              : const Color(0xFF6C63FF).withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: (unlocked ? const Color(0xFF6BCB77) : const Color(0xFF6C63FF))
                .withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
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
                  gradient: LinearGradient(
                    colors: unlocked
                        ? [const Color(0xFF6BCB77), const Color(0xFF00D2D3)]
                        : [const Color(0xFF6C63FF), const Color(0xFFC44DFF)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  unlocked ? Icons.lock_open : Icons.lock,
                  size: 18,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                unlocked ? 'Unlocked' : 'Locked',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: unlocked ? const Color(0xFF6BCB77) : const Color(0xFF6C63FF),
                ),
              ),
              const Spacer(),
              Text(
                unlocked
                    ? 'Opened ${DateFormat('MMM d, yyyy').format(capsule.unlockAt)}'
                    : 'Opens ${DateFormat('MMM d, yyyy').format(capsule.unlockAt)}',
                style: TextStyle(color: Colors.grey[400], fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (unlocked)
            Text(capsule.message, style: const TextStyle(fontSize: 15, height: 1.4))
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF6C63FF).withValues(alpha: 0.06),
                    const Color(0xFFC44DFF).withValues(alpha: 0.06),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text('⏳', style: TextStyle(fontSize: 32)),
                  const SizedBox(height: 8),
                  Text(
                    _remainingText(capsule.unlockAt),
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15,
                        color: Color(0xFF6C63FF)),
                  ),
                  const SizedBox(height: 4),
                  Text('This capsule is still sealed.',
                      style: TextStyle(fontSize: 13, color: Colors.grey[400])),
                ],
              ),
            ),
          const SizedBox(height: 10),
          Text(
            'Created ${DateFormat('MMM d, yyyy').format(capsule.createdAt.toLocal())}',
            style: TextStyle(color: Colors.grey[300], fontSize: 11),
          ),
        ],
      ),
    );
  }

  String _remainingText(DateTime unlockAt) {
    final diff = unlockAt.difference(DateTime.now());
    if (diff.inDays > 0) return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} remaining';
    if (diff.inHours > 0) return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} remaining';
    return 'Opening soon...';
  }
}
