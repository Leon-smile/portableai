import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/chat_message.dart';
import 'inference_engine.dart';

/// Talks to a local llama.cpp `llama-server` over its OpenAI-compatible API.
class LlamaServerEngine implements InferenceEngine {
  LlamaServerEngine({required this.baseUrl});

  final String baseUrl;
  http.Client? _client;

  @override
  Future<EngineStatus> status() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        return const EngineStatus(true, 'Model ready');
      }
      return EngineStatus(false, 'Model is loading (HTTP ${res.statusCode})');
    } catch (_) {
      return const EngineStatus(
        false,
        'Engine not running. Start it with Start-PocketGPT.bat',
      );
    }
  }

  @override
  Stream<String> chat(List<ChatMessage> history) async* {
    final client = http.Client();
    _client = client;
    try {
      final request = http.Request('POST', Uri.parse('$baseUrl/v1/chat/completions'))
        ..headers['Content-Type'] = 'application/json'
        ..body = jsonEncode({
          'messages': history.map((m) => m.toJson()).toList(),
          'stream': true,
        });

      final response = await client.send(request);
      if (response.statusCode != 200) {
        throw EngineException('Engine returned HTTP ${response.statusCode}');
      }

      // Server-sent events: lines like `data: {...json...}` and `data: [DONE]`.
      final lines = response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      await for (final line in lines) {
        if (!line.startsWith('data:')) continue;
        final data = line.substring(5).trim();
        if (data == '[DONE]') break;
        final piece = parseChunk(data);
        if (piece != null && piece.isNotEmpty) yield piece;
      }
    } finally {
      client.close();
      if (identical(_client, client)) _client = null;
    }
  }

  /// Pulls the text out of one streamed JSON chunk. Public so it can be tested.
  static String? parseChunk(String data) {
    final json = jsonDecode(data) as Map<String, dynamic>;
    final choices = json['choices'] as List?;
    if (choices == null || choices.isEmpty) return null;
    final delta = (choices.first as Map)['delta'] as Map?;
    return delta?['content'] as String?;
  }

  @override
  void cancel() {
    _client?.close();
    _client = null;
  }
}
