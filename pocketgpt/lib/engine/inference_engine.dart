import '../models/chat_message.dart';

/// Whether the AI engine can answer right now, and a human-readable reason.
class EngineStatus {
  const EngineStatus(this.ready, this.message);

  final bool ready;
  final String message;
}

class EngineException implements Exception {
  const EngineException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// The one interface the UI talks to. Windows and web use the llama.cpp
/// server; Android will get an on-device implementation later (Phase 7).
abstract class InferenceEngine {
  Future<EngineStatus> status();

  /// Streams the assistant's reply piece by piece.
  Stream<String> chat(List<ChatMessage> history);

  /// Stops a reply that is still being generated.
  void cancel();
}

/// Used where no real engine exists yet. It never invents answers.
class UnavailableEngine implements InferenceEngine {
  const UnavailableEngine(this.reason);

  final String reason;

  @override
  Future<EngineStatus> status() async => EngineStatus(false, reason);

  @override
  Stream<String> chat(List<ChatMessage> history) =>
      Stream.error(EngineException(reason));

  @override
  void cancel() {}
}
