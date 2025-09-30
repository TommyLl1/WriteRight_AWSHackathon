// import 'dart:async';
// import '../models/wrong_character.dart';
// // import 'package:dio/dio.dart'; // Uncomment when implementing API calls

// class WrongCharacterService {
//   static final WrongCharacterService _instance =
//       WrongCharacterService._internal();
//   factory WrongCharacterService() => _instance;
//   WrongCharacterService._internal();
//   // Mock data - replace with API calls later
//   final List<WrongCharacter> _mockCharacters = [
//     WrongCharacter(
//       wordId: 1,
//       character: '了',
//       description: '完成、結束的意思',
//       imageUrl: 'assets/images/incorrect_word.png',
//       pronunciationUrl: 'https://example.com/liu5.mp3',
//       strokesUrl: null,
//       wrongCount: 5,
//       wrongImageUrl: 'assets/images/incorrect_word.png',
//       lastWrongAt: DateTime.now().subtract(const Duration(days: 2)),
//       createdAt: DateTime.now().subtract(const Duration(days: 30)),
//     ),
//     WrongCharacter(
//       wordId: 2,
//       character: '仁',
//       description: '仁慈、仁愛的意思',
//       imageUrl: 'assets/images/incorrect_word.png',
//       pronunciationUrl: null,
//       strokesUrl: null,
//       wrongCount: 3,
//       wrongImageUrl: 'assets/images/incorrect_word.png',
//       lastWrongAt: DateTime.now().subtract(const Duration(days: 1)),
//       createdAt: DateTime.now().subtract(const Duration(days: 25)),
//     ),
//     WrongCharacter(
//       wordId: 3,
//       character: '非',
//       description: '不是、錯誤的意思',
//       imageUrl: 'assets/images/incorrect_word.png',
//       pronunciationUrl: null,
//       strokesUrl: null,
//       wrongCount: 7,
//       wrongImageUrl: 'assets/images/incorrect_word.png',
//       lastWrongAt: DateTime.now().subtract(const Duration(hours: 5)),
//       createdAt: DateTime.now().subtract(const Duration(days: 20)),
//     ),
//     WrongCharacter(
//       wordId: 4,
//       character: '為',
//       description: '做、當作的意思',
//       imageUrl: 'assets/images/incorrect_word.png',
//       pronunciationUrl: null,
//       strokesUrl: null,
//       wrongCount: 2,
//       wrongImageUrl: 'assets/images/incorrect_word.png',
//       lastWrongAt: DateTime.now().subtract(const Duration(days: 3)),
//       createdAt: DateTime.now().subtract(const Duration(days: 15)),
//     ),
//     WrongCharacter(
//       wordId: 5,
//       character: '目',
//       description: '眼睛、目標的意思',
//       imageUrl: 'assets/images/incorrect_word.png',
//       pronunciationUrl: null,
//       strokesUrl: null,
//       wrongCount: 4,
//       wrongImageUrl: 'assets/images/incorrect_word.png',
//       lastWrongAt: DateTime.now().subtract(const Duration(days: 1)),
//       createdAt: DateTime.now().subtract(const Duration(days: 10)),
//     ),
//     WrongCharacter(
//       wordId: 6,
//       character: '日',
//       description: '太陽、一天的意思',
//       imageUrl: 'assets/images/incorrect_word.png',
//       pronunciationUrl: null,
//       strokesUrl: null,
//       wrongCount: 6,
//       wrongImageUrl: 'assets/images/incorrect_word.png',
//       lastWrongAt: DateTime.now().subtract(const Duration(hours: 12)),
//       createdAt: DateTime.now().subtract(const Duration(days: 5)),
//     ),
//     // Additional mock data to simulate larger dataset
//     ...List.generate(150, (index) {
//       final baseIndex = index + 7;
//       final characters = [
//         '月',
//         '水',
//         '火',
//         '木',
//         '金',
//         '土',
//         '天',
//         '地',
//         '人',
//         '心',
//         '手',
//         '足',
//         '眼',
//         '耳',
//         '口',
//         '鼻',
//         '頭',
//         '身',
//         '山',
//         '河',
//         '海',
//         '風',
//         '雨',
//         '雪',
//         '花',
//         '草',
//         '樹',
//         '鳥',
//         '魚',
//         '虫',
//         '狗',
//         '貓',
//         '牛',
//         '馬',
//         '羊',
//         '豬',
//         '雞',
//         '鴨',
//         '鵝',
//         '虎',
//         '獅',
//         '象',
//         '猴',
//         '熊',
//         '鹿',
//         '兔',
//         '鼠',
//         '蛇',
//         '龍',
//         '鳳',
//         '家',
//         '房',
//         '門',
//         '窗',
//         '桌',
//         '椅',
//         '床',
//         '書',
//         '筆',
//         '紙',
//         '刀',
//         '劍',
//         '弓',
//         '箭',
//         '車',
//         '船',
//         '飛',
//         '機',
//         '電',
//         '話',
//         '光',
//         '影',
//         '聲',
//         '音',
//         '色',
//         '香',
//         '味',
//         '觸',
//         '冷',
//         '熱',
//         '乾',
//         '濕',
//         '軟',
//         '硬',
//         '重',
//         '輕',
//         '大',
//         '小',
//         '長',
//         '短',
//         '高',
//         '低',
//         '寬',
//         '窄',
//         '厚',
//         '薄',
//         '新',
//         '舊',
//         '好',
//         '壞',
//         '美',
//         '醜',
//         '善',
//         '惡',
//         '真',
//         '假',
//         '對',
//         '錯',
//         '是',
//         '否',
//         '有',
//         '無',
//         '多',
//         '少',
//         '全',
//         '空',
//         '滿',
//         '缺',
//         '始',
//         '終',
//         '前',
//         '後',
//         '左',
//         '右',
//         '上',
//         '下',
//         '內',
//         '外',
//         '東',
//         '西',
//         '南',
//         '北',
//         '中',
//         '央',
//         '邊',
//         '角',
//         '圓',
//         '方',
//         '直',
//         '彎',
//         '平',
//         '斜',
//         '深',
//         '淺',
//         '遠',
//         '近',
//         '快',
//         '慢',
//         '早',
//         '晚',
//         '今',
//         '昨',
//         '明',
//         '年',
//         '月',
//         '週',
//         '日',
//         '時',
//         '分',
//         '秒'
//       ];
//       final descriptions = [
//         '表示時間概念',
//         '表示方位概念',
//         '表示顏色概念',
//         '表示動物名稱',
//         '表示物品名稱',
//         '表示自然現象',
//         '表示人體部位',
//         '表示形容詞概念',
//         '表示動作概念',
//         '表示抽象概念'
//       ];

//       return WrongCharacter(
//         wordId: baseIndex,
//         character: characters[index % characters.length],
//         description: descriptions[index % descriptions.length],
//         imageUrl: 'assets/images/incorrect_word.png',
//         pronunciationUrl:
//             index % 5 == 0 ? 'https://example.com/sound_$baseIndex.mp3' : null,
//         strokesUrl: index % 7 == 0
//             ? 'https://example.com/strokes_$baseIndex.mp4'
//             : null,
//         wrongCount: (index % 10) + 1,
//         wrongImageUrl:
//             index % 3 == 0 ? 'assets/images/incorrect_word.png' : null,
//         lastWrongAt: DateTime.now().subtract(Duration(hours: (index % 72) + 1)),
//         createdAt: DateTime.now().subtract(Duration(days: (index % 100) + 1)),
//       );
//     }),
//   ];

//   /// Searches for wrong characters based on query with pagination
//   /// This method simulates API delay and will be replaced with actual API calls
//   Future<WrongCharacterResponse> searchCharacters(
//     String query, {
//     int page = 1,
//     int pageSize = 100, // Increased to maximum allowed
//     String? userId, // Will be used for API calls
//   }) async {
//     // Simulate network delay
//     await Future.delayed(const Duration(milliseconds: 300));

//     List<WrongCharacter> filtered;

//     if (query.isEmpty) {
//       filtered = List.from(_mockCharacters);
//     } else {
//       filtered = _mockCharacters.where((character) {
//         return character.character.contains(query) ||
//             character.correctWriting.contains(query) ||
//             character.pronunciation
//                 .toLowerCase()
//                 .contains(query.toLowerCase()) ||
//             character.meaning.contains(query) ||
//             (character.description?.contains(query) ?? false);
//       }).toList();
//     }

//     // Apply pagination
//     final startIndex = (page - 1) * pageSize;
//     final endIndex = startIndex + pageSize;
//     final paginatedItems = filtered.sublist(
//       startIndex,
//       endIndex > filtered.length ? filtered.length : endIndex,
//     );

//     return WrongCharacterResponse(
//       items: paginatedItems,
//       page: page,
//       pageSize: pageSize,
//       count: filtered.length,
//     );
//   }

//   /// Gets all wrong characters with pagination
//   /// This method will be replaced with actual API calls
//   /// TODO: Replace with actual API calls
//   Future<WrongCharacterResponse> getAllCharacters({
//     int page = 1,
//     int pageSize = 100, // Increased to maximum allowed
//     String? userId, // Will be used for API calls
//   }) async {
//     // Simulate network delay
//     await Future.delayed(const Duration(milliseconds: 500));

//     // Apply pagination to mock data
//     final startIndex = (page - 1) * pageSize;
//     final endIndex = startIndex + pageSize;
//     final paginatedItems = _mockCharacters.sublist(
//       startIndex,
//       endIndex > _mockCharacters.length ? _mockCharacters.length : endIndex,
//     );

//     return WrongCharacterResponse(
//       items: paginatedItems,
//       page: page,
//       pageSize: pageSize,
//       count: _mockCharacters.length,
//     );
//   }

//   /// Loads all wrong characters at once (for hidden menu option)
//   /// This will be a separate API call on the backend later
//   /// TODO: Replace with actual API calls
//   Future<List<WrongCharacter>> loadAllCharacters({
//     String? userId, // Will be used for API calls
//   }) async {
//     // Simulate longer network delay for bulk load
//     await Future.delayed(const Duration(milliseconds: 2000));

//     return List.from(_mockCharacters);
//   }

//   /// Gets a specific character by its ID
//   /// This method will be replaced with actual API calls
//   Future<WrongCharacter?> getCharacterById(int wordId) async {
//     // Simulate network delay
//     await Future.delayed(const Duration(milliseconds: 200));

//     try {
//       return _mockCharacters.firstWhere(
//         (character) => character.wordId == wordId,
//       );
//     } catch (e) {
//       return null;
//     }
//   }

//   /// Gets a specific character by its text
//   /// This method will be replaced with actual API calls
//   Future<WrongCharacter?> getCharacterByText(String characterText) async {
//     // Simulate network delay
//     await Future.delayed(const Duration(milliseconds: 200));

//     try {
//       return _mockCharacters.firstWhere(
//         (character) => character.character == characterText,
//       );
//     } catch (e) {
//       return null;
//     }
//   }

//   // TODO: Replace with actual API integration
//   // Future<WrongCharacterResponse> _fetchFromApi(
//   //   String userId, {
//   //   int page = 1,
//   //   int pageSize = 10,
//   //   String? query,
//   // }) async {
//   //   final queryParams = <String, dynamic>{
//   //     'page': page,
//   //     'page_size': pageSize,
//   //   };
//   //
//   //   if (query != null && query.isNotEmpty) {
//   //     queryParams['search'] = query;
//   //   }
//   //
//   //   final response = await dio.get(
//   //     '/wrong-words',
//   //     queryParameters: queryParams,
//   //     options: Options(
//   //       headers: {
//   //         'user_id': userId,
//   //       },
//   //     ),
//   //   );
//   //
//   //   return WrongCharacterResponse.fromJson(response.data);
//   // }
// }
