// import 'package:flutter/material.dart';
// import 'package:writeright/backend/models/questions.dart';
// import 'q_type3.dart';
// import 'q_type5.dart';
// import 'q_type7.dart';
// import 'q_type10.dart';

// void main() {
//   runApp(MaterialApp(home: QuestionListPage()));
// }

// // Question model
// class Question {
//   final String type;
//   final Map<String, dynamic> body; // ✅ Correct type

//   Question({required this.type, required this.body});

//   Map<String, dynamic> toJson() {
//     return {'type': type, 'body': body};
//   }
// }

class QuestionListPage {
  // placeholder
}


// class QuestionListPage extends StatelessWidget {
//   const QuestionListPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text("Questions"),
//         leading: IconButton(
//           icon: Icon(Icons.arrow_back),
//           onPressed: () => Navigator.of(context).maybePop(),
//         ),
//       ),
//       body: ListView.builder(
//         itemCount: sampleQuestions.length,
//         itemBuilder: (context, index) {
//           QuestionBase question = sampleQuestions[index];
//           QuestionType questionType = question.questionType;

//           return Padding(
//             padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//             child: ElevatedButton(
//               onPressed: () {
//                 // Navigate based on question type
//                 Widget destination;
//                 switch (questionType) {
//                   case QuestionType.copyStroke:
//                     destination = CopyStrokeView(
//                       question: question as CopyStrokeQuestion,
//                       onAnswer: (isCorrect) {
//                         // Handle answer submission
//                       },
//                     );
//                     break;
//                 }

//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (_) => destination),
//                 );
//               },
//               child: Text(key),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }

// // Different UI pages for different question types

// class UnknownQuestionPage extends StatelessWidget {
//   final String body;

//   const UnknownQuestionPage({super.key, required this.body});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text("Unknown Question Type")),
//       body: Center(
//         child: Text(
//           "Unrecognized question type.\n\n$body",
//           textAlign: TextAlign.center,
//         ),
//       ),
//     );
//   }
// }
