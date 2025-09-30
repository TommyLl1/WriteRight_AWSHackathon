class WrongCharacter {
  final int wordId;
  final String character; // word from API
  final String? description; // description from API
  final String? imageUrl; // image_url from API
  final String? pronunciationUrl; // pronunciation_url from API
  final String? strokesUrl; // strokes_url from API
  final int wrongCount; // wrong_count from API
  final String? wrongImageUrl; // wrong_image_url from API
  final DateTime
      lastWrongAt; // last_wrong_at from API (converted from Unix timestamp)
  final DateTime
      createdAt; // created_at from API (converted from Unix timestamp)

  // Computed properties for backward compatibility
  String get correctWriting => character;
  String get pronunciation => pronunciationUrl ?? '';
  String get meaning => description ?? '';
  String get example => ''; // Not provided by API, empty for now
  String? get imagePath => imageUrl;
  List<String> get commonMistakes => []; // Not provided by API, empty for now

  const WrongCharacter({
    required this.wordId,
    required this.character,
    this.description,
    this.imageUrl,
    this.pronunciationUrl,
    this.strokesUrl,
    required this.wrongCount,
    this.wrongImageUrl,
    required this.lastWrongAt,
    required this.createdAt,
  });

  factory WrongCharacter.fromJson(Map<String, dynamic> json) {
    return WrongCharacter(
      wordId: json['word_id'] as int,
      character: json['word'] as String,
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      pronunciationUrl: json['pronunciation_url'] as String?,
      strokesUrl: json['strokes_url'] as String?,
      wrongCount: json['wrong_count'] as int,
      wrongImageUrl: json['wrong_image_url'] as String?,
      lastWrongAt: DateTime.fromMillisecondsSinceEpoch(
          (json['last_wrong_at'] as int) * 1000),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
          (json['created_at'] as int) * 1000),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'word_id': wordId,
      'word': character,
      'description': description,
      'image_url': imageUrl,
      'pronunciation_url': pronunciationUrl,
      'strokes_url': strokesUrl,
      'wrong_count': wrongCount,
      'wrong_image_url': wrongImageUrl,
      'last_wrong_at': lastWrongAt.millisecondsSinceEpoch ~/ 1000,
      'created_at': createdAt.millisecondsSinceEpoch ~/ 1000,
    };
  }
}

class WrongCharacterResponse {
  final List<WrongCharacter> items;
  final int page;
  final int pageSize;
  final int count;

  const WrongCharacterResponse({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.count,
  });

  factory WrongCharacterResponse.fromJson(Map<String, dynamic> json) {
    return WrongCharacterResponse(
      items: (json['items'] as List<dynamic>)
          .map((item) => WrongCharacter.fromJson(item as Map<String, dynamic>))
          .toList(),
      page: json['page'] as int,
      pageSize: json['page_size'] as int,
      count: json['count'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'items': items.map((item) => item.toJson()).toList(),
      'page': page,
      'page_size': pageSize,
      'count': count,
    };
  }
}
