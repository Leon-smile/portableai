import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../engine/inference_engine.dart';
import '../engine/llama_server_engine.dart';
import '../engine/system_prompt.dart';
import '../models/chat_message.dart';
import '../storage/chat_storage.dart';

final storageProvider = Provider<ChatStorage>((ref) => PrefsChatStorage());

/// Picks the engine for the current platform.
final engineProvider = Provider<InferenceEngine>((ref) {
  if (kIsWeb) {
    // The web UI is served by llama-server itself, so same origin.
    return LlamaServerEngine(baseUrl: Uri.base.origin);
  }
  if (defaultTargetPlatform == TargetPlatform.windows) {
    return LlamaServerEngine(baseUrl: 'http://127.0.0.1:8080');
  }
  return const UnavailableEngine(
    'On-device engine for this platform is not built yet (Phase 7).',
  );
});

class ChatState {
  const ChatState({
    this.messages = const [],
    this.generating = false,
    this.engine,
    this.error,
  });

  final List<ChatMessage> messages;
  final bool generating;
  final EngineStatus? engine;
  final String? error;

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? generating,
    EngineStatus? engine,
    String? error,
    bool clearError = false,
  }) =>
      ChatState(
        messages: messages ?? this.messages,
        generating: generating ?? this.generating,
        engine: engine ?? this.engine,
        error: clearError ? null : (error ?? this.error),
      );
}

class ChatController extends Notifier<ChatState> {
  bool _cancelled = false;

  @override
  ChatState build() {
    Future.microtask(_init);
    return const ChatState();
  }

  Future<void> _init() async {
    final messages = await ref.read(storageProvider).load();
    final status = await ref.read(engineProvider).status();
    state = state.copyWith(messages: messages, engine: status);
  }

  Future<void> refreshStatus() async {
    final status = await ref.read(engineProvider).status();
    state = state.copyWith(engine: status);
  }

  Future<void> send(String text) async {
    final prompt = text.trim();
    if (prompt.isEmpty || state.generating) return;

    final history = [...state.messages, ChatMessage('user', prompt)];
    state = state.copyWith(
      messages: [...history, const ChatMessage('assistant', '')],
      generating: true,
      clearError: true,
    );
    _cancelled = false;

    final buffer = StringBuffer();
    try {
      final request = [buildSystemMessage(DateTime.now()), ...history];
      await for (final chunk in ref.read(engineProvider).chat(request)) {
        buffer.write(chunk);
        _setLastAssistant(buffer.toString());
      }
    } catch (e) {
      if (!_cancelled) state = state.copyWith(error: e.toString());
    } finally {
      // Never keep an empty assistant bubble: no reply means no message.
      final saved = buffer.isEmpty
          ? history
          : [...history, ChatMessage('assistant', buffer.toString())];
      state = state.copyWith(messages: saved, generating: false);
      await ref.read(storageProvider).save(saved);
      await refreshStatus();
    }
  }

  void stop() {
    _cancelled = true;
    ref.read(engineProvider).cancel();
  }

  Future<void> clearChat() async {
    if (state.generating) return;
    await ref.read(storageProvider).clear();
    state = state.copyWith(messages: const [], clearError: true);
  }

  void _setLastAssistant(String text) {
    final updated = [...state.messages];
    updated[updated.length - 1] = ChatMessage('assistant', text);
    state = state.copyWith(messages: updated);
  }
}

final chatProvider =
    NotifierProvider<ChatController, ChatState>(ChatController.new);
