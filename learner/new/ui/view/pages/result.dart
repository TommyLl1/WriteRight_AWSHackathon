// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
// import 'package:provider/provider.dart';
// import 'package:writeright/new/data/models/game.dart';
// import 'package:writeright/new/data/services/image_cache.dart';



// class ResultPage extends StatelessWidget {
//   final SubmitResponse? result;

//   const ResultPage({
//     Key? key,
//     this.result,
//   }) : super(key: key);



//   @override
//   Widget build(BuildContext context) {
//     // Extracting data from the result
//     if (result == null) {
//       return Scaffold(
//         body: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Text(
//               "沒有結果可顯示",
//               style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 20.0),
//             ElevatedButton(
//                   onPressed: () => context.go('/home'),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.blue.shade900,
//                     foregroundColor: Colors.white,
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 64.0,
//                       vertical: 16.0,
//                     ),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(32.0),
//                     ),
//                   ),
//                   child: Text(
//                     "回家", // "Go Home"
//                     style: TextStyle(fontSize: 18.0),
//                   ),
//             ),
//           ],
//         ),
//       );
//     }

//     final int correctAnswers = result!.correctCount;
//     final int totalQuestions = result!.questionCount;
//     final int gainedExp = result!.earnedExp; // Assuming this is the gained EXP
//     final int bonusCoins = 10; // Assuming a fixed value for bonus coins
//     final bool isSuccess = result!.remainingHearts > 0;

//     final imageCache = context.read<CommonImageCache>();

//     return Scaffold(
//       body: Stack(
//         children: [
//           // Background
//           imageCache.getBackgroundWidget(),

//           // Content
//           Center(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 // Result Card
//                 Container(
//                   margin: const EdgeInsets.symmetric(horizontal: 20.0),
//                   padding: const EdgeInsets.all(50.0),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(16.0),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black26,
//                         blurRadius: 10.0,
//                         offset: const Offset(0, 4),
//                       ),
//                     ],
//                   ),
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       // Title
//                       const Text(
//                         "戰績", // "Results"
//                         style: TextStyle(
//                           fontSize: 24.0,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       const SizedBox(height: 16.0),

//                       // Score
//                       Text(
//                         "$correctAnswers / $totalQuestions",
//                         style: const TextStyle(
//                           fontSize: 48.0,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       const SizedBox(height: 16.0),

//                       // Gained EXP and Coins
//                       Text(
//                         "EXP + $gainedExp",
//                         style: const TextStyle(
//                           fontSize: 18.0,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       const SizedBox(height: 8.0),
//                       Text(
//                         "金幣 + $bonusCoins", // "Coins +"
//                         style: const TextStyle(
//                           fontSize: 18.0,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       const SizedBox(height: 16.0),

//                       // Success or Failure Message
//                       Text(
//                         isSuccess
//                             ? "太棒啦!"
//                             : "再接再厲!", // "Great Job!" or "Try Again!"
//                         style: TextStyle(
//                           fontSize: 20.0,
//                           fontWeight: FontWeight.bold,
//                           color: isSuccess ? Colors.blue : Colors.red,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),

//                 const SizedBox(height: 32.0),

//                 // Optional: Retry Button
//                 // ElevatedButton(
//                 //   onPressed: onRetry,
//                 //   style: ElevatedButton.styleFrom(
//                 //     backgroundColor: Colors.blue.shade900,
//                 //     foregroundColor: Colors.white,
//                 //     padding: const EdgeInsets.symmetric(
//                 //       horizontal: 64.0,
//                 //       vertical: 16.0,
//                 //     ),
//                 //     shape: RoundedRectangleBorder(
//                 //       borderRadius: BorderRadius.circular(32.0),
//                 //     ),
//                 //   ),
//                 //   child: const Text(
//                 //     "再來一次！", // "Retry"
//                 //     style: TextStyle(fontSize: 18.0),
//                 //   ),
//                 // ),
//                 // const SizedBox(height: 16.0),                // Return to Home Button
//                 ElevatedButton(
//                   onPressed: () => context.go('/home'),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.blue.shade900,
//                     foregroundColor: Colors.white,
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 64.0,
//                       vertical: 16.0,
//                     ),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(32.0),
//                     ),
//                   ),
//                   child: const Text(
//                     "回家", // "Go Home"
//                     style: TextStyle(fontSize: 18.0),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }


// // Future<void> updateTaskAndStatus() async {
// //   try {
// //     final userStatusStore = GetIt.instance<UserStatusStore>();
// //     final taskStore = GetIt.instance<TaskStore>();

// //     // Update task progress first (if daily task exists)
// //     final dailyTaskId = taskStore.getDailyAdventureTaskId();
// //     if (dailyTaskId != null) {
// //       await taskStore.incrementTaskProgress(dailyTaskId);
// //     }

// //     // Then update user status
// //     await userStatusStore.fetchAndUpdate();
// //   } catch (e) {
// //     // Log error but don't block navigation
// //     AppLogger.error('Error updating task and status: $e');
// //   }
// // }