class ChatMessage {
  final String role;
  final String content;

  ChatMessage(this.role, this.content);

  Map<String, dynamic> toMap() {
    return {
      'role': role,
      'content': content,
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      map['role'] as String,
      map['content'] as String,
    );
  }
}

class VlmContent {
  final String type; // "text", "image", "audio"
  final String content; // text content or file path

  VlmContent(this.type, this.content);

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'content': content,
    };
  }

  factory VlmContent.fromMap(Map<String, dynamic> map) {
    return VlmContent(
      map['type'] as String,
      map['content'] as String,
    );
  }
}

class VlmChatMessage {
  final String role;
  final List<VlmContent> contents;

  VlmChatMessage(this.role, this.contents);

  Map<String, dynamic> toMap() {
    return {
      'role': role,
      'contents': contents.map((c) => c.toMap()).toList(),
    };
  }

  factory VlmChatMessage.fromMap(Map<String, dynamic> map) {
    return VlmChatMessage(
      map['role'] as String,
      (map['contents'] as List<dynamic>)
          .map((c) => VlmContent.fromMap(c as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ChatTemplateOutput {
  final String formattedText;

  ChatTemplateOutput(this.formattedText);

  factory ChatTemplateOutput.fromMap(Map<String, dynamic> map) {
    return ChatTemplateOutput(map['formattedText'] as String);
  }
}
