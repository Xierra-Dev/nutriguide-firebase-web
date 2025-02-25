import 'package:dash_chat_2/dash_chat_2.dart';

class ChatMessage {
  final String text;
  final ChatUser user;
  final DateTime createdAt;
  final List<ChatMedia>? medias;

  ChatMessage({
    required this.text,
    required this.user,
    required this.createdAt,
    this.medias,
  });

  // Konversi dari Map (untuk membaca dari Firestore)
  factory ChatMessage.fromMap(Map<String, dynamic> map, ChatUser currentUser, ChatUser geminiUser) {
    List<ChatMedia>? medias;
    if (map['medias'] != null) {
      medias = (map['medias'] as List).map((mediaMap) {
        return ChatMedia(
          url: mediaMap['url'],
          type: MediaType.image,
          fileName: mediaMap['fileName'],
        );
      }).toList();
    }

    return ChatMessage(
      text: map['text'] ?? '',
      user: map['isUser'] ? currentUser : geminiUser,
      createdAt: (map['timestamp'] as DateTime?) ?? DateTime.now(),
      medias: medias,
    );
  }

  // Konversi ke Map (untuk menyimpan ke Firestore)
  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'isUser': user.id == "0", // Assuming "0" is the user ID and "1" is Gemini's ID
      'timestamp': createdAt,
      'medias': medias?.map((media) => {
        'url': media.url,
        'type': media.type.toString(),
        'fileName': media.fileName,
      }).toList(),
    };
  }

  // Copy with method untuk membuat salinan dengan modifikasi
  ChatMessage copyWith({
    String? text,
    ChatUser? user,
    DateTime? createdAt,
    List<ChatMedia>? medias,
  }) {
    return ChatMessage(
      text: text ?? this.text,
      user: user ?? this.user,
      createdAt: createdAt ?? this.createdAt,
      medias: medias ?? this.medias,
    );
  }

  // Override equals operator untuk membandingkan pesan
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is ChatMessage &&
        other.text == text &&
        other.user.id == user.id &&
        other.createdAt == createdAt;
  }

  // Override hashCode
  @override
  int get hashCode => text.hashCode ^ user.hashCode ^ createdAt.hashCode;

  // Override toString untuk debugging
  @override
  String toString() {
    return 'ChatMessage(text: $text, user: ${user.firstName}, createdAt: $createdAt, hasMedia: ${medias != null})';
  }
}