/// One message in a conversation. [role] is "user" or "assistant".
class ChatMessage {
  const ChatMessage(this.role, this.content);

  final String role;
  final String content;

  bool get isUser => role == 'user';

  Map<String, dynamic> toJson() => {'role': role, 'content': content};

  factory ChatMessage.fromJson(Map<String, dynamic> json) =>
      ChatMessage(json['role'] as String, json['content'] as String);
}
