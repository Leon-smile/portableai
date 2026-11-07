import 'package:flutter_test/flutter_test.dart';
import 'package:pocketgpt/engine/llama_server_engine.dart';

void main() {
  test('parseChunk reads delta content', () {
    const data = '{"choices":[{"delta":{"content":"Hello"}}]}';
    expect(LlamaServerEngine.parseChunk(data), 'Hello');
  });

  test('parseChunk returns null when there is no text', () {
    expect(LlamaServerEngine.parseChunk('{"choices":[]}'), isNull);
    expect(
      LlamaServerEngine.parseChunk('{"choices":[{"delta":{}}]}'),
      isNull,
    );
  });
}
