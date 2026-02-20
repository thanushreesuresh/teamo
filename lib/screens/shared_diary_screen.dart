import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/diary_entry.dart';
import '../services/supabase_service.dart';

class SharedDiaryScreen extends StatefulWidget {
  final String pairId;

  const SharedDiaryScreen({super.key, required this.pairId});

  @override
  State<SharedDiaryScreen> createState() => _SharedDiaryScreenState();
}

class _SharedDiaryScreenState extends State<SharedDiaryScreen> {
  final _service = SupabaseService();
  final _contentController = TextEditingController();
  List<DiaryEntry> _entries = [];
  bool _loading = true;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    try {
      final entries = await _service.getDiaryEntries(widget.pairId);
      if (mounted) setState(() {
        _entries = entries;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _addEntry() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) return;

    setState(() => _submitting = true);

    try {
      await _service.addDiaryEntry(widget.pairId, content);
      _contentController.clear();
      await _loadEntries();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFFFF6B9D), Color(0xFFC44DFF)],
          ).createShader(bounds),
          child: const Text('Shared Diary',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.white)),
        ),
        centerTitle: true,
      ),
      backgroundColor: const Color(0xFFFFF5F7),
      body: Column(
        children: [
          // ── Input area ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _contentController,
                    maxLines: 3,
                    minLines: 1,
                    decoration: const InputDecoration(
                      hintText: 'Write something for both of you...',
                      border: OutlineInputBorder(),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _addEntry(),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton.filled(
                  onPressed: _submitting ? null : _addEntry,
                  icon: _submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                ),
              ],
            ),
          ),

          // ── Entries list ──
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Error loading entries',
                                style: TextStyle(color: Colors.red[400])),
                            TextButton(
                                onPressed: _loadEntries,
                                child: const Text('Retry')),
                          ],
                        ),
                      )
                    : _entries.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.menu_book_outlined,
                                    size: 48, color: Colors.grey[400]),
                                const SizedBox(height: 8),
                                Text('No entries yet',
                                    style:
                                        TextStyle(color: Colors.grey[500])),
                                const Text('Be the first to write!'),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadEntries,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _entries.length,
                              itemBuilder: (context, index) {
                                final entry = _entries[index];
                                final isMe = entry.authorId ==
                                    _service.currentUserId;
                                return _DiaryCard(
                                    entry: entry, isMe: isMe);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _DiaryCard extends StatelessWidget {
  final DiaryEntry entry;
  final bool isMe;

  const _DiaryCard({required this.entry, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isMe
              ? const Color(0xFFFF6B9D).withValues(alpha: 0.2)
              : const Color(0xFF6C63FF).withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: (isMe ? const Color(0xFFFF6B9D) : const Color(0xFF6C63FF))
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
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isMe
                        ? [const Color(0xFFFF6B9D), const Color(0xFFFFA07A)]
                        : [const Color(0xFF6C63FF), const Color(0xFF00D2D3)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isMe ? Icons.person : Icons.person_outline,
                  size: 14,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isMe ? 'You' : 'Partner',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: isMe
                      ? const Color(0xFFFF6B9D)
                      : const Color(0xFF6C63FF),
                ),
              ),
              const Spacer(),
              Text(
                DateFormat('MMM d, yyyy • h:mm a').format(entry.createdAt.toLocal()),
                style: TextStyle(color: Colors.grey[400], fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(entry.content, style: const TextStyle(fontSize: 15, height: 1.4)),
        ],
      ),
    );
  }
}
