// import 'package:flutter/material.dart';
// import 'package:writeright/backend/factories/game_service_factory.dart';
// import 'package:writeright/backend/models/questions.dart';
// import 'package:writeright/game/q_list.dart';
// import 'package:writeright/new/ui/view/result_page/result_page.dart';
// import 'package:writeright/utils/api_service.dart';
// import '../backend/models/game.dart';
// import '../backend/services/game_service.dart';
// import 'package:get_it/get_it.dart';
// import 'package:writeright/game/cards/popup.dart';
// import 'package:writeright/utils/logger.dart';
// import 'cards/hearts.dart';
// import '../new/ui/view/game_page/widgets/questions/listening.dart';
// import 'q_type1.dart';
// import '../new/ui/view/game_page/widgets/questions/copy_stroke.dart';
// import '../new/ui/view/game_page/widgets/questions/fill_in_sentence.dart';
// import '../new/ui/view/game_page/widgets/questions/pairing_cards.dart';

// /// Sample data for testing
// List<QuestionBase> sampleQuestions = [
//   PairingCardsQuestion.fromJson({
//     "question_id": "mock-game-id-${DateTime.now().millisecondsSinceEpoch}",
//     "question_type": "pairing_cards",
//     "answer_type": "pairing",
//     "exp": 10,
//     "target_word": "配對",
//     "prompt": "請將相對應的詞語配對",
//     "given": [
//       {
//         "material_type": "text_short",
//         "material_id": 1,
//         "image_url": null,
//         "alt_text": null,
//         "sound_url": null,
//         "text": "請將左邊和右邊意思相同的詞語配對"
//       }
//     ],
//     "mcq": null,
//     "pairing": {
//       "time_limit": 0,
//       "randomize": true,
//       "display": {"display_type": "grid", "rows": 4, "columns": 2},
//       "pairs": [
//         {
//           "pair_id": 1,
//           "items": [
//             {"option_id": 1, "text": "高興", "image": null},
//             {"option_id": 2, "text": "開心", "image": null}
//           ]
//         },
//         {
//           "pair_id": 2,
//           "items": [
//             {"option_id": 3, "text": "難過", "image": null},
//             {"option_id": 4, "text": "傷心", "image": null}
//           ]
//         },
//         {
//           "pair_id": 3,
//           "items": [
//             {"option_id": 5, "text": "憤怒", "image": null},
//             {"option_id": 6, "text": "生氣", "image": null}
//           ]
//         },
//         {
//           "pair_id": 4,
//           "items": [
//             {"option_id": 7, "text": "嫉妒", "image": null},
//             {"option_id": 8, "text": "眼紅", "image": null}
//           ]
//         },
//       ],
//       "submitted_pairs": null
//     },
//     "writing": null
//   }),
//   ListeningQuestion.fromJson({
//     "question_id": "f8efe52f-bc40-487d-b636-0f7be533810f",
//     "question_type": "listening",
//     "answer_type": "mcq",
//     "exp": 10,
//     "target_word": "尬",
//     "prompt": "Select the correct answer",
//     "given": [
//       {
//         "material_type": "sound",
//         "material_id": 1,
//         "image_url": null,
//         "alt_text": null,
//         "sound_url":
//             "https://www.secmenu.com/apps/words/www/audio/cantonese/gaai3.mp3",
//         "text": null
//       }
//     ],
//     "mcq": {
//       "time_limit": 0,
//       "min_choices": 1,
//       "max_choices": 1,
//       "choices": [
//         {"option_id": 1, "text": "尬", "image": "尬"},
//         {"option_id": 2, "text": "的", "image": "的"},
//         {"option_id": 3, "text": "是", "image": "是"},
//         {"option_id": 4, "text": "草", "image": "草"}
//       ],
//       "strict_order": false,
//       "randomize": true,
//       "display": {"display_type": "list", "rows": 4, "columns": null},
//       "answers": [
//         {
//           "answer_id": 1,
//           "choices": [1]
//         }
//       ],
//       "submitted_answers": null
//     },
//     "pairing": null,
//     "writing": null
//   }),
//   PairingCardsQuestion.fromJson({
//     "question_id": "123abc45-def6-7890-gh12-ijk345lmn678",
//     "question_type": "pairing_cards",
//     "answer_type": "pairing",
//     "exp": 10,
//     "target_word": "配對",
//     "prompt": "請將相對應的詞語配對",
//     "given": [
//       {
//         "material_type": "text_short",
//         "material_id": 1,
//         "image_url": null,
//         "alt_text": null,
//         "sound_url": null,
//         "text": "請將左邊和右邊意思相同的詞語配對"
//       }
//     ],
//     "mcq": null,
//     "pairing": {
//       "time_limit": 0,
//       "randomize": true,
//       "display": {"display_type": "grid", "rows": 2, "columns": 2},
//       "pairs": [
//         {
//           "pair_id": 1,
//           "items": [
//             {"option_id": 1, "text": "高興", "image": null},
//             {"option_id": 2, "text": "開心", "image": null}
//           ]
//         },
//         {
//           "pair_id": 2,
//           "items": [
//             {"option_id": 3, "text": "難過", "image": null},
//             {"option_id": 4, "text": "傷心", "image": null}
//           ]
//         }
//       ],
//       "submitted_pairs": null
//     },
//     "writing": null
//   }),
//   FillInVocabQuestion.fromJson({
//     "question_id": "6952c7de-3adb-48ef-8efc-b946471336f6",
//     "question_type": "fill_in_vocab",
//     "answer_type": "mcq",
//     "exp": 10,
//     "target_word": "普",
//     "prompt": "Fill in the blank",
//     "given": [
//       {
//         "material_type": "text_short",
//         "material_id": 1,
//         "image_url": null,
//         "alt_text": null,
//         "sound_url": null,
//         "text": "？通"
//       }
//     ],
//     "mcq": {
//       "time_limit": 0,
//       "min_choices": 1,
//       "max_choices": 1,
//       "choices": [
//         {"option_id": 1, "text": "普", "image": "普"},
//         {"option_id": 2, "text": "譜", "image": "娃"},
//         {"option_id": 3, "text": "蒲", "image": "哇"},
//         {"option_id": 4, "text": "舖", "image": "蛙"}
//       ],
//       "strict_order": false,
//       "randomize": true,
//       "display": {"display_type": "list", "rows": 4, "columns": null},
//       "answers": [
//         {
//           "answer_id": 1,
//           "choices": [1]
//         }
//       ],
//       "submitted_answers": null
//     },
//     "pairing": null,
//     "writing": null
//   }),
//   FillInSentenceQuestion.fromJson({
//     "question_id": "6952c7de-3adb-48ef-8efc-b946471336f6",
//     "question_type": "fill_in_vocab",
//     "answer_type": "mcq",
//     "exp": 10,
//     "target_word": "晴",
//     "prompt": "Fill in the blank",
//     "given": [
//       {
//         "material_type": "text_short",
//         "material_id": 1,
//         "image_url": null,
//         "alt_text": null,
//         "sound_url": null,
//         "text": "太陽出來了，今天的天氣很?朗"
//       }
//     ],
//     "mcq": {
//       "time_limit": 0,
//       "min_choices": 1,
//       "max_choices": 1,
//       "choices": [
//         {"option_id": 1, "text": "尬", "image": "口"},
//         {"option_id": 2, "text": "讓", "image": "娃"},
//         {"option_id": 3, "text": "廣", "image": "哇"},
//         {"option_id": 4, "text": "晴", "image": "蛙"}
//       ],
//       "strict_order": false,
//       "randomize": true,
//       "display": {"display_type": "list", "rows": 4, "columns": null},
//       "answers": [
//         {
//           "answer_id": 1,
//           "choices": [4]
//         }
//       ],
//       "submitted_answers": null
//     },
//     "pairing": null,
//     "writing": null
//   }),
//   CopyStrokeQuestion.fromJson({
//     "question_id": "b2039119-2103-410f-9056-68a77ed047d9",
//     "question_type": "copy_stroke",
//     "answer_type": "writing",
//     "exp": 10,
//     "target_word": "哪",
//     "prompt": "Write the character below",
//     "given": [],
//     "mcq": null,
//     "pairing": null,
//     "writing": {
//       "time_limit": 0,
//       "handwrite_target": "哪",
//       "submit_url":
//           "https://mock-s3-service.com/submit/b2977f0b-b464-4be3-9057-984e7ac4c9a9",
//       "background_image": null,
//       "submitted_image": null,
//       "is_correct": null
//     }
//   }),
// ];

// // trying to hold all state in game widget, then pass it down to the question widget.
// // Fixed the hearts and back button on the top row (cause they are connected to the game state)
// // (should be broken cause the question widget are dynamic in size and content)
// // The question fetching is done in the game widget for now, but put questions as arguments might be better
// // I avoided making too many changes to original code
// // Now only written q1 and q3

// class Game extends StatefulWidget {
//   final String userId;

//   const Game({super.key, required this.userId});

//   @override
//   GameState createState() => GameState();
// }

// class GameState extends State<Game> {
//   GameService? gameService;
//   // Define the game object
//   late Future<GameObject?> gameObjectFuture;
//   GameObject? gameObject;

//   // Set initial states
//   // Use ptr to lazy load the questions
//   int currentQuestionIndex = 0;
//   int lives = 4;

//   // Key for the popup message and lives display
//   final GlobalKey<PopupMessageWidgetState> _popupKey = GlobalKey();
//   final GlobalKey<LivesDisplayState> _livesDisplayKey = GlobalKey();

//   @override
//   void initState() {
//     super.initState();
//     AppLogger.debug("GameState initialized");
//     gameObjectFuture = fetchGameData();
//   }

//   /// Fetches GameObject data from the backend
//   /// TODO: Decide to do this in previous screen or here
//   Future<GameObject?> fetchGameData() async {
//     // Get the GameService instance from GetIt (dependency)
//     gameService = await GameServiceFactory.getAsync();
//     if (gameService == null) {
//       AppLogger.error("GameService is not initialized");
//       return null; // Handle the error as needed
//     }
//     try {
//       // Fetch the game data asynchronously
//       gameObject = await gameService!.startGame(
//         userId:
//             "b2977f0b-b464-4be3-9057-984e7ac4c9a9", // Replace with actual userId
//         qCount: 10, // Default number of questions
//       );
//       AppLogger.info("Game data fetched successfully: ${gameObject?.toJson()}");
//       return gameObject;
//     } catch (e) {
//       // Handle errors (optional)
//       AppLogger.info("Error fetching game data: $e");
//       return null; // Return null or handle as needed
//     }

//     // For testing, use sample questions
//     // Mock timer
//     // await Future.delayed(const Duration(seconds: 1));

//     // AppLogger.debug("question count: ${sampleQuestions.length}");
//     // return GameObject(
//     //     questions: sampleQuestions,
//     //     generatedAt: DateTime.now().millisecondsSinceEpoch,
//     //     userId: widget.userId,
//     //     gameId: "mock-game-id-${DateTime.now().millisecondsSinceEpoch}");

//     // intentially fail the future
//     // await Future.delayed(const Duration(seconds: 1), () {
//     //   throw Exception("Failed to fetch game data");
//     // });
//   }

//   /// Builds the question widget based on the question type
//   Widget buildQuestionWidget({
//     required QuestionBase question,
//     required Function(AnswerMethodBase) onAnswer,
//     required bool Function(void) pairingOnWrongAnswer,
//   }) {
//     switch (question.questionType) {
//       case QuestionType.fillInVocab:
//         return FillInvocabView(
//           key: ValueKey(question.questionId),
//           // Casted to FillInVocabQuestion, the switch should have checked the class
//           question: question as FillInVocabQuestion,
//           onAnswer: onAnswer,
//         );
//       case QuestionType.listening:
//         return ListeningQuestionView(
//           key: ValueKey(question.questionId),
//           question: question as ListeningQuestion,
//           onAnswer: onAnswer,
//         );
//       case QuestionType.copyStroke:
//         return CopyStrokeView(
//           key: ValueKey(question.questionId),
//           question: question as CopyStrokeQuestion,
//           onAnswer: onAnswer,
//         );
//       case QuestionType.fillInSentence:
//         return QuestionType7(
//           key: ValueKey(question.questionId),
//           question: question as FillInSentenceQuestion,
//           onAnswer: onAnswer,
//         );
//       case QuestionType.pairingCards:
//         Key key = ValueKey(question.questionId);
//         AppLogger.debug("Creating PairingCardsQType with key: $key");
//         return PairingCardsQType(
//           key: key,
//           answerPairing: (question as PairingCardsQuestion).pairing,
//           onWrongAnswer: pairingOnWrongAnswer,
//           onPairsSubmitted: onAnswer,
//         );
//       default:
//         return Center(child: Text("Unsupported question type"));
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     Widget questionContent = SafeArea(
//       child: FutureBuilder(
//         future: gameObjectFuture,
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             // Placeholder for waiting state
//             return const Center(child: CircularProgressIndicator());
//           } else if (snapshot.hasError) {
//             // Placeholder for error state
//             return Expanded(
//                 child: Center(
//               child: Text(
//                 "Error: ${snapshot.error}",
//                 style: TextStyle(color: Colors.white, fontSize: 16),
//               ),
//             ));
//           } else {
//             // Data is available, update the gameObject
//             gameObject = snapshot.data;
//             // Once the data is fetched, build the game UI
//             return buildQuestionWidget(
//               question: gameObject!.questions[currentQuestionIndex],
//               onAnswer: _onAnswer,
//               pairingOnWrongAnswer: opPairingWrongAnswer,
//             );
//           }
//         },
//       ),
//     );

//     Widget promptWidget = FutureBuilder(
//       future: gameObjectFuture,
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           // Show placeholder text while waiting
//           return const Padding(
//             padding: EdgeInsets.symmetric(horizontal: 20.0),
//             child: Text(
//               "Loading question...",
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 color: Colors.white,
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           );
//         } else if (snapshot.hasError) {
//           // Show error message
//           return const Padding(
//             padding: EdgeInsets.symmetric(horizontal: 20.0),
//             child: Text(
//               "Error loading question",
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 color: Colors.red,
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           );
//         } else if (snapshot.hasData) {
//           // Safely assign the non-null data to gameObject
//           gameObject = snapshot.data;

//           if (gameObject != null && gameObject!.questions.isNotEmpty) {
//             return Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 20.0),
//               child: Text(
//                 gameObject!.questions[currentQuestionIndex].prompt,
//                 textAlign: TextAlign.center,
//                 style: const TextStyle(
//                   color: Colors.white,
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             );
//           } else {
//             // Handle case where `questions` is empty or null
//             return const Padding(
//               padding: EdgeInsets.symmetric(horizontal: 20.0),
//               child: Text(
//                 "No questions available.",
//                 textAlign: TextAlign.center,
//                 style: TextStyle(
//                   color: Colors.grey,
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             );
//           }
//         } else {
//           // Fallback case if neither `hasData` nor `hasError`
//           return const Padding(
//             padding: EdgeInsets.symmetric(horizontal: 20.0),
//             child: Text(
//               "Unexpected error occurred.",
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 color: Colors.red,
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           );
//         }
//       },
//     );

//     /// Wrapper around the QuestionFactory widget
//     /// Including lives display, return, popup message
//     return Scaffold(
//       backgroundColor: const Color(0xFF0A3D62), // Deep blue background
//       body: Stack(
//         children: [
//           SafeArea(
//             child: Column(
//               children: [
//                 // Add a container to hold the health bar and back button
//                 Container(
//                   padding: const EdgeInsets.all(20),
//                   child: Stack(
//                     children: [
//                       // Back Button (aligned to the left)
//                       Align(
//                         alignment: Alignment.centerLeft,
//                         child: IconButton(
//                           icon:
//                               const Icon(Icons.arrow_back, color: Colors.white),
//                           onPressed: _onBackPressed,
//                         ),
//                       ),

//                       // Health Bar (aligned to the center)
//                       Align(
//                         alignment: Alignment.center,
//                         child: Padding(
//                           padding: const EdgeInsets.only(
//                             top: 8,
//                           ),
//                           child: LivesDisplay(
//                             key: _livesDisplayKey, // To get the state of lives
//                             initialLives: lives, // Update as needed
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),

//                 promptWidget, // Question prompt widget

//                 const SizedBox(
//                     height: 20), // Spacing between prompt and question content

//                 // Question Factory Widget
//                 Expanded(
//                   child: Center(
//                     child: ConstrainedBox(
//                       constraints: BoxConstraints(
//                         maxWidth: 800, // Set the maximum width to 800 pixels
//                       ),
//                       child: questionContent, // Your content widget
//                     ),
//                   ),
//                 ),

//                 const SizedBox(height: 20), // Spacing
//               ],
//             ),
//           ),

//           // Popup Message Widget
//           PopupMessageWidget(
//             key: _popupKey,
//             onButtonPressed: onNextQuestion,
//           ),
//         ],
//       ),
//     );
//   }

//   /// Callback function for the popup message
//   void onNextQuestion(bool isLast) async {
//     // handles moving to the next question or ending the game
//     // hide popup message
//     // change current question index

//     if (isLast || lives <= 0) {
//       // If it's the last question, show game over message
//       AppLogger.info("Game Over! Last question reached or lives are 0.");
//       _endGame();
//     } else {
//       // Move to the next question
//       setState(() {
//         currentQuestionIndex++;
//       });
//     }
//   }

//   /// handle end game logic
//   /// Called by the popup message when the game is over
//   /// or called when lives reach 0
//   /// TODO: error handling
//   void _endGame() async {
//     SubmitResponse response;
//     if (gameObject == null) {
//       gameService = await GameServiceFactory.getAsync();
//     }

//     /// Send api request to get game result
//     response = await gameService!.submitGameResult(game: gameObject!);

//     // For testing, create a mock response
//     /// Assumed gameObject is not null and has valid data
//     // response = SubmitResponse(
//     //   gameId: gameObject!.gameId,
//     //   userId: gameObject!.userId,
//     //   score: 100, // Mock score
//     //   timeTaken: 60, // Mock time taken in seconds
//     //   questions: gameObject!.questions,
//     //   earnedExp: 50, // Mock experience points earned
//     //   remainingHearts: lives, // Remaining lives
//     // );

//     // Jump to the result screen
//     if (mounted) {
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(
//           builder: (context) => ResultPage(
//             result: response,
//           ),
//         ),
//       );
//     }
//   }

//   void _onBackPressed() {
//     // Handle back button press
//     // For now, just pop the current screen
//     Navigator.pop(context);
//   }

//   /// callback for pairing question
//   /// If the answer is wrong
//   /// If no more lives left, return false
//   /// No popup message shown here
//   bool opPairingWrongAnswer(void pairing) {
//     // Decrease lives
//     _livesDisplayKey.currentState?.loseLife();
//     setState(() {
//       lives--;
//     });

//     return lives > 0; // Return true if lives are left, false if no lives left
//   }

//   /// Handles the answer submission logic
//   /// Puts the answer into the **current** question entry
//   /// Callback function for the QuestionFactory widget
//   ///
//   /// @param answer Should be already filled with answer data.
//   /// No extra validation on the answer
//   void _onAnswer(AnswerMethodBase answer) {
//     // There are only 3 types of answer objects:
//     // AnswerMultiChoice, AnswerHandwrite, AnswerPairing
//     // All are from AnswerMethodBase
//     // Check if arg answer is one of the answer types

//     AppLogger.debug("running _onAnswer with answer: ${answer.runtimeType}");

//     // Put the answer into the question entry
//     bool isCorrect = false;
//     if (answer is AnswerMultiChoice) {
//       QuestionBase currentQuestion =
//           gameObject!.questions[currentQuestionIndex];
//       if (currentQuestion is MultiChoiceQuestion) {
//         currentQuestion.mcq = answer;
//         isCorrect = currentQuestion.mcq.isCorrect;
//       }
//     } else if (answer is AnswerHandwrite) {
//       QuestionBase currentQuestion =
//           gameObject!.questions[currentQuestionIndex];
//       if (currentQuestion is HandwriteQuestion) {
//         currentQuestion.writing = answer;
//         isCorrect = currentQuestion.writing.isCorrect ??
//             false; // Default to false if isCorrect is null
//       }
//     } else if (answer is AnswerPairing) {
//       QuestionBase currentQuestion =
//           gameObject!.questions[currentQuestionIndex];
//       if (currentQuestion is PairingQuestion) {
//         currentQuestion.pairing = answer;

//         /// If completed the question, this will always be true
//         /// Allowing this function can be called even when terminated due to lives being 0
//         isCorrect = currentQuestion.pairing.isCorrect;
//         AppLogger.debug("isCorrect: $isCorrect");
//       }
//     } else {
//       // Unsupported answer type
//       AppLogger.info("Unsupported answer type: ${answer.runtimeType}");
//     }

//     // If the answer is not AnswerPairing, we can update the health
//     if (answer is! AnswerPairing) {
//       setState(() {
//         if (!isCorrect) {
//           // Decrease lives if the answer is incorrect
//           lives--;
//         }
//       });
//     }

//     // Show popup message with the result
//     if (isCorrect) {
//       _popupKey.currentState?.showCorrect(
//         "Correct! Well done!",
//         currentQuestionIndex == gameObject!.questions.length - 1,
//       );
//     } else {
//       _livesDisplayKey.currentState?.loseLife();
//       if (lives <= 0) {
//         _popupKey.currentState?.showWrong("Game Over! No lives left.", true);
//       } else {
//         _popupKey.currentState?.showWrong(
//           "Incorrect! You have $lives lives left.",
//           false,
//         );
//       }
//     }
//   }
// }
