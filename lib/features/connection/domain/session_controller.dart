import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/ads/ad_config.dart';

// ─── Session state enum ────────────────────────────────────────────────────

enum SessionState { idle, active, expired }

// ─── Session data model ────────────────────────────────────────────────────

class SessionData {
  final SessionState sessionState;
  final Duration remaining;
  final int adsWatchedToday;
  final bool hasFreePass;

  const SessionData({
    this.sessionState = SessionState.idle,
    this.remaining = Duration.zero,
    this.adsWatchedToday = 0,
    this.hasFreePass = false,
  });

  SessionData copyWith({
    SessionState? sessionState,
    Duration? remaining,
    int? adsWatchedToday,
    bool? hasFreePass,
  }) {
    return SessionData(
      sessionState: sessionState ?? this.sessionState,
      remaining: remaining ?? this.remaining,
      adsWatchedToday: adsWatchedToday ?? this.adsWatchedToday,
      hasFreePass: hasFreePass ?? this.hasFreePass,
    );
  }

  /// Remaining time formatted as HH:MM:SS.
  String get formattedRemaining {
    final h = remaining.inHours.toString().padLeft(2, '0');
    final m = remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────

final sessionControllerProvider =
    NotifierProvider<SessionController, SessionData>(
  SessionController.new,
);

// ─── Storage keys ─────────────────────────────────────────────────────────

const _kSessionExpiresAt = 'session_expires_at';
const _kAdsWatchedToday = 'ads_watched_today';
const _kAdsWatchedDate = 'ads_watched_date';
const _kFreePassExpiresAt = 'free_pass_expires_at';

// ─── Controller ────────────────────────────────────────────────────────────

class SessionController extends Notifier<SessionData> {
  Timer? _ticker;

  @override
  SessionData build() {
    ref.onDispose(_dispose);
    _loadPersistedState();
    return const SessionData();
  }

  // ── Persistence helpers ──────────────────────────────────────────────────

  Future<void> _loadPersistedState() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();

    // Restore ad streak (reset if it's a new calendar day).
    final savedDate = prefs.getString(_kAdsWatchedDate) ?? '';
    final today = _dateKey(now);
    final adsWatched =
        savedDate == today ? (prefs.getInt(_kAdsWatchedToday) ?? 0) : 0;

    // Restore free pass.
    final freePassMs = prefs.getInt(_kFreePassExpiresAt) ?? 0;
    final freePassExpires = DateTime.fromMillisecondsSinceEpoch(freePassMs);
    final hasFreePass = freePassExpires.isAfter(now);

    // Restore session timer.
    final sessionExpiresMs = prefs.getInt(_kSessionExpiresAt) ?? 0;
    final sessionExpires =
        DateTime.fromMillisecondsSinceEpoch(sessionExpiresMs);

    if (sessionExpires.isAfter(now)) {
      final remaining = sessionExpires.difference(now);
      state = state.copyWith(
        sessionState: SessionState.active,
        remaining: remaining,
        adsWatchedToday: adsWatched,
        hasFreePass: hasFreePass,
      );
      _startTicker(sessionExpires);
    } else {
      state = state.copyWith(
        sessionState: SessionState.idle,
        adsWatchedToday: adsWatched,
        hasFreePass: hasFreePass,
      );
    }
  }

  // ── Public API ───────────────────────────────────────────────────────────

  /// Call this when the user has successfully watched an ad and earned a
  /// reward. Starts a new 2-hour session and increments the streak counter.
  Future<void> onAdRewarded() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final today = _dateKey(now);

    // Increment streak (reset if new day).
    final savedDate = prefs.getString(_kAdsWatchedDate) ?? '';
    final previousCount =
        savedDate == today ? (prefs.getInt(_kAdsWatchedToday) ?? 0) : 0;
    final newCount = previousCount + 1;

    await prefs.setInt(_kAdsWatchedToday, newCount);
    await prefs.setString(_kAdsWatchedDate, today);

    // Check if streak threshold reached → grant 24-hour free pass.
    bool hasFreePass = state.hasFreePass;
    if (newCount >= AdConfig.streakThreshold && !hasFreePass) {
      final midnight =
          DateTime(now.year, now.month, now.day + 1); // next midnight
      await prefs.setInt(
          _kFreePassExpiresAt, midnight.millisecondsSinceEpoch);
      hasFreePass = true;
    }

    // Start session timer.
    final sessionDuration =
        const Duration(seconds: AdConfig.sessionDurationSeconds);
    final expiresAt = now.add(sessionDuration);
    await prefs.setInt(
        _kSessionExpiresAt, expiresAt.millisecondsSinceEpoch);

    state = state.copyWith(
      sessionState: SessionState.active,
      remaining: sessionDuration,
      adsWatchedToday: newCount,
      hasFreePass: hasFreePass,
    );

    _startTicker(expiresAt);
  }

  /// Call this when the free-pass is being used (no ad watched).
  /// Starts a session without incrementing the streak.
  Future<void> onFreePassUsed() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final sessionDuration =
        const Duration(seconds: AdConfig.sessionDurationSeconds);
    final expiresAt = now.add(sessionDuration);
    await prefs.setInt(
        _kSessionExpiresAt, expiresAt.millisecondsSinceEpoch);

    state = state.copyWith(
      sessionState: SessionState.active,
      remaining: sessionDuration,
    );

    _startTicker(expiresAt);
  }

  /// Ends the current session (e.g. user manually disconnected).
  Future<void> endSession() async {
    _dispose();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kSessionExpiresAt);
    state = state.copyWith(
      sessionState: SessionState.idle,
      remaining: Duration.zero,
    );
  }

  // ── Ticker ───────────────────────────────────────────────────────────────

  void _startTicker(DateTime expiresAt) {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final remaining = expiresAt.difference(DateTime.now());
      if (remaining.isNegative || remaining == Duration.zero) {
        _ticker?.cancel();
        state = state.copyWith(
          sessionState: SessionState.expired,
          remaining: Duration.zero,
        );
      } else {
        state = state.copyWith(remaining: remaining);
      }
    });
  }

  void _dispose() {
    _ticker?.cancel();
    _ticker = null;
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  static String _dateKey(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}
