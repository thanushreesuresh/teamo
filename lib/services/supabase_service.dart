import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'dart:math';
import '../models/pair_model.dart';
import '../models/diary_entry.dart';
import '../models/time_capsule.dart';
import '../models/user_profile.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  final _client = Supabase.instance.client;
  final _uuid = const Uuid();

  SupabaseClient get client => _client;
  String? get currentUserId => _client.auth.currentUser?.id;

  // ─── User Profile ───────────────────────────────────────────

  Future<UserProfile?> getProfile(String userId) async {
    final res = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    if (res == null) return null;
    return UserProfile.fromMap(res);
  }

  Future<void> upsertProfile({
    required String userId,
    required String email,
    String? displayName,
    String? pairId,
  }) async {
    await _client.from('profiles').upsert({
      'id': userId,
      'email': email,
      'display_name': displayName,
      'pair_id': pairId,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // ─── Pairing ────────────────────────────────────────────────

  String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random.secure();
    return List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  Future<PairModel> createPair() async {
    final userId = currentUserId!;
    final pairId = _uuid.v4();
    final inviteCode = _generateInviteCode();

    await _client.from('pairs').insert({
      'id': pairId,
      'user1_id': userId,
      'invite_code': inviteCode,
      'miss_you_count': 0,
      'created_at': DateTime.now().toIso8601String(),
    });

    await _client
        .from('profiles')
        .update({'pair_id': pairId}).eq('id', userId);

    return PairModel(
      id: pairId,
      user1Id: userId,
      inviteCode: inviteCode,
      createdAt: DateTime.now(),
    );
  }

  Future<PairModel?> joinPair(String inviteCode) async {
    final userId = currentUserId!;

    final res = await _client
        .from('pairs')
        .select()
        .eq('invite_code', inviteCode.toUpperCase().trim())
        .isFilter('user2_id', null)
        .maybeSingle();

    if (res == null) return null;

    final pairId = res['id'] as String;

    if (res['user1_id'] == userId) return null; // can't pair with yourself

    await _client
        .from('pairs')
        .update({'user2_id': userId}).eq('id', pairId);

    await _client
        .from('profiles')
        .update({'pair_id': pairId}).eq('id', userId);

    return PairModel.fromMap({...res, 'user2_id': userId});
  }

  Future<PairModel?> getPair(String pairId) async {
    final res =
        await _client.from('pairs').select().eq('id', pairId).maybeSingle();
    if (res == null) return null;
    return PairModel.fromMap(res);
  }

  // ─── Mood Ping ──────────────────────────────────────────────

  Future<void> updateMood(String pairId, String mood) async {
    final userId = currentUserId!;
    final pair = await getPair(pairId);
    if (pair == null) return;

    final column = pair.user1Id == userId ? 'mood1' : 'mood2';
    await _client.from('pairs').update({column: mood}).eq('id', pairId);
  }

  // ─── Miss You Counter ──────────────────────────────────────

  Future<int> incrementMissYou(String pairId) async {
    final res = await _client.rpc('increment_miss_you', params: {
      'pair_row_id': pairId,
    });
    return (res as int?) ?? 0;
  }

  // ─── Friendship Lamp ───────────────────────────────────────

  Future<void> updateLampColor(String pairId, String colorHex) async {
    final userId = currentUserId!;
    final pair = await getPair(pairId);
    if (pair == null) return;

    final column = pair.user1Id == userId ? 'lamp_color1' : 'lamp_color2';
    await _client.from('pairs').update({column: colorHex}).eq('id', pairId);
  }

  // ─── Shared Diary ──────────────────────────────────────────

  Future<List<DiaryEntry>> getDiaryEntries(String pairId) async {
    final res = await _client
        .from('diary_entries')
        .select()
        .eq('pair_id', pairId)
        .order('created_at', ascending: false);
    return (res as List).map((e) => DiaryEntry.fromMap(e)).toList();
  }

  Future<void> addDiaryEntry(String pairId, String content) async {
    await _client.from('diary_entries').insert({
      'id': _uuid.v4(),
      'pair_id': pairId,
      'author_id': currentUserId!,
      'content': content,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // ─── Time Capsule ──────────────────────────────────────────

  Future<List<TimeCapsule>> getTimeCapsules(String pairId) async {
    final res = await _client
        .from('time_capsules')
        .select()
        .eq('pair_id', pairId)
        .order('unlock_at', ascending: true);
    return (res as List).map((e) => TimeCapsule.fromMap(e)).toList();
  }

  Future<void> addTimeCapsule(
      String pairId, String message, DateTime unlockAt) async {
    await _client.from('time_capsules').insert({
      'id': _uuid.v4(),
      'pair_id': pairId,
      'author_id': currentUserId!,
      'message': message,
      'unlock_at': unlockAt.toIso8601String(),
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // ─── Realtime ───────────────────────────────────────────────

  RealtimeChannel subscribeToPair(
      String pairId, void Function(Map<String, dynamic>) onUpdate) {
    return _client
        .channel('pair_$pairId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'pairs',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: pairId,
          ),
          callback: (payload) {
            onUpdate(payload.newRecord);
          },
        )
        .subscribe();
  }

  void unsubscribeChannel(RealtimeChannel channel) {
    _client.removeChannel(channel);
  }
}
