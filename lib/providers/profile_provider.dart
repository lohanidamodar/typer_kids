import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/profile.dart';

/// Manages user profiles — create, switch, delete.
///
/// Storage keys:
///   `profiles`        → JSON-encoded list of Profile objects
///   `active_profile`  → ID of the currently active profile
class ProfileProvider extends ChangeNotifier {
  SharedPreferences? _prefs;
  List<Profile> _profiles = [];
  String? _activeProfileId;
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;
  List<Profile> get profiles => List.unmodifiable(_profiles);
  String? get activeProfileId => _activeProfileId;

  Profile? get activeProfile {
    if (_activeProfileId == null) return null;
    try {
      return _profiles.firstWhere((p) => p.id == _activeProfileId);
    } catch (_) {
      return null;
    }
  }

  bool get hasProfiles => _profiles.isNotEmpty;
  bool get hasActiveProfile => activeProfile != null;

  /// Initialize and load saved profiles.
  ///
  /// If there is legacy progress data (keys starting with `progress_` without
  /// a profile prefix), we auto-create a default profile and migrate the data.
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _loadProfiles();
    _activeProfileId = _prefs?.getString('active_profile');

    // Migrate legacy data if no profiles exist but old progress keys are found
    await _migrateLegacyData();

    // If active profile was deleted, clear it
    if (_activeProfileId != null && activeProfile == null) {
      _activeProfileId = null;
      await _prefs?.remove('active_profile');
    }
    _isLoaded = true;
    notifyListeners();
  }

  /// Migrates data from the old single-user format (keys like `progress_hr-01`)
  /// to the new per-profile format (keys like `profile_{id}_progress_hr-01`).
  Future<void> _migrateLegacyData() async {
    if (_prefs == null) return;
    // Only migrate if there are no profiles yet
    if (_profiles.isNotEmpty) return;

    final allKeys = _prefs!.getKeys();
    final legacyKeys = allKeys.where((k) => k.startsWith('progress_')).toList();
    final legacyLastLesson = _prefs!.getString('last_lesson_id');

    if (legacyKeys.isEmpty && legacyLastLesson == null) return;

    // Create a default profile for the existing user
    final profile = await createProfile(name: 'Player 1', emoji: '🐵');
    final prefix = 'profile_${profile.id}_';

    // Copy all legacy progress keys to the new prefix
    for (final key in legacyKeys) {
      final value = _prefs!.getString(key);
      if (value != null) {
        await _prefs!.setString('$prefix$key', value);
      }
      await _prefs!.remove(key);
    }

    // Migrate last lesson
    if (legacyLastLesson != null) {
      await _prefs!.setString('${prefix}last_lesson_id', legacyLastLesson);
      await _prefs!.remove('last_lesson_id');
    }
  }

  void _loadProfiles() {
    final raw = _prefs?.getString('profiles');
    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List<dynamic>;
        _profiles = list
            .map((e) => Profile.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {
        _profiles = [];
      }
    }
  }

  Future<void> _saveProfiles() async {
    final json = jsonEncode(_profiles.map((p) => p.toJson()).toList());
    await _prefs?.setString('profiles', json);
  }

  /// Create a new profile and make it active
  Future<Profile> createProfile({
    required String name,
    required String emoji,
  }) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final profile = Profile(
      id: id,
      name: name,
      emoji: emoji,
      createdAt: DateTime.now(),
    );
    _profiles.add(profile);
    await _saveProfiles();
    await setActiveProfile(id);
    return profile;
  }

  /// Switch the active profile
  Future<void> setActiveProfile(String profileId) async {
    _activeProfileId = profileId;
    await _prefs?.setString('active_profile', profileId);
    notifyListeners();
  }

  /// Delete a profile and all its progress data
  Future<void> deleteProfile(String profileId) async {
    _profiles.removeWhere((p) => p.id == profileId);
    await _saveProfiles();

    // Remove all progress keys that belong to this profile
    final allKeys = _prefs?.getKeys() ?? {};
    final prefix = 'profile_${profileId}_';
    for (final key in allKeys) {
      if (key.startsWith(prefix)) {
        await _prefs?.remove(key);
      }
    }

    // If this was the active profile, clear it
    if (_activeProfileId == profileId) {
      _activeProfileId = _profiles.isNotEmpty ? _profiles.first.id : null;
      if (_activeProfileId != null) {
        await _prefs?.setString('active_profile', _activeProfileId!);
      } else {
        await _prefs?.remove('active_profile');
      }
    }

    notifyListeners();
  }

  /// Update a profile's name or emoji
  Future<void> updateProfile({
    required String profileId,
    String? name,
    String? emoji,
  }) async {
    final index = _profiles.indexWhere((p) => p.id == profileId);
    if (index < 0) return;
    final old = _profiles[index];
    _profiles[index] = Profile(
      id: old.id,
      name: name ?? old.name,
      emoji: emoji ?? old.emoji,
      createdAt: old.createdAt,
    );
    await _saveProfiles();
    notifyListeners();
  }
}
