import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/chat_message.dart';

/// Where chats are saved. Swap the implementation without touching the UI.
abstract class ChatStorage {
  Future<List<ChatMessage>> load();
  Future<void> save(List<ChatMessage> messages);
  Future<void> clear();
}

/// Works on Windows, Android and web (browser storage on web).
/// Phase 6 replaces this with SQLite and multi-chat history.
class PrefsChatStorage implements ChatStorage {
  static const _key = 'pocketgpt.chat.v1';

  @override
  Future<List<ChatMessage>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> save(List<ChatMessage> messages) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(messages.map((m) => m.toJson()).toList()),
    );
  }

  @override
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
