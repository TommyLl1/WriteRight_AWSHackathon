// import 'package:flutter/material.dart';

// // MC Radical

// class QuestionType10 extends StatefulWidget {
//   final Map<String, dynamic> body;

//   const QuestionType10({super.key, required this.body});

//   @override
//   _WordGameScreenState createState() => _WordGameScreenState();
// }

// class _WordGameScreenState extends State<QuestionType10> {
//   int numberOfLives = 4;
//   String character = "天";
//   List<String> choices = ["請", "清"];
//   String imageUrl = "";
//   String? selectedChoice;

//   @override
//   void initState() {
//     super.initState();

//     // Extract values from widget.body
//     character = widget.body['character'] ?? "";
//     choices = List<String>.from(widget.body['choices'] ?? []);
//     imageUrl = widget.body['image_url'];
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFF0A3D62), // Deep blue background
//       body: SafeArea(
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Top Row with Back Button
//             Padding(
//               padding: const EdgeInsets.all(8.0),
//               child: IconButton(
//                 icon: Icon(Icons.arrow_back, color: Colors.white),
//                 onPressed: () {
//                   Navigator.pop(context);
//                 },
//               ),
//             ),

//             // Lives
//             Padding(
//               padding: const EdgeInsets.symmetric(vertical: 8.0),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: List.generate(
//                   numberOfLives,
//                   (index) => Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 4.0),
//                     child: Icon(
//                       Icons.favorite,
//                       color: Colors.pinkAccent,
//                       size: 28,
//                     ),
//                   ),
//                 ),
//               ),
//             ),

//             const Spacer(),

//             Image.network(
//               imageUrl,
//               width: 300,
//               height: 300,
//               fit: BoxFit.cover,
//               loadingBuilder: (context, child, loadingProgress) {
//                 if (loadingProgress == null) return child;
//                 return Center(
//                   child: CircularProgressIndicator(
//                     value: loadingProgress.expectedTotalBytes != null
//                         ? loadingProgress.cumulativeBytesLoaded /
//                             loadingProgress.expectedTotalBytes!
//                         : null,
//                   ),
//                 );
//               },
//             ),

//             const SizedBox(height: 40),

//             // Choices
//             ...choices.map((choice) {
//               bool isSelected = selectedChoice == choice;
//               return Padding(
//                 padding: const EdgeInsets.symmetric(
//                   vertical: 6.0,
//                   horizontal: 40,
//                 ),
//                 child: ElevatedButton(
//                   onPressed: () {
//                     setState(() {
//                       selectedChoice = choice;
//                     });
//                   },
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: isSelected ? Colors.amber : Colors.black87,
//                     foregroundColor: Colors.white,
//                     minimumSize: const Size.fromHeight(48),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(24),
//                     ),
//                   ),
//                   child: Text(choice, style: const TextStyle(fontSize: 20)),
//                 ),
//               );
//             }),

//             const SizedBox(height: 30),

//             // Submit Button
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 40),
//               child: ElevatedButton(
//                 onPressed: () {
//                   if (selectedChoice != null) {
//                     // Handle submit logic
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       SnackBar(content: Text("You selected: $selectedChoice")),
//                     );
//                   }
//                 },
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.green,
//                   foregroundColor: Colors.white,
//                   minimumSize: const Size.fromHeight(48),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(24),
//                   ),
//                 ),
//                 child: const Text("確定", style: TextStyle(fontSize: 20)),
//               ),
//             ),

//             const Spacer(),
//           ],
//         ),
//       ),
//     );
//   }
// }
