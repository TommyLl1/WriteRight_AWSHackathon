// // exercise_page.dart
// import 'package:flutter/material.dart';
// import 'package:writeright/game/question_generator.dart';
// import 'game/q_list.dart';
// import 'cards/exercise_card.dart';
// import 'utils/common_image_cache.dart';

// /*
//  * ========================================
//  * HOW TO ADD NEW EXERCISES TO THE CAROUSEL
//  * ========================================
//  * 
//  * To add a new exercise card to the carousel:
//  * 
//  * 1. CREATE THE EXERCISE PAGE/LOGIC:
//  *    - Create your new exercise widget/page (similar to QuestionListPage)
//  *    - Implement the exercise logic and UI
//  * 
//  * 2. ADD THE CARD TO THE CAROUSEL:
//  *    - In the PageView children list below, add a new _buildCarouselCard() call
//  *    - Use the ExerciseCard widget
//  *    - Don't forget to increment the index parameter in _buildCarouselCard()
//  * 
//  * 3. UPDATE THE NAVIGATION CONTROLS:
//  *    - Find the "Total number of cards" comment below
//  *    - Update the number in List.generate() to match your total card count
//  *    - Update the condition in next button (_currentIndex < NEW_TOTAL_MINUS_1)
//  * 
//  * 4. ADD THE EXERCISE IMAGE:
//  *    - Add your exercise image to assets/images/
//  *    - Update pubspec.yaml if needed
//  * 
//  * EXAMPLE:
//  * _buildCarouselCard(
//  *   ExerciseCard(
//  *     title: '我的新練習',
//  *     duration: '12 分鐘',
//  *     imagePath: 'assets/images/my_exercise.png',
//  *     width: 280,
//  *     height: 350,
//  *     onTap: () {
//  *       Navigator.push(
//  *         context,
//  *         MaterialPageRoute(
//  *           builder: (context) => MyNewExercisePage(),
//  *         ),
//  *       );
//  *     },
//  *   ),
//  *   2, // This should be the next available index
//  * ),
//  */

// class ExercisePage extends StatefulWidget {
//   const ExercisePage({super.key});

//   @override
//   State<ExercisePage> createState() => _ExercisePageState();
// }

// class _ExercisePageState extends State<ExercisePage> {
//   // PageController for the carousel with 55% viewport to show card previews
//   final PageController _pageController = PageController(
//     viewportFraction: 0.65,
//     initialPage: 0,
//   );

//   // Track the currently selected card index
//   int _currentIndex = 0;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Stack(
//         children: [
//           // Background Image with Darkened Effect
//           CommonImageCache()
//               .getBackgroundWidget(darkened: true), // Top-left back button
//           Positioned(
//             top: 50,
//             left: 20,
//             child: GestureDetector(
//               onTap: () {
//                 Navigator.pop(context); // Go back to HomePage
//               },
//               child: _iconButton(Icons.arrow_back),
//             ),
//           ),

//           // Top-right menu button (currently disabled)
//           Positioned(
//             top: 50,
//             right: 20,
//             child: GestureDetector(
//               onTap: () {
//                 // TODO: Add menu functionality
//                 //Navigator.push(
//                 //context,
//                 //MaterialPageRoute(builder: (context) => const ProfilePage()),
//                 //);
//               },
//               child: _iconButton(Icons.menu),
//             ),
//           ),

//           // Main content area
//           Padding(
//             padding: const EdgeInsets.only(
//                 top: 120, bottom: 20, left: 20, right: 20),
//             child: Column(
//               children: [
//                 // Page Title
//                 const Text(
//                   '冒險探索',
//                   style: TextStyle(
//                     fontSize: 32,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.white,
//                   ),
//                 ),
//                 const SizedBox(height: 40),

//                 // Exercise Cards Carousel
//                 Expanded(
//                   child: Column(
//                     children: [
//                       // Horizontal scrollable carousel with card previews
//                       Expanded(
//                         child: PageView(
//                           controller: _pageController,
//                           onPageChanged: (index) {
//                             setState(() {
//                               _currentIndex = index;
//                             });
//                           },
//                           children: [
//                             // Adventure Exercise Card - Main functional exercise
//                             _buildCarouselCard(
//                               ExerciseCard(
//                                 title: '冒險探索',
//                                 duration: '10 分鐘',
//                                 imagePath: 'assets/images/diver.png',
//                                 width: 280,
//                                 height: 350,
//                                 onTap: () {
//                                   Navigator.push(
//                                     context,
//                                     MaterialPageRoute(
//                                       builder: (context) => Game(
//                                           key: GlobalKey(), // To reset the state
//                                           userId: "random-user-id"),
//                                     ),
//                                   );
//                                 },
//                               ),
//                               0, // Card index for animation
//                             ),

//                             // Coming Soon Card - Placeholder for future exercises
//                             _buildCarouselCard(
//                               Container(
//                                 width: 280,
//                                 height: 350,
//                                 margin: const EdgeInsets.all(8),
//                                 decoration: BoxDecoration(
//                                   color: Colors.white
//                                       .withAlpha((0.05 * 255).toInt()),
//                                   borderRadius: BorderRadius.circular(20),
//                                   border: Border.all(
//                                     color: Colors.white
//                                         .withAlpha((0.3 * 255).toInt()),
//                                     width: 2,
//                                     style: BorderStyle.solid,
//                                   ),
//                                 ),
//                                 child: const Column(
//                                   mainAxisAlignment: MainAxisAlignment.center,
//                                   children: [
//                                     Icon(
//                                       Icons.add_circle_outline,
//                                       size: 64,
//                                       color: Colors.white54,
//                                     ),
//                                     SizedBox(height: 20),
//                                     Text(
//                                       '更多冒險\n即將推出',
//                                       style: TextStyle(
//                                         fontSize: 20,
//                                         color: Colors.white54,
//                                       ),
//                                       textAlign: TextAlign.center,
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                               1, // Card index for animation
//                             ),
//                           ],
//                         ),
//                       ),

//                       const SizedBox(height: 20),

//                       // Navigation controls row
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           // Previous button - navigate to previous card
//                           GestureDetector(
//                             onTap: _currentIndex > 0
//                                 ? () {
//                                     _pageController.previousPage(
//                                       duration:
//                                           const Duration(milliseconds: 400),
//                                       curve: Curves.easeInOut,
//                                     );
//                                   }
//                                 : null, // Disabled when at first card
//                             child: AnimatedContainer(
//                               duration: const Duration(milliseconds: 200),
//                               width: 50,
//                               height: 50,
//                               decoration: BoxDecoration(
//                                 color: _currentIndex > 0
//                                     ? Colors.white
//                                         .withAlpha((0.25 * 255).toInt())
//                                     : Colors.white
//                                         .withAlpha((0.1 * 255).toInt()),
//                                 borderRadius: BorderRadius.circular(25),
//                                 border: Border.all(
//                                   color: _currentIndex > 0
//                                       ? Colors.white
//                                           .withAlpha((0.6 * 255).toInt())
//                                       : Colors.white
//                                           .withAlpha((0.3 * 255).toInt()),
//                                   width: 1.5,
//                                 ),
//                                 boxShadow: _currentIndex > 0
//                                     ? [
//                                         BoxShadow(
//                                           color: Colors.black
//                                               .withAlpha((0.1 * 255).toInt()),
//                                           blurRadius: 8,
//                                           offset: const Offset(0, 2),
//                                         ),
//                                       ]
//                                     : [],
//                               ),
//                               child: Icon(
//                                 Icons.arrow_back_ios_new,
//                                 color: _currentIndex > 0
//                                     ? Colors.white
//                                     : Colors.white54,
//                                 size: 20,
//                               ),
//                             ),
//                           ),

//                           const SizedBox(width: 30),

//                           // Page indicators - dots showing current position
//                           Row(
//                             children: List.generate(
//                               2, // Total number of cards - UPDATE THIS when adding more exercises
//                               (index) => AnimatedContainer(
//                                 duration: const Duration(milliseconds: 300),
//                                 width: _currentIndex == index ? 12 : 8,
//                                 height: _currentIndex == index ? 12 : 8,
//                                 margin:
//                                     const EdgeInsets.symmetric(horizontal: 4),
//                                 decoration: BoxDecoration(
//                                   shape: BoxShape.circle,
//                                   color: _currentIndex == index
//                                       ? Colors.white
//                                       : Colors.white
//                                           .withAlpha((0.4 * 255).toInt()),
//                                   boxShadow: _currentIndex == index
//                                       ? [
//                                           BoxShadow(
//                                             color: Colors.white
//                                                 .withAlpha((0.3 * 255).toInt()),
//                                             blurRadius: 6,
//                                             spreadRadius: 1,
//                                           ),
//                                         ]
//                                       : [],
//                                 ),
//                               ),
//                             ),
//                           ),

//                           const SizedBox(width: 30),

//                           // Next button - navigate to next card
//                           GestureDetector(
//                             onTap: _currentIndex <
//                                     1 // UPDATE THIS when adding more exercises (total - 1)
//                                 ? () {
//                                     _pageController.nextPage(
//                                       duration:
//                                           const Duration(milliseconds: 400),
//                                       curve: Curves.easeInOut,
//                                     );
//                                   }
//                                 : null, // Disabled when at last card
//                             child: AnimatedContainer(
//                               duration: const Duration(milliseconds: 200),
//                               width: 50,
//                               height: 50,
//                               decoration: BoxDecoration(
//                                 color: _currentIndex < 1
//                                     ? Colors.white
//                                         .withAlpha((0.25 * 255).toInt())
//                                     : Colors.white
//                                         .withAlpha((0.1 * 255).toInt()),
//                                 borderRadius: BorderRadius.circular(25),
//                                 border: Border.all(
//                                   color: _currentIndex < 1
//                                       ? Colors.white
//                                           .withAlpha((0.6 * 255).toInt())
//                                       : Colors.white
//                                           .withAlpha((0.3 * 255).toInt()),
//                                   width: 1.5,
//                                 ),
//                                 boxShadow: _currentIndex < 1
//                                     ? [
//                                         BoxShadow(
//                                           color: Colors.black
//                                               .withAlpha((0.1 * 255).toInt()),
//                                           blurRadius: 8,
//                                           offset: const Offset(0, 2),
//                                         ),
//                                       ]
//                                     : [],
//                               ),
//                               child: Icon(
//                                 Icons.arrow_forward_ios,
//                                 color: _currentIndex < 1
//                                     ? Colors.white
//                                     : Colors.white54,
//                                 size: 20,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),

//                       const SizedBox(height: 40),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // Styled icon button widget for top navigation
//   Widget _iconButton(IconData icon) {
//     return Container(
//       width: 48,
//       height: 48,
//       decoration: BoxDecoration(
//         color: Colors.black.withAlpha((0.6 * 255).toInt()),
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Icon(icon, color: Colors.white),
//     );
//   }

//   @override
//   void dispose() {
//     // Clean up the PageController when the widget is disposed
//     _pageController.dispose();
//     super.dispose();
//   }

//   // Helper method to build carousel cards with proper centering and animation
//   // This creates a scaling effect where the focused card is larger than side cards
//   Widget _buildCarouselCard(Widget card, int index) {
//     return AnimatedBuilder(
//       animation: _pageController,
//       builder: (context, child) {
//         double value = 0.0;
//         if (_pageController.position.haveDimensions) {
//           // Calculate the distance from the current page to this card
//           value = _pageController.page! - index;
//           // Scale the card based on distance (closer = larger)
//           value = (1 - (value.abs() * 0.15)).clamp(0.85, 1.0);
//         } else {
//           // Fallback for when page controller isn't ready
//           value = _currentIndex == index ? 1.0 : 0.85;
//         }

//         return Center(
//           child: Transform.scale(
//             scale: value,
//             child: card,
//           ),
//         );
//       },
//     );
//   }
// }
