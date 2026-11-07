import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/chat_message.dart';
import '../state/providers.dart';

class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  void _send() {
    final text = _input.text;
    _input.clear();
    ref.read(chatProvider.notifier).send(text);
  }

  @override
  Widget build(BuildContext context) {
    final chat = ref.watch(chatProvider);
    final controller = ref.read(chatProvider.notifier);
    final ready = chat.engine?.ready ?? false;
    final scheme = Theme.of(context).colorScheme;

    ref.listen(chatProvider, (_, __) => _scrollToEnd());

    return Scaffold(
      appBar: AppBar(
        title: const Text('PocketGPT'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Chip(
              avatar: Icon(
                Icons.circle,
                size: 12,
                color: ready ? Colors.green : scheme.error,
              ),
              label: Text(ready ? 'Ready' : 'Offline'),
            ),
          ),
          IconButton(
            tooltip: 'Check engine',
            icon: const Icon(Icons.refresh),
            onPressed: controller.refreshStatus,
          ),
          IconButton(
            tooltip: 'Clear chat',
            icon: const Icon(Icons.delete_outline),
            onPressed: chat.generating ? null : controller.clearChat,
          ),
        ],
      ),
      body: Column(
        children: [
          if (!ready && chat.engine != null)
            MaterialBanner(
              content: Text(chat.engine!.message),
              leading: const Icon(Icons.info_outline),
              actions: [
                TextButton(
                  onPressed: controller.refreshStatus,
                  child: const Text('Retry'),
                ),
              ],
            ),
          Expanded(
            child: chat.messages.isEmpty
                ? const Center(child: Text('Ask anything. Everything stays on this device.'))
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(12),
                    itemCount: chat.messages.length,
                    itemBuilder: (_, i) => _Bubble(message: chat.messages[i]),
                  ),
          ),
          if (chat.error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(chat.error!, style: TextStyle(color: scheme.error)),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      minLines: 1,
                      maxLines: 5,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        hintText: 'Message PocketGPT',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  chat.generating
                      ? IconButton.filledTonal(
                          tooltip: 'Stop',
                          icon: const Icon(Icons.stop),
                          onPressed: controller.stop,
                        )
                      : IconButton.filled(
                          tooltip: 'Send',
                          icon: const Icon(Icons.send),
                          onPressed: ready ? _send : null,
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final user = message.isUser;
    return Align(
      alignment: user ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        decoration: BoxDecoration(
          color: user ? scheme.primaryContainer : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: SelectableText(message.content.isEmpty ? '…' : message.content),
      ),
    );
  }
}
